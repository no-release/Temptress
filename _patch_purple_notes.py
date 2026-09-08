from pathlib import Path
import re
import sys
sys.stdout.reconfigure(encoding="utf-8")

proj = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11")

# --- Main.gd HP colors: rich purple (full) -> rich red (low) ---
main_path = proj / "scripts" / "Main.gd"
main = main_path.read_text(encoding="utf-8")

old_p = (
    'var p_col = Color(0.95, 0.12, 0.22, 1) if p_pct <= 0.25 else '
    'Color(0.98, 0.45, 0.55, 1) if p_pct <= 0.5 else Color(0.98, 0.94, 0.96, 0.98)'
)
# Full HP = rich purple, mid = magenta-red, low = rich red
new_p = (
    'var p_col = Color(0.85, 0.08, 0.15, 1) if p_pct <= 0.25 else '
    'Color(0.72, 0.12, 0.42, 1) if p_pct <= 0.5 else Color(0.48, 0.12, 0.72, 1)'
)
if old_p not in main:
    raise SystemExit("player color missing")
main = main.replace(old_p, new_p)

old_e = (
    'var e_col = Color(0.75, 0.05, 0.28, 1) if e_pct <= 0.25 else '
    'Color(0.95, 0.28, 0.42, 1) if e_pct <= 0.5 else Color(0.95, 0.55, 0.68, 0.98)'
)
new_e = (
    'var e_col = Color(0.85, 0.08, 0.15, 1) if e_pct <= 0.25 else '
    'Color(0.72, 0.12, 0.42, 1) if e_pct <= 0.5 else Color(0.48, 0.12, 0.72, 1)'
)
if old_e not in main:
    raise SystemExit("enemy color missing")
main = main.replace(old_e, new_e)
main = main.replace("\r\n", "\n").replace("\r", "\n")
main_path.write_text(main, encoding="utf-8")

# Default fill in SideHpRail = rich purple (full)
rail_path = proj / "scripts" / "SideHpRail.gd"
rail = rail_path.read_text(encoding="utf-8")
rail = rail.replace(
    'var _fill_color: Color = Color(0.95, 0.92, 0.94, 0.98)',
    'var _fill_color: Color = Color(0.48, 0.12, 0.72, 1)',
)
rail = rail.replace("\r\n", "\n").replace("\r", "\n")
rail_path.write_text(rail, encoding="utf-8")

# --- BeatBar: fully opaque, no ghost alpha, no proximity glow alpha flicker ---
beat_path = proj / "scripts" / "BeatBar.gd"
beat = beat_path.read_text(encoding="utf-8")

beat = beat.replace(
    'const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)\n'
    'const COLOR_ACCENT     = Color(1.0, 0.642, 0.899, 1.0)\n'
    'const COLOR_GHOST      = Color(1.0, 0.642, 0.899, 0.45)\n'
    'const COLOR_IMPACT     = Color(1.0, 0.642, 0.899, 1.0)',
    'const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)\n'
    'const COLOR_ACCENT     = Color(1.0, 0.642, 0.899, 1.0)\n'
    'const COLOR_GHOST      = Color(1.0, 0.642, 0.899, 1.0)\n'
    'const COLOR_IMPACT     = Color(1.0, 0.642, 0.899, 1.0)',
)

# Simplify color pick - always COLOR_BEAT
old_c = """\t\t# Fixed color for every note — no proximity / type hue changes.
\t\tvar beat_color: Color = COLOR_BEAT
\t\tif accent <= 0:
\t\t\tbeat_color = COLOR_GHOST"""
new_c = """\t\t# One solid opaque color for every note.
\t\tvar beat_color: Color = COLOR_BEAT"""
if old_c not in beat:
    raise SystemExit("beat color block missing:\n" + beat[beat.find("beat_color")-80:beat.find("beat_color")+200])
beat = beat.replace(old_c, new_c)

# Soft glow was proximity*0.18 alpha - remove or make solid same color without flickering
# Find draw_circle glow line
old_glow = 'draw_circle(Vector2(bx, cy), radius + 10.0, Color(beat_color.r, beat_color.g, beat_color.b, proximity * 0.18))'
new_glow = 'draw_circle(Vector2(bx, cy), radius + 6.0, Color(beat_color.r, beat_color.g, beat_color.b, 0.22))'
if old_glow not in beat:
    # try find
    idx = beat.find("radius + 10")
    print("glow context", repr(beat[idx-60:idx+120]))
    raise SystemExit("glow line missing")
beat = beat.replace(old_glow, new_glow)

beat = beat.replace("\r\n", "\n").replace("\r", "\n")
beat_path.write_text(beat, encoding="utf-8")

print("main purple", "0.48, 0.12, 0.72" in main)
print("ghost opaque", "0.899, 0.45" not in beat and "COLOR_GHOST      = Color(1.0, 0.642, 0.899, 1.0)" in beat)
print("no prox glow", "proximity * 0.18" not in beat)