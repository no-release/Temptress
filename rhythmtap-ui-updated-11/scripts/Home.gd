extends Control
# =============================================================================
# Home.gd — Phase 2 stub / Phase 4 upgrades
# =============================================================================

@onready var body: Label = $Margin/VBox/Body
@onready var back_button: Button = $Margin/VBox/Back

func _ready() -> void:
	back_button.pressed.connect(func():
		SoundGen.play_ui_click()
		get_tree().change_scene_to_file("res://scenes/Town.tscn")
	)
	body.text = "Home sweet home.\nBanked gold: %d\n\nUpgrades arrive in Phase 4 — for now, rest and return to town." % MetaSave.banked_gold
