extends Control
# Fallback first-meet page. Combat is the real path; this only exists if
# something still loads FirstMeetVN.tscn. Same subtitle styling, no header,
# narration is nameless, whole-body art.

const CHARS_PER_SEC := 42.0

@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var dialogue_label: RichTextLabel = $Margin/VBox/TextBox/Margin/VBox/DialogueLabel
@onready var text_box: PanelContainer = $Margin/VBox/TextBox
@onready var continue_hint: Label = $Margin/VBox/TextBox/Margin/VBox/ContinueHint
@onready var character: TextureRect = $CharacterSprite

var _pages: PackedStringArray = []
var _page_index: int = 0
var _full_text: String = ""
var _visible_chars: int = 0
var _typing: bool = false
var _accum: float = 0.0
var _finishing: bool = false
var _enemy_id: String = ""

func _ready() -> void:
	var title := get_node_or_null("Margin/VBox/Title")
	if title:
		title.visible = false
	var enemy := FirstMeetBridge.pending_enemy
	if enemy == "":
		_finish()
		return
	_enemy_id = enemy
	_apply_biome_bg()
	_pages = FirstMeetScenes.enemy_pages(enemy)
	if _pages.is_empty():
		_pages = PackedStringArray(["..."])
	_load_enemy_portrait(enemy)
	text_box.gui_input.connect(_on_text_box_gui_input)
	_show_page(0)

func _apply_biome_bg() -> void:
	var biome := "dungeon"
	if ActiveRun.state and ActiveRun.state.quest:
		biome = str(ActiveRun.state.quest.biome).to_lower()
	var map := {
		"dungeon": "res://bg_images/dungeonbg.png",
		"forest": "res://bg_images/forrestbg.png",
		"forrest": "res://bg_images/forrestbg.png",
		"swamp": "res://bg_images/cavebg.png",
		"cave": "res://bg_images/cavebg.png",
		"volcanic": "res://bg_images/dungeonbg.png",
		"palace": "res://bg_images/receptionbg.png",
	}
	var path: String = map.get(biome, "res://bg_images/dungeonbg.png")
	if has_node("BgArt") and ResourceLoader.exists(path):
		$BgArt.texture = load(path) as Texture2D

func _load_enemy_portrait(enemy: String) -> void:
	var folder := "troll" if enemy == "troll_girl" else enemy
	# Prefer combat idle (full figure) over VN busts that crop the head.
	var candidates: Array[String] = [
		"res://enemy_images/%s/idle.png" % folder,
		"res://enemy_images/%s/idle.webp" % folder,
		"res://vn_portraits/%s_standing.png" % enemy,
		"res://vn_portraits/%s_neutral.png" % enemy,
		"res://vn_portraits/%s.png" % enemy,
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			character.texture = load(path) as Texture2D
			character.visible = true
			character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			return
	character.visible = false

func _split_speaker(page: String) -> Dictionary:
	# Nameless unless the page explicitly starts with "Name: ".
	var body := page.strip_edges()
	var speaker := ""
	var colon := body.find(": ")
	if colon > 0 and colon < 36:
		var head := body.substr(0, colon).strip_edges()
		if head.find("\n") < 0 and not head.begins_with("\""):
			speaker = head
			body = body.substr(colon + 2).strip_edges()
	return {"speaker": speaker, "body": body}

func _show_page(i: int) -> void:
	_page_index = i
	var parsed: Dictionary = _split_speaker(String(_pages[i]))
	var speaker: String = str(parsed.get("speaker", ""))
	_full_text = str(parsed.get("body", ""))
	name_label.visible = speaker != ""
	name_label.text = speaker.to_upper()
	_visible_chars = 0
	_typing = true
	_accum = 0.0
	var shown := _full_text
	if SubtitleMarkup and SubtitleMarkup.has_method("expand"):
		var wrapped: Dictionary = SubtitleMarkup.expand(_full_text, "first_meet")
		shown = str(wrapped.get("bbcode", _full_text))
	dialogue_label.bbcode_enabled = true
	dialogue_label.text = shown
	dialogue_label.visible_characters = 0
	continue_hint.visible = false

func _process(delta: float) -> void:
	if not _typing:
		return
	_accum += delta * CHARS_PER_SEC
	var advance := int(_accum)
	if advance <= 0:
		return
	_accum -= float(advance)
	_visible_chars = mini(_full_text.length(), _visible_chars + advance)
	dialogue_label.visible_characters = _visible_chars
	if _visible_chars >= _full_text.length():
		_typing = false
		continue_hint.visible = true
		if _page_index + 1 < _pages.size():
			continue_hint.text = "Click to continue..."
		else:
			continue_hint.text = "Click to begin the fight..."

func _on_text_box_gui_input(event: InputEvent) -> void:
	var clicked := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked = true
	elif event is InputEventScreenTouch and event.pressed:
		clicked = true
	if not clicked:
		return
	accept_event()
	_on_text_clicked()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_text_clicked()
		get_viewport().set_input_as_handled()

func _on_text_clicked() -> void:
	if _finishing:
		return
	if _typing:
		_visible_chars = _full_text.length()
		dialogue_label.visible_characters = -1
		_typing = false
		continue_hint.visible = true
		if _page_index + 1 < _pages.size():
			continue_hint.text = "Click to continue..."
		else:
			continue_hint.text = "Click to begin the fight..."
		SoundGen.play_ui_click()
		return
	if _page_index + 1 < _pages.size():
		SoundGen.play_ui_click()
		_show_page(_page_index + 1)
	else:
		SoundGen.play_ui_click()
		_finish()

func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	FirstMeetBridge.mark_finished_and_return()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
