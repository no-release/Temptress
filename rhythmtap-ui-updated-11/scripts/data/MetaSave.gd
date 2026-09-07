extends Node
class_name MetaSaveData
# =============================================================================
# MetaSave — persistent player meta (autoload candidate: MetaSave)
# =============================================================================
# Survives across runs. Combat (GameManager) should READ starting stats from
# here at run start, not own the long-term level forever.
#
# Suggested autoload name: MetaSave (instance of this script, or a thin
# wrapper that owns one MetaSaveData Resource and handles disk I/O).
# =============================================================================

const SAVE_PATH := "user://temptress_meta.save"

# ── Persistent combat baseline (home upgrades mutate these) ───────────────────
var player_level: int = 1
var player_xp: int = 0
var base_max_health: int = 30
var base_damage: int = 10
var banked_gold: int = 0

# ── Progression / unlocks ─────────────────────────────────────────────────────
var unlocked_biomes: PackedStringArray = PackedStringArray(["dungeon"])
var unlocked_upgrades: PackedStringArray = PackedStringArray()

# ── Town / receptionist ───────────────────────────────────────────────────────
## Soft affinity: negative after fails, recovers on clears. Drives dialogue.
var receptionist_affinity: int = 0
var last_outcome: String = ""  # "clear" | "concede" | ""

# ── Pending punishments for the NEXT run ──────────────────────────────────────
var pending_modifiers: Array = []  # Array[ModifierDef] (serialize carefully)

signal meta_changed()

func _ready() -> void:
	load_from_disk()

func xp_to_next_level() -> int:
	return 60 * player_level

func apply_level_drain(levels: int = 1) -> void:
	# Sensual fail consequence — clamp so we never go below 1.
	player_level = maxi(1, player_level - levels)
	# Optional: also shrink base stats toward defaults; Phase 2 tunes the fantasy.
	player_xp = mini(player_xp, xp_to_next_level() - 1)
	emit_signal("meta_changed")

func bank_treasure(gold: int, quest: QuestDef = null) -> void:
	var mult := 1.0 if quest == null else quest.gold_multiplier
	banked_gold += int(round(gold * mult))
	emit_signal("meta_changed")

func add_modifier(mod: ModifierDef) -> void:
	pending_modifiers.append(mod)
	emit_signal("meta_changed")

func consume_modifiers_for_run() -> Array:
	# Returns modifiers to apply this run, decrements runs_remaining, drops expired.
	var active: Array = []
	var remaining: Array = []
	for m in pending_modifiers:
		active.append(m)
		if m.runs_remaining < 0:
			remaining.append(m)
		else:
			m.runs_remaining -= 1
			if m.runs_remaining > 0:
				remaining.append(m)
	pending_modifiers = remaining
	emit_signal("meta_changed")
	return active

func on_quest_cleared() -> void:
	last_outcome = "clear"
	receptionist_affinity = mini(10, receptionist_affinity + 1)
	emit_signal("meta_changed")

func on_quest_conceded() -> void:
	last_outcome = "concede"
	receptionist_affinity = maxi(-10, receptionist_affinity - 2)
	emit_signal("meta_changed")

# ── Persistence (simple JSON dictionary — swap for ConfigFile / Resource later)
func to_dict() -> Dictionary:
	return {
		"player_level": player_level,
		"player_xp": player_xp,
		"base_max_health": base_max_health,
		"base_damage": base_damage,
		"banked_gold": banked_gold,
		"unlocked_biomes": Array(unlocked_biomes),
		"unlocked_upgrades": Array(unlocked_upgrades),
		"receptionist_affinity": receptionist_affinity,
		"last_outcome": last_outcome,
		# ModifierDef serialization: Phase 3 — store id + magnitude for now
		"pending_modifiers": pending_modifiers.map(func(m): return {
			"id": m.id,
			"kind": m.kind,
			"effect": m.effect,
			"display_name": m.display_name,
			"description": m.description,
			"magnitude": m.magnitude,
			"runs_remaining": m.runs_remaining,
		}),
	}

func from_dict(d: Dictionary) -> void:
	player_level = int(d.get("player_level", 1))
	player_xp = int(d.get("player_xp", 0))
	base_max_health = int(d.get("base_max_health", 30))
	base_damage = int(d.get("base_damage", 10))
	banked_gold = int(d.get("banked_gold", 0))
	unlocked_biomes = PackedStringArray(d.get("unlocked_biomes", ["dungeon"]))
	unlocked_upgrades = PackedStringArray(d.get("unlocked_upgrades", []))
	receptionist_affinity = int(d.get("receptionist_affinity", 0))
	last_outcome = str(d.get("last_outcome", ""))
	pending_modifiers.clear()
	for md in d.get("pending_modifiers", []):
		var m := ModifierDef.new()
		m.id = str(md.get("id", ""))
		m.kind = int(md.get("kind", 0))
		m.effect = int(md.get("effect", 0))
		m.display_name = str(md.get("display_name", ""))
		m.description = str(md.get("description", ""))
		m.magnitude = float(md.get("magnitude", 0.0))
		m.runs_remaining = int(md.get("runs_remaining", 1))
		pending_modifiers.append(m)

func save_to_disk() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("MetaSave: could not write %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(to_dict()))

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		from_dict(parsed)
