from pathlib import Path
import sys
sys.stdout.reconfigure(encoding="utf-8")
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")
# show radius block
idx = text.find("radius_base")
print(repr(text[idx-100:idx+350]))