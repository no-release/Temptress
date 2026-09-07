extends Control
# =============================================================================
# Town.gd — Phase 2 hub (expanded in Phase 3/4)
# =============================================================================
# Landing spot after quest clear or concede. Receptionist reacts to last outcome.
# =============================================================================

@onready var title_label: Label = $Margin/VBox/Title
@onready var receptionist_label: Label = $Margin/VBox/Receptionist
@onready var status_label: Label = $Margin/VBox/Status
@onready var modifiers_label: Label = $Margin/VBox/Modifiers
@onready var guild_button: Button = $Margin/VBox/GuildButton
@onready var home_button: Button = $Margin/VBox/HomeButton
@onready var menu_button: Button = $Margin/VBox/MenuButton

func _ready() -> void:
	guild_button.pressed.connect(_on_guild)
	home_button.pressed.connect(_on_home)
	menu_button.pressed.connect(_on_menu)
	_refresh()

func _refresh() -> void:
	var affinity := MetaSave.receptionist_affinity
	var outcome := MetaSave.last_outcome
	match outcome:
		"concede":
			receptionist_label.text = _disappointed_line(affinity)
		"clear":
			receptionist_label.text = _pleased_line(affinity)
		_:
			receptionist_label.text = "Welcome to the guild town. Ready for a quest?"

	status_label.text = "LV %d · Banked gold: %d · Affinity: %d" % [
		MetaSave.player_level, MetaSave.banked_gold, affinity
	]
	modifiers_label.text = _format_modifiers()
	# Home unlocks for real in Phase 4 — still navigable as a stub.
	home_button.text = "- HOME (upgrades soon) -"

func _disappointed_line(affinity: int) -> String:
	if affinity <= -6:
		return "Receptionist: "…You came back empty. Again. The guild notices.""
	if affinity <= -2:
		return "Receptionist: "You failed your quest. I expected better — there will be consequences.""
	return "Receptionist: "You gave in out there. Clean yourself up. The board is still open… for now.""

func _pleased_line(affinity: int) -> String:
	if affinity >= 4:
		return "Receptionist: "Flawless work. Your spoils are banked — the guild is proud.""
	return "Receptionist: "You held out and finished the quest. Good. Treasure is secured.""

func _format_modifiers() -> String:
	if MetaSave.pending_modifiers.is_empty():
		return "No active fines or curses."
	var lines: PackedStringArray = PackedStringArray(["Pending next-run punishments:"])
	for m in MetaSave.pending_modifiers:
		lines.append("• %s — %s" % [m.display_name, m.description])
	return "\n".join(lines)

func _on_guild() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/GuildBoard.tscn")

func _on_home() -> void:
	SoundGen.play_ui_click()
	# Phase 4 will replace this stub scene.
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

func _on_menu() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
