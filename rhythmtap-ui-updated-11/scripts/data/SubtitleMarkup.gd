extends RefCounted
class_name SubtitleMarkup
# =============================================================================
# Combat subtitle markup.
# Custom tags expand to Godot RichTextLabel BBCode + motion effects.
# Native BBCode ([b] [i] [color] [wave] [shake] [rainbow] …) passes through.
# =============================================================================

## Situation → default wrapper when a line has no custom tags.
const SITUATION_WRAP := {
	"taunt": "tease",
	"player_near_death": "hot",
	"player_defeated": "command",
	"near_win": "growl",
	"survive_loss": "threat",
	"losing": "drain",
	"gameover_remarks": "drain",
	"rematch": "tease",
	"drain": "drain",
	"notice": "soft",
}

## Convenience tags → BBCode. Keep nested-safe (no overlapping same tag).
const TAGS := {
	"whisper": "[font_size=15][i][color=#c8c8d8][fade start=0 length=18]",
	"shout": "[font_size=28][b][color=#ff4d4d][shake rate=28 level=10]",
	"moan": "[i][color=#ff8ab8][wave amp=12 freq=4]",
	"tease": "[i][color=#ffb3d4][wave amp=7 freq=3.5]",
	"command": "[b][color=#ffe08a][outline_size=4][outline_color=#3a2208]",
	"drain": "[i][color=#c9a0ff][fade start=2 length=16]",
	"hot": "[color=#ff7a3d][pulse freq=1.15 color=#ffd0a8]",
	"cold": "[color=#8ee8ff][fade start=0 length=20]",
	"sweet": "[i][color=#ffd4ea]",
	"threat": "[b][color=#ff6b6b][shake rate=14 level=5]",
	"giggle": "[i][color=#ffe36b][pulse freq=2.2 color=#fff4b0]",
	"pant": "[i][font_size=17][color=#ffc4c4][wave amp=9 freq=6]",
	"growl": "[b][color=#d9a07a][shake rate=10 level=6]",
	"heart": "[color=#ff5e8a][pulse freq=1.4 color=#ffb0c8]",
	"echo": "[color=#d0d0ff][fade start=4 length=22][outline_size=3][outline_color=#202040]",
	"soft": "[font_size=16][color=#e6e6ee]",
	"harsh": "[b][color=#ffd9d9][shake rate=22 level=7]",
	"lick": "[i][color=#ff9ec8][wave amp=5 freq=7]",
	"drip": "[i][color=#9eead2][wave amp=14 freq=2.2]",
	"queen": "[b][color=#ffd76a][wave amp=4 freq=2][outline_size=5][outline_color=#4a3008]",
	"prey": "[i][color=#ffb08a][shake rate=8 level=3]",
	"slow": "[i][color=#e8e0ff]",
	"fast": "[b][color=#fff3c8]",
	"hiss": "[i][color=#c6ff9a][shake rate=18 level=4]",
	"purr": "[i][color=#ffc89a][wave amp=6 freq=2.4]",
	"laugh": "[color=#ffd27a][pulse freq=1.8 color=#fff0c0]",
	"cry": "[i][color=#9bb8ff][wave amp=8 freq=1.6]",
	"glitch": "[color=#b8ffea][tornado radius=4 freq=18][shake rate=40 level=8]",
	"focus": "[b][color=#ffffff][outline_size=6][outline_color=#000000]",
	"mute": "[font_size=14][color=#9a9aaa][i]",
	"big": "[font_size=26][b]",
	"tiny": "[font_size=13][i]",
	"clingy": "[i][color=#ff9ec8][wave amp=6 freq=2.8]",
	"gooey": "[i][color=#9eead2][wave amp=16 freq=1.8]",
	"brat": "[b][color=#ffb45c][pulse freq=2.0 color=#ffe0a8]",
	"punk": "[b][color=#ff6b8a][shake rate=16 level=4]",
	"hyper": "[b][color=#fff38a][pulse freq=3.0 color=#ffffff]",
	"velvet": "[i][color=#d4b4ff][fade start=0 length=14]",
	"predator": "[b][color=#c080ff][pulse freq=0.8 color=#f0d0ff]",
	"sly": "[i][color=#ffc878][wave amp=5 freq=3.2]",
	"smug": "[i][color=#ffe0a0][pulse freq=1.1 color=#fff4d0]",
	"blunt": "[b][color=#e8d0b0][outline_size=3][outline_color=#201810]",
	"giantess": "[font_size=24][b][color=#d9a07a][shake rate=8 level=5]",
	"regal": "[b][color=#ffd76a][outline_size=5][outline_color=#3a2808]",
	"possessive": "[b][color=#ff8a6a][wave amp=3 freq=1.6]",
	"foot": "[i][color=#ffc4a8][wave amp=8 freq=5]",
}

