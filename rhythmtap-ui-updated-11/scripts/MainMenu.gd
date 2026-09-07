extends Control
# =============================================================================
# MainMenu.gd — ALPHA BUILD
# =============================================================================
# Controller for MainMenu.tscn, the game's entry scene (set in project.godot).
# Only "Start" is fully wired — it jumps into Main.tscn.
# Tutorial / Album / Option remain stubs for now.
# All buttons play a UI click via SoundGen.
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

func _on_start_pressed():
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_tutorial_pressed():
	SoundGen.play_ui_click()
	# TODO: no tutorial scene exists yet

func _on_album_pressed():
	SoundGen.play_ui_click()
	# TODO: no album/gallery scene exists yet

func _on_option_pressed():
	SoundGen.play_ui_click()
	# TODO: no options scene exists yet
