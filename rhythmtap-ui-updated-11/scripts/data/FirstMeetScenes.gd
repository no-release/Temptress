extends RefCounted
class_name FirstMeetScenes
# =============================================================================
# FirstMeetScenes — first-meet VN pages (voice pack)
# =============================================================================

const ENEMY_INTROS := {
	"slime_girl": [
		"Warm gel spreads across the floor, then rises into a girl-shaped smear of glossy pink.",
		"A soft tendril kisses your ankle and climbs.\n\"Ooh… you're warm. Don't pull away — I want to feel how hard you're already getting.\"",
		"She presses cool wetness against your thighs, pulsing with the distant beat.\n\"Melt for me. Leak if you need to. I'll drink every sticky drop when you break.\"",
		"\"Still standing? Cute little toy.\nThen keep the rhythm… and try not to cum when I squeeze.\"",
	],
	"goblin_girl": [
		"Bare feet slap stone. A goblin girl blocks the corridor, grinning like she already won.",
		"She plants one sole in your face and wiggles her toes.\n\"Look. Bet that little cock is twitching already~\"",
		"\"C'mon, softie — stare, stroke if you gotta, and spurt that pathetic load for me.\"",
		"She bounces on her heels, laughing.\n\"Or keep the beat. Either way? I'm taking it.\"",
	],
	"succubus": [
		"Shadows peel back. Wings half-open. A succubus watches you like a meal that walked in.",
		"\"First time meeting a real demoness?\nYour pulse is already singing for me. Delicious.\"",
		"Hot breath at your ear — she still hasn't touched you.\n\"I don't need hands yet. Hold the rhythm… and when you break, I'll taste every shudder.\"",
		"\"Whisper that you'll spill for me, if you like.\nOr resist. I savor both.\"",
	],
	"kitsune": [
		"Nine tails fan open. One brushes your cheek like a dare.",
		"\"Fresh prey.\nPink ears already? Foxes notice everything.\"",
		"A tail curls under your chin, tipping your face up.\n\"Gift for our first meeting: watch my hips, miss a beat, and I'll make you finish in your pants.\"",
		"\"Still proud? Good.\nThe longer you last, the sweeter it is when you fold.\"",
	],
	"troll_girl": [
		"The floor shakes. A towering troll girl plants her feet and looks down.",
		"\"You are small. I am not.\nLook up.\"",
		"She taps a slow, heavy rhythm on her thigh.\n\"You keep that beat. Miss it — you cum for me. Simple.\"",
		"\"First time with Troll Girl?\nLearn: resistance is a game. I always win.\"",
	],
	"dragoness": [
		"Heat rolls into the chamber. Gold eyes. A dragoness coils like she owns the air.",
		"\"A hunter in my den.\nBold… or foolish.\"",
		"A claw traces empty air over your chest, never quite touching.\n\"Kneel to the rhythm, little treasure. Spill for your queen — or prove you can endure fire.\"",
		"\"First audience ends two ways.\nConquest… or a puddle at my feet. Choose with your body.\"",
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
