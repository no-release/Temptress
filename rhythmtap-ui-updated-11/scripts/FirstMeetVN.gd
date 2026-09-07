extends Control
# =============================================================================
# FirstMeetVN.gd — Phase 8 full-screen visual-novel first-meet
# =============================================================================
# Letter-by-letter typewriter. Click the text box:
#   - typing in progress → instantly complete the current line
#   - already complete → advance to next page / finish → return to combat
# =============================================================================

const CHARS_PER_SEC := 42.0

@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var dialogue_label: Label = $Margin/VBox/TextBox/Margin/DialogueLabel
@onready var text_box: PanelContainer = $Margin/VBox/TextBox
@onready var continue_hint: Label = $Margin/VBox/TextBox/Margin/ContinueHint

var _pages: PackedStringArray = []
var _page_index: int = 0
var _full_text: String = ""
var _visible_chars: int = 0
var _typing: bool = false
var _accum: float = 0.0
var _finishing: bool = false

func _ready() -> void:
	var enemy := FirstMeetBridge.pending_enemy
	if enemy == "":
		_finish()
		return
	_pages = FirstMeetScenes.enemy_pages(enemy)
	if _pages.is_empty():
		_pages = PackedStringArray(["..."])
	name_label.text = enemy.replace("_", " ").capitalize()
	text_box.gui_input.connect(_on_text_box_gui_input)
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
		continue_hint.text = "Click to continue…" if _page_index + 1 < _pages.size() else "Click to begin the fight…"

func _on_text_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_text_clicked()
	elif event is InputEventScreenTouch and event.pressed:
		_on_text_clicked()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_text_clicked()
		get_viewport().set_input_as_handled()

elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Allow clicking outside the box too (full-screen advance)
		_on_text_clicked()
		get_viewport().set_input_as_handled()

func _on_text_clicked() -> void:
	if _finishing:
		return
	if _typing:
		_visible_chars = _full_text.length()
		dialogue_label.visible_characters = _visible_chars
		_typing = false
		continue_hint.visible = true
		continue_hint.text = "Click to continue…" if _page_index + 1 < _pages.size() else "Click to begin the fight…"
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
