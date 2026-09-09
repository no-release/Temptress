extends Node
# Readable OFL typefaces. Tries res://fonts, then user://fonts, then downloads
# from the Google Fonts GitHub mirror. Arcade Classic stays as last-resort fallback.

const FONT_DIR := "user://fonts"
const SOURCES := {
	"AtkinsonHyperlegible-Regular.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegible/AtkinsonHyperlegible-Regular.ttf",
	"AtkinsonHyperlegible-Bold.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegible/AtkinsonHyperlegible-Bold.ttf",
	"Cinzel-wght.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/Cinzel%5Bwght%5D.ttf",
	"Lora-wght.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/lora/Lora%5Bwght%5D.ttf",
}

var font_ui: Font = null
var font_ui_bold: Font = null
var font_title: Font = null
var font_body: Font = null
var theme: Theme = null

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(FONT_DIR)
	_load_available()
	_apply_root_theme()
	_fetch_missing()

func _res_path(name: String) -> String:
	return "res://fonts/%s" % name

func _user_path(name: String) -> String:
	return "%s/%s" % [FONT_DIR, name]

func _load_font(name: String) -> Font:
	for path in [_res_path(name), _user_path(name)]:
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			var font := FontFile.new()
			var err := font.load_dynamic_font(path)
			if err == OK:
				return font
	return null

func _load_available() -> void:
	font_ui = _load_font("AtkinsonHyperlegible-Regular.ttf")
	font_ui_bold = _load_font("AtkinsonHyperlegible-Bold.ttf")
	font_title = _load_font("Cinzel-wght.ttf")
	font_body = _load_font("Lora-wght.ttf")
	var arcade_path := "res://ARCADECLASSIC.TTF"
	var arcade: Font = null
	if ResourceLoader.exists(arcade_path):
		arcade = load(arcade_path) as Font
	if font_ui == null:
		font_ui = arcade
	if font_ui_bold == null:
		font_ui_bold = font_ui
	if font_title == null:
		font_title = font_ui
	if font_body == null:
		font_body = font_ui

func _build_theme() -> Theme:
	var t := Theme.new()
	if font_ui:
		t.default_font = font_ui
		t.default_font_size = 18
		t.set_font("font", "Label", font_body if font_body else font_ui)
		t.set_font_size("font_size", "Label", 18)
		t.set_font("font", "Button", font_ui_bold if font_ui_bold else font_ui)
		t.set_font_size("font_size", "Button", 20)
		t.set_font("normal_font", "RichTextLabel", font_body if font_body else font_ui)
		t.set_font("italics_font", "RichTextLabel", font_body if font_body else font_ui)
		t.set_font("bold_font", "RichTextLabel", font_ui_bold if font_ui_bold else font_ui)
		t.set_font_size("normal_font_size", "RichTextLabel", 20)
		t.set_font_size("bold_font_size", "RichTextLabel", 20)
		t.set_font_size("italics_font_size", "RichTextLabel", 20)
	t.set_color("font_color", "Button", Color(1, 0.80, 0.96, 1))
	t.set_color("font_hover_color", "Button", Color(1, 0.68, 0.97, 1))
	return t

func _apply_root_theme() -> void:
	theme = _build_theme()
	var root := get_tree().root
	if root:
		root.theme = theme

func apply_title(label: Label, size: int = 36) -> void:
	if label == null:
		return
	if font_title:
		label.add_theme_font_override("font", font_title)
	label.add_theme_font_size_override("font_size", size)

func apply_ui(node: Control, size: int = 18) -> void:
	if node == null:
		return
	if font_ui:
		node.add_theme_font_override("font", font_ui)
	node.add_theme_font_size_override("font_size", size)

func _fetch_missing() -> void:
	for name in SOURCES.keys():
		if _load_font(name) != null:
			continue
		_download(name, str(SOURCES[name]))

func _download(name: String, url: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.timeout = 20.0
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200 or body.size() < 1000:
			push_warning("FontKit: failed to fetch %s (%s %s)" % [name, result, code])
			return
		var path := _user_path(name)
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			return
		f.store_buffer(body)
		f.close()
		_load_available()
		_apply_root_theme()
	)
	var err := http.request(url)
	if err != OK:
		http.queue_free()
