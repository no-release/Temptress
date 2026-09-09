extends Node
# Phase 12: patterns/BPM/rematch/level-drain via GameManager hooks (autoload)

const TIER1 := ["slime_girl", "goblin_girl"]
const TIER2 := ["succubus", "kitsune"]

const LEVEL_DRAIN := {
	"slime_girl": ["[drain]Feel that? I'm melting a whole level out of you~[/drain]", "[drip]Drip… drip…[/drip] [drain]there goes a level.[/drain]"],
	"goblin_girl": ["[laugh]Hehe! Level drained![/laugh] That's what you get for giving in!", "[giggle]Poof — one level gone. Goblin tax~[/giggle]"],
	"succubus": ["[moan]Mmm… I just sipped a level from you.[/moan] Delicious.", "[drain]Your growth thins as you break. One level, mine~[/drain]"],
	"kitsune": ["[purr]A fox takes what you offer.[/purr] [drain]One level, plucked.[/drain]", "[tease]Gave in? Then forfeit a level. Fair play~[/tease]"],
	"troll_girl": ["[shout]YOU GIVE UP. I TAKE LEVEL.[/shout]", "[growl]Level gone. Weakness has a price.[/growl]"],
	"dragoness": ["[queen]A dragoness claims tribute[/queen] — [drain]one level from your path.[/drain]", "[drain]Surrender feeds the hoard. Your level thins.[/drain]"],
}

var _hooked: Dictionary = {}

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_scan")

func _scan() -> void:
	var root := get_tree().current_scene
	if root:
		_walk(root)

func _walk(n: Node) -> void:
	_try_hook(n)
	for c in n.get_children():
		_walk(c)

func _on_node_added(n: Node) -> void:
	_try_hook(n)

func _try_hook(n: Node) -> void:
	if n == null or not n.has_method("begin_encounter"):
		return
	var id := n.get_instance_id()
	if _hooked.has(id):
		return
	_hooked[id] = true
	if n.has_signal("enemy_type_swapped"):
		n.enemy_type_swapped.connect(func(t): _on_swapped(t, n))
	if n.has_signal("enemy_defeated"):
		n.enemy_defeated.connect(func(g): _on_won(g, n))
	if n.has_signal("enter_punishment"):
		n.enter_punishment.connect(func(e): _on_lost(e, n))

func _tier(t: String) -> int:
	if t in TIER1:
		return 1
	if t in TIER2:
		return 2
	return 3

func _on_swapped(type_name: String, gm: Node) -> void:
	var tier := _tier(type_name)
	var intensity := 0.90 if tier == 1 else (1.05 if tier == 2 else 1.22)
	var style := 0 if tier == 1 else (1 if tier == 2 else 2)
	var accents: Array = [2, 0, 1, 0] if tier == 1 else ([2, 1, 1, 0] if tier == 2 else [2, 1, 2, 1])
	gm.set_meta("p12_pattern_intensity", intensity)
	gm.set_meta("p12_pattern_style", style)
	gm.set_meta("p12_pattern_accents", accents)
	if "pattern_intensity" in gm:
		gm.pattern_intensity = intensity
	if "pattern_style" in gm:
		gm.pattern_style = style
	if "pattern_accents" in gm:
		gm.pattern_accents = accents
	if gm.get("active_enemy") != null:
		var base: int = int(gm.active_enemy.beats_in_turn)
		if "beats_in_turn_base" in gm.active_enemy:
			base = int(gm.active_enemy.beats_in_turn_base)
		var eff: int = maxi(4, int(round(float(base) / intensity)))
		gm.active_enemy.beats_in_turn = eff
		gm.set_meta("p12_effective_beats", eff)
		if "effective_beats_in_turn" in gm:
			gm.effective_beats_in_turn = eff
	var song_bpm := 128.0
	if MusicDirector and MusicDirector.has_method("get_current_bpm"):
		song_bpm = float(MusicDirector.get_current_bpm())
	var bonus := 0.0
	if gm.has_method("_modifier_bpm_bonus"):
		bonus = float(gm.call("_modifier_bpm_bonus"))
	gm.current_bpm = song_bpm * intensity + bonus
	if not MetaSave.has_met_enemy(type_name):
		return
	var last := ""
	if MetaSave.has_method("get_enemy_last_result"):
		last = str(MetaSave.get_enemy_last_result(type_name))
	if last != "won" and last != "lost":
		return
	var line := EncounterLines.rematch_greeting(type_name, last)
	if line != "":
		gm.emit_signal("enemy_dialogue", line, "rematch")

func _on_won(_gold: int, gm: Node) -> void:
	if MetaSave.has_method("set_enemy_last_result"):
		MetaSave.set_enemy_last_result(str(gm.active_enemy_type), "won")

func _on_lost(_enemy: String, gm: Node) -> void:
	if MetaSave.has_method("set_enemy_last_result"):
		MetaSave.set_enemy_last_result(str(gm.active_enemy_type), "lost")
	var old_lv := int(gm.player_level)
	gm.player_level = MetaSave.player_level
	gm.player_xp = MetaSave.player_xp
	gm.player_max_health = MetaSave.base_max_health
	gm.player_damage = MetaSave.base_damage
	var new_lv := int(gm.player_level)
	var flavor := EncounterLines.level_drain_line(str(gm.active_enemy_type))
	if flavor == "":
		flavor = "She drains a level from you as you give in..."
	if gm.has_signal("level_drained"):
		gm.emit_signal("level_drained", old_lv, new_lv, flavor)
	var lose := ""
	if gm.active_enemy and gm.active_enemy.has_method("get_line"):
		lose = str(gm.active_enemy.get_line("losing"))
	var msg := flavor if lose == "" else "%s\n%s" % [flavor, lose]
	gm.emit_signal("enemy_dialogue", msg, "drain")
	gm.emit_signal("player_stats_changed")
