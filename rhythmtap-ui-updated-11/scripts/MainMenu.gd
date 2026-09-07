extends Control
# =============================================================================
# MainMenu.gd — Phase 3 / Phase 10 / Phase 13
# =============================================================================
# Title is optional (reachable from Town / boot hub). Start walks back through
# the guild door — no longer the primary boot path (see ReceptionistBoot).
# Phase 13: no Town shortcut on the title/menu — Town only after guild entry.
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

func _on_start_pressed():
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ReceptionistBoot.tscn")

func _on_tutorial_pressed():
	SoundGen.play_ui_click()

func _on_album_pressed():
	SoundGen.play_ui_click()

func _on_option_pressed():
	SoundGen.play_ui_click()
