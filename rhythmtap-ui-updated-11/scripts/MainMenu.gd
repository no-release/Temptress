extends Control
# =============================================================================
# MainMenu.gd — Phase 3 / Phase 10
# =============================================================================
# Title is optional (reachable from Town / boot hub). Start walks back through
# the guild door — no longer the primary boot path (see ReceptionistBoot).
# =============================================================================

@onready var start_button:    Button = $MarginContainer/VBoxContainer/MenuList/Start
@onready var tutorial_button: Button = $MarginContainer/VBoxContainer/MenuList/Tutorial
@onready var album_button:    Button = $MarginContainer/VBoxContainer/MenuList/Album
@onready var option_button:   Button = $MarginContainer/VBoxContainer/MenuList/Option

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	album_button.pressed.connect(_on_album_pressed)
	option_button.pressed.connect(_on_option_pressed)
	start_button.text = "- ENTER GUILD -"
	# Phase 3: insert Town shortcut above Tutorial
	var town_btn := Button.new()
	town_btn.text = "- TOWN -"
	town_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var list := $MarginContainer/VBoxContainer/MenuList
	list.add_child(town_btn)
	list.move_child(town_btn, 1)
	town_btn.pressed.connect(_on_town_pressed)

func _on_start_pressed():
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ReceptionistBoot.tscn")

func _on_town_pressed():
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/Town.tscn")

func _on_tutorial_pressed():
	SoundGen.play_ui_click()

func _on_album_pressed():
	SoundGen.play_ui_click()

func _on_option_pressed():
	SoundGen.play_ui_click()
