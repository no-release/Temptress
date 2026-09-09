extends Node
# =============================================================================
# ActiveRun — Phase 1/2 autoload
# =============================================================================
# Holds the in-progress RunState between GuildBoard → Main → Town.
# =============================================================================

var state: RunState = null

func has_run() -> bool:
	return state != null and not state.rooms.is_empty()

func begin_quest(quest: QuestDef) -> RunState:
	state = RunState.new()
	state.quest = quest
	state.rooms = QuestGenerator.build_rooms(quest)
	state.room_index = -1
	state.treasure_bag_gold = 0
	state.treasure_bag_items.clear()
	state.cleared = false
	state.conceded = false
	state.active_modifiers = MetaSave.consume_modifiers_for_run()
	return state

func add_run_gold(amount: int) -> void:
	if state == null:
		return
	state.add_gold(amount)

func wipe_treasure() -> void:
	if state:
		state.wipe_treasure()

func mark_cleared() -> void:
	if state == null:
		return
	state.cleared = true
	MetaSave.bank_treasure(state.treasure_bag_gold, state.quest)
	MetaSave.on_quest_cleared()
	MetaSave.save_to_disk()

func mark_conceded() -> void:
	if state == null:
		return
	state.conceded = true
	state.wipe_treasure()
	# Sensual fail: drain a level and attach a next-run punishment
	MetaSave.apply_level_drain(1)
	MetaSave.add_modifier(_roll_fail_modifier())
	MetaSave.on_quest_conceded()
	MetaSave.save_to_disk()

func _roll_fail_modifier() -> ModifierDef:
	var roll := randi() % 4
	match roll:
		0:
			return ModifierDef.make_fine(
				"guild_fine_gold", ModifierDef.Effect.GOLD_DEBT, 15.0,
				"Guild Fine", "The receptionist docks your next purse — start 15 gold in debt.")
		1:
			return ModifierDef.make_curse(
				"weakened_resolve", ModifierDef.Effect.HP_PENALTY, 0.15,
				"Shaken Resolve", "Start the next quest at 15% less max HP.", 1)
		2:
			return ModifierDef.make_curse(
				"heavy_pulse", ModifierDef.Effect.BPM_PRESSURE, 10.0,
				"Heavy Pulse", "Beats run 10 BPM hotter next quest.", 1)
		_:
			return ModifierDef.make_fine(
				"cold_shoulder", ModifierDef.Effect.RECEPTIONIST_COLD, 1.0,
				"Cold Shoulder", "The receptionist is especially disappointed.")

func end_run() -> void:
	# Game-over used to skip mark_conceded and dump the player on Town.
	# If the run is still open, treat leaving as a fold so the hall has lines.
	if state and not state.cleared and not state.conceded:
		mark_conceded()
	state = null

func room_list() -> Array:
	if state == null:
		return []
	return state.rooms
