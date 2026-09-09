extends RefCounted
class_name FirstMeetOverlay
# First-meet pages play on the combat subtitle plate while the fight runs.

static func play(bubble: Node, enemy: String) -> void:
	if bubble == null or enemy == "":
		return
	MetaSave.mark_enemy_met(enemy)
	MetaSave.save_to_disk()
	var pages := FirstMeetScenes.enemy_pages(enemy)
	var formatted := PackedStringArray()
	for page in pages:
		formatted.append(_format_line(String(page)))
	if not bubble.has_method("play_sequence"):
		return
	if bubble.has_method("set_lane"):
		bubble.set_lane("combat")
	bubble.play_sequence(formatted, "first_meet")

static func attach_dev_button(ui_layer: CanvasLayer, bubble: Node) -> void:
	if ui_layer == null:
		return
	if ui_layer.has_node("DevForgetGirls"):
		return
	var btn := Button.new()
	btn.name = "DevForgetGirls"
	btn.text = "DEV: forget girls"
	btn.focus_mode = Control.FOCUS_NONE
	btn.z_index = 90
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.offset_left = 10.0
	btn.offset_top = 58.0
	btn.offset_right = 168.0
	btn.offset_bottom = 86.0
	btn.add_theme_font_size_override("font_size", 12)
	btn.modulate = Color(1, 1, 1, 0.72)
	ui_layer.add_child(btn)
	btn.pressed.connect(func():
		SoundGen.play_ui_click()
		if MetaSave.has_method("clear_met_enemies"):
			MetaSave.clear_met_enemies()
		else:
			MetaSave.met_enemies = PackedStringArray()
			MetaSave.save_to_disk()
		if bubble and bubble.has_method("show_plain"):
			bubble.show_plain("DEV: first-meets reset. Next unseen girl will introduce herself.")
	)

static func _format_line(page: String) -> String:
	# Nameless unless the page explicitly starts with "Name: ".
	var body := page.strip_edges()
	var colon := body.find(": ")
	if colon > 0 and colon < 36:
		var head := body.substr(0, colon).strip_edges()
		if head.find("\n") < 0 and not head.begins_with("\""):
			body = body.substr(colon + 2).strip_edges()
			if body.contains("[name="):
				return body
			return "[name=%s]%s" % [head, body]
	return body
