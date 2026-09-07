extends RefCounted
class_name RunState
# =============================================================================
# RunState — mutable progress for ONE active quest attempt
# =============================================================================
# Created when the player accepts a quest. Destroyed / archived on clear or
# concede. Treasure in treasure_bag is NOT banked until quest clear.
# Concede wipes treasure_bag and never touches MetaSave.banked_gold except
# for fines/curses applied afterward.
# =============================================================================

var quest: QuestDef = null
var room_index: int = -1
var rooms: Array = []  # Array of Dictionary room defs, same shape RoomManager uses today

## Loot earned this run only — wiped on concede, banked on clear.
var treasure_bag_gold: int = 0
var treasure_bag_items: Array = []  # future: item ids / Resources

## Snapshot of modifiers that were active when this run started (for UI + apply).
var active_modifiers: Array = []  # Array[ModifierDef]

var cleared: bool = false
var conceded: bool = false

func current_room() -> Dictionary:
	if room_index < 0 or room_index >= rooms.size():
		return {}
	return rooms[room_index]

func has_next_room() -> bool:
	return room_index + 1 < rooms.size()

func advance_room() -> Dictionary:
	room_index += 1
	if room_index >= rooms.size():
		return {}
	return rooms[room_index]

func add_gold(amount: int) -> void:
	treasure_bag_gold = max(0, treasure_bag_gold + amount)

func wipe_treasure() -> void:
	treasure_bag_gold = 0
	treasure_bag_items.clear()

func quest_progress_label() -> String:
	if quest == null or rooms.is_empty():
		return "QUEST ?/?"
	# Count combat rooms for HUD "QUEST n/m" feel, or total rooms — pick one in Phase 1.
	return "QUEST %d/%d" % [mini(room_index + 1, rooms.size()), rooms.size()]
