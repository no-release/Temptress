extends Control
# =============================================================================
# ReceptionistBoot.gd -- guild-door boot VN + hub
# Speaker plate above text box; body portrait on the right behind the box.
# When greeting ends, textbox/plate hide and hub buttons remain.
# =============================================================================

const CHARS_PER_SEC := 42.0
const DEFAULT_SPEAKER := "Receptionist"

@onready var title_label: Label = $Margin/VBox/Title
@onready var door_flavor: Label = $Margin/VBox/DoorFlavor
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var dialogue_label: Label = $Margin/VBox/TextBox/Margin/VBox/DialogueLabel
@onready var text_box: PanelContainer = $Margin/VBox/TextBox
@onready var continue_hint: Label = $Margin/VBox/TextBox/Margin/VBox/ContinueHint
@onready var hub_box: VBoxContainer = $Margin/VBox/HubButtons
@onready var guild_button: Button = $Margin/VBox/HubButtons/GuildButton
@onready var home_button: Button = $Margin/VBox/HubButtons/HomeButton
@onready var menu_button: Button = $Margin/VBox/HubButtons/MenuButton
@onready var character: TextureRect = $CharacterSprite

var _pages: PackedStringArray = []
var _page_index: int = 0
var _full_text: String = ""
var _visible_chars: int = 0
var _typing: bool = false
var _accum: float = 0.0
var _finishing: bool = false
var _is_contract: bool = false

func _ready() -> void:
	MusicDirector.stop()
	hub_box.visible = false
	guild_button.pressed.connect(_on_guild)
	home_button.pressed.connect(_on_home)
	menu_button.pressed.connect(_on_menu)
	text_box.gui_input.connect(_on_text_box_gui_input)
	_load_receptionist_portrait()
	if not MetaSave.receptionist_contract_signed:
		_is_contract = true
		title_label.text = "- GUILD INDUCTION -"
		_pages = FirstMeetScenes.receptionist_pages()
	else:
		_is_contract = false
		title_label.text = "- GUILD HALL -"
		_pages = ReceptionistGreetings.return_pages(
			MetaSave.last_outcome, MetaSave.receptionist_affinity
		)
	if _pages.is_empty():
		_pages = PackedStringArray(["Receptionist: Welcome."])
	_show_page(0)

func _load_receptionist_portrait() -> void:
	var emotion := "neutral"
	match str(MetaSave.last_outcome):
		"concede":
			emotion = "cold"
		"clear":
			emotion = "approve"
		_:
			emotion = "neutral"
	var candidates: Array[String] = [
		"res://vn_portraits/receptionist_%s.png" % emotion,
		"res://vn_portraits/receptionist_neutral.png",
		"res://ui_art/character_placeholder.png",
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			character.texture = load(path) as Texture2D
			character.visible = true
			return
	character.visible = false

func _split_speaker(page: String) -> Dictionary:
	var speaker := DEFAULT_SPEAKER
	var body := page
	var colon := page.find(": ")
	if colon > 0 and colon < 48:
		var head := page.substr(0, colon).strip_edges()
		var first_nl := page.find("\n")
		if head.find("\n") < 0 and (first_nl < 0 or colon < first_nl):
			speaker = head
			body = page.substr(colon + 2)
	body = body.replace(speaker + ": ", "")
	body = body.replace(DEFAULT_SPEAKER + ": ", "")
	return {"speaker": speaker, "body": body.strip_edges()}

func _show_page(i: int) -> void:
	_page_index = i
	var parsed: Dictionary = _split_speaker(String(_pages[i]))
	var speaker: String = str(parsed.get("speaker", DEFAULT_SPEAKER))
	_full_text = str(parsed.get("body", ""))
	text_box.visible = true
	if speaker == "":
		name_label.visible = false
	else:
		name_label.visible = true
		name_label.text = speaker
	_visible_chars = 0
	_typing = true
	_accum = 0.0
	dialogue_label.text = _full_text
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
		continue_hint.text = _hint_for_current_page()

func _hint_for_current_page() -> String:
	var last := _page_index + 1 >= _pages.size()
	if not last:
		return "Click to continue..."
	if _is_contract:
		return "Click to sign the contract..."
	return "Click when ready..."

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
	if hub_box.visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_text_clicked()
		get_viewport().set_input_as_handled()

func _on_text_clicked() -> void:
	if _finishing or hub_box.visible:
		return
	if _typing:
		_visible_chars = _full_text.length()
		dialogue_label.visible_characters = _visible_chars
		_typing = false
		continue_hint.visible = true
		continue_hint.text = _hint_for_current_page()
		SoundGen.play_ui_click()
		return
	if _page_index + 1 < _pages.size():
		SoundGen.play_ui_click()
		_show_page(_page_index + 1)
	else:
		SoundGen.play_ui_click()
		_finish_vn()

func _finish_vn() -> void:
	if _finishing:
		return
	_finishing = true
	if _is_contract:
		MetaSave.sign_receptionist_contract()
		MetaSave.save_to_disk()
		get_tree().change_scene_to_file("res://scenes/GuildBoard.tscn")
		return
	# Done talking — close VN chrome, keep hub
	_typing = false
	continue_hint.visible = false
	name_label.visible = false
	text_box.visible = false
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub_box.visible = true
	_finishing = false

func _on_guild() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/GuildBoard.tscn")

func _on_home() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

func _on_menu() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")