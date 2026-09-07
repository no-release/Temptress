extends RefCounted
class_name QuestGenerator
# =============================================================================
# QuestGenerator — Phase 1
# =============================================================================
# Turns a QuestDef into a RoomManager-compatible room list.
# Escalates enemy tier across the run (weak → strong within quest tier range).
# =============================================================================

static func build_rooms(quest: QuestDef) -> Array:
	var rooms: Array = []
	var combat_n: int = maxi(1, quest.combat_room_count)
	var forced: PackedStringArray = quest.forced_enemies

	for i in range(combat_n):
		var enemy_id: String
		if i < forced.size() and String(forced[i]) != "":
			enemy_id = String(forced[i])
		else:
			enemy_id = _pick_enemy(quest, i, combat_n)
		rooms.append({ "type": "combat", "enemy": enemy_id })

		if quest.allow_rest and combat_n >= 4 and i == int(combat_n / 2) - 1:
			rooms.append({ "type": "rest" })

	if quest.allow_shop and combat_n >= 5:
		var last_combat := rooms.size() - 1
		rooms.insert(last_combat, { "type": "shop" })

	return rooms

static func _pick_enemy(quest: QuestDef, index: int, total: int) -> String:
	var t_min: int = quest.min_enemy_tier
	var t_max: int = quest.max_enemy_tier
	var progress: float = 0.0 if total <= 1 else float(index) / float(total - 1)
	var target_tier: int = clampi(int(round(lerp(float(t_min), float(t_max), progress))), t_min, t_max)

	var pool: Array = EnemyCatalog.ids_for(quest.biome, target_tier, target_tier)
	if pool.is_empty():
		pool = EnemyCatalog.ids_for(quest.biome, t_min, t_max)
	if pool.is_empty():
		pool = EnemyCatalog.ids_in_tier_range(t_min, t_max)
	if pool.is_empty():
		return "slime_girl"
	return pool[randi() % pool.size()]
