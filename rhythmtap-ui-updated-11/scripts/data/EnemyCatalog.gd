extends RefCounted
class_name EnemyCatalog
# =============================================================================
# EnemyCatalog — Phase 0 bridge to GameManager's ENEMY_DATA
# =============================================================================
# Today enemies live as EnemyData inside GameManager._build_enemies().
# This catalog is the Phase 0 *index* for quest generation: tier + biomes,
# without duplicating combat stats. Phase 1 generator picks enemy ids from here;
# GameManager still owns HP/ATK/BPM/lines.
#
# Later: move full EnemyData into .tres Resources and have both systems read them.
# =============================================================================

## id -> { tier: int, biomes: PackedStringArray, display_name: String }
const ENTRIES := {
	"slime_girl":  { "tier": 1, "biomes": ["dungeon", "swamp"], "display_name": "Slime Girl" },
	"goblin_girl": { "tier": 1, "biomes": ["dungeon", "forest"], "display_name": "Goblin Girl" },
	"succubus":    { "tier": 2, "biomes": ["dungeon", "palace"], "display_name": "Succubus" },
	"kitsune":     { "tier": 2, "biomes": ["forest", "palace"], "display_name": "Kitsune" },
	"troll_girl":  { "tier": 3, "biomes": ["dungeon", "volcanic"], "display_name": "Troll Girl" },
	"dragoness":   { "tier": 3, "biomes": ["volcanic", "palace"], "display_name": "Dragoness" },
}

static func ids_for(biome: String, min_tier: int, max_tier: int) -> Array:
	var out: Array = []
	for id in ENTRIES.keys():
		var e: Dictionary = ENTRIES[id]
		var tier: int = int(e["tier"])
		if tier < min_tier or tier > max_tier:
			continue
		var biomes: PackedStringArray = e["biomes"]
		if biome in biomes or biomes.is_empty():
			out.append(id)
	return out

static func tier_of(enemy_id: String) -> int:
	if not ENTRIES.has(enemy_id):
		return 1
	return int(ENTRIES[enemy_id]["tier"])