const CLOSE_EXTRAS := {
	"whisper": "[/fade][/color][/i][/font_size]",
	"shout": "[/shake][/color][/b][/font_size]",
	"moan": "[/wave][/color][/i]",
	"tease": "[/wave][/color][/i]",
	"command": "[/outline_color][/outline_size][/color][/b]",
	"drain": "[/fade][/color][/i]",
	"hot": "[/pulse][/color]",
	"cold": "[/fade][/color]",
	"sweet": "[/color][/i]",
	"threat": "[/shake][/color][/b]",
	"giggle": "[/pulse][/color][/i]",
	"pant": "[/wave][/color][/font_size][/i]",
	"growl": "[/shake][/color][/b]",
	"heart": "[/pulse][/color]",
	"echo": "[/outline_color][/outline_size][/fade][/color]",
	"soft": "[/color][/font_size]",
	"harsh": "[/shake][/color][/b]",
	"lick": "[/wave][/color][/i]",
	"drip": "[/wave][/color][/i]",
	"queen": "[/outline_color][/outline_size][/wave][/color][/b]",
	"prey": "[/shake][/color][/i]",
	"slow": "[/color][/i]",
	"fast": "[/color][/b]",
	"hiss": "[/shake][/color][/i]",
	"purr": "[/wave][/color][/i]",
	"laugh": "[/pulse][/color]",
	"cry": "[/wave][/color][/i]",
	"glitch": "[/shake][/tornado][/color]",
	"focus": "[/outline_color][/outline_size][/color][/b]",
	"mute": "[/i][/color][/font_size]",
	"big": "[/b][/font_size]",
	"tiny": "[/i][/font_size]",
	"clingy": "[/wave][/color][/i]",
	"gooey": "[/wave][/color][/i]",
	"brat": "[/pulse][/color][/b]",
	"punk": "[/shake][/color][/b]",
	"hyper": "[/pulse][/color][/b]",
	"velvet": "[/fade][/color][/i]",
	"predator": "[/pulse][/color][/b]",
	"sly": "[/wave][/color][/i]",
	"smug": "[/pulse][/color][/i]",
	"blunt": "[/outline_color][/outline_size][/color][/b]",
	"giantess": "[/shake][/color][/b][/font_size]",
	"regal": "[/outline_color][/outline_size][/color][/b]",
	"possessive": "[/wave][/color][/b]",
	"foot": "[/wave][/color][/i]",
}

## Typewriter chars / sec modifiers from tags present in the raw line.
const SPEED_TAGS := {
	"slow": 18.0,
	"whisper": 22.0,
	"pant": 20.0,
	"moan": 24.0,
	"fast": 72.0,
	"shout": 64.0,
	"giggle": 58.0,
	"glitch": 80.0,
}

static func has_custom_tags(raw: String) -> bool:
	for tag in TAGS.keys():
		if raw.contains("[" + tag + "]") or raw.contains("[" + tag + "="):
			return true
	return raw.contains("[name=") or raw.contains("[color=") or raw.contains("[wave") or raw.contains("[shake")


static func default_cps(raw: String, situation: String = "") -> float:
	for tag in SPEED_TAGS.keys():
		if raw.contains("[" + tag + "]"):
			return float(SPEED_TAGS[tag])
	match situation:
		"player_near_death", "losing", "drain":
			return 26.0
		"shout", "player_defeated":
			return 52.0
		_:
			return 40.0


static func extract_speaker(raw: String) -> Dictionary:
	var speaker := ""
	var body := raw
	var re := RegEx.new()
	re.compile("\\[name=([^\\]]+)\\]")
	var m := re.search(body)
	if m:
		speaker = m.get_string(1).strip_edges()
		body = re.sub(body, "", true)
	return { "speaker": speaker, "body": body }


static func expand(raw: String, situation: String = "") -> Dictionary:
	var extracted: Dictionary = extract_speaker(raw)
	var body: String = extracted["body"]
	var speaker: String = extracted["speaker"]
	if not has_custom_tags(body) and situation != "" and SITUATION_WRAP.has(situation):
		var wrap: String = str(SITUATION_WRAP[situation])
		body = "[%s]%s[/%s]" % [wrap, body, wrap]
	body = _expand_tags(body)
	body = "[center]%s[/center]" % body
	return {
		"speaker": speaker,
		"bbcode": body,
		"cps": default_cps(raw, situation),
	}


static func _expand_tags(src: String) -> String:
	var out := src
	for tag in TAGS.keys():
		var open :String= "[" + tag + "]"
		var close :String= "[/" + tag + "]"
		out = out.replace(open, str(TAGS[tag]))
		out = out.replace(close, str(CLOSE_EXTRAS[tag]))
	return out


static func help_text() -> String:
	var keys: Array = TAGS.keys()
	keys.sort()
	return "Tags: " + ", ".join(keys) + " + native [b][i][color][wave][shake][tornado][fade][rainbow][pulse][font_size][outline_size]"
