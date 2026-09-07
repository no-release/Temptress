extends RefCounted
class_name BoardOfferPersist
# =============================================================================
# BoardOfferPersist — Phase 13 persistent unique guild board offers
# =============================================================================
# Serializes QuestDef offers into MetaSave.board_offers so reboot does not
# reroll. Keeps simultaneous offers unique (length+difficulty+biome key).
# =============================================================================

static func offer_key(q: QuestDef) -> String:
	# Distinct quest combo (enemy pool is derived from these params at run start).
	return "%d_%d_%s" % [int(q.length), int(q.difficulty), String(q.biome)]

static func quest_to_dict(q: QuestDef) -> Dictionary:
	return {
		"id": q.id,
		"display_name": q.display_name,
		"length": int(q.length),
		"difficulty": int(q.difficulty),
		"biome": q.biome,
		"combat_room_count": q.combat_room_count,
		"gold_multiplier": q.gold_multiplier,
		"xp_multiplier": q.xp_multiplier,
		"forced_enemies": Array(q.forced_enemies),
		"allow_rest": q.allow_rest,
		"allow_shop": q.allow_shop,
		"min_enemy_tier": q.min_enemy_tier,
		"max_enemy_tier": q.max_enemy_tier,
	}

static func quest_from_dict(d: Dictionary) -> QuestDef:
	var q := QuestDef.new()
	q.id = str(d.get("id", ""))
	q.display_name = str(d.get("display_name", ""))
	q.length = int(d.get("length", QuestDef.Length.SHORT)) as QuestDef.Length
	q.difficulty = int(d.get("difficulty", QuestDef.Difficulty.NORMAL)) as QuestDef.Difficulty
	q.biome = str(d.get("biome", "dungeon"))
	q.combat_room_count = int(d.get("combat_room_count", 3))
	q.gold_multiplier = float(d.get("gold_multiplier", 1.0))
	q.xp_multiplier = float(d.get("xp_multiplier", 1.0))
	q.forced_enemies = PackedStringArray(d.get("forced_enemies", []))
	q.allow_rest = bool(d.get("allow_rest", true))
	q.allow_shop = bool(d.get("allow_shop", true))
	q.min_enemy_tier = int(d.get("min_enemy_tier", 1))
	q.max_enemy_tier = int(d.get("max_enemy_tier", 2))
	if q.id == "":
		q.id = "%s_%s_%s" % [
			q.biome,
			QuestDef.length_label(q.length).to_lower(),
			QuestDef.difficulty_label(q.difficulty).to_lower(),
		]
	if q.display_name == "":
		q.display_name = "%s — %s / %s" % [
			q.biome.capitalize(),
			QuestDef.length_label(q.length),
			QuestDef.difficulty_label(q.difficulty),
		]
	return q

static func load_offers() -> Array:
	var out: Array = []
	for item in MetaSave.board_offers:
		if typeof(item) == TYPE_DICTIONARY:
			out.append(quest_from_dict(item))
	return out

static func persist_offers(offers: Array) -> void:
	var serialized: Array = []
	var seen: Dictionary = {}
	for q in offers:
		if not (q is QuestDef):
			continue
		var key := offer_key(q)
		if seen.has(key):
			continue
		seen[key] = true
		serialized.append(quest_to_dict(q))
	MetaSave.board_offers = serialized
	MetaSave.save_to_disk()
	MetaSave.emit_signal("meta_changed")

static func _seen_from(offers: Array) -> Dictionary:
	var seen: Dictionary = {}
	for q in offers:
		if q is QuestDef:
			seen[offer_key(q)] = true
	return seen

static func _append_unique(offers: Array, seen: Dictionary, need: int) -> void:
	var attempts := 0
	while offers.size() < need and attempts < 80:
		attempts += 1
		var batch: Array = QuestGenerator.generate_offers(1, "", seen)
		if batch.is_empty():
			break
		var q: QuestDef = batch[0]
		var key := offer_key(q)
		if seen.has(key):
			continue
		seen[key] = true
		offers.append(q)

## Load persisted offers or generate until board_offer_count() unique slots are filled.
static func ensure_offers() -> Array:
	var need := MetaSave.board_offer_count()
	var offers := load_offers()
	if offers.size() > need:
	offers = offers.slice(0, need)
	var seen := _seen_from(offers)
	_append_unique(offers, seen, need)
	persist_offers(offers)
	return load_offers()

## Accept one offer, then replace leftover slots with fresh unique offers (full board).
static func accept_and_refresh(selected_index: int) -> QuestDef:
	var offers := ensure_offers()
	if offers.is_empty():
		return null
	selected_index = clampi(selected_index, 0, offers.size() - 1)
	var accepted: QuestDef = offers[selected_index]
	var need := MetaSave.board_offer_count()
	var fresh: Array = []
	var seen: Dictionary = {}
	# Prefer not re-posting the just-accepted contract on the refreshed board.
	seen[offer_key(accepted)] = true
	_append_unique(fresh, seen, need)
	if fresh.size() < need:
		# Pool exhausted — allow the accepted key back and finish filling.
		seen.erase(offer_key(accepted))
		_append_unique(fresh, seen, need)
	persist_offers(fresh)
	return accepted

## board_postings upgrade bought — immediately fill any new empty slot(s).
static func fill_new_slots() -> void:
	ensure_offers()
