extends Node
var game_manager: Node
var room_manager: Node
var beat_bar:     Control
var background:   Control
var beat_sound:   AudioStreamPlayer
@onready var ui_layer: CanvasLayer = $UI
@onready var stage_label:   Label     = $UI/TopHud/MarginContainer/HBoxContainer/StageLabel
@onready var level_label:   Label     = $UI/TopHud/MarginContainer/HBoxContainer/LevelLabel
@onready var xp_label:      Label     = $UI/TopHud/MarginContainer/HBoxContainer/XPLabel
@onready var hp_label:      Label     = $UI/TopHud/MarginContainer/HBoxContainer/HPLabel
@onready var hp_bar_fill:   ColorRect = $UI/TopHud/MarginContainer/HBoxContainer/HPBarBg/HPBarFill
@onready var hp_bar_ghost:  ColorRect = $UI/TopHud/MarginContainer/HBoxContainer/HPBarBg/HPBarGhost
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
var _dialogue_timer: float = 0.0
const DIALOGUE_SHOW_SEC: float = 3.5
var _gold_display: float = 0.0
var _gold_target:  float = 0.0
var _tracked_player_hp: int = -1
var _hp_ghost_width: float = -1.0
var _shake_tween: Tween = null
var _card_stagger_tween: Tween = null
var _enemy_card_base_offsets: Vector2 = Vector2.ZERO
func _ready():
	game_manager = $GameManager
	room_manager = $RoomManager
	beat_bar     = $UI/BeatBar
	background   = $Background
	beat_sound   = $SoundPlayers/BeatSound
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
	_tracked_player_hp = game_manager.player_health
	_enemy_card_base_offsets = Vector2(enemy_card_anchor.offset_left, enemy_card_anchor.offset_right)
	call_deferred("_update_all_hud")
	if FirstMeetBridge.return_to_combat:
		FirstMeetBridge.return_to_combat = false
		var idx: int = FirstMeetBridge.saved_room_index
		FirstMeetBridge.apply_combat(game_manager)
		_gold_display = float(game_manager.player_gold)
		_gold_target = _gold_display
		room_manager.restore_at_room(idx)
		FirstMeetBridge.clear()
	else:
		room_manager.start_run()
func _update_all_hud():
	_update_player_hud()
	_update_enemy_hud()
func _update_player_hud():
	var gm = game_manager
	var hp_dropped := _tracked_player_hp >= 0 and gm.player_health < _tracked_player_hp
	hp_label.text  = "HP: %d/%d" % [gm.player_health, gm.player_max_health]
	atk_label.text = "ATK: %d" % gm.player_damage
	level_label.text = "LV %d" % gm.player_level
	xp_label.text    = "XP: %d/%d" % [gm.player_xp, gm.xp_to_next_level()]
	_gold_target = float(gm.player_gold)
	var p_pct = clamp(
		float(gm.player_health) / float(gm.player_max_health) if gm.player_max_health > 0 else 0.0,
		0.0, 1.0)
	var bg_w: float = hp_bar_fill.get_parent().size.x
	var new_w: float = bg_w * p_pct
	if hp_dropped:
		var prev_w: float = hp_bar_fill.size.x if hp_bar_fill.size.x > 0.0 else new_w
		if _hp_ghost_width < 0.0:
			_hp_ghost_width = prev_w
		else:
			_hp_ghost_width = maxf(_hp_ghost_width, prev_w)
		_play_player_hurt_feedback()
	elif _tracked_player_hp >= 0 and gm.player_health >= _tracked_player_hp:
		_hp_ghost_width = new_w
	hp_bar_fill.size.x = new_w
	hp_bar_fill.color = Color(0.95, 0.15, 0.15, 1) if p_pct <= 0.25 else \
						Color(0.95, 0.65, 0.1,  1) if p_pct <= 0.5  else \
						Color(0.85, 0.85, 0.85, 1)
	if hp_bar_ghost:
		hp_bar_ghost.position = Vector2.ZERO
		hp_bar_ghost.size.y = hp_bar_fill.size.y if hp_bar_fill.size.y > 0.0 else hp_bar_fill.get_parent().size.y
		if _hp_ghost_width < 0.0:
			_hp_ghost_width = new_w
		hp_bar_ghost.size.x = maxf(_hp_ghost_width, new_w)
	_tracked_player_hp = gm.player_health
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
func _process(delta: float):
	background.size = get_viewport().get_visible_rect().size
	beat_bar.size   = background.size
	if _dialogue_timer > 0.0:
		_dialogue_timer -= delta
		dialogue_bubble.modulate.a = min(1.0, _dialogue_timer * 2.0)
		if _dialogue_timer <= 0.0:
			dialogue_bubble.visible = false
	if not is_equal_approx(_gold_display, _gold_target):
		var diff  = _gold_target - _gold_display
		var speed = max(abs(diff) * 3.0, 10.0)
		_gold_display = move_toward(_gold_display, _gold_target, speed * delta)
		gold_label.text = "Gold: %d" % int(_gold_display)
	if hp_bar_ghost and _hp_ghost_width >= 0.0:
		var fill_w: float = hp_bar_fill.size.x
		if _hp_ghost_width > fill_w:
			var drain := maxf(36.0, (_hp_ghost_width - fill_w) * 2.8)
			_hp_ghost_width = move_toward(_hp_ghost_width, fill_w, drain * delta)
		else:
			_hp_ghost_width = fill_w
		hp_bar_ghost.size.x = _hp_ghost_width
		hp_bar_ghost.size.y = hp_bar_fill.size.y if hp_bar_fill.size.y > 0.0 else hp_bar_fill.get_parent().size.y
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
