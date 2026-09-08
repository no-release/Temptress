from pathlib import Path
import re

path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\Main.gd")
text = path.read_text(encoding="utf-8")

old_onready = """@onready var hp_label:      Label     = $UI/TopHud/MarginContainer/HBoxContainer/HPLabel
@onready var hp_bar_fill:   ColorRect = $UI/TopHud/MarginContainer/HBoxContainer/HPBarBg/HPBarFill
@onready var hp_bar_ghost:  ColorRect = $UI/TopHud/MarginContainer/HBoxContainer/HPBarBg/HPBarGhost
@onready var atk_label:     Label     = $UI/TopHud/MarginContainer/HBoxContainer/AtkLabel
@onready var gold_label:    Label     = $UI/TopHud/MarginContainer/HBoxContainer/GoldLabel
@onready var enemy_card_anchor: Control   = $UI/EnemyCardAnchor
@onready var enemy_name_label:  Label     = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/EnemyNameLabel
@onready var enemy_hp_bar_fill: ColorRect = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/HPRow/EnemyHPBarBg/EnemyHPBarFill
@onready var enemy_atk_label:   Label     = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/EnemyAtkLabel"""

new_onready = """@onready var hp_label:      Label     = $UI/TopHud/MarginContainer/HBoxContainer/HPLabel
@onready var hp_bar_fill:   ColorRect = $UI/TopHud/MarginContainer/HBoxContainer/HPBarBg/HPBarFill
@onready var hp_bar_ghost:  ColorRect = $UI/TopHud/MarginContainer/HBoxContainer/HPBarBg/HPBarGhost
@onready var atk_label:     Label     = $UI/TopHud/MarginContainer/HBoxContainer/AtkLabel
@onready var gold_label:    Label     = $UI/TopHud/MarginContainer/HBoxContainer/GoldLabel
@onready var enemy_card_anchor: Control   = $UI/EnemyCardAnchor
@onready var enemy_name_label:  Label     = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/EnemyNameLabel
@onready var enemy_hp_bar_fill: ColorRect = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/HPRow/EnemyHPBarBg/EnemyHPBarFill
@onready var enemy_atk_label:   Label     = $UI/EnemyCardAnchor/EnemyCard/MarginContainer/VBoxContainer/EnemyAtkLabel
@onready var player_hp_rail: Control = $UI/PlayerHpRail
@onready var player_side_fill: ColorRect = $UI/PlayerHpRail/Fill
@onready var player_side_ghost: ColorRect = $UI/PlayerHpRail/Ghost
@onready var player_side_name: Label = $UI/PlayerHpRail/NameLabel
@onready var enemy_hp_rail: Control = $UI/EnemyHpRail
@onready var enemy_side_fill: ColorRect = $UI/EnemyHpRail/Fill
@onready var enemy_side_ghost: ColorRect = $UI/EnemyHpRail/Ghost
@onready var enemy_side_name: Label = $UI/EnemyHpRail/NameLabel"""

if old_onready not in text:
    raise SystemExit("onready block not found")
text = text.replace(old_onready, new_onready, 1)
text = text.replace("var _hp_ghost_width: float = -1.0", "var _hp_ghost_height: float = -1.0", 1)

needle = "\tbeat_bar.game_manager   = game_manager\n\tloser_button.visible = false"
insert = """\tbeat_bar.game_manager   = game_manager
\t# Edge HP rails replace the old top HP strip + enemy card ATK block.
\thp_label.visible = false
\thp_bar_fill.get_parent().visible = false
\tatk_label.visible = false
\tenemy_card_anchor.visible = false
\tif enemy_atk_label:
\t\tenemy_atk_label.visible = false
\tplayer_side_name.text = \"YOU\"
\tloser_button.visible = false"""
if needle not in text:
    raise SystemExit("ready needle not found")
text = text.replace(needle, insert, 1)

m = re.search(r"func _update_player_hud\(\):.*?func _update_enemy_hud\(\):", text, re.S)
if not m:
    raise SystemExit("player hud func not found")
