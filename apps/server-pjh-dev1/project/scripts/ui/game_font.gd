extends RefCounted
class_name GameFont

const PATH := "res://assets/fonts/Galmuri11.ttf"
const BOLD_PATH := "res://assets/fonts/Galmuri11-Bold.ttf"

static var _cached: Font = null
static var _bold_cached: Font = null

static func get_font() -> Font:
    if _cached == null:
        _cached = load(PATH)
    return _cached

static func get_bold_font() -> Font:
    if _bold_cached == null:
        _bold_cached = load(BOLD_PATH)
    return _bold_cached
