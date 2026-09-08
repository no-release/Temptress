from pathlib import Path
import sys
sys.stdout.reconfigure(encoding="utf-8")
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")

# Remove hue shift helper and HUE_SHIFT_MAX
import re
text = re.sub(r"\n## Max hue shift.*?\nconst HUE_SHIFT_MAX: float = 0\.045\n", "\n", text, count=1, flags=re.S)
text = re.sub(r"\nfunc _hue_shift\(c: Color, amount: float\) -> Color:.*?(?=\nfunc )", "\n", text, count=1, flags=re.S)

# Unify note colors: one pink for all; ghost keeps lower alpha only
# Replace COLOR_ACCENT and COLOR_GHOST to match COLOR_BEAT (ghost dimmer)
old = """const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_ACCENT     = Color(1.0, 0.85, 0.35, 1.0)
const COLOR_GHOST      = Color(0.55, 0.45, 0.75, 0.55)
const COLOR_IMPACT     = Color(0.752, 0.0, 0.606, 1.0)"""

new = """const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_ACCENT     = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_GHOST      = Color(1.0, 0.642, 0.899, 0.45)
const COLOR_IMPACT     = Color(1.0, 0.642, 0.899, 1.0)"""

if old not in text:
    raise SystemExit("const block not found:\n" + text[text.find("const COLOR_BEAT"):text.find("const COLOR_BEAT")+400])
text = text.replace(old, new)

# Replace color assignment to fixed base, no hue shift
old_c = """\t\tvar base_color: Color = COLOR_BEAT
\t\tif accent >= 2:
\t\t\tbase_color = COLOR_ACCENT
\t\telif accent <= 0:
\t\t\tbase_color = COLOR_GHOST
\t\t# Slight hue drift only — no big pink→purple jump.
\t\tvar beat_color: Color = _hue_shift(base_color, proximity * proximity * HUE_SHIFT_MAX)"""

new_c = """\t\t# Fixed color for every note — no proximity / type hue changes.
\t\tvar beat_color: Color = COLOR_BEAT
\t\tif accent <= 0:
\t\t\tbeat_color = COLOR_GHOST"""

if old_c not in text:
    # try find what we have
    idx = text.find("base_color")
    print("MISSING block, context:", repr(text[idx-50:idx+350]) if idx>=0 else "no base_color")
    raise SystemExit(1)
text = text.replace(old_c, new_c)

text = text.replace("\r\n", "\n").replace("\r", "\n")
path.write_text(text, encoding="utf-8")
print("ok")
print("hue_shift", "_hue_shift" in text)
print("HUE_SHIFT", "HUE_SHIFT" in text)
print("COLOR_ACCENT yellow", "0.85, 0.35" in text)