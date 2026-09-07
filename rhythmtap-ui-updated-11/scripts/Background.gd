extends Control
# =============================================================================
# Background.gd — ALPHA BUILD
# =============================================================================
# Draws the full-screen enemy art behind everything else, with a subtle pulse
# on every beat and a brightness/scale flicker tied to enemy state.
#
# ASSET LOADING:
#   Expects images at res://enemy_images/<type_name>/<state>.<ext>
#   where state is one of "idle", "attack", "hurt" and ext is one of
#   png/jpg/jpeg/webp. Missing files silently fall back to
#   res://backgrounds/image1.jpg — if you add a new enemy and forget art,
#   it won't crash, it'll just show the fallback image for whatever's missing.
#
#   Loading happens on background threads (Thread.new()) so swapping enemies
#   doesn't hitch the main thread. This is probably overkill for small alpha
#   images but doesn't hurt — revisit if asset loading becomes more complex
#   (e.g. animated sprites instead of static images per state).
#
# STATE:
#   current_state is driven by GameManager's enemy_state_changed signal
#   ("idle" / "attack" / "hurt"). There's no animation between states yet —
#   it's a hard texture swap. Could become a tween/crossfade later.
# =============================================================================

var pulse:     float = 0.0
var img_scale: float = 1.0

var enemy_textures:  Dictionary = {}   # state -> ImageTexture
var current_state:   String     = "idle"
var active_type:     String     = ""
var _loading_count:  int        = 0    # threads in flight, currently unread but useful for debugging

func _ready():
	set_process(true)

# Called by Main.gd whenever GameManager emits enemy_type_swapped.
# Skips reloading if it's the same enemy (e.g. redundant calls during init).
func load_enemy_assets(type_name: String):
	if type_name == active_type:
		return
	active_type     = type_name
	enemy_textures.clear()
	current_state   = "idle"

	var states     = ["idle", "attack", "hurt"]
	var extensions = [".png", ".jpg", ".jpeg", ".webp"]
	var base_dir   = "res://enemy_images/" + type_name + "/"
	var fallback   = "res://backgrounds/image1.jpg"

	for state in states:
		var path_found = ""
		for ext in extensions:
			var p = base_dir + state + ext
			if ResourceLoader.exists(p):
				path_found = p
				break
		if path_found == "" and ResourceLoader.exists(fallback):
			path_found = fallback
		if path_found != "":
			_loading_count += 1
			var thread = Thread.new()
			thread.start(_thread_load.bind(state, path_found, thread))

func _thread_load(state: String, path: String, thread: Thread):
	var img = Image.load_from_file(path)
	call_deferred("_on_loaded", state, img, thread)

func _on_loaded(state: String, img: Image, thread: Thread):
	thread.wait_to_finish()
	_loading_count -= 1
	if img:
		enemy_textures[state] = ImageTexture.create_from_image(img)

# Called by Main.gd on every beat — purely a visual pulse, no gameplay effect.
func on_beat(_beat_num: int):
	pulse     = 1.0
	img_scale = 1.05

func on_enemy_state_changed(new_state: String):
	current_state = new_state

func _process(delta: float):
	pulse     = max(0.0, pulse - delta * 3.0)
	img_scale = lerp(img_scale, 1.0, delta * 8.0)
	queue_redraw()

func _draw():
	var w = size.x
	var h = size.y

	draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.03, 0.05, 1.0))

	var tex = enemy_textures.get(current_state, null)
	if tex == null:
		tex = enemy_textures.get("idle", null)  # fall back to idle if current state has no art
	if tex == null:
		return  # nothing loaded yet — just show the background fill above

	var ts      = tex.get_size()
	var scale   = min(w / ts.x, h / ts.y) * img_scale
	var draw_w  = ts.x * scale
	var draw_h  = ts.y * scale
	var ox      = (w - draw_w) / 2.0
	var oy      = (h - draw_h) / 2.0
	var bright  = 0.55 + pulse * 0.20
	draw_texture_rect(tex, Rect2(ox, oy, draw_w, draw_h), false,
		Color(bright, bright, bright, 1.0))
