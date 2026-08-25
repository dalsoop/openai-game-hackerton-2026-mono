extends RefCounted
class_name GameFont

const PATH := "res://assets/fonts/Galmuri11.ttf"
const BOLD_PATH := "res://assets/fonts/Galmuri11-Bold.ttf"

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
	var loaded = load(PATH)
	if loaded is Font:
		_cached = loaded
		return _cached
	_cached = _load_raw(PATH)
	if _cached != null:
		print("[gangup] font raw %s" % PATH)
		return _cached
	print("[gangup] font fallback")
	return ThemeDB.fallback_font

static func get_bold_font() -> Font:
	if _bold_cached != null:
		return _bold_cached
	if _bold_tried:
		return get_font()
	_bold_tried = true
	var loaded = load(BOLD_PATH)
	if loaded is Font:
		_bold_cached = loaded
		return _bold_cached
	_bold_cached = _load_raw(BOLD_PATH)
	if _bold_cached != null:
		print("[gangup] font bold raw %s" % BOLD_PATH)
		return _bold_cached
	return get_font()

static func _load_raw(path: String) -> Font:
	var abs_path := ProjectSettings.globalize_path(path)
	var ff := FontFile.new()
	if ff.load_dynamic_font(abs_path) == OK:
		return ff
	return null
