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
	loser_button.text = "I can't hold it..."
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

	# RoomManager drives the run from ActiveRun (guild quest) when present
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
	if ActiveRun.state:
		var bag = Label.new()
		bag.text = "Quest bag: %d Gold" % ActiveRun.state.treasure_bag_gold
		bag.add_theme_font_size_override("font_size", 14)
		bag.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		loot_list.add_child(bag)
	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(1.0, 0.88, 0.2, 0.55))
	loot_list.add_child(sep)
	treasure_screen.visible = true

func _on_treasure_continue():
	SoundGen.play_ui_click()
	treasure_screen.visible = false
	# Always advance — past the last room this emits run_complete
	room_manager.advance_room()

# ── Room Routing ──────────────────────────────────────────────────────────────
# RoomManager emits room_started with the room dict; we dispatch here.
# First combat room is a no-op because GameManager already booted with "goblin".
func _on_room_started(room: Dictionary):
	var room_num = room_manager.get_room_number()
	var total    = room_manager.get_total_rooms()
	if ActiveRun.state and ActiveRun.state.quest:
		stage_label.text = ActiveRun.state.quest_progress_label()
	else:
		stage_label.text = "QUEST %d/%d" % [room_num, total]

	match room.get("type", ""):
		"combat":
			var enemy = room.get("enemy", "slime_girl")
			if not MetaSave.has_met_enemy(enemy):
				await _play_first_meet_intro(enemy)
				MetaSave.mark_enemy_met(enemy)
				MetaSave.save_to_disk()
			if game_manager.game_state == game_manager.GameState.TREASURE:
				game_manager.continue_after_treasure(enemy)
			else:
				# First room (or non-treasure combat): sync encounter to quest enemy
				game_manager.begin_encounter(enemy)
		"rest":
			await _run_rest_room()
		"shop":
			await _run_shop_room()

func _show_simple_notice(text: String) -> void:
	dialogue_label.text = text
	_dialogue_timer = 1.5
	dialogue_bubble.visible = true
	dialogue_bubble.modulate = Color(1, 1, 1, 1)

func _on_run_complete():
	# Bank run treasure into MetaSave, then return to town
	if ActiveRun.state and not ActiveRun.state.conceded:
		ActiveRun.mark_cleared()
	ActiveRun.end_run()
	get_tree().change_scene_to_file("res://scenes/Town.tscn")

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
	# Fail path already called ActiveRun.mark_conceded in on_player_concedes
	ActiveRun.end_run()
	get_tree().change_scene_to_file("res://scenes/Town.tscn")


# ── Phase 6: first-meet enemy intro ───────────────────────────────────────────
func _play_first_meet_intro(enemy_id: String) -> void:
	game_manager.set_process(false)
	var pages := FirstMeetScenes.enemy_pages(enemy_id)
	var pretty := enemy_id.replace("_", " ").capitalize()
	var title := "- FIRST MEETING: %s -" % pretty
	for i in range(pages.size()):
		var last: bool = i >= pages.size() - 1
		var btn := "Face her" if last else "Continue (%d/%d)" % [i + 1, pages.size()]
		_show_choice_overlay(title, pages[i], btn, func(): pass)
		await _overlay_done
	game_manager.set_process(true)

func _run_rest_room() -> void:
	var heal := int(game_manager.player_max_health * 0.35)
	game_manager.player_health = mini(game_manager.player_max_health, game_manager.player_health + heal)
	game_manager.emit_signal("player_stats_changed")
	_show_choice_overlay(
		"- REST -",
		"You catch your breath. Resolve +%d HP." % heal,
		"Continue",
		func(): room_manager.advance_room()
	)
	await _overlay_done

func _run_shop_room() -> void:
	# Cheap mid-run purchases from the quest bag / temporary HP
	var price := 20
	var can_buy: bool = int(game_manager.player_gold) >= price
	var detail := "Travelling merchant.\n20 gold: +8 HP now (from quest bag)."
	if not can_buy:
		detail += "\n(You can't afford anything — move on.)"
	_show_choice_overlay(
		"- SHOP -",
		detail,
		"Buy tonic" if can_buy else "Leave",
		func():
			if can_buy and game_manager.player_gold >= price:
				game_manager.player_gold -= price
				if ActiveRun.state:
					ActiveRun.state.treasure_bag_gold = maxi(0, ActiveRun.state.treasure_bag_gold - price)
				game_manager.player_health = mini(game_manager.player_max_health, game_manager.player_health + 8)
				game_manager.emit_signal("player_stats_changed")
			room_manager.advance_room()
	)
	# Always offer a leave if buy shown — second button
	if can_buy and _overlay_secondary:
		_overlay_secondary.text = "Leave"
		_overlay_secondary.visible = true
		if not _overlay_secondary.pressed.is_connected(_on_overlay_leave):
			_overlay_secondary.pressed.connect(_on_overlay_leave)
	await _overlay_done

signal _overlay_done

var _overlay_root: Control = null
var _overlay_secondary: Button = null

func _show_choice_overlay(title: String, body: String, primary: String, on_primary: Callable) -> void:
	if _overlay_root:
		_overlay_root.queue_free()
	_overlay_root = PanelContainer.new()
	_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(_overlay_root)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_top", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_bottom", 80)
	_overlay_root.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 28)
	v.add_child(t)
	var b := Label.new()
	b.text = body
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var btn := Button.new()
	btn.text = primary
	btn.pressed.connect(func():
		SoundGen.play_ui_click()
		_close_overlay()
		on_primary.call()
	)
	row.add_child(btn)
	_overlay_secondary = Button.new()
	_overlay_secondary.visible = false
	row.add_child(_overlay_secondary)

func _on_overlay_leave() -> void:
	SoundGen.play_ui_click()
	_close_overlay()
	room_manager.advance_room()

func _close_overlay() -> void:
	if _overlay_root:
		_overlay_root.queue_free()
		_overlay_root = null
	_overlay_secondary = null
	emit_signal("_overlay_done")

