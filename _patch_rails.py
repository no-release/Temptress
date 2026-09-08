from pathlib import Path
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\Main.gd")
text = path.read_text(encoding="utf-8")

if "player_side_frame" not in text:
    old = "@onready var player_side_name: Label = $UI/PlayerHpRail/NameLabel"
    new = """@onready var player_side_name: Label = $UI/PlayerHpRail/NameLabel
@onready var player_side_frame: TextureRect = $UI/PlayerHpRail/Frame
@onready var enemy_side_frame: TextureRect = $UI/EnemyHpRail/Frame"""
    if old not in text:
        raise SystemExit("name onready missing")
    text = text.replace(old, new, 1)

if "_setup_hp_rail_frames" not in text:
    for needle, insert in [
        ("\t_setup_side_hp_labels()\n\tloser_button.visible = false",
         "\t_setup_side_hp_labels()\n\t_setup_hp_rail_frames()\n\tloser_button.visible = false"),
        ("\t_setup_side_hp_labels()\r\n\tloser_button.visible = false",
         "\t_setup_side_hp_labels()\r\n\t_setup_hp_rail_frames()\r\n\tloser_button.visible = false"),
    ]:
        if needle in text:
            text = text.replace(needle, insert, 1)
            break
    else:
        raise SystemExit("setup call needle missing")

setup_fn = """
func _setup_hp_rail_frames() -> void:
	var ptex := load("res://ui_art/hp_rail_player_frame.png") as Texture2D
	var etex := load("res://ui_art/hp_rail_enemy_frame.png") as Texture2D
	if player_side_frame and ptex:
		player_side_frame.texture = ptex
		player_side_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		player_side_frame.stretch_mode = TextureRect.STRETCH_SCALE
	if enemy_side_frame and etex:
		enemy_side_frame.texture = etex
		enemy_side_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		enemy_side_frame.stretch_mode = TextureRect.STRETCH_SCALE

"""
if "func _setup_hp_rail_frames" not in text:
    text = text.replace(
        "func _setup_side_hp_labels() -> void:",
        setup_fn.replace("\n", "\r\n") + "func _setup_side_hp_labels() -> void:",
        1,
    )

import re
new_apply = """func _apply_vertical_fill(fill: ColorRect, rail_size: Vector2, height: float, col: Color) -> void:
	# Usable channel matches tapered frame (below ~38% height, above beat margin).
	var inset_x: float = 4.0
	var w: float = maxf(1.0, rail_size.x - inset_x * 2.0)
	var channel_top: float = rail_size.y * 0.38
	var channel_bottom: float = maxf(channel_top + 1.0, rail_size.y - 72.0)
	var channel_h: float = channel_bottom - channel_top
	var ratio: float = 0.0
	if rail_size.y > 0.0:
		ratio = clampf(height / rail_size.y, 0.0, 1.0)
	var h: float = channel_h * ratio
	fill.color = col
	fill.size = Vector2(w, h)
	fill.position = Vector2(inset_x, channel_bottom - h)
"""
m = re.search(r"func _apply_vertical_fill\(fill: ColorRect.*?(?=\r?\nfunc )", text, re.S)
if not m:
    raise SystemExit("apply fn not found")
text = text[: m.start()] + new_apply.replace("\n", "\r\n") + text[m.end() :]

path.write_text(text, encoding="utf-8")
print("OK")
for s in ["_setup_hp_rail_frames", "player_side_frame", "channel_top", "hp_rail_player_frame"]:
    print(s, text.count(s))