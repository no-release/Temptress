extends Node
# =============================================================================
# GameManager.gd — ALPHA BUILD, everything here is provisional
# =============================================================================
# Central brain of a combat encounter. Owns the rhythm clock, turn machine,
# player/enemy stats, and all game-state transitions.
#
# DESIGN OVERVIEW (as of this alpha):
#   Fights are turn-based but expressed as a rhythm. The beat generator
#   schedules beats into the future; each beat carries a "turn_phase" tag
#   (ENEMY or PLAYER). When the phase flips, _end_of_turn() resolves damage.
#
# PLAYER INPUT:
#   The player does NOT press a button each beat. Instead BeatBar.gd draws
#   an approach track and the player taps the screen/clicks anywhere to hit
#   beats. Taps are consumed by BeatBar.gd — GameManager only sees whether
#   the player landed enough beats to complete their turn (the beat generator
#   handles this implicitly by cycling through PLAYER beats).
#   This means "player damage" applies automatically at end of player turn
#   without explicit hit detection per-beat. This is an alpha simplification
#   and may change if a miss/accuracy system is added later.
#
# GAME FLOW:
#   PLAYING   → normal combat, alternating ENEMY/PLAYER turns
#   SURVIVAL  → player HP hit 0; must tap through N rapid beats to survive
#               gold is NOT stolen here — only stolen if they concede
#   TREASURE  → enemy dead; game pauses, loot screen shown, beats stop
#   PUNISHMENT→ player conceded during survival; 10-second countdown to death
#   GAMEOVER  → countdown expired; transition back to menu
#
# ROOM SEQUENCING:
#   GameManager doesn't know which enemy comes next — RoomManager decides
#   that and passes the enemy type string via continue_after_treasure().
#   This keeps GameManager reusable for any room sequence.
# =============================================================================

# ── Enemy Resource ────────────────────────────────────────────────────────────
# Simple data container — no logic here intentionally.
# Dialogue lines are keyed by situation; get_line() picks one at random.
# Adding a new enemy: add an entry in _build_enemies() with its own line dict.
class EnemyData:
	var name:          String
	var max_health:    int
	var damage:        int
	var beats_in_turn: int   # how many beats before the turn flips
	var base_bpm:      float # BPM during normal combat
	var xp:            int
	var gold:          int
	var lines:         Dictionary
	var last_line:     String = ""

	func _init(p_name, p_max_hp, p_dmg, p_beats, p_bpm, p_xp, p_gold, p_lines):
		name = p_name; max_health = p_max_hp; damage = p_dmg
		beats_in_turn = p_beats; base_bpm = p_bpm
		xp = p_xp; gold = p_gold; lines = p_lines

	func get_line(situation: String) -> String:
		var pool = lines.get(situation, [])
		if pool.is_empty():
			return ""
		var choices: Array = []
		for raw in pool:
			var line := str(raw)
			if line != last_line:
				choices.append(line)
		if choices.is_empty():
			return ""
		var pick: String = str(choices[randi() % choices.size()])
		last_line = pick
		return pick

# ── Enemy Definitions ─────────────────────────────────────────────────────────
# Alpha roster: goblin (fast, weak) and troll (slow, hard-hitting).
# Extend freely — add entries here and reference them from RoomManager.
# ── Enemy Definitions ─────────────────────────────────────────────────────────
# Monstergirl roster ordered roughly by difficulty (weak → strong).
# RoomManager sequences them so early rooms use weaker types.
# Lines lean into teasing / femdom / "make you lose control" tone for the
# eventual guild-quest + cum-resistance fantasy. Full orgasm system is later.
var ENEMY_DATA: Dictionary = {}

