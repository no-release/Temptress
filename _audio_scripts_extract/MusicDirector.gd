extends Node
# =============================================================================
# MusicDirector.gd — Phase 7 situation-based BGM (+ Phase 12 BPM map)
# =============================================================================
# Autoload. Call MusicDirector.play("combat") / stop() / play("") to silence.
# Swap tracks by editing TRACKS — one place for all situation music.
# AudioStreamMP3 has no BPM metadata; TRACK_BPM supplies song tempo for combat.
# =============================================================================

const TRACKS := {
	# combat = existing user MP3. Hub/home/menu from CC0 web packs.
	"combat": "res://audio/combat_theme.mp3",
	"town": "res://audio/music/town_theme.ogg",
	"home": "res://audio/music/home_theme.mp3",
	"menu": "res://audio/music/dungeon_theme.ogg",
	"dungeon": "res://audio/music/dungeon_theme.ogg",
	"survival": "res://audio/music/action_theme.ogg",
}

## Optional BPM per TRACKS key. Default combat theme ≈ 128.
const TRACK_BPM := {
	"combat": 128.0,
}

const DEFAULT_BPM := 128.0
const FADE_SEC := 0.6

var _player: AudioStreamPlayer = null
var _current: String = ""
var _fade_tween: Tween = null

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Master"
	add_child(_player)

## Play (or crossfade to) the track for a situation key. Unknown/empty = stop.
func play(situation: String) -> void:
	if situation == "" or not TRACKS.has(situation):
		stop()
		return
	if situation == _current and _player.playing:
		return
	var path: String = TRACKS[situation]
	var stream := load(path)
	if stream == null:
		push_warning("MusicDirector: missing track %s (%s)" % [situation, path])
		return
	_current = situation
	if stream is AudioStream:
		# Loop when the stream type supports it
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
	_fade_to(stream)

func stop() -> void:
	_current = ""
	if _player == null:
		return
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", -40.0, FADE_SEC)
	_fade_tween.tween_callback(func():
		_player.stop()
		_player.stream = null
		_player.volume_db = 0.0
	)

func _fade_to(stream: AudioStream) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	# Quick dip then swap, then rise — simple crossfade-ish without dual players
	_fade_tween = create_tween()
	if _player.playing:
		_fade_tween.tween_property(_player, "volume_db", -40.0, FADE_SEC * 0.5)
		_fade_tween.tween_callback(func():
			_player.stop()
			_player.stream = stream
			_player.volume_db = -40.0
			_player.play()
		)
		_fade_tween.tween_property(_player, "volume_db", 0.0, FADE_SEC * 0.5)
	else:
		_player.stream = stream
		_player.volume_db = -40.0
		_player.play()
		_fade_tween.tween_property(_player, "volume_db", 0.0, FADE_SEC)

func current_situation() -> String:
	return _current

## BPM for a situation key (or current track / combat default).
func get_track_bpm(situation: String = "") -> float:
	var key := situation if situation != "" else _current
	if key == "":
		key = "combat"
	if TRACK_BPM.has(key):
		return float(TRACK_BPM[key])
	return DEFAULT_BPM

func get_current_bpm() -> float:
	return get_track_bpm(_current if _current != "" else "combat")
