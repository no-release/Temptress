extends PanelContainer
class_name CombatSubtitle
# Bottom subtitle plate. Can play a queued first-meet / receptionist sequence.

const HOLD_SEC := 3.6
const FADE_IN_SEC := 0.12
const FADE_OUT_SEC := 0.45
const PAGE_FADE_SEC := 0.18
const PLATE_WIDTH := 640.0
const LINE_H := 26.0
const PAD_Y := 16.0
const BOTTOM_GAP_COMBAT := 128.0
const BOTTOM_GAP_SURVIVAL := 248.0
const BOTTOM_GAP_DRAIN := 360.0
const BOTTOM_GAP_HUB := 88.0
const FIRST_MEET_LINGER := 2.85

signal sequence_finished

@onready var speaker_label: Label = $Margin/VBox/Speaker
@onready var body: RichTextLabel = $Margin/VBox/Body

var _hold_left: float = 0.0
var _cps: float = 40.0
var _typed: float = 0.0
var _target_chars: int = 0
var _active: bool = false
var _bottom_gap: float = BOTTOM_GAP_COMBAT
var _lane: String = "combat"
var _queue: Array = []
var _playing_sequence: bool = false
var _page_linger: float = FIRST_MEET_LINGER
var _turning_page: bool = false

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(PLATE_WIDTH, LINE_H + PAD_Y)
	size.x = PLATE_WIDTH
	_pin_bottom(LINE_H + PAD_Y)
	if speaker_label:
		speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if body:
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.bbcode_enabled = true
		body.scroll_active = false
		body.fit_content = true
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(PLATE_WIDTH - 36.0, LINE_H)

func is_playing_sequence() -> bool:
	return _playing_sequence

func set_lane(lane: String) -> void:
	_lane = lane
	match lane:
		"survival":
			_bottom_gap = BOTTOM_GAP_SURVIVAL
		"drain", "punishment":
			_bottom_gap = BOTTOM_GAP_DRAIN
		"hub", "receptionist":
			_bottom_gap = BOTTOM_GAP_HUB
		_:
			_bottom_gap = BOTTOM_GAP_COMBAT
	if visible:
		_fit_height()

func play_sequence(pages: PackedStringArray, situation: String = "first_meet", linger: float = FIRST_MEET_LINGER) -> void:
	_queue.clear()
	for page in pages:
		var text := String(page).strip_edges()
		if text == "":
			continue
		_queue.append({"text": text, "situation": situation})
	_page_linger = linger
	_playing_sequence = true
	_turning_page = false
	if _queue.is_empty():
		_playing_sequence = false
		sequence_finished.emit()
		return
	_advance_queue()

func show_line(text: String, situation: String = "") -> void:
	if text.strip_edges() == "":
		return
	if _playing_sequence and situation not in ["first_meet", "receptionist", "notice"]:
		_queue.append({"text": text, "situation": situation})
		return
	var parsed: Dictionary = SubtitleMarkup.expand(text, situation)
	_cps = float(parsed.get("cps", 40.0))
	var speaker := str(parsed.get("speaker", ""))
	if speaker_label:
		speaker_label.visible = speaker != ""
		speaker_label.text = speaker.to_upper()
	if body:
		body.text = str(parsed.get("bbcode", text))
		body.visible_characters = 0
	_target_chars = _visible_length()
	_typed = 0.0
	if _playing_sequence:
		_hold_left = _page_linger
	elif situation in ["drain", "losing", "gameover_remarks"]:
		set_lane("drain")
		_hold_left = HOLD_SEC + 2.4
	elif situation in ["player_defeated"]:
		set_lane("survival")
		_hold_left = HOLD_SEC
	else:
		_hold_left = HOLD_SEC
	_active = true
	_turning_page = false
	visible = true
	modulate.a = 0.0
	_fit_height()
	call_deferred("_fit_height")

func show_plain(text: String) -> void:
	show_line(text, "notice")

func hide_now() -> void:
	_active = false
	_hold_left = 0.0
	_turning_page = false
	visible = false
	modulate.a = 0.0

func _advance_queue() -> void:
	if _queue.is_empty():
		_playing_sequence = false
		_turning_page = false
		sequence_finished.emit()
		return
	var item: Dictionary = _queue.pop_front()
	show_line(str(item.get("text", "")), str(item.get("situation", "")))

func _process(delta: float) -> void:
	if not _active:
		return
	if _typed < float(_target_chars):
		_typed += _cps * delta
		if body:
			body.visible_characters = mini(_target_chars, int(_typed))
		modulate.a = minf(1.0, modulate.a + delta / FADE_IN_SEC)
		return
	if body:
		body.visible_characters = -1
	_hold_left -= delta
	if _hold_left > 0.0:
		modulate.a = minf(1.0, modulate.a + delta / FADE_IN_SEC)
		return
	var fade := PAGE_FADE_SEC if (_playing_sequence and not _queue.is_empty()) else FADE_OUT_SEC
	modulate.a = maxf(0.0, modulate.a - delta / fade)
	if modulate.a > 0.01:
		return
	if _playing_sequence:
		_advance_queue()
	else:
		hide_now()

func _fit_height() -> void:
	size.x = PLATE_WIDTH
	custom_minimum_size.x = PLATE_WIDTH
	var text_h := LINE_H
	if body:
		var content_h := float(body.get_content_height())
		if content_h < 1.0:
			content_h = LINE_H
		text_h = maxf(LINE_H, content_h)
		body.custom_minimum_size = Vector2(PLATE_WIDTH - 36.0, text_h)
	var speaker_h := 0.0
	if speaker_label and speaker_label.visible:
		speaker_h = 16.0
	var h := text_h + speaker_h + PAD_Y
	custom_minimum_size = Vector2(PLATE_WIDTH, h)
	size = Vector2(PLATE_WIDTH, h)
	_pin_bottom(h)

func _pin_bottom(h: float) -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -PLATE_WIDTH * 0.5
	offset_right = PLATE_WIDTH * 0.5
	offset_bottom = -_bottom_gap
	offset_top = -_bottom_gap - h

func _visible_length() -> int:
	if body == null:
		return 0
	return body.get_parsed_text().length()
