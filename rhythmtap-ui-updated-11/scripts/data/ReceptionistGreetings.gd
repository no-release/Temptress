extends RefCounted
class_name ReceptionistGreetings
# =============================================================================
# ReceptionistGreetings -- Phase 10 boot return lines
# =============================================================================
# Performance-aware greeting pages for ReceptionistBoot after the contract is
# signed. Contract pages stay on FirstMeetScenes.receptionist_pages().
# =============================================================================

const RETURN_CONCEDE := [
	[
		"Receptionist: You again. Empty-handed.",
		"Receptionist: Wash up. The board is still open -- if they will still take you.",
	],
	[
		"Receptionist: Back already... and you gave in.",
		"Receptionist: The guild keeps records. Do not make me explain this upstairs.",
	],
	[
		"Receptionist: ...Again.",
		"Receptionist: Consequences stick. Pay your fines or outgrow them.",
	],
]

const RETURN_CLEAR := [
	[
		"Receptionist: You held out and finished. Good.",
		"Receptionist: Spoils are banked. The board is waiting when you are ready.",
	],
	[
		"Receptionist: A clean clear. The guild notices the ones who do not fold.",
		"Receptionist: Rest, then take another contract.",
	],
	[
		"Receptionist: Welcome back, hunter. Your purse looks healthier.",
		"Receptionist: Do not get cocky -- the next quest will not go easy on you.",
	],
]

const RETURN_NEUTRAL := [
	[
		"Receptionist: You are back.",
		"Receptionist: Contracts, rest, and home -- in that order if you are smart.",
	],
	[
		"Receptionist: Guild hall. Do not loiter.",
		"Receptionist: The board is open.",
	],
]

static func return_pages(outcome: String, affinity: int) -> PackedStringArray:
	var pool: Array = RETURN_NEUTRAL
	match outcome:
		"concede":
			pool = RETURN_CONCEDE
		"clear":
			pool = RETURN_CLEAR
		_:
			pool = RETURN_NEUTRAL
	var pick: Array = pool[randi() % pool.size()]
	var pages := PackedStringArray(pick)
	if outcome == "concede" and affinity <= -6:
		pages.append("Receptionist: ...She barely looks at you. Just points at the board.")
	elif outcome == "clear" and affinity >= 4:
		pages.append("Receptionist: (A rare almost-smile.) Do not waste that goodwill.")
	return pages
