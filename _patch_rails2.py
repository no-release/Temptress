from pathlib import Path
import re
import sys
sys.stdout.reconfigure(encoding="utf-8")

path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\Main.gd")
text = path.read_text(encoding="utf-8")

text = re.sub(
    r"\nfunc _apply_vertical_fill\(fill: ColorRect.*?(?=\nfunc )",
    "\n",
    text,
    count=1,
    flags=re.S,
)

text = text.replace(
    'player_hp_rail.set_label("PLAYER  %d/%d" % [gm.player_health, gm.player_max_health])',
    'player_hp_rail.set_label("PLAYER")',
)

old_enemy_label = 'enemy_hp_rail.set_label("%s  %d/%d" % [pretty, gm.enemy_health, gm.enemy_max_health])'
new_enemy_label = 'enemy_hp_rail.set_label(_side_enemy_label(pretty, gm.active_enemy_type if gm.active_enemy else ""))'
if old_enemy_label in text:
    text = text.replace(old_enemy_label, new_enemy_label)

text = text.replace(
    'enemy_hp_rail.set_label(pretty)',
    'enemy_hp_rail.set_label(_side_enemy_label(pretty, type_name))',
)

helper = '''
func _side_enemy_label(pretty: String, type_name: String) -> String:
	# Prefer first token of type (slime_girl → SLIME); fallback to pretty.
	var raw := type_name.strip_edges()
	if raw != "":
		var token := raw.split("_")[0]
		if token != "":
			return token.to_upper()
	return pretty.to_upper()

'''
if "func _side_enemy_label" not in text:
    text = text.replace("func _init_side_hp_rails() -> void:", helper + "func _init_side_hp_rails() -> void:", 1)

path.write_text(text.replace("\r\n", "\n").replace("\r", "\n"), encoding="utf-8")
print("Main.gd cleaned")
print("apply_vertical", text.count("_apply_vertical_fill"))
print("side_enemy", "func _side_enemy_label" in text)
print("PLAYER only lines", text.count('set_label("PLAYER")'))

ms = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scenes\Main.tscn").read_text(encoding="utf-8")
idx = ms.find('[node name="PlayerHpRail"')
print("--- Main.tscn rails ---")
print(ms[idx:idx+900] if idx >= 0 else "NOT FOUND")

rail = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\SideHpRail.gd").read_text(encoding="utf-8")
print("rail bytes", len(rail), "path_points" in rail, "flip_side" in rail)