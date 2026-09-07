extends Resource
class_name QuestDef
# =============================================================================
# QuestDef — Phase 0 data model
# =============================================================================
# Immutable definition of a guild quest the player can take.
# RoomManager / QuestRunner turn this into a concrete room list for one run.
# Does NOT store progress — that lives in RunState.
# =============================================================================

enum Length { SHORT, MEDIUM, LONG }
enum Difficulty { EASY, NORMAL, HARD, NIGHTMARE }

@export var id: String = ""
@export var display_name: String = ""

@export var length: Length = Length.SHORT
@export var difficulty: Difficulty = Difficulty.NORMAL
@export var biome: String = "dungeon"  # e.g. dungeon, swamp, forest, volcanic, palace

## How many combat rooms (rest/shop inserted by generator rules).
@export var combat_room_count: int = 3

## Multipliers applied when banking treasure / XP at quest clear.
@export var gold_multiplier: float = 1.0
@export var xp_multiplier: float = 1.0

## Optional forced enemy ids (empty = pick from biome + difficulty pool).
@export var forced_enemies: PackedStringArray = []

## Soft constraints for the generator.
@export var allow_rest: bool = true
@export var allow_shop: bool = true
@export var min_enemy_tier: int = 1
@export var max_enemy_tier: int = 2

static func length_label(l: Length) -> String:
	match l:
		Length.SHORT: return "Short"
		Length.MEDIUM: return "Medium"
		Length.LONG: return "Long"
	return "?"

static func difficulty_label(d: Difficulty) -> String:
	match d:
		Difficulty.EASY: return "Easy"
		Difficulty.NORMAL: return "Normal"
		Difficulty.HARD: return "Hard"
		Difficulty.NIGHTMARE: return "Nightmare"
	return "?"

## Sensible defaults for guild-board picks before custom quests exist.
static func from_board(length: Length, difficulty: Difficulty, biome: String) -> QuestDef:
	var q := QuestDef.new()
	q.length = length
	q.difficulty = difficulty
	q.biome = biome
	q.id = "%s_%s_%s" % [biome, length_label(length).to_lower(), difficulty_label(difficulty).to_lower()]
	q.display_name = "%s — %s / %s" % [biome.capitalize(), length_label(length), difficulty_label(difficulty)]

	match length:
		Length.SHORT:
			q.combat_room_count = 3
			q.allow_rest = false
			q.allow_shop = false
		Length.MEDIUM:
			q.combat_room_count = 5
			q.allow_rest = true
			q.allow_shop = false
		Length.LONG:
			q.combat_room_count = 7
			q.allow_rest = true
			q.allow_shop = true

	match difficulty:
		Difficulty.EASY:
			q.min_enemy_tier = 1
			q.max_enemy_tier = 2
			q.gold_multiplier = 0.85
			q.xp_multiplier = 0.85
		Difficulty.NORMAL:
			q.min_enemy_tier = 1
			q.max_enemy_tier = 3
			q.gold_multiplier = 1.0
			q.xp_multiplier = 1.0
		Difficulty.HARD:
			q.min_enemy_tier = 2
			q.max_enemy_tier = 3
			q.gold_multiplier = 1.25
			q.xp_multiplier = 1.25
		Difficulty.NIGHTMARE:
			q.min_enemy_tier = 3
			q.max_enemy_tier = 3
			q.gold_multiplier = 1.6
			q.xp_multiplier = 1.6

	return q
