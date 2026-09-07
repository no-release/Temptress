extends Node
# =============================================================================
# FirstMeetBridge.gd — Phase 8 autoload handoff
# =============================================================================
# Survives change_scene between Main ↔ FirstMeetVN.
# Captures mid-run combat stats so returning from the VN does not wipe HP/gold.
# =============================================================================

var pending_enemy: String = ""
var return_to_combat: bool = false
var saved_room_index: int = -1
var combat_snapshot: Dictionary = {}

## Call from Main before leaving for the VN scene.
func begin(enemy_id: String, room_index: int, gm: Node = null) -> void:
	pending_enemy = enemy_id
	saved_room_index = room_index
	return_to_combat = false
	combat_snapshot.clear()
	if gm:
		capture_combat(gm)

func capture_combat(gm: Node) -> void:
	combat_snapshot = {
		"player_health": gm.player_health,
		"player_max_health": gm.player_max_health,
		"player_damage": gm.player_damage,
		"player_xp": gm.player_xp,
		"player_level": gm.player_level,
		"player_gold": gm.player_gold,
	}

func apply_combat(gm: Node) -> void:
	if combat_snapshot.is_empty() or gm == null:
		return
	gm.player_health = int(combat_snapshot.get("player_health", gm.player_health))
	gm.player_max_health = int(combat_snapshot.get("player_max_health", gm.player_max_health))
	gm.player_damage = int(combat_snapshot.get("player_damage", gm.player_damage))
	gm.player_xp = int(combat_snapshot.get("player_xp", gm.player_xp))
	gm.player_level = int(combat_snapshot.get("player_level", gm.player_level))
	gm.player_gold = int(combat_snapshot.get("player_gold", gm.player_gold))
	gm.emit_signal("player_stats_changed")

## Called by FirstMeetVN when all pages are done.
func mark_finished_and_return() -> void:
	if pending_enemy != "":
		MetaSave.mark_enemy_met(pending_enemy)
		MetaSave.save_to_disk()
	return_to_combat = true

func clear() -> void:
	pending_enemy = ""
	return_to_combat = false
	saved_room_index = -1
	combat_snapshot.clear()
