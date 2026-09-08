from pathlib import Path
import re
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\Main.gd")
text = path.read_text(encoding="utf-8")

# Replace ColorRect/frame onready with simple rail refs if still old style
old_block = """@onready var player_hp_rail: Control = $UI/PlayerHpRail
@onready var player_side_fill: ColorRect = $UI/PlayerHpRail/Fill
@onready var player_side_ghost: ColorRect = $UI/PlayerHpRail/Ghost
@onready var player_side_name: Label = $UI/PlayerHpRail/NameLabel
@onready var player_side_frame: TextureRect = $UI/PlayerHpRail/Frame
@onready var enemy_side_frame: TextureRect = $UI/EnemyHpRail/Frame
@onready var enemy_hp_rail: Control = $UI/EnemyHpRail
@onready var enemy_side_fill: ColorRect = $UI/EnemyHpRail/Fill
@onready var enemy_side_ghost: ColorRect = $UI/EnemyHpRail/Ghost
@onready var enemy_side_name: Label = $UI/EnemyHpRail/NameLabel"""

new_block = """@onready var player_hp_rail: Control = $UI/PlayerHpRail
@onready var enemy_hp_rail: Control = $UI/EnemyHpRail"""

if "player_side_fill" in text:
    # Flexible replace of the onready rail cluster
    text2 = re.sub(
        r"@onready var player_hp_rail: Control = \$UI/PlayerHpRail\n(?:@onready var player_side_.*\n)+@onready var enemy_hp_rail: Control = \$UI/EnemyHpRail\n(?:@onready var enemy_side_.*\n)+",
        new_block + "\n",
        text,
    )
    if text2 == text:
        # try without frames
        text2 = re.sub(
            r"@onready var player_hp_rail: Control = \$UI/PlayerHpRail.*?@onready var enemy_side_name: Label = \$UI/EnemyHpRail/NameLabel\n",
            new_block + "\n",
            text,
            count=1,
            flags=re.S,
        )
    text = text2

# Remove ghost height tracking usage for side fills — keep var for safety or remove process ghost
# Simplify _setup_side_hp_labels / frames
text = re.sub(r"\nfunc _setup_hp_rail_frames\(\) -> void:.*?(?=\nfunc )", "\n", text, count=1, flags=re.S)
text = re.sub(r"\nfunc _setup_side_hp_labels\(\) -> void:.*?(?=\nfunc )", "\n", text, count=1, flags=re.S)

text = text.replace("\t_setup_side_hp_labels()\n\t_setup_hp_rail_frames()\n", "\t_init_side_hp_rails()\n")
text = text.replace("\t_setup_side_hp_labels()\n", "\t_init_side_hp_rails()\n")
text = text.replace("\tplayer_side_name.text = \"YOU\"\n", "")

init_fn = '''
func _init_side_hp_rails() -> void:
	if player_hp_rail and player_hp_rail.has_method("set_label"):
		player_hp_rail.set_label("PLAYER")
	if enemy_hp_rail and enemy_hp_rail.has_method("set_label"):
		enemy_hp_rail.set_label("ENEMY")

'''
if "func _init_side_hp_rails" not in text:
    text = text.replace("func _update_all_hud():", init_fn + "func _update_all_hud():", 1)

# Replace player hud fill section
# Find and replace the vertical fill calls in _update_player_hud
text = re.sub(
    r"\t_apply_vertical_fill\(player_side_fill, player_hp_rail\.size, new_h, .*?\n\tplayer_side_name\.text = .*?\n\tif player_side_ghost:.*?\n\t\t_apply_vertical_fill\(player_side_ghost, player_hp_rail\.size, maxf\(_hp_ghost_height, new_h\), .*?\n",
    "\tvar p_col = Color(0.95, 0.15, 0.15, 1) if p_pct <= 0.25 else Color(0.95, 0.65, 0.1, 1) if p_pct <= 0.5 else Color(0.85, 0.85, 0.85, 0.95)\n\tif player_hp_rail and player_hp_rail.has_method(\"set_hp\"):\n\t\tplayer_hp_rail.set_hp(p_pct, p_col)\n\tif player_hp_rail and player_hp_rail.has_method(\"set_label\"):\n\t\tplayer_hp_rail.set_label(\"PLAYER  %d/%d\" % [gm.player_health, gm.player_max_health])\n",
    text,
    count=1,
    flags=re.S,
)

