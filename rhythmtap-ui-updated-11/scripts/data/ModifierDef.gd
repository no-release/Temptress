extends Resource
class_name ModifierDef
# =============================================================================
# ModifierDef — fines & curses that alter the NEXT run
# =============================================================================
# Applied on concede / fail, cleared or consumed when the next run starts
# (or when paid off — Phase 3 decides the UX).
# Keep effects data-driven so GameManager / QuestRunner read flags, not
# hard-coded receptionist dialogue.
# =============================================================================

enum Kind { FINE, CURSE }
enum Effect {
	GOLD_DEBT,           # start run with negative / owed gold
	HP_PENALTY,          # reduce starting / max HP for the run
	ATK_PENALTY,         # reduce starting ATK for the run
	BPM_PRESSURE,        # slight BPM increase (harder rhythm)
	EXTRA_EARLY_ENEMY,   # insert one extra weak combat at start
	SURVIVAL_SHORTER,    # fewer survival beats required? or window shorter — tune in Phase 2
	RECEPTIONIST_COLD,   # dialogue / affinity flag only
}

@export var id: String = ""
@export var kind: Kind = Kind.FINE
@export var effect: Effect = Effect.GOLD_DEBT
@export var display_name: String = ""
@export var description: String = ""

## Magnitude meaning depends on effect (gold amount, % HP, BPM delta, etc.).
@export var magnitude: float = 0.0

## How many runs this stays active (-1 = until cleared manually).
@export var runs_remaining: int = 1

static func make_fine(id: String, effect: Effect, magnitude: float, name: String, desc: String) -> ModifierDef:
	var m := ModifierDef.new()
	m.id = id
	m.kind = Kind.FINE
	m.effect = effect
	m.magnitude = magnitude
	m.display_name = name
	m.description = desc
	m.runs_remaining = 1
	return m

static func make_curse(id: String, effect: Effect, magnitude: float, name: String, desc: String, runs: int = 1) -> ModifierDef:
	var m := ModifierDef.new()
	m.id = id
	m.kind = Kind.CURSE
	m.effect = effect
	m.magnitude = magnitude
	m.display_name = name
	m.description = desc
	m.runs_remaining = runs
	return m
