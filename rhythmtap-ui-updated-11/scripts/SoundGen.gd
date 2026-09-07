extends Node
# =============================================================================
# SoundGen.gd — ALPHA BUILD
# =============================================================================
# Procedurally synthesizes the beat-hit sound and UI click at runtime instead
# of loading audio files. This is an autoload (singleton).
#
# Main.gd calls SoundGen.create_beat_hit() once and reuses the resulting stream.
# Any button can call SoundGen.play_ui_click() for a short click feedback.
# =============================================================================

var _ui_player: AudioStreamPlayer = null

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

func play_ui_click():
	if _ui_player == null:
		_ui_player = AudioStreamPlayer.new()
		_ui_player.name = "UIClickPlayer"
		add_child(_ui_player)
		_ui_player.stream = create_ui_click()
		_ui_player.volume_db = -4.0
	if _ui_player.playing:
		_ui_player.stop()
	_ui_player.play()