# Enemy hud
text = re.sub(
    r"\t_apply_vertical_fill\(enemy_side_fill, enemy_hp_rail\.size, new_h, .*?\n\tenemy_side_name\.text = .*?\n\tif enemy_side_ghost:.*?\n\t\t_apply_vertical_fill\(enemy_side_ghost, enemy_hp_rail\.size, new_h, .*?\n",
    "\tvar e_col = Color(0.95, 0.35, 0.55, 1) if e_pct <= 0.25 else Color(0.95, 0.55, 0.35, 1) if e_pct <= 0.5 else Color(0.9, 0.75, 0.85, 0.95)\n\tif enemy_hp_rail and enemy_hp_rail.has_method(\"set_hp\"):\n\t\tenemy_hp_rail.set_hp(e_pct, e_col)\n\tif enemy_hp_rail and enemy_hp_rail.has_method(\"set_label\"):\n\t\tenemy_hp_rail.set_label(\"%s  %d/%d\" % [pretty, gm.enemy_health, gm.enemy_max_health])\n",
    text,
    count=1,
    flags=re.S,
)

# Remove _apply_vertical_fill if unused
if "player_side_fill" not in text and "enemy_side_fill" not in text:
    text = re.sub(r"\nfunc _apply_vertical_fill\(fill: ColorRect.*?(?=\nfunc )", "\n", text, count=1, flags=re.S)

# Ghost process block that references player_side_ghost — neutralize
text = re.sub(
    r"\tif player_side_ghost and _hp_ghost_height >= 0\.0:.*?(?=\nfunc |\Z)",
    "\tpass\n",
    text,
    count=1,
    flags=re.S,
)

# enemy_side_name references
text = text.replace("\tenemy_side_name.text = pretty", "\tif enemy_hp_rail and enemy_hp_rail.has_method(\"set_label\"):\n\t\tenemy_hp_rail.set_label(pretty)")

# Remove unused bg_h/new_h if left orphaned in player update — keep for now if still used
# Clean leftover vars computing new_h for old fill
text = re.sub(
    r"\tvar bg_h: float = maxf\(1\.0, player_hp_rail\.size\.y\)\n\tvar new_h: float = bg_h \* p_pct\n",
    "",
    text,
)
text = re.sub(
    r"\tvar bg_h: float = maxf\(1\.0, enemy_hp_rail\.size\.y\)\n\tvar new_h: float = bg_h \* e_pct\n",
    "",
    text,
)
# Fix ghost tracking that still uses new_h / player_side_fill
text = re.sub(
    r"\tif hp_dropped:\n\t\tvar prev_h: float = player_side_fill\.size\.y if player_side_fill\.size\.y > 0\.0 else new_h\n\t\tif _hp_ghost_height < 0\.0:\n\t\t\t_hp_ghost_height = prev_h\n\t\telse:\n\t\t\t_hp_ghost_height = maxf\(_hp_ghost_height, prev_h\)\n\t\t_play_player_hurt_feedback\(\)\n\telif _tracked_player_hp >= 0 and gm\.player_health >= _tracked_player_hp:\n\t\t_hp_ghost_height = new_h\n",
    "\tif hp_dropped:\n\t\t_play_player_hurt_feedback()\n",
    text,
)

path.write_text(text.replace("\r\n", "\n").replace("\r", "\n"), encoding="utf-8")
print("Main.gd patched")
for s in ["set_hp", "set_label", "player_side_fill", "_apply_vertical", "_init_side_hp", "player_side_frame"]:
    print(s, text.count(s))