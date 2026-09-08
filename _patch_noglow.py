from pathlib import Path
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")
old = """\t\tfor bx in [lx, rx]:
\t\t\tdraw_circle(Vector2(bx, cy), radius + 6.0, Color(beat_color.r, beat_color.g, beat_color.b, 0.22))
\t\t\tdraw_circle(Vector2(bx, cy), radius, beat_color)"""
new = """\t\tfor bx in [lx, rx]:
\t\t\tdraw_circle(Vector2(bx, cy), radius, beat_color)"""
if old not in text:
    raise SystemExit("draw block missing")
text = text.replace(old, new)
path.write_text(text.replace("\r\n","\n").replace("\r","\n"), encoding="utf-8")
print("glow removed")