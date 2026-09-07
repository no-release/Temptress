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

## Guild rank E→S (ascending difficulty). Shown on Town; drives board offers.
const GUILD_RANKS := ["E", "D", "C", "B", "A", "S"]

# ── Persistent combat baseline (home upgrades mutate these) ────────────────
var player_level: int = 1
var player_xp: int = 0
var base_max_health: int = 30
var base_damage: int = 10
var banked_gold: int = 0

# ── Progression / unlocks ──────────────────────────────────────────────────
var unlocked_biomes: PackedStringArray = PackedStringArray(["dungeon"])
var unlocked_upgrades: PackedStringArray = PackedStringArray()
## upgrade_id -> rank stored as "id:rank" entries in unlocked_upgrades
var starting_gold_bonus: int = 0
var survival_cushion: int = 0

# ── Town / receptionist ────────────────────────────────────────────────────
## Soft affinity: negative after fails, recovers on clears. Drives dialogue.
var receptionist_affinity: int = 0
var last_outcome: String = ""  # "clear" | "concede" | ""
## Phase 6 — first-visit contract signing
var receptionist_contract_signed: bool = false
## Enemy ids the player has already seen a first-meet intro for
var met_enemies: PackedStringArray = PackedStringArray()
## Phase 11 — public guild rank (E easiest → S hardest)
var guild_rank: String = "E"
## Phase 12 — last contest vs each enemy: enemy_id -> "won" | "lost"
var enemy_last_result: Dictionary = {}

# ── Pending punishments for the NEXT run ───────────────────────────────────
var pending_modifiers: Array = []  # Array[ModifierDef] (serialize carefully)

signal meta_changed()

func _ready() -> void:
	load_from_disk()

func xp_to_next_level() -> int:
	return 60 * player_level

func has_met_enemy(enemy_id: String) -> bool:
	return enemy_id in met_enemies

func mark_enemy_met(enemy_id: String) -> void:
	if enemy_id == "" or enemy_id in met_enemies:
		return
	met_enemies.append(enemy_id)
	emit_signal("meta_changed")

func get_enemy_last_result(enemy_id: String) -> String:
	return str(enemy_last_result.get(enemy_id, ""))

func set_enemy_last_result(enemy_id: String, result: String) -> void:
	if enemy_id == "":
		return
	if result not in ["won", "lost"]:
		return
	enemy_last_result[enemy_id] = result
	emit_signal("meta_changed")

func sign_receptionist_contract() -> void:
	receptionist_contract_signed = true
	receptionist_affinity = maxi(receptionist_affinity, 0)
	emit_signal("meta_changed")

func rank_index(rank: String = "") -> int:
	var r := rank if rank != "" else guild_rank
	var idx := GUILD_RANKS.find(r.to_upper())
	return maxi(0, idx)

func guild_rank_label() -> String:
	return guild_rank.to_upper()

func try_rank_up() -> bool:
	var i := rank_index()
	if i >= GUILD_RANKS.size() - 1:
		return false
	guild_rank = GUILD_RANKS[i + 1]
	emit_signal("meta_changed")
	return true

func try_rank_down() -> bool:
	var i := rank_index()
	if i <= 0:
		return false
	guild_rank = GUILD_RANKS[i - 1]
	emit_signal("meta_changed")
	return true

func board_offer_count() -> int:
	# Base 2 offers + board_postings ranks, capped at 4.
	return clampi(2 + upgrade_rank("board_postings"), 2, 4)

func upgrade_rank(id: String) -> int:
	var prefix := id + ":"
	for entry in unlocked_upgrades:
		if String(entry).begins_with(prefix):
			return int(String(entry).substr(prefix.length()))
		if String(entry) == id:
			return 1
	return 0

func set_upgrade_rank(id: String, rank: int) -> void:
	var prefix := id + ":"
	var next := PackedStringArray()
	for entry in unlocked_upgrades:
		if String(entry).begins_with(prefix) or String(entry) == id:
			continue
		next.append(entry)
	if rank > 0:
		next.append("%s:%d" % [id, rank])
	unlocked_upgrades = next
	emit_signal("meta_changed")

func try_buy_upgrade(id: String) -> bool:
	if not UpgradeCatalog.UPGRADES.has(id):
		return false
	var def: Dictionary = UpgradeCatalog.UPGRADES[id]
	var rank := upgrade_rank(id)
	if rank >= int(def["max_rank"]):
		return false
	var cost := UpgradeCatalog.cost_for(id)
	if banked_gold < cost:
		return false
	banked_gold -= cost
	rank += 1
	set_upgrade_rank(id, rank)
	match String(def["stat"]):
		"base_max_health":
			base_max_health += int(def["amount"])
		"base_damage":
			base_damage += int(def["amount"])
		"starting_gold":
			starting_gold_bonus += int(def["amount"])
		"survival_cushion":
			survival_cushion += int(def["amount"])
		"board_postings", "none", "":
			pass  # meta-only upgrades (extra quest choices, etc.)
	save_to_disk()
	emit_signal("meta_changed")
	return true

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
	try_rank_up()
	emit_signal("meta_changed")

func on_quest_conceded() -> void:
	last_outcome = "concede"
	receptionist_affinity = maxi(-10, receptionist_affinity - 2)
	# Slight chance to demote guild rank on fold
	if randf() < 0.35:
		try_rank_down()
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
		"starting_gold_bonus": starting_gold_bonus,
		"survival_cushion": survival_cushion,
		"receptionist_affinity": receptionist_affinity,
		"last_outcome": last_outcome,
		"receptionist_contract_signed": receptionist_contract_signed,
		"met_enemies": Array(met_enemies),
		"guild_rank": guild_rank,
		"enemy_last_result": enemy_last_result.duplicate(),
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
	starting_gold_bonus = int(d.get("starting_gold_bonus", 0))
	survival_cushion = int(d.get("survival_cushion", 0))
	receptionist_affinity = int(d.get("receptionist_affinity", 0))
	last_outcome = str(d.get("last_outcome", ""))
	receptionist_contract_signed = bool(d.get("receptionist_contract_signed", false))
	met_enemies = PackedStringArray(d.get("met_enemies", []))
	var loaded_rank := str(d.get("guild_rank", "E")).to_upper()
	guild_rank = loaded_rank if loaded_rank in GUILD_RANKS else "E"
	enemy_last_result.clear()
	var elr = d.get("enemy_last_result", {})
	if typeof(elr) == TYPE_DICTIONARY:
		for k in elr.keys():
			var v := str(elr[k])
			if v in ["won", "lost"]:
				enemy_last_result[str(k)] = v
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
