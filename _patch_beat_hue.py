from pathlib import Path
path = Path(r"C:\Users\kruig\Documents\GitHub\Temptress\rhythmtap-ui-updated-11\scripts\BeatBar.gd")
text = path.read_text(encoding="utf-8")

# Soften COLOR_BEAT_CLOSE toward a near-neighbor of COLOR_BEAT (slightly more magenta)
# and replace lerps with a small HSV hue shift helper.

old_consts = """const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_BEAT_CLOSE = Color(0.4, 0.002, 0.634, 1.0)
const COLOR_ACCENT     = Color(1.0, 0.85, 0.35, 1.0)
const COLOR_GHOST      = Color(0.55, 0.45, 0.75, 0.55)
const COLOR_IMPACT     = Color(0.752, 0.0, 0.606, 1.0)"""

new_consts = """const COLOR_BEAT       = Color(1.0, 0.642, 0.899, 1.0)
const COLOR_ACCENT     = Color(1.0, 0.85, 0.35, 1.0)
const COLOR_GHOST      = Color(0.55, 0.45, 0.75, 0.55)
const COLOR_IMPACT     = Color(0.752, 0.0, 0.606, 1.0)
## Max hue shift (degrees / 360) as a note reaches the center — keep it subtle.
const HUE_SHIFT_MAX: float = 0.045"""

if old_consts not in text:
    raise SystemExit("const block not found")
text = text.replace(old_consts, new_consts)

old_color = """\t\tvar beat_color: Color
\t\tif accent >= 2:
\t\t\tbeat_color = COLOR_ACCENT.lerp(COLOR_BEAT_CLOSE, proximity * proximity)
\t\telif accent <= 0:
\t\t\tbeat_color = COLOR_GHOST.lerp(COLOR_BEAT_CLOSE, proximity * proximity * 0.45)
\t\telse:
\t\t\tbeat_color = COLOR_BEAT.lerp(COLOR_BEAT_CLOSE, proximity * proximity)"""

new_color = """\t\tvar base_color: Color = COLOR_BEAT
\t\tif accent >= 2:
\t\t\tbase_color = COLOR_ACCENT
\t\telif accent <= 0:
\t\t\tbase_color = COLOR_GHOST
\t\t# Slight hue drift only — no big pink→purple jump.
\t\tvar beat_color: Color = _hue_shift(base_color, proximity * proximity * HUE_SHIFT_MAX)"""

if old_color not in text:
    raise SystemExit("color block not found")
text = text.replace(old_color, new_color)

helper = """
func _hue_shift(c: Color, amount: float) -> Color:
\t# amount is fractional hue (0.045 ≈ +16°)
\tvar h: float = c.h + amount
\tif h > 1.0:
\t\th -= 1.0
\telif h < 0.0:
\t\th += 1.0
\treturn Color.from_hsv(h, c.s, c.v, c.a)

"""

if "func _hue_shift" not in text:
    # Insert before _ready or after consts
    text = text.replace("func _ready() -> void:", helper + "func _ready() -> void:", 1)

text = text.replace("\r\n", "\n").replace("\r", "\n")
path.write_text(text, encoding="utf-8")
print("patched")
print("BEAT_CLOSE", "COLOR_BEAT_CLOSE" in text)
print("hue_shift", "func _hue_shift" in text)
print("HUE_SHIFT_MAX", "HUE_SHIFT_MAX" in text)