func _build_enemies():
	# ── Tier 1: weak / early ──────────────────────────────────────────────────
	ENEMY_DATA["slime_girl"] = EnemyData.new("slime_girl", 28, 5, 20, 120.0, 25, 10, {
		"taunt": [
			"[drip]Ooh, your rhythm's all sticky already~[/drip]",
			"[tease]Slippery beats for a slippery boy~[/tease]",
			"[clingy]Don't melt yet… I want to savor the drip.[/clingy]",
			"[gooey]Hug the beat. I'll hug you harder.[/gooey]",
			"[lick]You're warm.[/lick]",
			"[whisper]Don't pull away.[/whisper]",
		],
		"player_near_death": [
			"[pant]You're dripping…[/pant] [hot]almost done?[/hot]",
			"[heart]One more squeeze and you'll be mine~[/heart]",
			"[moan]Your hands are shaking so cute~[/moan]",
			"[drip]Leak for me. Just a little. Then a lot.[/drip]",
			"[clingy]I can feel your pulse through the gel.[/clingy]",
		],
		"player_defeated": [
			"[sweet]Aww, you fell already?[/sweet] [command]Keep tapping or I'll keep you~[/command]",
			"[tease]Down already? Prove you can still hold on~[/tease]",
			"[gooey]Floor feels nice, doesn't it? Sticky boy.[/gooey]",
		],
		"near_win": [
			"[pant]Nngh—[/pant] you hit hard for a [prey]soft boy[/prey]~",
			"[growl]That actually stung… interesting.[/growl]",
			"[tease]Ooh. Rough. Do it again.[/tease]",
		],
		"survive_loss": [
			"[threat]Tch. You held out.[/threat] Fine — take the loot.",
			"[hiss]You resisted a slime?[/hiss] Annoying… and hot.",
		],
		"losing": [
			"[command]You admit it? Good boy.[/command] [drain]Feel the beat until you break.[/drain]",
			"[clingy]Gave up already?[/clingy] [drain]I'll make sure you remember the squeeze.[/drain]",
		],
		"gameover_remarks": [
			"[drip]Even a slime made you lose control~[/drip]",
			"[tease]Come back when you can last longer, softie.[/tease]",
			"[moan]Mmm. Sticky defeat tastes sweet.[/moan]",
		],
	})
	ENEMY_DATA["goblin_girl"] = EnemyData.new("goblin_girl", 40, 8, 22, 135.0, 40, 15, {
		"taunt": [
			"[giggle]Hehe, too slow![/giggle]",
			"[brat]Can't keep up, can ya?[/brat]",
			"[laugh]My grandma taps faster than that![/laugh]",
			"[punk]Look at you struggling — pathetic and cute.[/punk]",
			"[foot]Look at these toes~ twitching yet?[/foot]",
			"[hyper]Keep up or shut up.[/hyper]",
		],
		"player_near_death": [
			"[shout]One more and you're DONE![/shout]",
			"[hot]I can smell how close you are~[/hot]",
			"[command]Just give in already, softie![/command]",
			"[brat]Spurt. I dare you.[/brat]",
		],
		"player_defeated": [
			"[laugh]Hah! Knocked you flat![/laugh] [fast]Tap fast or you're finished![/fast]",
			"[tease]Down you go, loser~[/tease]",
			"[punk]On the floor already? Beg with your hips.[/punk]",
		],
		"near_win": [
			"[harsh]Ow ow… lucky hit![/harsh]",
			"[giggle]That tickled![/giggle] [mute](It didn't.)[/mute]",
			"[brat]Hey! Rude![/brat]",
		],
		"survive_loss": [
			"[threat]Ugh, fine…[/threat] take your stupid gold.",
			"[growl]You survived? Annoying little thing.[/growl]",
		],
		"losing": [
			"[shout]You SAID you lost![/shout] [drain]Good. Now suffer the beat.[/drain]",
			"[tease]Can't handle the rhythm?[/tease] [threat]Pathetic~[/threat]",
		],
		"gameover_remarks": [
			"[laugh]Even a goblin girl broke you![/laugh]",
			"[command]That's how a goblin makes an adventurer beg.[/command]",
			"[foot]Remember my soles next time you get hard.[/foot]",
		],
	})
	ENEMY_DATA["succubus"] = EnemyData.new("succubus", 55, 11, 16, 125.0, 65, 25, {
		"taunt": [
			"[velvet]Feel that pulse?[/velvet] [heart]It's matching your heartbeat~[/heart]",
			"[lick]I can already taste how desperate you are.[/lick]",
			"[command]Dance for me,[/command] [prey]little hero.[/prey]",
			"[predator]Don't look away. I want to watch you unravel.[/predator]",
			"[whisper]I don't need to rush you.[/whisper]",
		],
		"player_near_death": [
			"[moan]You're throbbing in time with me~[/moan]",
			"[slow]So close…[/slow] [hot]just let go.[/hot]",
			"[sweet]Your resolve is melting so prettily.[/sweet]",
			"[velvet]Whisper it. Tell me you're going to spill.[/velvet]",
		],
		"player_defeated": [
			"[tease]Fallen already?[/tease] [command]Keep the rhythm or I'll claim you fully~[/command]",
			"[queen]On your knees.[/queen] [pant]Tap if you still can.[/pant]",
			"[predator]Good. Broken looks good on you.[/predator]",
		],
		"near_win": [
			"[purr]Mmm…[/purr] you actually hurt me. [harsh]How rude.[/harsh]",
			"[hot]That fire in you is delicious.[/hot]",
			"[velvet]Interesting. Most fold quieter.[/velvet]",
		],
		"survive_loss": [
			"[threat]You held back from a succubus?[/threat] Impressive… and frustrating.",
			"[soft]Fine. Leave with your prize.[/soft] [echo]For now.[/echo]",
		],
		"losing": [
			"[command]You admitted defeat. Perfect.[/command] [drain]Feel every beat until you break.[/drain]",
			"[prey]Good boy.[/prey] [drain]The guild will hear how easily you folded.[/drain]",
		],
		"gameover_remarks": [
			"[drain]Another soul who couldn't last~[/drain]",
			"[command]Come back when you're ready to serve properly.[/command]",
			"[velvet]I'll be tasting that loss for days.[/velvet]",
		],
	})
	ENEMY_DATA["kitsune"] = EnemyData.new("kitsune", 65, 12, 14, 115.0, 80, 30, {
		"taunt": [
			"[sly]Nine tails, one rhythm. Keep up~[/sly]",
			"[giggle]Your ears are turning red already.[/giggle]",
			"[purr]Foxes play with their food, you know.[/purr]",
			"[smug]Miss a beat and I'll make it embarrassing.[/smug]",
			"[tease]Pink ears already? Foxes notice everything.[/tease]",
		],
		"player_near_death": [
			"[sweet]You're trembling. Adorable.[/sweet]",
			"[heart]One more push and you'll be mine~[/heart]",
			"[command]The beat owns you now.[/command]",
			"[sly]Pride first… puddle second. Almost there.[/sly]",
		],
		"player_defeated": [
			"[tease]Collapsed so soon?[/tease] [focus]Prove you can still resist.[/focus]",
			"[whisper]Down already? The tails are disappointed.[/whisper]",
			"[command]Look at me when you shake.[/command]",
		],
		"near_win": [
			"[giggle]Oh? A scratch.[/giggle] How bold of you.",
			"[purr]You're stronger than you look…[/purr] interesting.",
			"[smug]Hah. Clever prey.[/smug]",
		],
		"survive_loss": [
			"[threat]You endured the fox. Rare.[/threat] Take the loot and go.",
			"[hiss]Hmph.[/hiss] You win this round.",
		],
		"losing": [
			"[command]You gave in. Good.[/command] [drain]Now the beat will finish what I started.[/drain]",
			"[tease]Admitted weakness already?[/tease] [drain]The guild will love this report.[/drain]",
		],
		"gameover_remarks": [
			"[tease]Even a kitsune outlasted you~[/tease]",
			"[soft]Next time, try not to fold so quickly.[/soft]",
			"[sly]Tails remember every blush.[/sly]",
		],
	})
	ENEMY_DATA["troll_girl"] = EnemyData.new("troll_girl", 85, 15, 10, 90.0, 110, 40, {
		"taunt": [
			"[shout]TROLL GIRL SMASH RHYTHM.[/shout]",
			"[growl]You think you can keep up? I doubt it.[/growl]",
			"[big]Boom. Boom. Boom.[/big] [focus]Feel it in your bones.[/focus]",
			"[blunt]Look up when you speak to me.[/blunt]",
			"[giantess]You are small.[/giantess]",
		],
		"player_near_death": [
			"[shout]ONE MORE. I FINISH THIS.[/shout]",
			"[harsh]Your hands shake.[/harsh] I see it.",
			"[slow]Almost.[/slow] I am patient.",
			"[blunt]Cum if you must. I will watch.[/blunt]",
		],
		"player_defeated": [
			"[growl]You fall. Not surprised.[/growl] [fast]Tap fast if you still can.[/fast]",
			"[command]Down already? One chance. Use it.[/command]",
			"[blunt]Small body. Loud surrender. Good.[/blunt]",
		],
		"near_win": [
			"[harsh]...Felt that.[/harsh]",
			"[growl]You are stronger than I thought.[/growl]",
			"[blunt]Hmm. Worth keeping.[/blunt]",
		],
		"survive_loss": [
			"[threat]Hmph. Fine. Leave now.[/threat]",
			"[growl]You live. This time.[/growl] I am disappointed.",
		],
		"losing": [
			"[command]You admit weakness? Good.[/command] [drain]Now suffer the maximum drum.[/drain]",
			"[shout]You said it.[/shout] [threat]Prepare to break.[/threat]",
		],
		"gameover_remarks": [
			"[focus]Troll girl wins.[/focus] Think about what you did.",
			"[drain]Even the slowest beat broke you.[/drain]",
			"[giantess]Next time, last longer under me.[/giantess]",
		],
	})
	ENEMY_DATA["dragoness"] = EnemyData.new("dragoness", 110, 18, 8, 80.0, 150, 55, {
		"taunt": [
			"[queen]A dragoness does not rush.[/queen] [echo]The beat will claim you.[/echo]",
			"[command]Kneel to the rhythm,[/command] [prey]little treasure-hunter.[/prey]",
			"[hot]Your heat rises with every pulse~[/hot]",
			"[regal]Do not waste my time. Burn properly.[/regal]",
			"[possessive]A hunter in my den.[/possessive]",
		],
		"player_near_death": [
			"[hot]You are burning.[/hot] [queen]Good.[/queen]",
			"[heart]One more and you belong to me.[/heart]",
			"[hot]The fire in your body betrays you.[/hot]",
			"[regal]Spill for your queen. Or prove you won't.[/regal]",
		],
		"player_defeated": [
			"[queen]Fallen before a dragoness.[/queen] [command]Keep the beat or be claimed.[/command]",
			"[threat]On the ground already?[/threat] Prove your will.",
			"[possessive]Treasure at my feet. Fitting.[/possessive]",
		],
		"near_win": [
			"[harsh]You dared strike a dragoness…[/harsh] bold.",
			"[purr]That heat of yours is interesting.[/purr]",
			"[regal]Rare. Do not make me respect you.[/regal]",
		],
		"survive_loss": [
			"[queen]You endured me. Rare.[/queen] Take your spoils and leave my domain.",
			"[echo]Hmph. You may go… for now.[/echo]",
		],
		"losing": [
			"[command]You surrendered. Perfect.[/command] [drain]The beat will finish you.[/drain]",
			"[drain]The guild will know how quickly their hunter broke.[/drain]",
		],
		"gameover_remarks": [
			"[queen]A dragoness always collects what is hers.[/queen]",
			"[soft]Return when you can last longer than a few measures.[/soft]",
			"[possessive]Your loss feeds the hoard.[/possessive]",
		],
	})

