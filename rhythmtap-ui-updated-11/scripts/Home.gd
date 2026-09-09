extends Control
# Home upgrades parked for now. Bounce to the guild hall.

func _ready() -> void:
	get_tree().change_scene_to_file("res://scenes/ReceptionistBoot.tscn")
