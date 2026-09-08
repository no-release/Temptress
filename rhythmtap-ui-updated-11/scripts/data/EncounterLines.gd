extends RefCounted
class_name EncounterLines
# Rematch + drain — voice pack, tagged for combat subtitles.

const REMATCH_WON := {
	"slime_girl": [
		"[drip]Back again? Still sticky from last time~[/drip]",
		"[tease]You beat me once.[/tease] [clingy]Let's see if that was luck… or a fluke drip.[/clingy]",
	],
	"goblin_girl": [
		"[giggle]Hehe, rematch?[/giggle] [brat]I remember you winning — won't happen twice![/brat]",
		"[tease]Back for another round, softie?[/tease]",
	],
	"succubus": [
		"[velvet]You walked away last time.[/velvet] [tease]Brave… or foolish~[/tease]",
		"[lick]Still tasting that victory?[/lick] [predator]I'll take it back, slow.[/predator]",
	],
	"kitsune": [
		"[sly]The fox remembers who scratched her.[/sly] Hello again.",
		"[tease]You won once.[/tease] [smug]Tails don't forget — or forgive.[/smug]",
	],
	"troll_girl": [
		"[blunt]You beat Troll Girl. Rematch. Now.[/blunt]",
		"[growl]Back. I hit harder this time.[/growl]",
	],
	"dragoness": [
		"[queen]You left my hoard once. Rare.[/queen] Do not expect mercy twice.",
		"[echo]Treasure-hunter returns.[/echo] [regal]The beat still claims.[/regal]",
	],
}

const REMATCH_LOST := {
	"slime_girl": [
		"[moan]Ooh, you folded for me last time~[/moan] [drip]Miss that drip?[/drip]",
		"[clingy]Back already?[/clingy] [drain]Your level still tastes sweet on my tongue.[/drain]",
	],
	"goblin_girl": [
		"[laugh]Hah! The one who gave in![/laugh] [hot]Ready to break again?[/hot]",
		"[brat]Look who crawled back after conceding~[/brat]",
	],
	"succubus": [
		"[heart]My favorite quitter.[/heart] [drain]Shall I drain you again?[/drain]",
		"[command]You admitted defeat before.[/command] [velvet]Your body remembers me.[/velvet]",
	],
	"kitsune": [
		"[sweet]You gave in so prettily last time.[/sweet] Again?",
		"[giggle]Folded for foxes once… ears still red?[/giggle]",
	],
	"troll_girl": [
		"[command]You said you lost. Good. Say it again.[/command]",
		"[blunt]You broke for me. Rematch. Same ending.[/blunt]",
	],
	"dragoness": [
		"[queen]You surrendered to a dragoness.[/queen] [command]Kneel to the rhythm again.[/command]",
		"[drain]The guild knows you folded.[/drain] Prove otherwise… or don't.",
	],
}

const REMATCH_NEUTRAL := {
	"slime_girl":  ["[drip]Mmm, familiar face. Slippery beats await~[/drip]"],
	"goblin_girl": ["[giggle]Oh, you again. Try to keep up![/giggle]"],
	"succubus":    ["[velvet]We meet again.[/velvet] [command]Dance for me.[/command]"],
	"kitsune":     ["[sly]Nine tails, same rhythm. Keep up~[/sly]"],
	"troll_girl":  ["[blunt]You return.[/blunt] [big]Boom. Boom.[/big]"],
	"dragoness":   ["[queen]Again before a dragoness.[/queen] [hot]Hold the heat.[/hot]"],
}

const LEVEL_DRAIN := {
	"slime_girl": [
		"[drain]Feel that? I'm melting a whole level out of you~[/drain]",
		"[drip]Drip… drip…[/drip] [drain]there goes a level. Sticky progress~[/drain]",
	],
	"goblin_girl": [
		"[laugh]Hehe! Level drained![/laugh] [threat]That's what you get for giving in![/threat]",
		"[giggle]Poof — one level gone. Goblin tax~[/giggle]",
	],
	"succubus": [
		"[moan]Mmm… I just sipped a level from you.[/moan] [velvet]Delicious.[/velvet]",
		"[drain]Your growth thins as you break. One level, mine~[/drain]",
	],
	"kitsune": [
		"[sly]A fox takes what you offer.[/sly] [drain]One level, plucked.[/drain]",
		"[tease]Gave in? Then forfeit a level. Fair play~[/tease]",
	],
	"troll_girl": [
		"[shout]YOU GIVE UP. I TAKE LEVEL.[/shout]",
		"[blunt]Level gone. Weakness has a price.[/blunt]",
	],
	"dragoness": [
		"[queen]A dragoness claims tribute[/queen] — [drain]one level from your path.[/drain]",
		"[drain]Surrender feeds the hoard. Your level thins.[/drain]",
	],
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
