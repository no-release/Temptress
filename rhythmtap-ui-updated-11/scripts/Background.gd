extends Control
# =============================================================================
# Background.gd — combat backdrop + enemy art
# =============================================================================
# Draws biome plate from bg_images, then enemy cutout (idle/attack/hurt).
# Folder aliases: troll_girl -> troll. Missing art: soft empty (no old mismatched JPGs).
# =============================================================================

var pulse:     float = 0.0
var img_scale: float = 1.0
var stagger_x: float = 0.0

var enemy_textures:  Dictionary = {}
var biome_texture:   Texture2D = null
var current_state:   String     = "idle"
var active_type:     String     = ""
var show_enemy:      bool       = true
var _loading_count:  int        = 0
var _stagger_tween:  Tween      = null

const BIOME_BG := {
	"dungeon": "res://bg_images/dungeonbg.png",
	"forest": "res://bg_images/forrestbg.png",
	"forrest": "res://bg_images/forrestbg.png",
	"swamp": "res://bg_images/cavebg.png",
	"cave": "res://bg_images/cavebg.png",
	"volcanic": "res://bg_images/dungeonbg.png",
	"palace": "res://bg_images/receptionbg.png",
}

const FOLDER_ALIAS := {
	"troll_girl": "troll",
}

func _ready():
	set_process(true)
	_load_biome_from_run()

func _load_biome_from_run() -> void:
	var biome := "dungeon"
	if ActiveRun.state and ActiveRun.state.quest:
		biome = str(ActiveRun.state.quest.biome)
	set_biome(biome)

func set_biome(biome: String) -> void:
	var path: String = BIOME_BG.get(biome.to_lower(), "res://bg_images/dungeonbg.png")
	if ResourceLoader.exists(path):
		biome_texture = load(path) as Texture2D
	else:
		biome_texture = null
	queue_redraw()

func load_enemy_assets(type_name: String):
	if type_name == active_type:
		return
	active_type     = type_name
	enemy_textures.clear()
	current_state   = "idle"
	_load_biome_from_run()

	var folder: String = FOLDER_ALIAS.get(type_name, type_name)
	var states     = ["idle", "attack", "hurt"]
	var extensions = [".png", ".webp", ".jpg", ".jpeg"]
	var base_dir   = "res://enemy_images/" + folder + "/"

	for state in states:
		var path_found = ""
		for ext in extensions:
			var p = base_dir + state + ext
			if ResourceLoader.exists(p):
				path_found = p
				break
		# Also try vn_portraits tall sheets as idle fallback
		if path_found == "" and state == "idle":
			for p2 in [
				"res://vn_portraits/%s_standing.png" % type_name,
				"res://vn_portraits/%s_neutral.png" % type_name,
				"res://vn_portraits/%s.png" % type_name,
			]:
				if ResourceLoader.exists(p2):
					path_found = p2
					break
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
	queue_redraw()

func on_beat(_beat_num: int):
	pulse     = 1.0
	img_scale = 1.05

func set_enemy_visible(v: bool) -> void:
	show_enemy = v
	queue_redraw()


func on_enemy_state_changed(new_state: String):
	current_state = new_state

func play_hit_stagger():
	if _stagger_tween and _stagger_tween.is_valid():
		_stagger_tween.kill()
	stagger_x = 0.0
	_stagger_tween = create_tween()
	_stagger_tween.tween_property(self, "stagger_x", 7.0, 0.045)
	_stagger_tween.tween_property(self, "stagger_x", -7.0, 0.07)
	_stagger_tween.tween_property(self, "stagger_x", 4.0, 0.055)
	_stagger_tween.tween_property(self, "stagger_x", 0.0, 0.07)

func _process(delta: float):
	pulse     = max(0.0, pulse - delta * 3.0)
	img_scale = lerp(img_scale, 1.0, delta * 8.0)
	queue_redraw()

func _draw():
	var w = size.x
	var h = size.y

	# Biome plate (or near-black fallback)
	if biome_texture:
		var bs = biome_texture.get_size()
		var bscale = max(w / bs.x, h / bs.y)
		var bw = bs.x * bscale
		var bh = bs.y * bscale
		var bx = (w - bw) / 2.0
		var by = (h - bh) / 2.0
		draw_texture_rect(biome_texture, Rect2(bx, by, bw, bh), false, Color(0.85, 0.85, 0.9, 1.0))
		# Soft vignette so UI stays readable
		draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.01, 0.03, 0.28))
	else:
		draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.03, 0.05, 1.0))

	if not show_enemy:
		return
	var tex = enemy_textures.get(current_state, null)
	if tex == null:
		tex = enemy_textures.get("idle", null)
	if tex == null:
		return

	var ts      = tex.get_size()
	# Tall 1080x1920 sheets have large empty padding — overscale so the FIGURE reads big.
	# Cover-ish: fill ~140% of screen height, allow sides to crop.
	var scale   = (h * 1.85) / maxf(1.0, ts.y) * img_scale
	# Keep a minimum presence on ultrawide / short windows
	var min_w_scale :float= (w * 0.95) / maxf(1.0, ts.x)
	if scale < min_w_scale * 0.55:
		scale = min_w_scale * 0.55
	var draw_w  = ts.x * scale
	var draw_h  = ts.y * scale
	var ox      = (w - draw_w) / 2.0 + stagger_x
	# Bias upward so head/torso sit in the upper 2/3 (textbox/beatbar eat the bottom)
	var oy      = (h - draw_h) * 0.15
	var bright  = 0.78 + pulse * 0.22
	draw_texture_rect(tex, Rect2(ox, oy, draw_w, draw_h), false,
		Color(bright, bright, bright, 1.0))