# ── Player Stats ──────────────────────────────────────────────────────────────
# Alpha starting values — balance hasn't been considered yet.
var player_max_health: int   = 30
var player_health:     int   = 30
var player_damage:     int   = 10
var player_xp:         int   = 0
var player_level:      int   = 1
var player_gold:       int   = 0

func xp_to_next_level() -> int:
	return 60 * player_level

# ── Active Enemy ──────────────────────────────────────────────────────────────
var active_enemy_type: String    = "slime_girl"
var active_enemy:      EnemyData = null
var enemy_health:      int       = 0
var enemy_max_health:  int       = 0

# ── Game State ────────────────────────────────────────────────────────────────
enum GameState { PLAYING, SURVIVAL, PUNISHMENT, TREASURE, GAMEOVER }
var game_state: int = GameState.PLAYING

var punishment_countdown: float = 10.0
const PUNISHMENT_BPM: float = 220.0  # frantic BPM during the death countdown
# Each whole number in the countdown (10, 9, 8...) lasts this many real seconds.
# punishment_countdown itself still counts 10.0 -> 0.0, but it now drains at
# 1/PUNISHMENT_SECONDS_PER_COUNT per second instead of 1-for-1 with delta.
const PUNISHMENT_SECONDS_PER_COUNT: float = 1.5

