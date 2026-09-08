extends Control
# BeatBar.gd — Phase 12 pattern accents (tap accuracy still stubbed)

const LOOKAHEAD: float = 1.5
const TRACK_BOTTOM_MARGIN: float = 48.0
const TRACK_HEIGHT: float = 54.0

var game_manager: Node = null
var impact_alpha: float = 0.0
var impact_scale: float = 1.0

const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_BEAT_CLOSE = Color(0.4, 0.002, 0.634, 1.0)
const COLOR_ACCENT     = Color(1.0, 0.85, 0.35, 1.0)
const COLOR_GHOST      = Color(0.55, 0.45, 0.75, 0.55)
const COLOR_IMPACT     = Color(0.752, 0.0, 0.606, 1.0)
const COLOR_TRACK_BG   = Color(0.0,  0.0,  0.0, 0.40)
const COLOR_TRACK_LINE = Color(1.0,  1.0,  1.0, 0.14)

func _ready():
	set_process(true)

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
	draw_rect(Rect2(0, rect_top, w, TRACK_HEIGHT), COLOR_TRACK_BG)
	draw_line(Vector2(0, rect_top), Vector2(w, rect_top), COLOR_TRACK_LINE, 1.5)
	draw_line(Vector2(0, rect_top + TRACK_HEIGHT), Vector2(w, rect_top + TRACK_HEIGHT), COLOR_TRACK_LINE, 1.5)
	draw_line(Vector2(0, cy), Vector2(w, cy), COLOR_TRACK_LINE, 1.0)
	var now = game_manager.game_time
	var upcoming: Array = []
	if game_manager.has_method("get_next_beat_entries"):
		upcoming = game_manager.get_next_beat_entries(12)
	else:
		var accents = game_manager.get_meta("p12_pattern_accents", [1]) if game_manager.has_meta("p12_pattern_accents") else [1]
		var times = game_manager.get_next_beats(12)
		for i in range(times.size()):
			var acc := 1
			if accents.size() > 0:
				acc = int(accents[i % accents.size()])
			upcoming.append({"time": times[i], "accent": acc})
	var style := 0
	if "pattern_style" in game_manager:
		style = int(game_manager.pattern_style)
	elif game_manager.has_meta("p12_pattern_style"):
		style = int(game_manager.get_meta("p12_pattern_style"))
	for entry in upcoming:
		var bt: float = float(entry.get("time", 0.0))
		var accent: int = int(entry.get("accent", 1))
		var time_until = bt - now
		if time_until < 0.0 or time_until > LOOKAHEAD:
			continue
		if accent <= 0 and style < 1:
			continue
		var ratio     = time_until / LOOKAHEAD
		var proximity = 1.0 - ratio
		var lx = cx * (1.0 - ratio)
		var rx = cx + cx * ratio
		var beat_color: Color
		if accent >= 2:
			beat_color = COLOR_ACCENT.lerp(COLOR_BEAT_CLOSE, pow(proximity, 2.0))
		elif accent <= 0:
			beat_color = COLOR_GHOST.lerp(COLOR_BEAT_CLOSE, pow(proximity, 2.0) * 0.5)
		else:
			beat_color = COLOR_BEAT.lerp(COLOR_BEAT_CLOSE, pow(proximity, 2.0))
		var radius_base := 7.0
		if accent >= 2:
			radius_base = 10.0
		elif accent <= 0:
			radius_base = 4.5
		if style >= 2 and accent == 1:
			radius_base = 6.0
		var radius = lerp(radius_base, radius_base + 9.0, pow(proximity, 0.5))
		for bx in [lx, rx]:
			draw_circle(Vector2(bx, cy), radius + 9.0, Color(beat_color.r, beat_color.g, beat_color.b, proximity * 0.15))
			draw_circle(Vector2(bx, cy), radius, beat_color)
			if accent >= 2:
				var tick :float= 3.0 + proximity * 4.0
				draw_line(Vector2(bx, cy - tick - 6.0), Vector2(bx, cy - tick), beat_color, 2.0)
	if impact_alpha > 0.0:
		draw_circle(Vector2(cx, cy), 22.0 * impact_scale, Color(COLOR_IMPACT.r, COLOR_IMPACT.g, COLOR_IMPACT.b, impact_alpha * 0.6))
