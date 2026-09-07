extends RefCounted
class_name QuestGenerator
# =============================================================================
# QuestGenerator — Phase 1 + Phase 11 ranked offers + Phase 13 uniqueness
# =============================================================================
# Turns a QuestDef into a RoomManager-compatible room list.
# Escalates enemy tier across the run (weak → strong within quest tier range).
# Phase 11: generate N board offers scaled to MetaSave.guild_rank.
# Phase 13: exclude_keys keeps simultaneous offers unique (no duplicate combos).
# =============================================================================

const ALL_BIOMES := ["dungeon", "forest", "swamp", "volcanic", "palace"]

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

## Generate N distinct quest offers for the guild board, scaled to rank.
## exclude_keys: map of offer_key -> true to skip (Phase 13 persistence / refresh).
static func generate_offers(count: int = -1, rank: String = "", exclude_keys: Dictionary = {}) -> Array:
	var n := count if count > 0 else MetaSave.board_offer_count()
	n = clampi(n, 1, 4)
	var r := rank if rank != "" else MetaSave.guild_rank
	var ranges: Dictionary = rank_param_ranges(r)
	var offers: Array = []
	var seen: Dictionary = exclude_keys.duplicate()
	var attempts := 0
	while offers.size() < n and attempts < 80:
		attempts += 1
		var length: int = ranges["lengths"][randi() % ranges["lengths"].size()]
		var difficulty: int = ranges["diffs"][randi() % ranges["diffs"].size()]
		var biome: String = _pick_biome()
		var key := "%d_%d_%s" % [length, difficulty, biome]
		if seen.has(key):
			continue
		seen[key] = true
		var q := QuestDef.from_board(length, difficulty, biome)
		# Soft-clamp enemy tiers toward rank band (from_board already sets by diff)
		q.min_enemy_tier = clampi(q.min_enemy_tier, int(ranges["tier_min"]), int(ranges["tier_max"]))
		q.max_enemy_tier = clampi(q.max_enemy_tier, q.min_enemy_tier, int(ranges["tier_max"]))
		offers.append(q)
	return offers

## Map guild rank → length/difficulty pools + soft tier band.
static func rank_param_ranges(rank: String) -> Dictionary:
	match rank.to_upper():
		"E":
			return {
				"lengths": [QuestDef.Length.SHORT, QuestDef.Length.MEDIUM],
				"diffs": [QuestDef.Difficulty.EASY, QuestDef.Difficulty.NORMAL],
				"tier_min": 1, "tier_max": 2,
			}
		"D":
			return {
				"lengths": [QuestDef.Length.SHORT, QuestDef.Length.MEDIUM],
				"diffs": [QuestDef.Difficulty.EASY, QuestDef.Difficulty.NORMAL],
				"tier_min": 1, "tier_max": 3,
			}
		"C":
			return {
				"lengths": [QuestDef.Length.SHORT, QuestDef.Length.MEDIUM, QuestDef.Length.LONG],
				"diffs": [QuestDef.Difficulty.NORMAL, QuestDef.Difficulty.HARD],
				"tier_min": 1, "tier_max": 3,
			}
		"B":
			return {
				"lengths": [QuestDef.Length.MEDIUM, QuestDef.Length.LONG],
				"diffs": [QuestDef.Difficulty.NORMAL, QuestDef.Difficulty.HARD],
				"tier_min": 2, "tier_max": 3,
			}
		"A":
			return {
				"lengths": [QuestDef.Length.MEDIUM, QuestDef.Length.LONG],
				"diffs": [QuestDef.Difficulty.HARD, QuestDef.Difficulty.NIGHTMARE],
				"tier_min": 2, "tier_max": 3,
			}
		"S":
			return {
				"lengths": [QuestDef.Length.LONG],
				"diffs": [QuestDef.Difficulty.HARD, QuestDef.Difficulty.NIGHTMARE],
				"tier_min": 3, "tier_max": 3,
			}
		_:
			return {
				"lengths": [QuestDef.Length.SHORT, QuestDef.Length.MEDIUM],
				"diffs": [QuestDef.Difficulty.EASY, QuestDef.Difficulty.NORMAL],
				"tier_min": 1, "tier_max": 2,
			}

static func _pick_biome() -> String:
	var unlocked: PackedStringArray = MetaSave.unlocked_biomes
	var pool: Array = []
	for b in ALL_BIOMES:
		if unlocked.is_empty() or b in unlocked or b == "dungeon":
			pool.append(b)
	if pool.is_empty():
		return "dungeon"
	return pool[randi() % pool.size()]

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
