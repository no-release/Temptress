extends Control
# Side HP panel: flat top under status bar, diagonal slant at the BOTTOM toward center.
# Right side: set flip_side = true.

@export var flip_side: bool = false
@export var label_text: String = "PLAYER"
@export var bottom_cut_ratio: float = 0.14

var _ratio: float = 1.0
var _fill_color: Color = Color(0.802, 0.0, 0.499, 1.0)
var _track_color: Color = Color(0.02, 0.012, 0.031, 1.0)
var _edge_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Stay under TopHud
	z_index = 0
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
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
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

func _cut_h() -> float:
	return size.y * clampf(bottom_cut_ratio, 0.05, 0.4)

func _mirror(pts: PackedVector2Array) -> PackedVector2Array:
	if not flip_side:
		return pts
	var w := size.x
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(w - p.x, p.y))
	return out

## Left: flat top (0,0)-(w,0); bottom diagonal from inner (w,h-cut) to outer (0,h).
func _panel_poly() -> PackedVector2Array:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return PackedVector2Array()
	var cut := _cut_h()
	return _mirror(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(w, 0.0),
		Vector2(w, h - cut),
		Vector2(0.0, h),
	]))

func _fill_poly() -> PackedVector2Array:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0 or _ratio <= 0.001:
		return PackedVector2Array()
	var cut := _cut_h()
	var fill_top := h * (1.0 - _ratio)
	var bottom_inner_y := h - cut
	var pts: PackedVector2Array
	# Below bottom_inner_y the shape tapers: diagonal (w, h-cut)->(0,h)
	# x_inner along diagonal at y: from y=h-cut (x=w) to y=h (x=0)
	# x(y) = w * (h - y) / cut
	if fill_top >= bottom_inner_y:
		# Fill only in the tapered tip
		var x_at := 0.0 if cut <= 0.001 else w * ((h - fill_top) / cut)
		pts = PackedVector2Array([
			Vector2(0.0, fill_top),
			Vector2(x_at, fill_top),
			Vector2(0.0, h),
		])
	else:
		pts = PackedVector2Array([
			Vector2(0.0, fill_top),
			Vector2(w, fill_top),
			Vector2(w, bottom_inner_y),
			Vector2(0.0, h),
		])
	return _mirror(pts)

func _draw() -> void:
	var panel := _panel_poly()
	if panel.size() < 3:
		return
	draw_colored_polygon(panel, _track_color)
	var fill := _fill_poly()
	if fill.size() >= 3:
		draw_colored_polygon(fill, _fill_color)
	var outline := PackedVector2Array(panel)
	outline.append(panel[0])
	draw_polyline(outline, _edge_color, 3.0, true)

func _place_label() -> void:
	if _label == null:
		return
	_apply_label_text()
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return
	_label.rotation_degrees = 0.0
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.size = Vector2(maxi(16.0, w * 0.95), h * 0.45)
	_label.pivot_offset = Vector2(_label.size.x * 0.5, _label.size.y * 0.5)
	_label.position = Vector2((w - _label.size.x) * 0.5, h * 0.22)