# Survival window: player must tap through this many rapid beats after HP hits 0.
# 30 beats at 180 BPM ≈ 10 seconds. Tweak freely.
const SURVIVAL_BEATS_REQUIRED: int   = 30
const SURVIVAL_BPM:             float = 180.0
var survival_beats_left: int = 0

# ── Rhythm Clock ──────────────────────────────────────────────────────────────
# game_time is a self-managed accumulator (starts at 0, always increases).
# It keeps advancing even during TREASURE so beat timestamps never go stale.
# beat_times holds upcoming beats pre-scheduled SCHEDULE_AHEAD seconds ahead.
var game_time:  float = 0.0
var beat_times: Array = []
var beat_sound: AudioStreamPlayer = null  # injected by Main.gd

enum Turn { ENEMY, PLAYER }
var generator_turn:        int   = Turn.ENEMY  # which turn the scheduler is currently filling
var generator_beats_count: int   = 0
var generator_last_time:   float = 0.0
var current_bpm:           float = 140.0
var process_turn:          int   = Turn.ENEMY  # which turn is currently being processed

const SCHEDULE_AHEAD: float = 3.0  # seconds of beats to keep pre-scheduled

var _total_beats_fired:  int = 0
var _last_dialogue_beat: int = -10  # prevents dialogue spamming; -10 so first line fires early

