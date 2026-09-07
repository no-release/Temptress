extends Control
# =============================================================================
# GuildBoard.gd — Phase 1
# =============================================================================
# Simple guild quest picker: length, difficulty, biome → builds ActiveRun → Main.
# =============================================================================

@onready var title_label: Label = $MarginContainer/VBox/Title
@onready var length_row: HBoxContainer = $MarginContainer/VBox/LengthRow
@onready var diff_row: HBoxContainer = $MarginContainer/VBox/DiffRow
@onready var biome_row: HBoxContainer = $MarginContainer/VBox/BiomeRow
@onready var summary_label: Label = $MarginContainer/VBox/Summary
@onready var accept_button: Button = $MarginContainer/VBox/Accept
@onready var back_button: Button = $MarginContainer/VBox/Back

var _length: int = QuestDef.Length.SHORT
var _difficulty: int = QuestDef.Difficulty.NORMAL
var _biome: String = "dungeon"

const BIOMES := ["dungeon", "forest", "swamp", "volcanic", "palace"]

func _ready() -> void:
	_build_option_buttons(length_row, [
		["Short", QuestDef.Length.SHORT],
		["Medium", QuestDef.Length.MEDIUM],
		["Long", QuestDef.Length.LONG],
	], "_on_length")
	_build_option_buttons(diff_row, [
		["Easy", QuestDef.Difficulty.EASY],
		["Normal", QuestDef.Difficulty.NORMAL],
		["Hard", QuestDef.Difficulty.HARD],
		["Nightmare", QuestDef.Difficulty.NIGHTMARE],
	], "_on_diff")
	var biome_opts: Array = []
	for b in BIOMES:
		# Only offer unlocked biomes when MetaSave has them; fallback all.
		if MetaSave.unlocked_biomes.is_empty() or b in MetaSave.unlocked_biomes or b == "dungeon":
			biome_opts.append([b.capitalize(), b])
	if biome_opts.is_empty():
		biome_opts.append(["Dungeon", "dungeon"])
	_build_biome_buttons(biome_row, biome_opts)
	accept_button.pressed.connect(_on_accept)
	back_button.pressed.connect(_on_back)
	_refresh_summary()

func _build_option_buttons(row: HBoxContainer, opts: Array, method: String) -> void:
	for child in row.get_children():
		child.queue_free()
	for opt in opts:
		var btn := Button.new()
		btn.text = str(opt[0])
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var value = opt[1]
		btn.pressed.connect(func(): call(method, value))
		row.add_child(btn)

func _build_biome_buttons(row: HBoxContainer, opts: Array) -> void:
	for child in row.get_children():
		child.queue_free()
	for opt in opts:
		var btn := Button.new()
		btn.text = str(opt[0])
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var value: String = str(opt[1])
		btn.pressed.connect(func(): _on_biome(value))
		row.add_child(btn)

func _on_length(v: int) -> void:
	SoundGen.play_ui_click()
	_length = v
	_refresh_summary()

func _on_diff(v: int) -> void:
	SoundGen.play_ui_click()
	_difficulty = v
	_refresh_summary()

func _on_biome(v: String) -> void:
	SoundGen.play_ui_click()
	_biome = v
	_refresh_summary()

func _refresh_summary() -> void:
	var q := QuestDef.from_board(_length, _difficulty, _biome)
	summary_label.text = "%s\n%d combat rooms · gold x%.2f · XP x%.2f · tiers %d–%d" % [
		q.display_name, q.combat_room_count, q.gold_multiplier, q.xp_multiplier,
		q.min_enemy_tier, q.max_enemy_tier
	]

func _on_accept() -> void:
	SoundGen.play_ui_click()
	var q := QuestDef.from_board(_length, _difficulty, _biome)
	ActiveRun.begin_quest(q)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_back() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