new_player = r'''func _update_player_hud():
	var gm = game_manager
	var hp_dropped: bool = _tracked_player_hp >= 0 and gm.player_health < _tracked_player_hp
	hp_label.text  = "HP: %d/%d" % [gm.player_health, gm.player_max_health]
	atk_label.text = "ATK: %d" % gm.player_damage
	level_label.text = "LV %d" % gm.player_level
	xp_label.text    = "XP: %d/%d" % [gm.player_xp, gm.xp_to_next_level()]
	_gold_target = float(gm.player_gold)
	var p_pct = clamp(
		float(gm.player_health) / float(gm.player_max_health) if gm.player_max_health > 0 else 0.0,
		0.0, 1.0)
	var bg_h: float = maxf(1.0, player_hp_rail.size.y)
	var new_h: float = bg_h * p_pct
	if hp_dropped:
		var prev_h: float = player_side_fill.size.y if player_side_fill.size.y > 0.0 else new_h
		if _hp_ghost_height < 0.0:
			_hp_ghost_height = prev_h
		else:
			_hp_ghost_height = maxf(_hp_ghost_height, prev_h)
		_play_player_hurt_feedback()
	elif _tracked_player_hp >= 0 and gm.player_health >= _tracked_player_hp:
		_hp_ghost_height = new_h
	_apply_vertical_fill(player_side_fill, player_hp_rail.size, new_h, Color(0.95, 0.15, 0.15, 1) if p_pct <= 0.25 else \
						Color(0.95, 0.65, 0.1,  1) if p_pct <= 0.5  else \
						Color(0.85, 0.85, 0.85, 0.95))
	player_side_name.text = "YOU\n%d/%d" % [gm.player_health, gm.player_max_health]
	if player_side_ghost:
		if _hp_ghost_height < 0.0:
			_hp_ghost_height = new_h
		_apply_vertical_fill(player_side_ghost, player_hp_rail.size, maxf(_hp_ghost_height, new_h), Color(0.9, 0.12, 0.12, 0.55))
	_tracked_player_hp = gm.player_health

func _update_enemy_hud():'''
text = text[: m.start()] + new_player + text[m.end() :]

m2 = re.search(r"func _update_enemy_hud\(\):.*?func _process\(delta: float\):", text, re.S)
if not m2:
    raise SystemExit("enemy hud func not found")
new_enemy = r'''func _update_enemy_hud():
	var gm = game_manager
	var pretty := "Enemy"
	if gm.active_enemy:
		pretty = gm.active_enemy_type.replace("_", " ").capitalize()
		enemy_name_label.text = "- %s -" % pretty
		enemy_atk_label.text  = "ATK: %d" % gm.active_enemy.damage
	var e_pct = clamp(
		float(gm.enemy_health) / float(gm.enemy_max_health) if gm.enemy_max_health > 0 else 0.0,
		0.0, 1.0)
	var bg_h: float = maxf(1.0, enemy_hp_rail.size.y)
	var new_h: float = bg_h * e_pct
	_apply_vertical_fill(enemy_side_fill, enemy_hp_rail.size, new_h, Color(0.95, 0.35, 0.55, 1) if e_pct <= 0.25 else \
						Color(0.95, 0.55, 0.35, 1) if e_pct <= 0.5 else \
						Color(0.9, 0.75, 0.85, 0.95))
	enemy_side_name.text = "%s\n%d/%d" % [pretty, gm.enemy_health, gm.enemy_max_health]
	if enemy_side_ghost:
		_apply_vertical_fill(enemy_side_ghost, enemy_hp_rail.size, new_h, Color(0.7, 0.2, 0.35, 0.35))
	if enemy_hp_bar_fill and enemy_hp_bar_fill.get_parent():
		enemy_hp_bar_fill.size.x = enemy_hp_bar_fill.get_parent().size.x * e_pct

func _apply_vertical_fill(fill: ColorRect, rail_size: Vector2, height: float, col: Color) -> void:
	var w: float = maxf(1.0, rail_size.x)
	var h: float = maxf(0.0, minf(height, rail_size.y))
	fill.color = col
	fill.size = Vector2(w, h)
	fill.position = Vector2(0.0, maxf(0.0, rail_size.y - h))

func _process(delta: float):'''
text = text[: m2.start()] + new_enemy + text[m2.end() :]