# ── Signals ───────────────────────────────────────────────────────────────────
# Main.gd listens to all of these to drive UI updates.
signal new_beat(beat_num: int)
signal enemy_state_changed(state: String)   # "idle", "attack", "hurt" — drives background art
signal enemy_type_swapped(type_name: String)
signal player_stats_changed()
signal enemy_hp_changed()
signal enemy_dialogue(text: String, situation: String)
signal enemy_defeated(gold_reward: int)
signal enter_punishment(enemy_name: String)
signal punishment_tick(seconds_left: float)
signal enter_survival(enemy_name: String)
signal survival_progress(beats_left: int, beats_required: int)
signal survival_success()
signal game_over(enemy_name: String)

# ── Boot ──────────────────────────────────────────────────────────────────────
func _ready():
	_build_enemies()
	_apply_meta_stats()
	# Placeholder enemy until Main / RoomManager calls begin_encounter()
	_initialize_enemy("slime_girl")
	# Beat clock is started by begin_encounter() from Main when the first room fires.
	# call_deferred("_start") removed in Phase 1 to avoid double-scheduling beats.

## Pull persistent baseline from MetaSave autoload (Phase 1/2).
func _apply_meta_stats() -> void:
	player_level = MetaSave.player_level
	player_xp = MetaSave.player_xp
	player_max_health = MetaSave.base_max_health
	player_damage = MetaSave.base_damage
	player_gold = MetaSave.starting_gold_bonus  # run bag starts with home purse upgrades
	_apply_active_run_modifiers()
	player_health = player_max_health
	emit_signal("player_stats_changed")

