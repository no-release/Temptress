from pathlib import Path
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")
old = """\t\t# One solid opaque color for every note.
\t\tvar beat_color: Color = COLOR_BEAT

\t\tvar radius: float = 8.0

\t\tfor bx in [lx, rx]:
\t\t\tdraw_circle(Vector2(bx, cy), radius, beat_color)"""
new = """\t\t# Same size/color; alpha 0 at spawn (edges) → 1 at center.
\t\tvar beat_color: Color = Color(COLOR_BEAT.r, COLOR_BEAT.g, COLOR_BEAT.b, clampf(proximity, 0.0, 1.0))
\t\tvar radius: float = 8.0

\t\tfor bx in [lx, rx]:
\t\t\tdraw_circle(Vector2(bx, cy), radius, beat_color)"""
if old not in text:
    raise SystemExit("block missing")
text = text.replace(old, new)
path.write_text(text.replace("\r\n","\n").replace("\r","\n"), encoding="utf-8")
print("ok")