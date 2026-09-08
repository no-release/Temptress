from pathlib import Path
import re

proj = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11")

# --- SideHpRail default track/edge (Helltaker: deep black track, vivid crimson rim) ---
rail_path = proj / "scripts" / "SideHpRail.gd"
rail = rail_path.read_text(encoding="utf-8")
rail = rail.replace(
    'var _fill_color: Color = Color(0.85, 0.85, 0.85, 0.95)\n'
    'var _track_color: Color = Color(0.05, 0.04, 0.06, 0.88)\n'
    'var _edge_color: Color = Color(0.78, 0.1, 0.16, 1.0)',
    'var _fill_color: Color = Color(0.95, 0.92, 0.94, 0.98)\n'
    'var _track_color: Color = Color(0.02, 0.01, 0.03, 0.92)\n'
    'var _edge_color: Color = Color(0.92, 0.08, 0.18, 1.0)',
)
# Slightly thicker crimson outline for that graphic punch
rail = rail.replace('draw_polyline(outline, _edge_color, 2.5, true)', 'draw_polyline(outline, _edge_color, 3.0, true)')
rail = rail.replace("\r\n", "\n").replace("\r", "\n")
rail_path.write_text(rail, encoding="utf-8")

# --- Main.gd: STAMINA label + Helltaker fill colors ---
main_path = proj / "scripts" / "Main.gd"
main = main_path.read_text(encoding="utf-8")

main = main.replace('player_hp_rail.set_label("PLAYER")', 'player_hp_rail.set_label("STAMINA")')
main = main.replace('set_label("PLAYER")', 'set_label("STAMINA")')

# Player fill colors (was grey/orange/red) -> white / soft rose / hot crimson
old_p = (
    'var p_col = Color(0.95, 0.15, 0.15, 1) if p_pct <= 0.25 else '
    'Color(0.95, 0.65, 0.1, 1) if p_pct <= 0.5 else Color(0.85, 0.85, 0.85, 0.95)'
)
new_p = (
    'var p_col = Color(0.95, 0.12, 0.22, 1) if p_pct <= 0.25 else '
    'Color(0.98, 0.45, 0.55, 1) if p_pct <= 0.5 else Color(0.98, 0.94, 0.96, 0.98)'
)
if old_p not in main:
    raise SystemExit("player color line missing")
main = main.replace(old_p, new_p)

# Enemy fill: blush pink / coral / deep magenta-red (Helltaker demonette)
old_e = (
    'var e_col = Color(0.95, 0.35, 0.55, 1) if e_pct <= 0.25 else '
    'Color(0.95, 0.55, 0.35, 1) if e_pct <= 0.5 else Color(0.9, 0.75, 0.85, 0.95)'
)
new_e = (
    'var e_col = Color(0.75, 0.05, 0.28, 1) if e_pct <= 0.25 else '
    'Color(0.95, 0.28, 0.42, 1) if e_pct <= 0.5 else Color(0.95, 0.55, 0.68, 0.98)'
)
if old_e not in main:
    raise SystemExit("enemy color line missing")
main = main.replace(old_e, new_e)

main = main.replace("\r\n", "\n").replace("\r", "\n")
main_path.write_text(main, encoding="utf-8")

# Default label in scene
tscn = (proj / "scenes" / "SideHpRail.tscn").read_text(encoding="utf-8")
tscn = tscn.replace('text = "PLAYER"', 'text = "STAMINA"')
(proj / "scenes" / "SideHpRail.tscn").write_text(tscn.replace("\r\n", "\n"), encoding="utf-8")

print("STAMINA count", main.count("STAMINA"))
print("PLAYER left", main.count('"PLAYER"'))
print("p_col ok", "0.98, 0.94, 0.96" in main)
print("e_col ok", "0.95, 0.55, 0.68" in main)