## Fines/curses attached when the quest began (ActiveRun.active_modifiers).
func _apply_active_run_modifiers() -> void:
	if ActiveRun.state == null:
		return
	for m in ActiveRun.state.active_modifiers:
		match m.effect:
			ModifierDef.Effect.HP_PENALTY:
				player_max_health = maxi(1, int(player_max_health * (1.0 - m.magnitude)))
			ModifierDef.Effect.ATK_PENALTY:
				player_damage = maxi(1, int(player_damage * (1.0 - m.magnitude)))
			ModifierDef.Effect.GOLD_DEBT:
				player_gold = -int(m.magnitude)
			ModifierDef.Effect.BPM_PRESSURE:
				pass
			_:
				pass

func _modifier_bpm_bonus() -> float:
	if ActiveRun.state == null:
		return 0.0
	var bonus := 0.0
	for m in ActiveRun.state.active_modifiers:
		if m.effect == ModifierDef.Effect.BPM_PRESSURE:
			bonus += m.magnitude
	return bonus

## Start or swap into a combat encounter for the current room.
func begin_encounter(type_name: String) -> void:
	if not ENEMY_DATA.has(type_name):
		push_warning("GameManager.begin_encounter: unknown enemy %s" % type_name)
		type_name = "slime_girl"
	game_state = GameState.PLAYING
	_initialize_enemy(type_name)
	current_bpm = active_enemy.base_bpm + _modifier_bpm_bonus()
	process_turn = Turn.ENEMY
	generator_last_time = game_time
	generator_beats_count = 0
	generator_turn = Turn.ENEMY
	beat_times.clear()
	_fill_beat_buffer()
	emit_signal("player_stats_changed")
	emit_signal("enemy_hp_changed")

func _start():
	game_time           = 0.0
	generator_last_time = 0.0
	current_bpm         = active_enemy.base_bpm
	_fill_beat_buffer()

# ── Enemy Init ────────────────────────────────────────────────────────────────
# Resets all enemy state. Called both at boot and when continue_after_treasure
# transitions to a new enemy. Does NOT reset player stats.
func _initialize_enemy(type_name: String):
	active_enemy_type     = type_name
	active_enemy          = ENEMY_DATA[type_name]
	enemy_max_health      = active_enemy.max_health
	enemy_health          = enemy_max_health
	current_bpm           = active_enemy.base_bpm
	generator_turn        = Turn.ENEMY
	generator_beats_count = 0
	emit_signal("enemy_type_swapped", type_name)
	emit_signal("enemy_hp_changed")

# ── Beat Buffer ───────────────────────────────────────────────────────────────
# Keeps beat_times filled SCHEDULE_AHEAD seconds into the future.
# Each beat carries its turn_phase so _fire_beat knows when a turn flips.
# During non-PLAYING states beats_per_turn is set to 999 so the turn never
# flips — all beats are tagged with whatever generator_turn is currently set to.
func _fill_beat_buffer():
	var beats_per_turn = active_enemy.beats_in_turn if game_state == GameState.PLAYING else 999
	var interval       = 60.0 / current_bpm
	while generator_last_time < game_time + SCHEDULE_AHEAD:
		generator_last_time += interval
		beat_times.append({ "time": generator_last_time, "turn_phase": generator_turn })
		generator_beats_count += 1
		if game_state == GameState.PLAYING and generator_beats_count >= beats_per_turn:
			generator_beats_count = 0
			generator_turn = Turn.PLAYER if generator_turn == Turn.ENEMY else Turn.ENEMY

# ── Process ───────────────────────────────────────────────────────────────────
# game_time advances every frame regardless of state so timestamps stay valid.
# Beat firing and buffer filling are skipped during TREASURE to pause gameplay
# without freezing the clock (which would cause a beat backlog on resume).
func _process(delta: float):
	game_time += delta

	if game_state == GameState.TREASURE:
		return

	while beat_times.size() > 0 and game_time >= beat_times[0]["time"]:
		_fire_beat(beat_times.pop_front())

	# Guard: _on_enemy_defeated() can set state to TREASURE mid-loop above,
	# so re-check before filling — otherwise stale beats flood the buffer.
	if game_state != GameState.TREASURE:
		_fill_beat_buffer()

	if game_state == GameState.PUNISHMENT:
		punishment_countdown -= delta / PUNISHMENT_SECONDS_PER_COUNT
		emit_signal("punishment_tick", punishment_countdown)
		if punishment_countdown <= 0.0:
			_trigger_game_over()

