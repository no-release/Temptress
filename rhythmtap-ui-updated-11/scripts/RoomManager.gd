extends Node
# =============================================================================
# RoomManager.gd — ALPHA BUILD / Phase 1
# =============================================================================
# Sequences the player through a run. Phase 1: prefers ActiveRun.room_list()
# from the guild board; falls back to DEFAULT_RUN if none.
# =============================================================================

signal room_started(room: Dictionary)
signal run_complete()

const DEFAULT_RUN: Array = [
	{ "type": "combat", "enemy": "slime_girl"  },
	{ "type": "combat", "enemy": "goblin_girl" },
	{ "type": "combat", "enemy": "succubus"    },
	{ "type": "combat", "enemy": "kitsune"     },
	{ "type": "combat", "enemy": "troll_girl"  },
	{ "type": "combat", "enemy": "dragoness"   },
]

var _rooms:         Array = []
var _current_index: int   = -1

var current_room: Dictionary:
	get: return _rooms[_current_index] if _current_index >= 0 else {}

func start_run(run_def: Array = []):
	if run_def.is_empty() and ActiveRun.has_run():
		run_def = ActiveRun.room_list()
	if run_def.is_empty():
		run_def = DEFAULT_RUN
	_rooms         = run_def.duplicate(true)
	_current_index = -1
	if ActiveRun.state:
		ActiveRun.state.rooms = _rooms.duplicate(true)
	advance_room()

func advance_room():
	_current_index += 1
	if ActiveRun.state:
		ActiveRun.state.room_index = _current_index
	if _current_index >= _rooms.size():
		emit_signal("run_complete")
		return
	emit_signal("room_started", current_room)

func has_next_room() -> bool:
	return _current_index + 1 < _rooms.size()

func peek_next_room() -> Dictionary:
	var next = _current_index + 1
	return _rooms[next] if next < _rooms.size() else {}

func get_room_number() -> int:
	return _current_index + 1

func get_total_rooms() -> int:
	return _rooms.size()
