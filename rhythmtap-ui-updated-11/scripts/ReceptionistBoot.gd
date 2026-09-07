extends Control
# =============================================================================
# ReceptionistBoot.gd -- Phase 10 guild-door boot (no Start)
# =============================================================================
# main_scene entry: walking through the guild door. First visit = contract VN
# (typewriter + sign). Later boots = performance-aware greeting, then hub picks.
# Reuses Phase 8 FirstMeetVN typewriter pattern.
# =============================================================================

const CHARS_PER_SEC := 42.0

@onready var title_label: Label = $Margin/VBox/Title
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var dialogue_label: Label = $Margin/VBox/TextBox/Margin/VBox/DialogueLabel
@onready var text_box: PanelContainer = $Margin/VBox/TextBox
@onready var continue_hint: Label = $Margin/VBox/TextBox/Margin/VBox/ContinueHint
@onready var hub_box: VBoxContainer = $Margin/VBox/HubButtons
@onready var guild_button: Button = $Margin/VBox/HubButtons/GuildButton
@onready var home_button: Button = $Margin/VBox/HubButtons/HomeButton
@onready var menu_button: Button = $Margin/VBox/HubButtons/MenuButton

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
	name_label.text = "Receptionist"
	hub_box.visible = false
	guild_button.pressed.connect(_on_guild)
	home_button.pressed.connect(_on_home)
	menu_button.pressed.connect(_on_menu)
	text_box.gui_input.connect(_on_text_box_gui_input)
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

func _show_page(i: int) -> void:
	_page_index = i
	_full_text = String(_pages[i])
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
	# Return greeting done -- offer board / home (Town-like hub)
	continue_hint.visible = false
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
