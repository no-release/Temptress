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

	func _init(p_name, p_max_hp, p_dmg, p_beats, p_bpm, p_xp, p_gold, p_lines):
		name = p_name; max_health = p_max_hp; damage = p_dmg
		beats_in_turn = p_beats; base_bpm = p_bpm
		xp = p_xp; gold = p_gold; lines = p_lines

	func get_line(situation: String) -> String:
		var pool = lines.get(situation, [])
		return "" if pool.is_empty() else pool[randi() % pool.size()]

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
		"taunt":            ["Ooh, your rhythm is all sticky~", "Slippery beats for a slippery boy~", "Don't melt for me yet..."],
		"player_near_death":["You're dripping... almost done?", "One more and you'll be mine~", "Your hands are shaking so cute~"],
		"player_defeated":  ["Aww, you fell already? Keep tapping or I'll keep you~", "Down already? Prove you can still hold on~"],
		"near_win":         ["Nngh— you hit hard for a soft boy~", "That actually stung... interesting."],
		"survive_loss":     ["Tch. You held out. Fine, take the loot.", "You resisted a slime? Annoying..."],
		"losing":           ["You admit it? Good boy. Now feel the beat until you break.", "Gave up already? I'll make sure you remember this."],
		"gameover_remarks": ["Even a slime made you lose control~", "Come back when you can last longer, softie."],
	})
	ENEMY_DATA["goblin_girl"] = EnemyData.new("goblin_girl", 40, 8, 22, 135.0, 40, 15, {
		"taunt":            ["Hehe, too slow!", "Can't keep up, can ya?", "My grandma taps faster than that!"],
		"player_near_death":["One more and you're DONE!", "I can smell how close you are~", "Just give in already!"],
		"player_defeated":  ["Hah! Knocked you flat! Tap fast or you're finished!", "Down you go, loser~"],
		"near_win":         ["Ow ow... lucky hit!", "That tickled! (It didn't)"],
		"survive_loss":     ["Ugh, fine... take your stupid gold.", "You survived? Annoying little thing."],
		"losing":           ["You SAID you lost! Good. Now suffer the beat.", "Can't handle the rhythm? Pathetic~"],
		"gameover_remarks": ["Even a goblin girl broke you!", "That's how a goblin makes an adventurer beg."],
	})

	# ── Tier 2: mid ───────────────────────────────────────────────────────────
	ENEMY_DATA["succubus"] = EnemyData.new("succubus", 55, 11, 16, 125.0, 65, 25, {
		"taunt":            ["Feel that pulse? It's matching your heartbeat~", "I can already taste how desperate you are.", "Dance for me, little hero."],
		"player_near_death":["You're throbbing in time with me~", "So close... just let go.", "Your resolve is melting so prettily."],
		"player_defeated":  ["Fallen already? Keep the rhythm or I'll claim you fully~", "On your knees. Tap if you still can."],
		"near_win":         ["Mmm... you actually hurt me. How rude.", "That fire in you is delicious."],
		"survive_loss":     ["You held back from a succubus? Impressive... and frustrating.", "Fine. Leave with your prize. For now."],
		"losing":           ["You admitted defeat. Perfect. Now feel every beat until you break.", "Good boy. The guild will hear how easily you folded."],
		"gameover_remarks": ["Another soul who couldn't last~", "Come back when you're ready to serve properly."],
	})
	ENEMY_DATA["kitsune"] = EnemyData.new("kitsune", 65, 12, 14, 115.0, 80, 30, {
		"taunt":            ["Nine tails, one rhythm. Keep up~", "Your ears are turning red already.", "Foxes play with their food, you know."],
		"player_near_death":["You're trembling. Adorable.", "One more push and you'll be mine~", "The beat owns you now."],
		"player_defeated":  ["Collapsed so soon? Prove you can still resist.", "Down already? The tails are disappointed."],
		"near_win":         ["Oh? A scratch. How bold of you.", "You're stronger than you look... interesting."],
		"survive_loss":     ["You endured the fox. Rare. Take the loot and go.", "Hmph. You win this round."],
		"losing":           ["You gave in. Good. Now the beat will finish what I started.", "Admitted weakness already? The guild will love this report."],
		"gameover_remarks": ["Even a kitsune outlasted you~", "Next time, try not to fold so quickly."],
	})

	# ── Tier 3: strong / late ─────────────────────────────────────────────────
	ENEMY_DATA["troll_girl"] = EnemyData.new("troll_girl", 85, 15, 10, 90.0, 110, 40, {
		"taunt":            ["TROLL GIRL SMASH RHYTHM.", "You think you can keep up? I doubt it.", "Boom. Boom. Boom. Feel it."],
		"player_near_death":["ONE MORE. I FINISH THIS.", "Your hands shake. I can see it.", "Almost. I am patient."],
		"player_defeated":  ["You fall. Not surprised. Tap fast if you still can.", "Down already? One chance. Use it."],
		"near_win":         ["...Felt that.", "You are stronger than I thought."],
		"survive_loss":     ["Hmph. Fine. Leave now.", "You live. This time. I am disappointed."],
		"losing":           ["You admit weakness? Good. Now suffer the maximum drum.", "You said it. Prepare to break."],
		"gameover_remarks": ["Troll girl wins. Think about what you did.", "Even the slowest beat broke you."],
	})
	ENEMY_DATA["dragoness"] = EnemyData.new("dragoness", 110, 18, 8, 80.0, 150, 55, {
		"taunt":            ["A dragoness does not rush. The beat will claim you.", "Kneel to the rhythm, little treasure-hunter.", "Your heat rises with every pulse~"],
		"player_near_death":["You are burning. Good.", "One more and you belong to me.", "The fire in your body betrays you."],
		"player_defeated":  ["Fallen before a dragoness. Keep the beat or be claimed.", "On the ground already? Prove your will."],
		"near_win":         ["You dared strike a dragoness... bold.", "That heat of yours is interesting."],
		"survive_loss":     ["You endured me. Rare. Take your spoils and leave my domain.", "Hmph. You may go... for now."],
		"losing":           ["You surrendered. Perfect. The beat will finish you.", "The guild will know how quickly their hunter broke."],
		"gameover_remarks": ["A dragoness always collects what is hers.", "Return when you can last longer than a few measures."],
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
signal enemy_dialogue(text: String)
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
	player_gold = 0  # run bag starts empty; banked gold lives on MetaSave
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
			emit_signal("enemy_dialogue", line)

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
	survival_beats_left   = SURVIVAL_BEATS_REQUIRED
	current_bpm           = SURVIVAL_BPM
	beat_times.clear()
	generator_last_time   = game_time
	generator_beats_count = 0
	generator_turn        = Turn.PLAYER
	emit_signal("survival_progress", survival_beats_left, SURVIVAL_BEATS_REQUIRED)
	var line = active_enemy.get_line("player_defeated")
	if line != "":
		emit_signal("enemy_dialogue", line)
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
	emit_signal("enemy_dialogue", active_enemy.get_line("survive_loss"))
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
	emit_signal("enemy_dialogue", active_enemy.get_line("losing"))
	emit_signal("enter_punishment", active_enemy_type)

func _trigger_game_over():
	game_state = GameState.GAMEOVER
	set_process(false)
	emit_signal("enemy_dialogue", active_enemy.get_line("gameover_remarks"))
	emit_signal("game_over", active_enemy_type)

# ── BeatBar Adapter ───────────────────────────────────────────────────────────
# BeatBar.gd calls this to get upcoming beat timestamps for drawing the approach track.
func get_next_beats(count: int) -> Array:
	var list = []
	for i in range(min(count, beat_times.size())):
		list.append(beat_times[i]["time"])
	return list
