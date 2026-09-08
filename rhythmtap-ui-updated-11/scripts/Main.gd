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
@onready var player_hp_rail: Control = $UI/PlayerHpRail
@onready var player_side_fill: ColorRect = $UI/PlayerHpRail/Fill
@onready var player_side_ghost: ColorRect = $UI/PlayerHpRail/Ghost
@onready var player_side_name: Label = $UI/PlayerHpRail/NameLabel
@onready var enemy_hp_rail: Control = $UI/EnemyHpRail
@onready var enemy_side_fill: ColorRect = $UI/EnemyHpRail/Fill
@onready var enemy_side_ghost: ColorRect = $UI/EnemyHpRail/Ghost
@onready var enemy_side_name: Label = $UI/EnemyHpRail/NameLabel
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
var _hp_ghost_height: float = -1.0
var _shake_tween: Tween = null
var _card_stagger_tween: Tween = null
var _enemy_card_base_offsets: Vector2 = Vector2.ZERO
func _ready():
	game_manager = $GameManager
	room_manager = $RoomManager
	beat_bar     = $BeatLayer/BeatBar
	background   = $Background
	beat_sound   = $SoundPlayers/BeatSound
	beat_sound.stream       = SoundGen.create_beat_hit()
	game_manager.beat_sound = beat_sound
	beat_bar.game_manager   = game_manager
	# Edge HP rails replace the old top HP strip + enemy card ATK block.
	hp_label.visible = false
	hp_bar_fill.get_parent().visible = false
	atk_label.visible = false
	enemy_card_anchor.visible = false
	if enemy_atk_label:
		enemy_atk_label.visible = false
	player_side_name.text = "YOU"
	_setup_side_hp_labels()
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

func _setup_side_hp_labels() -> void:
	for lab in [player_side_name, enemy_side_name]:
		if lab == null:
			continue
		lab.add_theme_font_size_override("font_size", 32)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.autowrap_mode = TextServer.AUTOWRAP_OFF
		lab.rotation_degrees = -90.0
		lab.set_anchors_preset(Control.PRESET_FULL_RECT)
		lab.offset_left = -120.0
		lab.offset_right = 120.0
		lab.offset_top = 0.0
		lab.offset_bottom = 0.0
func _update_all_hud():
	_update_player_hud()
	_update_enemy_hud()
func _update_player_hud():
	var gm = game_manager
	var hp_dropped: bool = _tracked_player_hp >= 0 and gm.player_health < _tracked_player_hp
	hp_label.text  = "HP: %d/%d" % [gm.player_health, gm.player_max_health]
	atk_label.text = "ATK: %d" % gm.player_damage
	level_label.text = "LV %d" % gm.player_level
	xp_label.text    = "XP: %d/%d" % [gm.player_xp, gm.xp_to_next_level()]
	_gold_target = float(gm.player_gold)
	var p_pct = clamp(
		float(gm.player_health) / float(gm.player_max_health) if gm.player_max_health > 0 else 0.0,
		0.0, 1.0)
	var bg_h: float = maxf(1.0, player_hp_rail.size.y)
	var new_h: float = bg_h * p_pct
	if hp_dropped:
		var prev_h: float = player_side_fill.size.y if player_side_fill.size.y > 0.0 else new_h
		if _hp_ghost_height < 0.0:
			_hp_ghost_height = prev_h
		else:
			_hp_ghost_height = maxf(_hp_ghost_height, prev_h)
		_play_player_hurt_feedback()
	elif _tracked_player_hp >= 0 and gm.player_health >= _tracked_player_hp:
		_hp_ghost_height = new_h
	_apply_vertical_fill(player_side_fill, player_hp_rail.size, new_h, Color(0.95, 0.15, 0.15, 1) if p_pct <= 0.25 else \
						Color(0.95, 0.65, 0.1,  1) if p_pct <= 0.5  else \
						Color(0.85, 0.85, 0.85, 0.95))
	player_side_name.text = "YOU  %d/%d" % [gm.player_health, gm.player_max_health]
	if player_side_ghost:
		if _hp_ghost_height < 0.0:
			_hp_ghost_height = new_h
		_apply_vertical_fill(player_side_ghost, player_hp_rail.size, maxf(_hp_ghost_height, new_h), Color(0.9, 0.12, 0.12, 0.55))
	_tracked_player_hp = gm.player_health

func _update_enemy_hud():
	var gm = game_manager
	var pretty := "Enemy"
	if gm.active_enemy:
		pretty = gm.active_enemy_type.replace("_", " ").capitalize()
		enemy_name_label.text = "- %s -" % pretty
		enemy_atk_label.text  = "ATK: %d" % gm.active_enemy.damage
	var e_pct = clamp(
		float(gm.enemy_health) / float(gm.enemy_max_health) if gm.enemy_max_health > 0 else 0.0,
		0.0, 1.0)
	var bg_h: float = maxf(1.0, enemy_hp_rail.size.y)
	var new_h: float = bg_h * e_pct
	_apply_vertical_fill(enemy_side_fill, enemy_hp_rail.size, new_h, Color(0.95, 0.35, 0.55, 1) if e_pct <= 0.25 else \
						Color(0.95, 0.55, 0.35, 1) if e_pct <= 0.5 else \
						Color(0.9, 0.75, 0.85, 0.95))
	enemy_side_name.text = "%s  %d/%d" % [pretty, gm.enemy_health, gm.enemy_max_health]
	if enemy_side_ghost:
		_apply_vertical_fill(enemy_side_ghost, enemy_hp_rail.size, new_h, Color(0.7, 0.2, 0.35, 0.35))
	if enemy_hp_bar_fill and enemy_hp_bar_fill.get_parent():
		enemy_hp_bar_fill.size.x = enemy_hp_bar_fill.get_parent().size.x * e_pct

