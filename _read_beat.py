from pathlib import Path
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")
# Show the color section
lines = text.splitlines()
for i, line in enumerate(lines):
    if i < 25 or (95 <= i <= 125):
        print(f"{i+1}: {line}")