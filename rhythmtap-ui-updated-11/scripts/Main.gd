extends Node
# =============================================================================
# Main.gd — ALPHA BUILD
# =============================================================================
# Scene controller for the gameplay screen (Main.tscn).
# Owns all UI node references and wires GameManager + RoomManager signals
# to the interface. Does not contain game logic — that lives in GameManager.
#
# UI STRUCTURE (all children of the UI CanvasLayer in Main.tscn):
#   TopHud          — stage/level/XP/HP/ATK/gold bar across the very top (always visible)
#   BeatBar         — approach track drawn at bottom; player taps here
#   EnemyCardAnchor — enemy name/HP/ATK card, bottom-center
#   DialogueBubble  — speech bubble, top-right, auto-fades after DIALOGUE_SHOW_SEC
#   LoserButton     — only visible during SURVIVAL; styled as a real button
#   CountdownLabel  — big pulsing countdown during PUNISHMENT, scales from center
#                      (pivot_offset set in Main.tscn so it doesn't drift top-left)
#   TreasureScreen  — full overlay (starts at y=48 so TopHud stays visible)
#
# GOLD ANIMATION:
#   _gold_display chases _gold_target in _process() each frame.
#   Speed scales with the difference so large gains animate fast then taper off.
#   This means the label always shows the animated value, not the raw stat.
#
# ENEMY HP BAR:
#   Uses size.x (pixels) not scale.x — scale fights Godot's anchor layout system
#   and resets on hide/show cycles. After survival the card is hidden then reshown,
#   so _force_enemy_bar_update() fires a deferred enemy_hp_changed to redraw
#   the bar once layout has settled.
# =============================================================================

var game_manager: Node
var room_manager: Node
var beat_bar:     Control
var background:   Control
var beat_sound:   AudioStreamPlayer

# ── UI Node Refs ──────────────────────────────────────────────────────────────
@onready var ui_layer: CanvasLayer = $UI

@onready var stage_label:   Label     = $UI/TopHud/MarginContainer/HBoxContainer/StageLabel
@onready var level_label:   Label     = $UI/TopHud/MarginContainer/HBoxContainer/LevelLabel
@onready var xp_label:      Label     = $UI/TopHud/MarginContainer/HBoxContainer/XPLabel
@onready var hp_label:      Label     = $UI/TopHud/MarginContainer/HBoxContainer/HPLabel
@onready var hp_bar_fill:   ColorRect = $UI/TopHud/MarginContainer/HBoxContainer/HPBarBg/HPBarFill
@onready var atk_label:     Label     = $UI/TopHud/MarginContainer/HBoxContainer/AtkLabel
@onready var gold_label:    Label     = $UI/TopHud/MarginContainer/HBoxContainer/GoldLabel

@onready var enemy_card_anchor: Control   = $UI/EnemyCardAnchor
@onready var enemy_name_label:  Label     = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/EnemyNameLabel
@onready var enemy_hp_bar_fill: ColorRect = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/HPRow/EnemyHPBarBg/EnemyHPBarFill
@onready var enemy_atk_label:   Label     = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/EnemyAtkLabel

@onready var dialogue_bubble: PanelContainer = $UI/DialogueBubble
@onready var dialogue_label:  Label          = $UI/DialogueBubble/MarginContainer/DialogueLabel

@onready var loser_button:    Button = $UI/LoserButton
@onready var countdown_label: Label  = $UI/CountdownLabel

@onready var treasure_screen: PanelContainer = $UI/TreasureScreen
@onready var loot_list:       VBoxContainer  = $UI/TreasureScreen/MarginContainer/VBoxContainer/LootList
@onready var continue_button: Button         = $UI/TreasureScreen/MarginContainer/VBoxContainer/ContinueButton

# ── State ─────────────────────────────────────────────────────────────────────
var _dialogue_timer: float = 0.0
const DIALOGUE_SHOW_SEC: float = 3.5

