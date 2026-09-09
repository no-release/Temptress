extends Node
# Always-on dev controls. Forgets first-meet flags so intros can be replayed.
# Visible on every screen (title, hall, combat). F9 does the same thing.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_spawn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F9:
			_on_forget()
			get_viewport().set_input_as_handled()

func _spawn() -> void:
	if has_node("Layer"):
		return
	var layer := CanvasLayer.new()
	layer.name = "Layer"
	layer.layer = 128
	add_child(layer)
	var btn := Button.new()
	btn.name = "ForgetGirls"
	btn.text = "DEV: forget girls  (F9)"
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.offset_left = 10.0
	btn.offset_top = 8.0
	btn.offset_right = 220.0
	btn.offset_bottom = 38.0
	btn.add_theme_font_size_override("font_size", 13)
	btn.modulate = Color(1.0, 0.92, 0.55, 0.95)
	layer.add_child(btn)
	btn.pressed.connect(_on_forget)

func _on_forget() -> void:
	if Engine.has_singleton("SoundGen") or has_node("/root/SoundGen"):
		SoundGen.play_ui_click()
	if MetaSave.has_method("clear_met_enemies"):
		MetaSave.clear_met_enemies()
	else:
		MetaSave.met_enemies = PackedStringArray()
		MetaSave.save_to_disk()
	print("DEV: met_enemies cleared")
	var bubble := _find_bubble()
	if bubble and bubble.has_method("show_plain"):
		bubble.show_plain("DEV: first-meets reset. Next unseen girl will introduce herself.")

func _find_bubble() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	if scene.has_node("UI/DialogueBubble"):
		return scene.get_node("UI/DialogueBubble")
	return scene.find_child("DialogueBubble", true, false)
