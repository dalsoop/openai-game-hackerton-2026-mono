extends RefCounted
class_name GameFont

const PATH := "res://core/assets/fonts/Galmuri11.ttf"
const BOLD_PATH := "res://core/assets/fonts/Galmuri11-Bold.ttf"
const FALLBACK_PATH := "res://core/assets/fonts/GmarketSansMedium.otf"

static var _cached: Font = null
static var _bold_cached: Font = null
static var _tried := false
static var _bold_tried := false

static func get_font() -> Font:
	if _cached != null:
		return _cached
	if _tried:
		return ThemeDB.fallback_font
	_tried = true
	_cached = _load_font(PATH)
	if _cached != null:
		return _cached
	_cached = _load_font(FALLBACK_PATH)
	if _cached != null:
		return _cached
	return ThemeDB.fallback_font

static func get_bold_font() -> Font:
	if _bold_cached != null:
		return _bold_cached
	if _bold_tried:
		return get_font()
	_bold_tried = true
	_bold_cached = _load_font(BOLD_PATH)
	if _bold_cached != null:
		return _bold_cached
	return get_font()

static func _load_font(path: String) -> Font:
	var loaded = load(path)
	if loaded is Font:
		return loaded
	var abs_path := ProjectSettings.globalize_path(path)
	var ff := FontFile.new()
	if ff.load_dynamic_font(abs_path) == OK:
		return ff
	return null
