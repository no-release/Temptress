extends Node
# =============================================================================
# SoundGen.gd — ALPHA BUILD
# =============================================================================
# Procedurally synthesizes the beat-hit sound and UI click at runtime instead
# of loading audio files. This is an autoload (singleton).
#
# Main.gd calls SoundGen.create_beat_hit() once and reuses the resulting stream.
# Any button can call SoundGen.play_ui_click() for a short click feedback.
# Phase 9: play_hit() / play_hurt() for combat feedback.
# =============================================================================

var _ui_player: AudioStreamPlayer = null
var _hit_player: AudioStreamPlayer = null
var _hurt_player: AudioStreamPlayer = null

func create_beat_hit() -> AudioStreamWAV:
	var sample_rate = 44100
	var samples = int(sample_rate * 0.18)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / sample_rate
		var env = exp(-t / 0.05)
		# Punchy thud + bright click + mid tone, each with independent decay
		var wave = sin(TAU * 120.0 * t) * 0.5 * exp(-t / 0.08)
		wave += sin(TAU * 800.0 * t) * 0.3 * exp(-t / 0.015)
		wave += sin(TAU * 440.0 * t) * 0.2 * env
		wave = clamp(wave * 0.85, -1.0, 1.0)
		var s = int(wave * 32767)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	stream.data = data
	return stream

func create_ui_click() -> AudioStreamWAV:
	# Short, sharp UI click — bright and quick so it feels responsive
	var sample_rate = 44100
	var samples = int(sample_rate * 0.06)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / sample_rate
		var env = exp(-t / 0.012)
		var wave = sin(TAU * 1800.0 * t) * 0.55 * env
		wave += sin(TAU * 900.0 * t) * 0.25 * exp(-t / 0.02)
		wave = clamp(wave * 0.9, -1.0, 1.0)
		var s = int(wave * 32767)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	stream.data = data
	return stream

## Short punchy impact — enemy taking damage.
func create_hit() -> AudioStreamWAV:
	var sample_rate = 44100
	var samples = int(sample_rate * 0.12)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / sample_rate
		# Low thud + mid punch + brief noise-like high transient
		var wave = sin(TAU * 90.0 * t) * 0.55 * exp(-t / 0.045)
		wave += sin(TAU * 220.0 * t) * 0.35 * exp(-t / 0.025)
		wave += sin(TAU * 1400.0 * t) * 0.22 * exp(-t / 0.008)
		wave = clamp(wave * 0.95, -1.0, 1.0)
		var s = int(wave * 32767)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	stream.data = data
	return stream

## Softer hurt blip — player taking damage.
func create_hurt() -> AudioStreamWAV:
	var sample_rate = 44100
	var samples = int(sample_rate * 0.14)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / sample_rate
		# Descending soft tone + muted body
		var freq = 520.0 - 180.0 * min(1.0, t / 0.1)
		var wave = sin(TAU * freq * t) * 0.40 * exp(-t / 0.06)
		wave += sin(TAU * 160.0 * t) * 0.28 * exp(-t / 0.05)
		wave = clamp(wave * 0.85, -1.0, 1.0)
		var s = int(wave * 32767)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	stream.data = data
	return stream


const SFX := {
	"ui_click": "res://audio/sfx/ui_click.wav",
	"hit": "res://audio/sfx/hit.ogg",
	"hurt": "res://audio/sfx/hurt.ogg",
	"coins": "res://audio/sfx/coins.ogg",
	"swing": "res://audio/sfx/swing.wav",
	"spell": "res://audio/sfx/spell.ogg",
}

func _load_sfx(key: String) -> AudioStream:
	var path: String = SFX.get(key, "")
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	var stream = load(path)
	return stream if stream is AudioStream else null

func play_ui_click():
	if _ui_player == null:
		_ui_player = AudioStreamPlayer.new()
		_ui_player.name = "UIClickPlayer"
		add_child(_ui_player)
		var ui_stream := _load_sfx("ui_click")
		_ui_player.stream = ui_stream if ui_stream else create_ui_click()
		_ui_player.volume_db = -4.0
	if _ui_player.playing:
		_ui_player.stop()
	_ui_player.play()

func play_hit():
	if _hit_player == null:
		_hit_player = AudioStreamPlayer.new()
		_hit_player.name = "HitPlayer"
		add_child(_hit_player)
		var hit_stream := _load_sfx("hit")
		_hit_player.stream = hit_stream if hit_stream else create_hit()
		_hit_player.volume_db = -2.0
	if _hit_player.playing:
		_hit_player.stop()
	_hit_player.play()

func play_hurt():
	if _hurt_player == null:
		_hurt_player = AudioStreamPlayer.new()
		_hurt_player.name = "HurtPlayer"
		add_child(_hurt_player)
		var hurt_stream := _load_sfx("hurt")
		_hurt_player.stream = hurt_stream if hurt_stream else create_hurt()
		_hurt_player.volume_db = -5.0
	if _hurt_player.playing:
		_hurt_player.stop()
	_hurt_player.play()


func play_coins():
	var stream := _load_sfx("coins")
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = stream
	p.volume_db = -4.0
	p.finished.connect(p.queue_free)
	p.play()

func play_swing():
	var stream := _load_sfx("swing")
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = stream
	p.volume_db = -3.0
	p.finished.connect(p.queue_free)
	p.play()

func play_spell():
	var stream := _load_sfx("spell")
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = stream
	p.volume_db = -3.0
	p.finished.connect(p.queue_free)
	p.play()
