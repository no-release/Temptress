from pathlib import Path
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")
# find proximity definition
for i, line in enumerate(text.splitlines(), 1):
    if "proximity" in line or "ratio" in line:
        print(f"{i}: {line}")