# Gold animation — _gold_display is what's shown, chases _gold_target
var _gold_display: float = 0.0
var _gold_target:  float = 0.0

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready():
	game_manager = $GameManager
	room_manager = $RoomManager
	beat_bar     = $UI/BeatBar
	background   = $Background
	beat_sound   = $SoundPlayers/BeatSound

	# SoundGen is an autoload — generates the beat click sound procedurally
	beat_sound.stream       = SoundGen.create_beat_hit()
	game_manager.beat_sound = beat_sound
	beat_bar.game_manager   = game_manager

	loser_button.visible = false
	loser_button.pressed.connect(_on_loser_pressed)
	continue_button.pressed.connect(_on_treasure_continue)

	game_manager.new_beat.connect(_on_new_beat)
	game_manager.enemy_state_changed.connect(_on_enemy_state_changed)
	game_manager.enemy_type_swapped.connect(_on_enemy_type_swapped)
	game_manager.player_stats_changed.connect(_update_player_hud)
	game_manager.enemy_hp_changed.connect(_update_enemy_hud)
	game_manager.enemy_dialogue.connect(_on_enemy_dialogue)
	game_manager.enemy_defeated.connect(_on_enemy_defeated)
	game_manager.enter_survival.connect(_on_enter_survival)
	game_manager.survival_success.connect(_on_survival_success)
	game_manager.enter_punishment.connect(_on_enter_punishment)
	game_manager.punishment_tick.connect(_on_punishment_tick)
	game_manager.game_over.connect(_on_game_over)

	room_manager.room_started.connect(_on_room_started)
	room_manager.run_complete.connect(_on_run_complete)

	_on_enemy_type_swapped(game_manager.active_enemy_type)
	_gold_display = float(game_manager.player_gold)
	_gold_target  = _gold_display

	# Deferred so Godot's layout pass runs first and size.x values are real
	call_deferred("_update_all_hud")

	# RoomManager drives the run; first room_started fires here
	room_manager.start_run()

# ── HUD Update ────────────────────────────────────────────────────────────────
func _update_all_hud():
	_update_player_hud()
	_update_enemy_hud()

func _update_player_hud():
	var gm = game_manager
	hp_label.text  = "HP: %d/%d" % [gm.player_health, gm.player_max_health]
	atk_label.text = "ATK: %d" % gm.player_damage
	level_label.text = "LV %d" % gm.player_level
	xp_label.text    = "XP: %d/%d" % [gm.player_xp, gm.xp_to_next_level()]
	# Don't set gold_label here — it's animated in _process via _gold_target
	_gold_target = float(gm.player_gold)

	var p_pct = clamp(
		float(gm.player_health) / float(gm.player_max_health) if gm.player_max_health > 0 else 0.0,
		0.0, 1.0)
	hp_bar_fill.size.x = hp_bar_fill.get_parent().size.x * p_pct
	hp_bar_fill.color = Color(0.95, 0.15, 0.15, 1) if p_pct <= 0.25 else \
						Color(0.95, 0.65, 0.1,  1) if p_pct <= 0.5  else \
						Color(0.85, 0.85, 0.85, 1)

func _update_enemy_hud():
	var gm = game_manager
	if gm.active_enemy:
		var pretty = gm.active_enemy_type.replace("_", " ").capitalize()
		enemy_name_label.text = "- %s -" % pretty
		enemy_atk_label.text  = "ATK: %d" % gm.active_enemy.damage
	var e_pct = clamp(
		float(gm.enemy_health) / float(gm.enemy_max_health) if gm.enemy_max_health > 0 else 0.0,
		0.0, 1.0)
	enemy_hp_bar_fill.size.x = enemy_hp_bar_fill.get_parent().size.x * e_pct

# ── Process ───────────────────────────────────────────────────────────────────
func _process(delta: float):
	background.size = get_viewport().get_visible_rect().size
	beat_bar.size   = background.size

	# Dialogue fade-out — alpha reaches 0 then hides the node
	if _dialogue_timer > 0.0:
		_dialogue_timer -= delta
		dialogue_bubble.modulate.a = min(1.0, _dialogue_timer * 2.0)
		if _dialogue_timer <= 0.0:
			dialogue_bubble.visible = false

	# Animated gold counter — fast when far from target, tapers as it approaches
	if not is_equal_approx(_gold_display, _gold_target):
		var diff  = _gold_target - _gold_display
		var speed = max(abs(diff) * 3.0, 10.0)
		_gold_display = move_toward(_gold_display, _gold_target, speed * delta)
		gold_label.text = "Gold: %d" % int(_gold_display)

