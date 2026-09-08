from pathlib import Path
import sys
sys.stdout.reconfigure(encoding="utf-8")
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")
# show draw section around beat_color / radius / draw_circle
idx = text.find("One solid opaque")
if idx < 0:
    idx = text.find("beat_color")
print(text[idx-80:idx+400])