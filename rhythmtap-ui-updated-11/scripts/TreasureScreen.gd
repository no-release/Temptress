extends PanelContainer
# Treasure rest: defeated sprite + 8s emptying bar, then auto-advance.

signal finished

const REST_SEC := 8.0
const FOLDER := {
	"troll_girl": "troll",
}

@onready var sprite: TextureRect = $Root/DefeatedSprite
@onready var title_label: Label = $Root/UIColumn/TitleLabel
@onready var subtitle_label: Label = $Root/UIColumn/SubtitleLabel
@onready var loot_list: VBoxContainer = $Root/UIColumn/LootList
@onready var rest_label: Label = $Root/UIColumn/RestRow/RestLabel
@onready var bar_fill: ColorRect = $Root/UIColumn/TimerBar/Fill
@onready var bar_bg: ColorRect = $Root/UIColumn/TimerBar
@onready var continue_button: Button = $Root/UIColumn/ContinueButton

var _left: float = 0.0
var _running: bool = false
var _bar_full_w: float = 280.0

func _ready() -> void:
	visible = false
	if continue_button and not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
	_ensure_text_plate()
	set_process(true)


func _ensure_text_plate() -> void:
	var col := get_node_or_null("Root/UIColumn")
	if col == null or col.get_node_or_null("TextPlate") != null:
		return
	var plate := ColorRect.new()
	plate.name = "TextPlate"
	plate.color = Color(0.04, 0.03, 0.06, 0.55)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	plate.offset_left = -16
	plate.offset_top = -12
	plate.offset_right = 16
	plate.offset_bottom = 12
	col.add_child(plate)
	col.move_child(plate, 0)


func present(enemy_id: String, gold_reward: int, bag_gold: int) -> void:
	_load_sprite(enemy_id)
	_fill_loot(gold_reward, bag_gold)
	var pretty := enemy_id.replace("_", " ").capitalize()
	if title_label:
		title_label.text = "- TREASURE -"
	if subtitle_label:
		subtitle_label.text = "%s is down. Catch your breath." % pretty
	_left = REST_SEC
	_running = true
	visible = true
	modulate = Color(1, 1, 1, 1)
	call_deferred("_sync_bar_width")


func _sync_bar_width() -> void:
	if bar_bg:
		_bar_full_w = maxf(120.0, bar_bg.size.x)
	_update_bar()


func _process(delta: float) -> void:
	if not _running:
		return
	_left = maxf(0.0, _left - delta)
	_update_bar()
	if _left <= 0.0:
		_finish()


func _update_bar() -> void:
	var t := clampf(_left / REST_SEC, 0.0, 1.0)
	if rest_label:
		rest_label.text = "REST  %.1fs" % _left
	if bar_fill:
		bar_fill.size.x = _bar_full_w * t
		bar_fill.color = Color(1.0, 0.72, 0.88, 0.95).lerp(Color(1.0, 0.35, 0.45, 0.95), 1.0 - t)


func _fill_loot(gold_reward: int, bag_gold: int) -> void:
	if loot_list == null:
		return
	for child in loot_list.get_children():
		child.queue_free()
	var row := Label.new()
	row.text = "+%d Gold" % gold_reward
	row.add_theme_font_size_override("font_size", 22)
	row.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1))
	loot_list.add_child(row)
	var bag := Label.new()
	bag.text = "Quest bag: %d Gold" % bag_gold
	bag.add_theme_font_size_override("font_size", 16)
	bag.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	loot_list.add_child(bag)


func _load_sprite(enemy_id: String) -> void:
	var folder := str(FOLDER.get(enemy_id, enemy_id))
	var path := "res://enemy_images/%s/defeated.png" % folder
	if not ResourceLoader.exists(path):
		path = "res://enemy_images/%s/hurt.png" % folder
	if not ResourceLoader.exists(path):
		path = "res://enemy_images/%s/idle.png" % folder
	if sprite:
		sprite.texture = load(path) if ResourceLoader.exists(path) else null
		sprite.visible = sprite.texture != null


func _on_continue_pressed() -> void:
	_finish()


func _finish() -> void:
	if not _running and not visible:
		return
	_running = false
	visible = false
	finished.emit()
