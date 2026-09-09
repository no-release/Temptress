extends Control
# Town hub is parked. All arrivals bounce to the guild hall.

func _ready() -> void:
	get_tree().change_scene_to_file("res://scenes/ReceptionistBoot.tscn")
