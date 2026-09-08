extends Node
# Phase 12: survival clarity UI + stub icon hide + level-drain banner (autoload)
# Hooks Main scene without requiring Main.gd edits.

var _survival_hint: Label = null
var _drain_banner: RichTextLabel = null
var _hooked_main: Node = null

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_scan")

func _scan() -> void:
	var root := get_tree().current_scene
	if root:
		_try_hook(root)
		for c in root.get_children():
			_try_hook(c)

func _on_node_added(n: Node) -> void:
	_try_hook(n)

func _try_hook(n: Node) -> void:
	if n == null or _hooked_main != null:
		return
	var gm := n.get_node_or_null("GameManager")
	var ui := n.get_node_or_null("UI")
	if gm == null or ui == null:
		return
	_hooked_main = n
	_hide_icons(n)
	_ensure_hint(ui)
	_ensure_drain_banner(ui)
	if not gm.enter_survival.is_connected(_on_enter_survival):
		gm.enter_survival.connect(_on_enter_survival)
	if not gm.survival_success.is_connected(_on_survival_success):
		gm.survival_success.connect(_on_survival_success)
	if not gm.enter_punishment.is_connected(_on_enter_punishment):
		gm.enter_punishment.connect(_on_enter_punishment)
	if gm.has_signal("level_drained") and not gm.level_drained.is_connected(_on_level_drained):
		gm.level_drained.connect(_on_level_drained)
	var loser := n.get_node_or_null("UI/LoserButton")
	if loser and loser is BaseButton and not loser.pressed.is_connected(_on_loser):
		loser.pressed.connect(_on_loser)

func _hide_icons(main: Node) -> void:
	var icons := main.get_node_or_null("UI/TopHud/MarginContainer/HBoxContainer/Icons")
	if icons:
		icons.visible = false

func _ensure_hint(ui: Node) -> void:
	_survival_hint = ui.get_node_or_null("SurvivalHint") as Label
	if _survival_hint:
		_survival_hint.visible = false
		return
	_survival_hint = Label.new()
	_survival_hint.name = "SurvivalHint"
	_survival_hint.visible = false
	_survival_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_survival_hint.anchor_left = 0.5
	_survival_hint.anchor_right = 0.5
	_survival_hint.offset_left = -320.0
	_survival_hint.offset_right = 320.0
	_survival_hint.offset_top = 72.0
	_survival_hint.offset_bottom = 140.0
	_survival_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_survival_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_survival_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_survival_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_survival_hint.add_theme_font_size_override("font_size", 18)
	_survival_hint.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75, 1.0))
	_survival_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_survival_hint.add_theme_constant_override("shadow_offset_x", 2)
	_survival_hint.add_theme_constant_override("shadow_offset_y", 2)
	_survival_hint.text = "HOLD THE RHYTHM — outlast her to recover.\nGive in and she'll drain your level."
	ui.add_child(_survival_hint)

func _on_enter_survival(_enemy_name: String) -> void:
	if _survival_hint:
		_survival_hint.visible = true
		_survival_hint.text = "HOLD THE RHYTHM — outlast her to recover.\nGive in and she'll drain your level."
		_survival_hint.modulate = Color(1, 1, 1, 1)

func _on_survival_success() -> void:
	if _survival_hint:
		_survival_hint.visible = false

func _on_enter_punishment(_enemy_name: String) -> void:
	if _survival_hint:
		_survival_hint.visible = false
	if _drain_banner:
		_drain_banner.visible = true

func _on_loser() -> void:
	if _survival_hint:
		_survival_hint.visible = false

func _ensure_drain_banner(ui: Node) -> void:
	_drain_banner = ui.get_node_or_null("DrainBanner") as RichTextLabel
	if _drain_banner:
		_drain_banner.visible = false
		return
	_drain_banner = RichTextLabel.new()
	_drain_banner.name = "DrainBanner"
	_drain_banner.visible = false
	_drain_banner.bbcode_enabled = true
	_drain_banner.fit_content = true
	_drain_banner.scroll_active = false
	_drain_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drain_banner.z_index = 90
	_drain_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_drain_banner.anchor_left = 0.5
	_drain_banner.anchor_right = 0.5
	_drain_banner.offset_left = -360.0
	_drain_banner.offset_right = 360.0
	_drain_banner.offset_top = 88.0
	_drain_banner.offset_bottom = 200.0
	_drain_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_drain_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_drain_banner.add_theme_font_size_override("normal_font_size", 22)
	_drain_banner.add_theme_color_override("default_color", Color(1.0, 0.86, 1.0, 1.0))
	ui.add_child(_drain_banner)

func _on_level_drained(old_level: int, new_level: int, flavor: String) -> void:
	if _hooked_main == null:
		return
	var parsed: Dictionary = SubtitleMarkup.expand(
		"[shout]LEVEL DRAINED[/shout]\n[drain]LV %d → LV %d[/drain]\n%s" % [old_level, new_level, flavor],
		"drain"
	)
	if _drain_banner:
		_drain_banner.text = "[center]%s[/center]" % str(parsed.get("bbcode", flavor))
		_drain_banner.visible = true
		_drain_banner.modulate = Color(1, 1, 1, 1)
	var bubble := _hooked_main.get_node_or_null("UI/DialogueBubble")
	if bubble and bubble.has_method("set_lane"):
		bubble.set_lane("drain")
	# Flavor line stays on the high lane so it does not cover the give-up button.
	if bubble and bubble.has_method("show_line") and flavor != "":
		bubble.show_line(flavor, "drain")
