extends Control
# Safety-net first-meet page. Main now plays first-meet as combat subtitles.
# If this scene still loads, it auto-plays the same styled lines, shows the
# whole body, and never uses a speaker plate on narration.

const CHARS_PER_SEC := 32.0
const LINGER_BASE := 2.85
const LINGER_PER_CHAR := 0.016
const LINGER_MIN := 2.5
const LINGER_MAX := 4.5

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
var _hold_left: float = 0.0
var _finishing: bool = false
var _enemy_id: String = ""

func _ready() -> void:
	var title := get_node_or_null("Margin/VBox/Title")
	if title:
		title.visible = false
	if name_label:
		name_label.visible = false
		name_label.text = ""
	if continue_hint:
		continue_hint.visible = false
		continue_hint.text = ""
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
	var candidates: Array[String] = [
		"res://enemy_images/%s/idle.png" % folder,
		"res://enemy_images/%s/idle.webp" % folder,
		"res://vn_portraits/%s_standing.png" % enemy,
		"res://vn_portraits/%s_neutral.png" % enemy,
		"res://vn_portraits/%s.png" % enemy,
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			var img := Image.load_from_file(path)
			if img:
				var cropped := _crop_opaque(img)
				character.texture = ImageTexture.create_from_image(cropped)
			else:
				character.texture = load(path) as Texture2D
			character.visible = true
			character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			return
	character.visible = false

func _crop_opaque(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	var step := 2
	for y in range(0, h, step):
		for x in range(0, w, step):
			if img.get_pixel(x, y).a > 0.08:
				if x < min_x:
					min_x = x
				if y < min_y:
					min_y = y
				if x > max_x:
					max_x = x
				if y > max_y:
					max_y = y
	if max_x < min_x:
		return img
	min_x = maxi(0, min_x - 8)
	min_y = maxi(0, min_y - 8)
	max_x = mini(w - 1, max_x + 8)
	max_y = mini(h - 1, max_y + 8)
	return img.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))

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
	if name_label:
		name_label.visible = speaker != ""
		name_label.text = speaker.to_upper()
	_visible_chars = 0
	_typing = true
	_accum = 0.0
	_hold_left = 0.0
	var shown := _full_text
	if SubtitleMarkup and SubtitleMarkup.has_method("expand"):
		var wrapped: Dictionary = SubtitleMarkup.expand(_full_text, "first_meet")
		shown = str(wrapped.get("bbcode", _full_text))
	dialogue_label.bbcode_enabled = true
	dialogue_label.text = shown
	dialogue_label.visible_characters = 0
	if continue_hint:
		continue_hint.visible = false

func _linger_for_page() -> float:
	var extra := float(maxi(0, _full_text.length() - 48)) * LINGER_PER_CHAR
	return clampf(LINGER_BASE + extra, LINGER_MIN, LINGER_MAX)

func _process(delta: float) -> void:
	if _finishing:
		return
	if _typing:
		_accum += delta * CHARS_PER_SEC
		var advance := int(_accum)
		if advance <= 0:
			return
		_accum -= float(advance)
		_visible_chars = mini(_full_text.length(), _visible_chars + advance)
		dialogue_label.visible_characters = _visible_chars
		if _visible_chars >= _full_text.length():
			_typing = false
			_hold_left = _linger_for_page()
		return
	if _hold_left > 0.0:
		_hold_left -= delta
		if _hold_left <= 0.0:
			_advance_or_finish()

func _advance_or_finish() -> void:
	if _page_index + 1 < _pages.size():
		_show_page(_page_index + 1)
	else:
		_finish()

func _unhandled_input(event: InputEvent) -> void:
	# Optional skip of linger only — pages auto-advance.
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		get_viewport().set_input_as_handled()
		if _typing:
			_visible_chars = _full_text.length()
			dialogue_label.visible_characters = -1
			_typing = false
			_hold_left = 0.35
		elif _hold_left > 0.15:
			_hold_left = 0.05

func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	FirstMeetBridge.mark_finished_and_return()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
