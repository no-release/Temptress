extends Control
# =============================================================================
# Town.gd — Phase 3 town loop
# =============================================================================
# Hub after clear/concede. Receptionist dialogue pools, optional pay-off of fines,
# routes to Guild / Home / Title.
# =============================================================================

@onready var title_label: Label = $Margin/VBox/Title
@onready var receptionist_label: Label = $Margin/VBox/Receptionist
@onready var status_label: Label = $Margin/VBox/Status
@onready var modifiers_label: Label = $Margin/VBox/Modifiers
@onready var guild_button: Button = $Margin/VBox/GuildButton
@onready var home_button: Button = $Margin/VBox/HomeButton
@onready var pay_button: Button = $Margin/VBox/PayButton
@onready var menu_button: Button = $Margin/VBox/MenuButton

const DISAPPOINTED := [
	"Receptionist: \"You failed your quest. I expected better — there will be consequences.\"",
	"Receptionist: \"Back already… and empty-handed. The guild keeps records.\"",
	"Receptionist: \"You gave in. Wash up. The board is still open — if they'll still take you.\"",
	"Receptionist: \"…Again. Don't make me explain this to the guildmaster.\"",
]
const PLEASED := [
	"Receptionist: \"You held out and finished. Good. Spoils are banked.\"",
	"Receptionist: \"A clean clear. The guild notices the ones who don't fold.\"",
	"Receptionist: \"Welcome back, hunter. Your purse looks healthier.\"",
	"Receptionist: \"Flawless enough. Rest, then take another contract.\"",
]
const NEUTRAL := [
	"Receptionist: \"Welcome to guild town. The board is open.\"",
	"Receptionist: \"Contracts, rest, and home — in that order if you're smart.\"",
]

func _ready() -> void:
	guild_button.pressed.connect(_on_guild)
	home_button.pressed.connect(_on_home)
	pay_button.pressed.connect(_on_pay_fine)
	menu_button.pressed.connect(_on_menu)
	_refresh()

func _refresh() -> void:
	var affinity := MetaSave.receptionist_affinity
	var outcome := MetaSave.last_outcome
	match outcome:
		"concede":
			receptionist_label.text = DISAPPOINTED[randi() % DISAPPOINTED.size()]
			if affinity <= -6:
				receptionist_label.text += "\n(She barely looks at you.)"
		"clear":
			receptionist_label.text = PLEASED[randi() % PLEASED.size()]
			if affinity >= 4:
				receptionist_label.text += "\n(A rare almost-smile.)"
		_:
			receptionist_label.text = NEUTRAL[randi() % NEUTRAL.size()]

	status_label.text = "LV %d · Banked gold: %d · Affinity: %d" % [
		MetaSave.player_level, MetaSave.banked_gold, affinity
	]
	modifiers_label.text = _format_modifiers()
	var fine_cost := _gold_debt_total()
	pay_button.visible = fine_cost > 0
	pay_button.text = "- PAY GUILD FINE (%d gold) -" % fine_cost
	home_button.text = "- HOME -"

func _gold_debt_total() -> int:
	var total := 0
	for m in MetaSave.pending_modifiers:
		if m.effect == ModifierDef.Effect.GOLD_DEBT:
			total += int(m.magnitude)
	return total

func _format_modifiers() -> String:
	if MetaSave.pending_modifiers.is_empty():
		return "No active fines or curses."
	var lines: PackedStringArray = PackedStringArray(["Pending next-run punishments:"])
	for m in MetaSave.pending_modifiers:
		lines.append("• %s — %s" % [m.display_name, m.description])
	return "\n".join(lines)

func _on_pay_fine() -> void:
	SoundGen.play_ui_click()
	var cost := _gold_debt_total()
	if cost <= 0:
		return
	if MetaSave.banked_gold < cost:
		receptionist_label.text = "Receptionist: \"You don't have enough banked gold to clear the fine.\""
		return
	MetaSave.banked_gold -= cost
	# Drop GOLD_DEBT modifiers only
	var kept: Array = []
	for m in MetaSave.pending_modifiers:
		if m.effect != ModifierDef.Effect.GOLD_DEBT:
			kept.append(m)
	MetaSave.pending_modifiers = kept
	MetaSave.receptionist_affinity = mini(10, MetaSave.receptionist_affinity + 1)
	MetaSave.save_to_disk()
	receptionist_label.text = "Receptionist: \"Debt settled. Don't make me write another notice.\""
	_refresh()

func _on_guild() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/GuildBoard.tscn")

func _on_home() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

func _on_menu() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
