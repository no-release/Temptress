from pathlib import Path
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")
# show color-related bits
for i, line in enumerate(text.splitlines(), 1):
    if any(k in line for k in ("COLOR_", "hue", "beat_color", "base_color", "proximity", "accent")):
        print(f"{i}: {line}")