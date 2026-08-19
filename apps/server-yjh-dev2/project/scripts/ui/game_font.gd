extends RefCounted
class_name GameFont

const PATH := "res://assets/fonts/GmarketSansMedium.otf"

static var _cached: Font = null

static func get_font() -> Font:
    if _cached == null:
        _cached = load(PATH)
    return _cached
