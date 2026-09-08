from pathlib import Path
import sys
sys.stdout.reconfigure(encoding="utf-8")

proj = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11")
ms = (proj / "scenes" / "Main.tscn").read_text(encoding="utf-8")
for line in ms.splitlines():
    if "10_sidehp" in line or "SideHpRail" in line:
        print(line)

# Check for CR in Main.gd
raw = (proj / "scripts" / "Main.gd").read_bytes()
print("Main.gd CR count", raw.count(b"\r"))
print("SideHpRail CR count", (proj / "scripts" / "SideHpRail.gd").read_bytes().count(b"\r"))

# Rewrite SideHpRail with cleaner draw + stacked vertical letters
rail = r'''extends Control
# Simple edge HP rail along blue guide: outer stub → short diagonal in → long vertical.
# Right rail: set flip_side = true.

@export var flip_side: bool = false
@export var rail_width: float = 16.0
@export var label_text: String = "PLAYER"

var _ratio: float = 1.0
var _fill_color: Color = Color(0.85, 0.85, 0.85, 0.95)
var _track_color: Color = Color(0.04, 0.03, 0.05, 0.92)
var _edge_color: Color = Color(0.78, 0.1, 0.16, 1.0)
var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_label()
	queue_redraw()

func _ensure_label() -> void:
	_label = get_node_or_null("NameLabel") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "NameLabel"
		add_child(_label)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.rotation_degrees = 0.0
	_apply_label_text()
	_place_label()

func _stacked(text: String) -> String:
	var chars: PackedStringArray = []
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		if ch != " ":
			chars.append(ch)
	return "\n".join(chars)

func _apply_label_text() -> void:
	if _label:
		_label.text = _stacked(label_text.to_upper())

func set_label(text: String) -> void:
	label_text = text.to_upper()
	_apply_label_text()
	_place_label()

func set_hp(ratio: float, fill_color: Color = Color(-1, -1, -1, -1)) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	if fill_color.a >= 0.0:
		_fill_color = fill_color
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_place_label()
		queue_redraw()

func _path_points() -> PackedVector2Array:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return PackedVector2Array()
	# Cyan guide: near outer edge, small ~45° inward notch near top, then long vertical.
	var margin := 6.0
	var outer_x := margin + rail_width * 0.5
	var kink_depth := mini(w * 0.55, 36.0)
	var inner_x := outer_x + kink_depth
	var y0 := 4.0
	var y1 := h * 0.10
	var y2 := h * 0.18
	var y3 := h - 6.0
	var pts := PackedVector2Array([
		Vector2(outer_x, y0),
		Vector2(outer_x, y1),
		Vector2(inner_x, y2),
		Vector2(inner_x, y3),
	])
	if flip_side:
		for i in range(pts.size()):
			pts[i] = Vector2(w - pts[i].x, pts[i].y)
	return pts

func _polyline_length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total

func _point_along(pts: PackedVector2Array, dist: float) -> Vector2:
	var left := dist
	for i in range(pts.size() - 1):
		var seg := pts[i].distance_to(pts[i + 1])
		if left <= seg or i == pts.size() - 2:
			var t := 0.0 if seg <= 0.0 else clampf(left / seg, 0.0, 1.0)
			return pts[i].lerp(pts[i + 1], t)
		left -= seg
	return pts[pts.size() - 1]

func _build_strip(pts: PackedVector2Array, half_w: float) -> PackedVector2Array:
	if pts.size() < 2:
		return PackedVector2Array()
	var lefts: Array[Vector2] = []
	var rights: Array[Vector2] = []
	for i in range(pts.size()):
		var tangent: Vector2
		if i == 0:
			tangent = (pts[1] - pts[0]).normalized()
		elif i == pts.size() - 1:
			tangent = (pts[i] - pts[i - 1]).normalized()
		else:
			var a := (pts[i] - pts[i - 1]).normalized()
			var b := (pts[i + 1] - pts[i]).normalized()
			tangent = (a + b).normalized()
			if tangent.length_squared() < 0.01:
				tangent = a
		var n := Vector2(-tangent.y, tangent.x) * half_w
		lefts.append(pts[i] + n)
		rights.append(pts[i] - n)
	var poly := PackedVector2Array()
	for p in lefts:
		poly.append(p)
	for i in range(rights.size() - 1, -1, -1):
		poly.append(rights[i])
	return poly

func _draw() -> void:
	var pts := _path_points()
	if pts.size() < 2:
		return
	var half := rail_width * 0.5
	# Dark track
	var track := _build_strip(pts, half)
	if track.size() >= 3:
		draw_colored_polygon(track, _track_color)
	# Fill from bottom along path
	var total := _polyline_length(pts)
	var fill_len := total * _ratio
	if fill_len > 0.5:
		var start_dist := total - fill_len
		var fill_pts := PackedVector2Array()
		var steps := maxi(10, int(fill_len / 4.0))
		for s in range(steps + 1):
			var d := start_dist + fill_len * (float(s) / float(steps))
			fill_pts.append(_point_along(pts, d))
		var fill_poly := _build_strip(fill_pts, half * 0.78)
		if fill_poly.size() >= 3:
			draw_colored_polygon(fill_poly, _fill_color)
	# Red outline along the guide path
	draw_polyline(pts, _edge_color, 2.8, true)

func _place_label() -> void:
	if _label == null:
		return
	_apply_label_text()
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return
	var outer_x := 6.0 + rail_width * 0.5
	var kink_depth := mini(w * 0.55, 36.0)
	var lx := outer_x + kink_depth
	if flip_side:
		lx = w - lx
	_label.rotation_degrees = 0.0
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.size = Vector2(rail_width + 10.0, h * 0.42)
	_label.pivot_offset = Vector2(_label.size.x * 0.5, _label.size.y * 0.5)
	_label.position = Vector2(lx - _label.size.x * 0.5, h * 0.38)
'''

# Keep arrow as ascii comment to avoid encoding issues - replace unicode arrow
rail = rail.replace("→", "->")
(proj / "scripts" / "SideHpRail.gd").write_text(rail.replace("\r\n", "\n"), encoding="utf-8")
print("SideHpRail rewritten stacked labels")

# Quick syntax-ish check Main.gd has helper and calls
mg = (proj / "scripts" / "Main.gd").read_text(encoding="utf-8")
for needle in ["_side_enemy_label", 'set_label("PLAYER")', "set_hp", "_apply_vertical_fill", "player_side_fill"]:
    print(needle, mg.count(needle))