func _apply_vertical_fill(fill: ColorRect, rail_size: Vector2, height: float, col: Color) -> void:
	var w: float = maxf(1.0, rail_size.x)
	var h: float = maxf(0.0, minf(height, rail_size.y))
	fill.color = col
	fill.size = Vector2(w, h)
	fill.position = Vector2(0.0, maxf(0.0, rail_size.y - h))

func _process(delta: float):
	background.size = get_viewport().get_visible_rect().size
	beat_bar.size = get_viewport().get_visible_rect().size
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
	if player_side_ghost and _hp_ghost_height >= 0.0:
		var fill_h: float = player_side_fill.size.y
		if _hp_ghost_height > fill_h:
			var drain := maxf(36.0, (_hp_ghost_height - fill_h) * 2.8)
			_hp_ghost_height = move_toward(_hp_ghost_height, fill_h, drain * delta)
		else:
			_hp_ghost_height = fill_h
		_apply_vertical_fill(player_side_ghost, player_hp_rail.size, _hp_ghost_height, Color(0.9, 0.12, 0.12, 0.55))
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
	room_manager.advance_room()
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
				FirstMeetBridge.begin(enemy, room_manager.get_room_number() - 1, game_manager)
				get_tree().change_scene_to_file("res://scenes/FirstMeetVN.tscn")
				return
			if game_manager.game_state == game_manager.GameState.TREASURE:
				game_manager.continue_after_treasure(enemy)
			else:
				game_manager.begin_encounter(enemy)
			MusicDirector.play("combat")
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
	if ActiveRun.state and not ActiveRun.state.conceded:
		ActiveRun.mark_cleared()
	ActiveRun.end_run()
	MusicDirector.stop()
	get_tree().change_scene_to_file("res://scenes/Town.tscn")
func _on_new_beat(beat_num: int):
	beat_bar.on_beat()
	background.on_beat(beat_num)
func _on_enemy_state_changed(state: String):
	background.on_enemy_state_changed(state)
	if state == "hurt":
		_play_enemy_hit_feedback()
func _on_enemy_type_swapped(type_name: String):
	background.load_enemy_assets(type_name)
	var pretty = type_name.replace("_", " ").capitalize()
	enemy_name_label.text = "- %s -" % pretty
	enemy_side_name.text = pretty
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
	loser_button.visible      = true
	enemy_hp_rail.visible = false
func _on_survival_success():
	loser_button.visible      = false
	enemy_hp_rail.visible = true
	call_deferred("_force_enemy_bar_update")
func _force_enemy_bar_update():
	game_manager.emit_signal("enemy_hp_changed")
func _on_loser_pressed():
	if game_manager.game_state != game_manager.GameState.SURVIVAL:
		return
	SoundGen.play_ui_click()
	loser_button.visible = false
	game_manager.on_player_concedes()
func _on_enter_punishment(_enemy_name: String):
	countdown_label.modulate = Color(1, 1, 1, 1)
	_update_player_hud()
func _on_punishment_tick(seconds_left: float):
	countdown_label.text = str(int(ceil(seconds_left)))
	var pulse = fmod(seconds_left, 1.0)
	countdown_label.scale = Vector2.ONE * (1.0 + (1.0 - pulse) * 0.25)
func _on_game_over(_enemy_name: String):
	countdown_label.modulate = Color(1, 1, 1, 0)
	await get_tree().create_timer(4.0).timeout
	ActiveRun.end_run()
	MusicDirector.stop()
	get_tree().change_scene_to_file("res://scenes/Town.tscn")
func _play_player_hurt_feedback() -> void:
	SoundGen.play_hurt()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	# Never shake the UI CanvasLayer — BeatBar lives there and must stay rock-steady.
	ui_layer.offset = Vector2.ZERO
	background.position = Vector2.ZERO
	_shake_tween = create_tween()
	_shake_tween.tween_property(background, "position", Vector2(6, -4), 0.035)
	_shake_tween.tween_property(background, "position", Vector2(-5, 4), 0.04)
	_shake_tween.tween_property(background, "position", Vector2(3, -2), 0.035)
	_shake_tween.tween_property(background, "position", Vector2.ZERO, 0.05)
func _play_enemy_hit_feedback() -> void:
	SoundGen.play_hit()
	if background.has_method("play_hit_stagger"):
		background.play_hit_stagger()
	if _card_stagger_tween and _card_stagger_tween.is_valid():
		_card_stagger_tween.kill()
	var base_l: float = enemy_hp_rail.offset_left
	var base_r: float = enemy_hp_rail.offset_right
	enemy_hp_rail.offset_left = base_l
	enemy_hp_rail.offset_right = base_r
	_card_stagger_tween = create_tween()
	_card_stagger_tween.tween_callback(func():
		enemy_hp_rail.offset_left = base_l - 4.0
		enemy_hp_rail.offset_right = base_r - 4.0
	)
	_card_stagger_tween.tween_interval(0.045)
	_card_stagger_tween.tween_callback(func():
		enemy_hp_rail.offset_left = base_l + 4.0
		enemy_hp_rail.offset_right = base_r + 4.0
	)
	_card_stagger_tween.tween_interval(0.07)
	_card_stagger_tween.tween_callback(func():
		enemy_hp_rail.offset_left = base_l
		enemy_hp_rail.offset_right = base_r
	)
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
	t.add_theme_font_size_override("font_size", 32)
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
