extends Node
# =============================================================================
# ActiveRun — Phase 1 autoload
# =============================================================================
# Holds the in-progress RunState between GuildBoard → Main.
# Autoload name: ActiveRun
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
	MetaSave.on_quest_conceded()
	MetaSave.save_to_disk()

func end_run() -> void:
	state = null

func room_list() -> Array:
	if state == null:
		return []
	return state.rooms
