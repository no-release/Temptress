extends Node
# =============================================================================
# MusicDirector.gd — Phase 7 situation-based BGM
# =============================================================================
# Autoload. Call MusicDirector.play("combat") / stop() / play("") to silence.
# Swap tracks by editing TRACKS — one place for all situation music.
# =============================================================================

const TRACKS := {
	# Only combat wired for now (user MP3). Add town/menu/survival later.
	"combat": "res://audio/combat_theme.mp3",
}

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
