extends RefCounted
class_name FirstMeetScenes
# =============================================================================
# FirstMeetScenes — Phase 6 elaborate first-meet dialogue
# =============================================================================
# Multi-page intros the first time you meet each enemy (and the receptionist).
# Later encounters skip these and use normal in-combat taunts.
# =============================================================================

const ENEMY_INTROS := {
	"goblin_girl": [
		"A goblin girl blocks the corridor, barefoot, toes curling against the stone.",
		"She lifts one foot and wiggles her toes in your face, grinning wide.\n\"Look at these. Bet your little cock is already twitching~\"",
		"\"C'mon, adventurer — don't fight it. Stare at my soles, stroke if you have to, and spurt out your little load for me.\"",
		"She laughs, bouncing on her heels.\n\"Or try to keep the beat. Either way, I'm taking that load.\"",
	],
	"slime_girl": [
		"A translucent slime girl oozes into shape, warm and sticky, wrapping a tendril around your ankle.",
		"\"Ooh… a new toy. Don't tense up — I want to feel every throb.\"",
		"She presses cool gel against your thighs, pulsing in time with the distant beat.\n\"Melt for me. Let it leak. I'll drink every drop if you give in.\"",
		"\"Still standing? Cute. Then dance — and try not to cum when I squeeze.\"",
	],
	"succubus": [
		"A succubus unfolds from the shadows, wings half-spread, eyes locked on yours.",
		"\"First time seeing a real demoness? Your pulse is already singing for me.\"",
		"She leans in, breath hot on your ear.\n\"I don't need to touch you yet. Just keep rhythm… and when you break, I'll taste it.\"",
		"\"Submit now if you like — whisper that you'll spill for me. Or resist. I love both.\"",
	],
	"kitsune": [
		"A kitsune girl fans her tails, one brushing your cheek like a tease.",
		"\"Fresh prey. Your ears are already pink — foxes notice that.\"",
		"She curls a tail under your chin.\n\"First meeting gift: watch my hips, miss a beat, and I'll make you finish in your pants.\"",
		"\"Still proud? Good. The longer you last, the sweeter it is when you fold.\"",
	],
	"troll_girl": [
		"A towering troll girl plants her feet, the floor trembling.",
		"\"You are small. I am not. Look up.\"",
		"She cracks her knuckles, then taps a slow, heavy rhythm on her thigh.\n\"You will keep that beat. If you fail, you cum for me. Simple.\"",
		"\"First time meeting Troll Girl? Then learn: resistance is a game I always win.\"",
	],
	"dragoness": [
		"Heat rolls off a dragoness as she coils into the chamber, gold eyes narrowing.",
		"\"A hunter in my den. Bold. Or foolish.\"",
		"She extends a claw and traces the air near your chest.\n\"Kneel to the rhythm, little treasure. Spill for your queen, or prove you can endure fire.\"",
		"\"First audience with me ends two ways — conquest, or a puddle at my feet. Choose with your body.\"",
	],
}

const RECEPTIONIST_CONTRACT := [
	"Receptionist: \"New face. Don't loiter — the Temptress Guild doesn't babysit tourists.\"",
	"Receptionist: \"Contracts are simple. You take a quest. You face monstergirls who will try to make you lose control.\"",
	"Receptionist: \"Hold the rhythm, clear the rooms, bank the spoils. Give in — climax, concede — and we dock your level, seize quest treasure, and write you up.\"",
	"Receptionist: \"Fines. Curses. My disappointment. All of it sticks until you pay or outgrow it.\"",
	"She slides a parchment across the desk, quill waiting.\nReceptionist: \"Sign. Acknowledge you know what you're walking into — and that if you spurt on the job, that's on you.\"",
]

static func enemy_pages(enemy_id: String) -> PackedStringArray:
	if ENEMY_INTROS.has(enemy_id):
		return PackedStringArray(ENEMY_INTROS[enemy_id])
	return PackedStringArray([
		"Something dangerous steps into the light.",
		"\"First time? Cute. Try not to finish too fast.\"",
	])

static func receptionist_pages() -> PackedStringArray:
	return PackedStringArray(RECEPTIONIST_CONTRACT)
