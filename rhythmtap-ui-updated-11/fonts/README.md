# Temptress fonts (SIL Open Font License)

Picked for on-screen reading, not decoration.

| File | Face | Use |
| --- | --- | --- |
| `AtkinsonHyperlegible-Regular.ttf` | Atkinson Hyperlegible | UI, buttons, HUD |
| `AtkinsonHyperlegible-Bold.ttf` | Atkinson Hyperlegible Bold | Button labels |
| `Cinzel-wght.ttf` | Cinzel (variable) | Titles — GUILD HALL, TEMPTRESS |
| `Lora-wght.ttf` | Lora (variable) | Dialogue / subtitle body |

Atkinson Hyperlegible was designed by the Braille Institute so similar glyphs stay distinct. Lora holds up at subtitle size. Cinzel is a Roman inscription face that stays clear at heading size.

Arcade Classic remains in the project as a fallback if these files are missing.

`FontKit` autoload loads `res://fonts/` first, then `user://fonts/`, and will fetch the Google Fonts GitHub copies on first launch if neither exists.

Vendor copies live in this folder when present. Licenses: see `OFL-*.txt`.
