extends Control
# Guild hall hub. Receptionist is large and on-screen; copy uses the subtitle plate.

const DEFAULT_SPEAKER := "Receptionist"
const LINGER := 2.7

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
var _is_contract: bool = false
var _sub: CombatSubtitle = null
var _sign_button: Button = null
var _finishing: bool = false

func _ready() -> void:
	MusicDirector.stop()
	hub_box.visible = false
	guild_button.pressed.connect(_on_guild)
	home_button.pressed.connect(_on_home)
	menu_button.pressed.connect(_on_menu)
	_hide_old_vn_chrome()
	_layout_receptionist()
	_style_type()
	_attach_subtitle()
	_load_receptionist_portrait()
	if not MetaSave.receptionist_contract_signed:
		_is_contract = true
		title_label.text = "GUILD INDUCTION"
		_pages = FirstMeetScenes.receptionist_pages()
	else:
		_is_contract = false
		title_label.text = "GUILD HALL"
		_pages = ReceptionistGreetings.return_pages(
			MetaSave.last_outcome, MetaSave.receptionist_affinity
		)
	if _pages.is_empty():
		_pages = PackedStringArray(["Receptionist: Welcome."])
	var formatted := PackedStringArray()
	for page in _pages:
		formatted.append(_format_line(String(page)))
	_sub.set_lane("receptionist")
	_sub.play_sequence(formatted, "receptionist", LINGER)
	if not _sub.sequence_finished.is_connected(_on_sequence_finished):
		_sub.sequence_finished.connect(_on_sequence_finished)

func _style_type() -> void:
	if has_node("/root/FontKit"):
		FontKit.apply_title(title_label, 34)
		FontKit.apply_ui(guild_button, 20)
		FontKit.apply_ui(menu_button, 18)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.94, 1.0))

func _hide_old_vn_chrome() -> void:
	if name_label:
		name_label.visible = false
	if text_box:
		text_box.visible = false
		text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if continue_hint:
		continue_hint.visible = false
	if dialogue_label:
		dialogue_label.visible = false
	if door_flavor:
		door_flavor.visible = false
	if home_button:
		home_button.visible = false
		home_button.disabled = true
	if menu_button:
		menu_button.text = "- TITLE SCREEN -"

func _layout_receptionist() -> void:
	if character == null:
		return
	character.anchor_left = 0.18
	character.anchor_top = 0.0
	character.anchor_right = 1.0
	character.anchor_bottom = 1.0
	character.offset_left = 0.0
	character.offset_top = -36.0
	character.offset_right = 48.0
	character.offset_bottom = 24.0
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character.z_index = 0
	character.visible = true
	if has_node("Dim"):
		var dim := $Dim as CanvasItem
		if dim:
			dim.modulate = Color(1, 1, 1, 0.35)
	if has_node("Margin"):
		$Margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Margin.z_index = 2

func _attach_subtitle() -> void:
	var packed: PackedScene = load("res://scenes/DialogueBubble.tscn") as PackedScene
	_sub = packed.instantiate() as CombatSubtitle
	add_child(_sub)
	_sub.z_index = 8

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

func _format_line(page: String) -> String:
	var speaker := DEFAULT_SPEAKER
	var body := page.strip_edges()
	var colon := body.find(": ")
	if colon > 0 and colon < 48:
		var head := body.substr(0, colon).strip_edges()
		if head.find("\n") < 0:
			speaker = head
			body = body.substr(colon + 2).strip_edges()
	body = body.replace(DEFAULT_SPEAKER + ": ", "")
	if body.contains("[name="):
		return body
	return "[name=%s]%s" % [speaker, body]

func _on_sequence_finished() -> void:
	if _finishing:
		return
	if _is_contract:
		_show_sign_button()
		return
	hub_box.visible = true

func _show_sign_button() -> void:
	if _sign_button and is_instance_valid(_sign_button):
		_sign_button.visible = true
		return
	_sign_button = Button.new()
	_sign_button.text = "- SIGN THE CONTRACT -"
	_sign_button.focus_mode = Control.FOCUS_NONE
	_sign_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sign_button.offset_left = -180.0
	_sign_button.offset_right = 180.0
	_sign_button.offset_top = -168.0
	_sign_button.offset_bottom = -128.0
	_sign_button.add_theme_font_size_override("font_size", 18)
	add_child(_sign_button)
	_sign_button.pressed.connect(_on_sign)

func _on_sign() -> void:
	if _finishing:
		return
	_finishing = true
	SoundGen.play_ui_click()
	MetaSave.sign_receptionist_contract()
	MetaSave.save_to_disk()
	get_tree().change_scene_to_file("res://scenes/GuildBoard.tscn")

func _on_guild() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/GuildBoard.tscn")

func _on_home() -> void:
	SoundGen.play_ui_click()

func _on_menu() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
