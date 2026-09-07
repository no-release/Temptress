extends Node
# =============================================================================
# RoomManager.gd — ALPHA BUILD
# =============================================================================
# Sequences the player through a "run" — an ordered list of rooms.
# Inspired by Slay the Spire: each room is a dictionary with a "type" and
# whatever data that type needs. Main.gd listens to room_started and routes
# to the appropriate system (GameManager for combat, future scenes for others).
#
# CURRENT ROOM TYPES:
#   { "type": "combat", "enemy": "slime_girl" }  — wires into GameManager
#   { "type": "rest"  }                          — stub, not yet implemented
#   { "type": "shop"  }                          — stub, not yet implemented
#
# Enemy order is weak → strong so early rooms feel approachable and later
# rooms ramp difficulty. This is the temporary stand-in for the future
# guild-quest system (player picks length/difficulty/biome).
# =============================================================================

signal room_started(room: Dictionary)  # Main.gd listens to this
signal run_complete()                  # all rooms cleared; Main.gd handles victory

# Ordered by escalating difficulty. Edit freely.
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

func start_run(run_def: Array = DEFAULT_RUN):
	_rooms         = run_def.duplicate(true)
	_current_index = -1
	advance_room()

func advance_room():
	_current_index += 1
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