old_ghost = """\tif hp_bar_ghost and _hp_ghost_width >= 0.0:
\t\tvar fill_w: float = hp_bar_fill.size.x
\t\tif _hp_ghost_width > fill_w:
\t\t\tvar drain := maxf(36.0, (_hp_ghost_width - fill_w) * 2.8)
\t\t\t_hp_ghost_width = move_toward(_hp_ghost_width, fill_w, drain * delta)
\t\telse:
\t\t\t_hp_ghost_width = fill_w
\t\thp_bar_ghost.size.x = _hp_ghost_width
\t\thp_bar_ghost.size.y = hp_bar_fill.size.y if hp_bar_fill.size.y > 0.0 else hp_bar_fill.get_parent().size.y"""
new_ghost = """\tif player_side_ghost and _hp_ghost_height >= 0.0:
\t\tvar fill_h: float = player_side_fill.size.y
\t\tif _hp_ghost_height > fill_h:
\t\t\tvar drain := maxf(36.0, (_hp_ghost_height - fill_h) * 2.8)
\t\t\t_hp_ghost_height = move_toward(_hp_ghost_height, fill_h, drain * delta)
\t\telse:
\t\t\t_hp_ghost_height = fill_h
\t\t_apply_vertical_fill(player_side_ghost, player_hp_rail.size, _hp_ghost_height, Color(0.9, 0.12, 0.12, 0.55))"""
if old_ghost not in text:
    raise SystemExit("ghost block not found; still has width=%s" % ("_hp_ghost_width" in text))
text = text.replace(old_ghost, new_ghost, 1)

# Survival toggles enemy rail (not the hidden card)
text = text.replace(
    "\tloser_button.visible      = true\n\tenemy_card_anchor.visible = false",
    "\tloser_button.visible      = true\n\tenemy_hp_rail.visible = false",
)
text = text.replace(
    "\tloser_button.visible      = false\n\tenemy_card_anchor.visible = true",
    "\tloser_button.visible      = false\n\tenemy_hp_rail.visible = true",
)

old_stagger = """\tvar base_l: float = _enemy_card_base_offsets.x
\tvar base_r: float = _enemy_card_base_offsets.y
\tenemy_card_anchor.offset_left = base_l
\tenemy_card_anchor.offset_right = base_r
\t_card_stagger_tween = create_tween()
\t_card_stagger_tween.tween_callback(func():
\t\tenemy_card_anchor.offset_left = base_l + 6.0
\t\tenemy_card_anchor.offset_right = base_r + 6.0
\t)
\t_card_stagger_tween.tween_interval(0.045)
\t_card_stagger_tween.tween_callback(func():
\t\tenemy_card_anchor.offset_left = base_l - 6.0
\t\tenemy_card_anchor.offset_right = base_r - 6.0
\t)
\t_card_stagger_tween.tween_interval(0.07)
\t_card_stagger_tween.tween_callback(func():
\t\tenemy_card_anchor.offset_left = base_l
\t\tenemy_card_anchor.offset_right = base_r
\t)"""
new_stagger = """\tvar base_l: float = enemy_hp_rail.offset_left
\tvar base_r: float = enemy_hp_rail.offset_right
\tenemy_hp_rail.offset_left = base_l
\tenemy_hp_rail.offset_right = base_r
\t_card_stagger_tween = create_tween()
\t_card_stagger_tween.tween_callback(func():
\t\tenemy_hp_rail.offset_left = base_l - 4.0
\t\tenemy_hp_rail.offset_right = base_r - 4.0
\t)
\t_card_stagger_tween.tween_interval(0.045)
\t_card_stagger_tween.tween_callback(func():
\t\tenemy_hp_rail.offset_left = base_l + 4.0
\t\tenemy_hp_rail.offset_right = base_r + 4.0
\t)
\t_card_stagger_tween.tween_interval(0.07)
\t_card_stagger_tween.tween_callback(func():
\t\tenemy_hp_rail.offset_left = base_l
\t\tenemy_hp_rail.offset_right = base_r
\t)"""
if old_stagger not in text:
    raise SystemExit("stagger block not found")
text = text.replace(old_stagger, new_stagger, 1)

text = text.replace(
    """\tvar pretty = type_name.replace("_", " ").capitalize()
\tenemy_name_label.text = "- %s -" % pretty""",
    """\tvar pretty = type_name.replace("_", " ").capitalize()
\tenemy_name_label.text = "- %s -" % pretty
\tenemy_side_name.text = pretty""",
)

path.write_text(text, encoding="utf-8")
print("Main.gd patched OK")
for s in ["_hp_ghost_height", "player_hp_rail", "_apply_vertical_fill", "enemy_side_name", "_hp_ghost_width"]:
    print(s, text.count(s))