func _fire_beat(beat: Dictionary):
	_total_beats_fired += 1

	# beat_sound is an AudioStreamPlayer injected from Main.gd.
	# Stop-then-play restarts the sample cleanly if it's still playing.
	if beat_sound:
		if beat_sound.playing:
			beat_sound.stop()
		beat_sound.play()

	# PUNISHMENT and SURVIVAL bypass normal turn logic entirely
	if game_state == GameState.PUNISHMENT:
		emit_signal("enemy_state_changed", "attack")
		emit_signal("new_beat", _total_beats_fired)
		return

	if game_state == GameState.SURVIVAL:
		emit_signal("enemy_state_changed", "attack")
		emit_signal("new_beat", _total_beats_fired)
		survival_beats_left -= 1
		emit_signal("survival_progress", survival_beats_left, SURVIVAL_BEATS_REQUIRED)
		if survival_beats_left <= 0:
			_on_survival_success()
		return

	# Normal PLAYING turn logic
	var incoming_turn = beat["turn_phase"]
	if incoming_turn != process_turn:
		_end_of_turn(process_turn)
		process_turn = incoming_turn

	emit_signal("enemy_state_changed", "attack" if process_turn == Turn.ENEMY else "idle")
	emit_signal("new_beat", _total_beats_fired)
	_maybe_say_dialogue()

# ── Dialogue ──────────────────────────────────────────────────────────────────
# Fires at most once every 6 beats. Situation is picked by health thresholds;
# "taunt" is a random fallback with a 35% chance. All very alpha — rework freely.
func _maybe_say_dialogue():
	if _total_beats_fired - _last_dialogue_beat < 6:
		return
	var situation = ""
	if float(player_health) / float(player_max_health) <= 0.20:
		situation = "player_near_death"
	elif float(enemy_health) / float(enemy_max_health) <= 0.20:
		situation = "near_win"
	elif randf() < 0.35:
		situation = "taunt"
	if situation != "":
		var line = active_enemy.get_line(situation)
		if line != "":
			_last_dialogue_beat = _total_beats_fired
			emit_signal("enemy_dialogue", line, situation)

# ── Turn Resolution ───────────────────────────────────────────────────────────
# Damage is applied at end-of-turn, not per-beat. This is intentional alpha
# simplification — no accuracy/miss system yet. Each full enemy turn deals
# flat damage; each full player turn deals flat player_damage to the enemy.
func _end_of_turn(turn_that_just_ended: int):
	if game_state != GameState.PLAYING:
		return
	if turn_that_just_ended == Turn.ENEMY:
		player_health = max(0, player_health - active_enemy.damage)
		emit_signal("player_stats_changed")
		emit_signal("enemy_state_changed", "idle")
		if player_health <= 0:
			_on_player_defeated()
	else:
		enemy_health = max(0, enemy_health - player_damage)
		emit_signal("enemy_state_changed", "hurt")
		emit_signal("enemy_hp_changed")
		if enemy_health <= 0:
			_on_enemy_defeated()

# ── Player Defeated ───────────────────────────────────────────────────────────
# HP hit 0 → enter SURVIVAL window. Player must tap 30 rapid beats to recover.
# Gold is NOT taken here. It's only taken if the player actively concedes via
# on_player_concedes(). If they survive they keep everything.
func _on_player_defeated():
	game_state            = GameState.SURVIVAL
	survival_beats_left   = SURVIVAL_BEATS_REQUIRED + MetaSave.survival_cushion
	current_bpm           = SURVIVAL_BPM
	beat_times.clear()
	generator_last_time   = game_time
	generator_beats_count = 0
	generator_turn        = Turn.PLAYER
	emit_signal("survival_progress", survival_beats_left, SURVIVAL_BEATS_REQUIRED)
	var line = active_enemy.get_line("player_defeated")
	if line != "":
		emit_signal("enemy_dialogue", line, "player_defeated")
	emit_signal("enter_survival", active_enemy_type)

