extends "res://scripts/MainBase.gd"
# Phase 12 Main — remainder of scene controller (UI clarity via Phase12CombatUI autoload)
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
	enemy_card_anchor.visible = false
func _on_survival_success():
	loser_button.visible      = false
	enemy_card_anchor.visible = true
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
	ui_layer.offset = Vector2.ZERO
	_shake_tween = create_tween()
	_shake_tween.tween_property(ui_layer, "offset", Vector2(5, -3), 0.035)
	_shake_tween.tween_property(ui_layer, "offset", Vector2(-4, 3), 0.04)
	_shake_tween.tween_property(ui_layer, "offset", Vector2(3, -2), 0.035)
	_shake_tween.tween_property(ui_layer, "offset", Vector2.ZERO, 0.05)
func _play_enemy_hit_feedback() -> void:
	SoundGen.play_hit()
	if background.has_method("play_hit_stagger"):
		background.play_hit_stagger()
	if _card_stagger_tween and _card_stagger_tween.is_valid():
		_card_stagger_tween.kill()
	var base_l: float = _enemy_card_base_offsets.x
	var base_r: float = _enemy_card_base_offsets.y
	enemy_card_anchor.offset_left = base_l
	enemy_card_anchor.offset_right = base_r
	_card_stagger_tween = create_tween()
	_card_stagger_tween.tween_callback(func():
		enemy_card_anchor.offset_left = base_l + 6.0
		enemy_card_anchor.offset_right = base_r + 6.0
	)
	_card_stagger_tween.tween_interval(0.045)
	_card_stagger_tween.tween_callback(func():
		enemy_card_anchor.offset_left = base_l - 6.0
		enemy_card_anchor.offset_right = base_r - 6.0
	)
	_card_stagger_tween.tween_interval(0.07)
	_card_stagger_tween.tween_callback(func():
		enemy_card_anchor.offset_left = base_l
		enemy_card_anchor.offset_right = base_r
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
