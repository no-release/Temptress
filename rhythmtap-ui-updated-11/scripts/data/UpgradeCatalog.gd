extends RefCounted
class_name UpgradeCatalog
# =============================================================================
# UpgradeCatalog — Phase 4
# =============================================================================
# id -> { name, description, cost, stat, amount, max_rank }
# =============================================================================

const UPGRADES := {
	"vitality": {
		"name": "Vitality Training",
		"description": "+5 max HP (permanent)",
		"cost": 40,
		"stat": "base_max_health",
		"amount": 5,
		"max_rank": 10,
	},
	"strike": {
		"name": "Harder Strikes",
		"description": "+2 ATK (permanent)",
		"cost": 50,
		"stat": "base_damage",
		"amount": 2,
		"max_rank": 10,
	},
	"purse": {
		"name": "Starting Purse",
		"description": "Begin each quest with +10 gold in the run bag",
		"cost": 35,
		"stat": "starting_gold",
		"amount": 10,
		"max_rank": 5,
	},
	"iron_will": {
		"name": "Iron Will",
		"description": "+5 survival beats required (harder to auto-clear — wait, bonus cushion)",
		"cost": 60,
		"stat": "survival_cushion",
		"amount": 5,
		"max_rank": 3,
	},
}

static func rank_of(id: String) -> int:
	var key := "upgrade_%s" % id
	# ranks encoded in unlocked_upgrades as id:rank or repeated ids — use MetaSave helper
	return MetaSave.upgrade_rank(id)

static func cost_for(id: String) -> int:
	var def: Dictionary = UPGRADES[id]
	var rank := MetaSave.upgrade_rank(id)
	return int(def["cost"]) + rank * int(def["cost"] / 2)