func _on_survival_success():
	# Player tapped through the whole survival window — restore to 50% HP and resume.
	game_state    = GameState.PLAYING
	player_health = int(player_max_health * 0.5)
	emit_signal("player_stats_changed")
	current_bpm           = active_enemy.base_bpm
	beat_times.clear()
	generator_last_time   = game_time
	generator_beats_count = 0
	generator_turn        = Turn.ENEMY
	process_turn          = Turn.ENEMY
	emit_signal("enemy_dialogue", active_enemy.get_line("survive_loss"), "survive_loss")
	emit_signal("enemy_hp_changed")  # triggers enemy bar redraw after card reappears
	emit_signal("survival_success")

# ── Enemy Defeated ────────────────────────────────────────────────────────────
# Enemy HP hit 0 → award gold/XP, pause in TREASURE state.
# RoomManager decides what comes next; Main.gd calls continue_after_treasure()
# with the next enemy type when the player dismisses the treasure screen.
func _on_enemy_defeated():
	player_gold += active_enemy.gold
	# Run-only treasure bag (Phase 1) — banked on quest clear via ActiveRun.mark_cleared
	ActiveRun.add_run_gold(active_enemy.gold)
	player_xp   += active_enemy.xp
	# Keep MetaSave XP/level in sync for mid-run level-ups
	MetaSave.player_xp = player_xp
	MetaSave.player_level = player_level
	emit_signal("player_stats_changed")
	while player_xp >= xp_to_next_level():
		player_xp -= xp_to_next_level()
		_level_up()
	game_state = GameState.TREASURE
	beat_times.clear()
	emit_signal("enemy_defeated", active_enemy.gold)

# Called by Main.gd (via RoomManager) when the player hits Continue.
# next_enemy_type comes from the RoomManager's room definition.
func continue_after_treasure(next_enemy_type: String):
	if game_state != GameState.TREASURE:
		return
	_initialize_enemy(next_enemy_type)
	game_state            = GameState.PLAYING
	process_turn          = Turn.ENEMY
	generator_last_time   = game_time  # schedule from now, not from stale past
	generator_beats_count = 0
	generator_turn        = Turn.ENEMY

func _level_up():
	# Alpha levelling: flat percentage scaling. No cap, no diminishing returns yet.
	player_level      += 1
	player_max_health  = int(player_max_health * 1.25)
	player_damage      = int(player_damage     * 1.20)
	player_health      = player_max_health
	MetaSave.player_level = player_level
	MetaSave.player_xp = player_xp
	MetaSave.base_max_health = player_max_health
	MetaSave.base_damage = player_damage
	MetaSave.save_to_disk()
	emit_signal("player_stats_changed")

# ── Concede ───────────────────────────────────────────────────────────────────
# "I'm a Loser" button. Only callable during SURVIVAL.
# This is the only moment gold is stolen — player actively gave up.
func on_player_concedes():
	if game_state != GameState.SURVIVAL:
		return
	# Concede / climax: lose all quest treasure, drain meta via ActiveRun
	player_gold = 0
	ActiveRun.mark_conceded()
	emit_signal("player_stats_changed")
	game_state            = GameState.PUNISHMENT
	current_bpm           = PUNISHMENT_BPM
	punishment_countdown  = 10.0
	beat_times.clear()
	generator_last_time   = game_time
	generator_beats_count = 0
	generator_turn        = Turn.ENEMY
	emit_signal("enemy_dialogue", active_enemy.get_line("losing"), "losing")
	emit_signal("enter_punishment", active_enemy_type)

func _trigger_game_over():
	game_state = GameState.GAMEOVER
	set_process(false)
	emit_signal("enemy_dialogue", active_enemy.get_line("gameover_remarks"), "gameover_remarks")
	emit_signal("game_over", active_enemy_type)

# ── BeatBar Adapter ───────────────────────────────────────────────────────────
# BeatBar.gd calls this to get upcoming beat timestamps for drawing the approach track.
func get_next_beats(count: int) -> Array:
	var list = []
	for i in range(min(count, beat_times.size())):
		list.append(beat_times[i]["time"])
	return list
