extends Control
# BeatBar.gd — smooth approach track (own CanvasLayer; never shaken)
# Notes glide from screen edges toward the center hit line every frame.

const LOOKAHEAD: float = 2.25
const TRACK_BOTTOM_MARGIN: float = 48.0
const TRACK_HEIGHT: float = 58.0

var game_manager: Node = null
var impact_alpha: float = 0.0
var impact_scale: float = 1.0

const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_ACCENT     = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_GHOST      = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_IMPACT     = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_TRACK_BG   = Color(0.0,  0.0,  0.0, 0.45)
const COLOR_TRACK_LINE = Color(1.0,  1.0,  1.0, 0.18)



func _ready() -> void:
	set_process(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_viewport()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_VISIBILITY_CHANGED:
		_fill_viewport()

func _fill_viewport() -> void:
	var vr := get_viewport().get_visible_rect().size
	if vr.x > 1.0 and vr.y > 1.0:
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		position = Vector2.ZERO
		size = vr

func on_beat() -> void:
	impact_alpha = 1.0
	impact_scale = 1.45

func _process(delta: float) -> void:
	# Keep covering the viewport even if Main stops assigning size
	if size.x < 8.0 or size.y < 8.0:
		_fill_viewport()
	impact_alpha = maxf(0.0, impact_alpha - delta * 4.5)
	impact_scale = lerpf(impact_scale, 1.0, delta * 12.0)
	queue_redraw()

func _draw() -> void:
	if game_manager == null:
		return
	var w: float = size.x
	var h: float = size.y
	if w < 8.0 or h < 8.0:
		var vr := get_viewport().get_visible_rect().size
		w = vr.x
		h = vr.y
		if w < 8.0 or h < 8.0:
			return
	var cx: float = w * 0.5
	var cy: float = h - TRACK_BOTTOM_MARGIN - (TRACK_HEIGHT * 0.5)
	var rect_top: float = h - TRACK_BOTTOM_MARGIN - TRACK_HEIGHT

	draw_rect(Rect2(0, rect_top, w, TRACK_HEIGHT), COLOR_TRACK_BG)
	draw_line(Vector2(0, rect_top), Vector2(w, rect_top), COLOR_TRACK_LINE, 1.5)
	draw_line(Vector2(0, rect_top + TRACK_HEIGHT), Vector2(w, rect_top + TRACK_HEIGHT), COLOR_TRACK_LINE, 1.5)
	draw_line(Vector2(0, cy), Vector2(w, cy), COLOR_TRACK_LINE, 1.0)
	draw_circle(Vector2(cx, cy), 6.0, Color(1, 1, 1, 0.4))
	draw_line(Vector2(cx, rect_top + 4.0), Vector2(cx, rect_top + TRACK_HEIGHT - 4.0), Color(1, 1, 1, 0.35), 2.0)

	var now: float = float(game_manager.game_time)
	var upcoming: Array = []
	if game_manager.has_method("get_next_beats"):
		var times: Array = game_manager.get_next_beats(20)
		var accents: Array = [1]
		if game_manager.has_meta("p12_pattern_accents"):
			accents = game_manager.get_meta("p12_pattern_accents")
		if accents.is_empty():
			accents = [1]
		for i in range(times.size()):
			upcoming.append({
				"time": float(times[i]),
				"accent": int(accents[i % accents.size()]),
			})

	# Always draw approach notes — do not drop accent 0 (that looked like a dead bar)
	for entry in upcoming:
		var bt: float = float(entry.get("time", 0.0))
		var accent: int = int(entry.get("accent", 1))
		var time_until: float = bt - now
		if time_until > LOOKAHEAD or time_until < -0.05:
			continue
		var clamped: float = clampf(time_until, 0.0, LOOKAHEAD)
		var ratio: float = clamped / LOOKAHEAD  # 1 = far (edges), 0 = hit (center)
		var proximity: float = 1.0 - ratio
		var lx: float = cx * (1.0 - ratio)
		var rx: float = cx + cx * ratio

		# Same size/color; alpha 0 at spawn (edges) → 1 at center.
		var beat_color: Color = Color(COLOR_BEAT.r, COLOR_BEAT.g, COLOR_BEAT.b, clampf(proximity, 0.0, 1.0))
		var radius: float = 8.0

		for bx in [lx, rx]:
			draw_circle(Vector2(bx, cy), radius, beat_color)

	if impact_alpha > 0.0:
		draw_circle(Vector2(cx, cy), 24.0 * impact_scale, Color(COLOR_IMPACT.r, COLOR_IMPACT.g, COLOR_IMPACT.b, impact_alpha * 0.55))
