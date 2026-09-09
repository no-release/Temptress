extends Control
# =============================================================================
# GuildBoard.gd — Phase 11 ranked board + Phase 13 persisted offers
# =============================================================================
# No free pick of length/difficulty/biome. Shows N quest offers scaled to
# MetaSave.guild_rank (E easier → S harder). Player picks one of 2–4 cards.
# N = 2 + board_postings upgrade (capped at 4).
# Phase 13: offers load from MetaSave (no reboot reroll); accept refreshes
# leftover slots with fresh unique contracts.
# =============================================================================

@onready var title_label: Label = $MarginContainer/VBox/Title
@onready var subtitle_label: Label = $MarginContainer/VBox/Subtitle
@onready var offers_box: VBoxContainer = $MarginContainer/VBox/Offers
@onready var summary_label: Label = $MarginContainer/VBox/Summary
@onready var accept_button: Button = $MarginContainer/VBox/Accept
@onready var back_button: Button = $MarginContainer/VBox/Back

var _offers: Array = []  # Array[QuestDef]
var _selected: int = 0
var _offer_buttons: Array = []  # Array[Button]

func _ready() -> void:
	accept_button.pressed.connect(_on_accept)
	back_button.pressed.connect(_on_back)
	back_button.text = "- BACK TO HALL -"
	_load_offers()

func _load_offers() -> void:
	_offers = BoardOfferPersist.ensure_offers()
	_selected = 0
	subtitle_label.text = "Rank %s contracts — pick one offer." % MetaSave.guild_rank_label()
	_rebuild_offer_buttons()
	_refresh_summary()

func _rebuild_offer_buttons() -> void:
	for child in offers_box.get_children():
		child.queue_free()
	_offer_buttons.clear()
	for i in range(_offers.size()):
		var q: QuestDef = _offers[i]
		var btn := Button.new()
		btn.text = _card_text(q, i)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx := i
		btn.pressed.connect(func(): _on_select(idx))
		offers_box.add_child(btn)
		_offer_buttons.append(btn)
	_highlight_selected()

func _card_text(q: QuestDef, index: int) -> String:
	return "[%d] %s\n%s · %s · %d rooms · gold x%.2f · XP x%.2f · tiers %d–%d" % [
		index + 1,
		q.display_name,
		q.biome.capitalize(),
		QuestDef.difficulty_label(q.difficulty),
		q.combat_room_count,
		q.gold_multiplier,
		q.xp_multiplier,
		q.min_enemy_tier,
		q.max_enemy_tier,
	]

func _on_select(index: int) -> void:
	SoundGen.play_ui_click()
	_selected = clampi(index, 0, maxi(0, _offers.size() - 1))
	_highlight_selected()
	_refresh_summary()

func _highlight_selected() -> void:
	for i in range(_offer_buttons.size()):
		var btn: Button = _offer_buttons[i]
		if not is_instance_valid(btn):
			continue
		if i == _selected:
			btn.modulate = Color(1.0, 0.75, 1.0, 1.0)
		else:
			btn.modulate = Color(1, 1, 1, 1)

func _refresh_summary() -> void:
	if _offers.is_empty():
		summary_label.text = "No contracts posted."
		accept_button.disabled = true
		return
	accept_button.disabled = false
	var q: QuestDef = _offers[_selected]
	summary_label.text = "Selected: %s\n%d combat rooms · gold x%.2f · XP x%.2f · tiers %d–%d" % [
		q.display_name, q.combat_room_count, q.gold_multiplier, q.xp_multiplier,
		q.min_enemy_tier, q.max_enemy_tier
	]

func _on_accept() -> void:
	if _offers.is_empty():
		return
	SoundGen.play_ui_click()
	var q: QuestDef = BoardOfferPersist.accept_and_refresh(_selected)
	if q == null:
		return
	ActiveRun.begin_quest(q)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_back() -> void:
	SoundGen.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ReceptionistBoot.tscn")