# ── Treasure Screen ───────────────────────────────────────────────────────────
func _show_treasure_screen(gold_reward: int):
	for child in loot_list.get_children():
		child.queue_free()
	var row = Label.new()
	row.text = "%d Gold" % gold_reward
	row.add_theme_font_size_override("font_size", 18)
	row.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1))
	loot_list.add_child(row)
	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(1.0, 0.88, 0.2, 0.55))
	loot_list.add_child(sep)
	treasure_screen.visible = true

func _on_treasure_continue():
	SoundGen.play_ui_click()
	treasure_screen.visible = false
	if room_manager.has_next_room():
		room_manager.advance_room()
	else:
		# run_complete is emitted by RoomManager when no rooms remain
		pass

# ── Room Routing ──────────────────────────────────────────────────────────────
# RoomManager emits room_started with the room dict; we dispatch here.
# First combat room is a no-op because GameManager already booted with "goblin".
func _on_room_started(room: Dictionary):
	var room_num = room_manager.get_room_number()
	var total    = room_manager.get_total_rooms()
	stage_label.text = "QUEST %d/%d" % [room_num, total]

	match room.get("type", ""):
		"combat":
			var enemy = room.get("enemy", "slime_girl")
			if game_manager.game_state == game_manager.GameState.TREASURE:
				game_manager.continue_after_treasure(enemy)
			# else: first room, GameManager already initialised in _ready
		"rest":
			pass  # TODO: show rest room UI — heal, maybe a dialogue scene
		"shop":
			pass  # TODO: show shop UI — spend gold on upgrades/items

func _on_run_complete():
	# TODO: victory screen. For now just return to menu.
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ── Signal Handlers ───────────────────────────────────────────────────────────
func _on_new_beat(beat_num: int):
	beat_bar.on_beat()
	background.on_beat(beat_num)

func _on_enemy_state_changed(state: String):
	background.on_enemy_state_changed(state)

func _on_enemy_type_swapped(type_name: String):
	background.load_enemy_assets(type_name)
	var pretty = type_name.replace("_", " ").capitalize()
	enemy_name_label.text = "- %s -" % pretty



func _on_enemy_dialogue(text: String):
	if text == "":
		return
	dialogue_label.text      = text
	_dialogue_timer          = DIALOGUE_SHOW_SEC
	dialogue_bubble.visible  = true
	dialogue_bubble.modulate = Color(1, 1, 1, 1)

func _on_enemy_defeated(gold_reward: int):
	_show_treasure_screen(gold_reward)

func _on_enter_survival(_enemy_name: String):
	# Hide the enemy card while the loser button is showing — they overlap
	loser_button.visible      = true
	enemy_card_anchor.visible = false

func _on_survival_success():
	loser_button.visible      = false
	enemy_card_anchor.visible = true
	# Defer so layout settles before we read size.x for the HP bar
	call_deferred("_force_enemy_bar_update")

func _force_enemy_bar_update():
	# 0-damage signal: re-triggers _update_enemy_hud() once the node
	# is visible and laid out so size.x is a real pixel value
	game_manager.emit_signal("enemy_hp_changed")

func _on_loser_pressed():
	if game_manager.game_state != game_manager.GameState.SURVIVAL:
		return
	SoundGen.play_ui_click()
	loser_button.visible = false
	game_manager.on_player_concedes()

func _on_enter_punishment(_enemy_name: String):
	# Countdown ticks immediately — no delay (simplified from earlier version)
	countdown_label.modulate = Color(1, 1, 1, 1)

func _on_punishment_tick(seconds_left: float):
	countdown_label.text = str(int(ceil(seconds_left)))
	var pulse = fmod(seconds_left, 1.0)
	countdown_label.scale = Vector2.ONE * (1.0 + (1.0 - pulse) * 0.25)

func _on_game_over(_enemy_name: String):
	countdown_label.modulate = Color(1, 1, 1, 0)
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
