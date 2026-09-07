extends Control
# =============================================================================
# BeatBar.gd — ALPHA BUILD, visual only — TAP INPUT IS NOT YET WIRED UP
# =============================================================================
# Draws the rhythm approach track: two markers slide inward from the screen
# edges toward the center "impact" point as each beat approaches, plus a
# flash/splash effect when a beat actually fires.
#
# IMPORTANT — KNOWN GAP (read this before assuming taps work):
#   This script currently has NO input handling. There's no _input(),
#   _gui_input(), or _unhandled_input() anywhere in this file or the rest of
#   the project. on_beat() is only ever called by Main.gd in response to
#   GameManager's new_beat signal — i.e. it reacts to beats firing on a timer,
#   not to the player tapping anything.
#
#   Right now GameManager resolves turn damage automatically once enough
#   beats have elapsed (see GameManager._end_of_turn) — there's no actual
#   accuracy/hit-or-miss check tied to player input. Functionally the player
#   currently can't "miss" a beat because nothing is reading their taps.
#
#
# VISUAL LOGIC:
#   game_manager.get_next_beats(12) returns upcoming beat timestamps.
#   For each one within LOOKAHEAD seconds, two markers are drawn sliding
#   inward from the left/right edges toward the center track, converging
#   exactly when time_until reaches 0. on_beat() triggers a brief flash/scale
#   pulse at the center point, called every time GameManager fires a beat.
# =============================================================================

const LOOKAHEAD: float = 1.5
const TRACK_BOTTOM_MARGIN: float = 48.0
const TRACK_HEIGHT: float = 54.0

var game_manager: Node = null  # injected by Main.gd
var impact_alpha: float = 0.0
var impact_scale: float = 1.0

const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_BEAT_CLOSE = Color(0.4, 0.002, 0.634, 1.0)
const COLOR_IMPACT     = Color(0.752, 0.0, 0.606, 1.0)
const COLOR_TRACK_BG   = Color(0.0,  0.0,  0.0, 0.40)
const COLOR_TRACK_LINE = Color(1.0,  1.0,  1.0, 0.14)

func _ready():
	set_process(true)

# Called by Main.gd whenever GameManager fires a beat — purely visual flash.
func on_beat():
	impact_alpha = 1.0
	impact_scale = 1.5

func _process(delta: float):
	impact_alpha = max(0.0, impact_alpha - delta * 4.5)
	impact_scale = lerp(impact_scale, 1.0, delta * 12.0)
	queue_redraw()

func _draw():
	if not game_manager:
		return

	var w = size.x
	var h = size.y
	var cx = w / 2.0
	var cy = h - TRACK_BOTTOM_MARGIN - (TRACK_HEIGHT / 2.0)
	var rect_top = h - TRACK_BOTTOM_MARGIN - TRACK_HEIGHT

	# Track background + guide lines
	draw_rect(Rect2(0, rect_top, w, TRACK_HEIGHT), COLOR_TRACK_BG)
	draw_line(Vector2(0, rect_top), Vector2(w, rect_top), COLOR_TRACK_LINE, 1.5)
	draw_line(Vector2(0, rect_top + TRACK_HEIGHT), Vector2(w, rect_top + TRACK_HEIGHT), COLOR_TRACK_LINE, 1.5)
	draw_line(Vector2(0, cy), Vector2(w, cy), COLOR_TRACK_LINE, 1.0)

	var now = game_manager.game_time
	var upcoming = game_manager.get_next_beats(12)

	for bt in upcoming:
		var time_until = bt - now
		if time_until < 0.0 or time_until > LOOKAHEAD:
			continue

		var ratio     = time_until / LOOKAHEAD
		var proximity = 1.0 - ratio
		var lx = cx * (1.0 - ratio)
		var rx = cx + cx * ratio

		var beat_color = COLOR_BEAT.lerp(COLOR_BEAT_CLOSE, pow(proximity, 2.0))
		var radius = lerp(7.0, 16.0, pow(proximity, 0.5))

		for bx in [lx, rx]:
			draw_circle(Vector2(bx, cy), radius + 9.0, Color(beat_color.r, beat_color.g, beat_color.b, proximity * 0.15))
			draw_circle(Vector2(bx, cy), radius, beat_color)

	# Center impact flash, triggered by on_beat()
	if impact_alpha > 0.0:
		draw_circle(Vector2(cx, cy), 22.0 * impact_scale, Color(COLOR_IMPACT.r, COLOR_IMPACT.g, COLOR_IMPACT.b, impact_alpha * 0.6))
