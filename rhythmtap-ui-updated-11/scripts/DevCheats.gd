extends Node
# Always-on dev controls. Forgets first-meet flags so intros can be replayed.

func _ready() -> void:
	call_deferred("_spawn")

func _spawn() -> void:
	if has_node("Layer"):
		return
	var layer := CanvasLayer.new()
	layer.name = "Layer"
	layer.layer = 128
	add_child(layer)
	var btn := Button.new()
	btn.name = "ForgetGirls"
	btn.text = "DEV: forget girls"
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.offset_left = 10.0
	btn.offset_top = 8.0
	btn.offset_right = 178.0
	btn.offset_bottom = 36.0
	btn.add_theme_font_size_override("font_size", 13)
	btn.modulate = Color(1, 1, 1, 0.8)
	layer.add_child(btn)
	btn.pressed.connect(_on_forget)

func _on_forget() -> void:
	if has_node("/root/SoundGen"):
		SoundGen.play_ui_click()
	if MetaSave.has_method("clear_met_enemies"):
		MetaSave.clear_met_enemies()
	else:
		MetaSave.met_enemies = PackedStringArray()
		MetaSave.save_to_disk()
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
