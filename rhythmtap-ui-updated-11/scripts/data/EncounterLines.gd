extends RefCounted
class_name EncounterLines
# =============================================================================
# EncounterLines — Phase 12 rematch greetings + level-drain flavor
# =============================================================================
# Short non-VN lines for already-met enemies (first meet still uses FirstMeetVN).
# last_result: "won" (player cleared that foe) | "lost" (player conceded to them).
# =============================================================================

const REMATCH_WON := {
	"slime_girl":  ["Back again? Still sticky from last time~", "You beat me once. Let's see if that was luck."],
	"goblin_girl": ["Hehe, rematch? I remember you winning!", "Back for another round, softie?"],
	"succubus":    ["You walked away last time. Brave… or foolish~", "Still tasting that victory? I'll take it back."],
	"kitsune":     ["The fox remembers who scratched her. Hello again.", "You won once. Tails don't forget."],
	"troll_girl":  ["You beat Troll Girl. Rematch. Now.", "Back. I hit harder this time."],
	"dragoness":   ["You left my hoard once. Rare. Do not expect mercy twice.", "Treasure-hunter returns. The beat still claims."],
}

const REMATCH_LOST := {
	"slime_girl":  ["Ooh, you folded for me last time~ Miss that drip?", "Back already? Your level still tastes sweet."],
	"goblin_girl": ["Hah! The one who gave in! Ready to break again?", "Look who crawled back after conceding~"],
	"succubus":    ["My favorite quitter. Shall I drain you again?", "You admitted defeat before. Body remembers."],
	"kitsune":     ["You gave in so prettily last time. Again?", "Folded for foxes once… ears still red?"],
	"troll_girl":  ["You said you lost. Good. Say it again.", "You broke for me. Rematch. Same ending."],
	"dragoness":   ["You surrendered to a dragoness. Kneel to the rhythm again.", "The guild knows you folded. Prove otherwise… or don't."],
}

const REMATCH_NEUTRAL := {
	"slime_girl":  ["Mmm, familiar face. Slippery beats await~"],
	"goblin_girl": ["Oh, you again. Try to keep up!"],
	"succubus":    ["We meet again. Dance for me."],
	"kitsune":     ["Nine tails, same rhythm. Keep up~"],
	"troll_girl":  ["You return. Boom. Boom."],
	"dragoness":   ["Again before a dragoness. Hold the heat."],
}

const LEVEL_DRAIN := {
	"slime_girl":  ["Feel that? I'm melting a whole level out of you~", "Drip… drip… there goes a level. Sticky progress~"],
	"goblin_girl": ["Hehe! Level drained! That's what you get for giving in!", "Poof — one level gone. Goblin tax~"],
	"succubus":    ["Mmm… I just sipped a level from you. Delicious.", "Your growth thins as you break. One level, mine~"],
	"kitsune":     ["A fox takes what you offer. One level, plucked.", "Gave in? Then forfeit a level. Fair play~"],
	"troll_girl":  ["YOU GIVE UP. I TAKE LEVEL.", "Level gone. Weakness has a price."],
	"dragoness":   ["A dragoness claims tribute — one level from your path.", "Surrender feeds the hoard. Your level thins."],
}

static func rematch_greeting(enemy_id: String, last_result: String) -> String:
	var pool: Array = REMATCH_NEUTRAL.get(enemy_id, ["We meet again."])
	match last_result:
		"won":
			pool = REMATCH_WON.get(enemy_id, pool)
		"lost":
			pool = REMATCH_LOST.get(enemy_id, pool)
		_:
			pass
	if pool.is_empty():
		return ""
	return str(pool[randi() % pool.size()])

static func level_drain_line(enemy_id: String) -> String:
	var pool: Array = LEVEL_DRAIN.get(enemy_id, ["She drinks a level from you as you give in…"])
	if pool.is_empty():
		return "LEVEL DRAINED."
	return str(pool[randi() % pool.size()])
