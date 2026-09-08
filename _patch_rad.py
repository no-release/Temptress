from pathlib import Path
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")
old = """\t\tvar radius_base: float = 8.0
\t\tif accent >= 2:
\t\t\tradius_base = 11.0
\t\telif accent <= 0:
\t\t\tradius_base = 5.5
\t\tvar radius: float = lerpf(radius_base, radius_base + 10.0, sqrt(proximity))"""
new = """\t\tvar radius: float = 8.0"""
if old not in text:
    raise SystemExit("radius block missing")
text = text.replace(old, new)
path.write_text(text.replace("\r\n","\n").replace("\r","\n"), encoding="utf-8")
print("fixed size")