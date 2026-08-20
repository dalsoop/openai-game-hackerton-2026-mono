extends Control

@export var caption := "버튼"
@export var accent := Color("#ffd166")
@export var font_size := 26

var held := false

var _edge_pending := false
var _touch_index := -1
var _font: Font = null

const _MOUSE_ID := -1000

func _ready() -> void:
    mouse_filter = MOUSE_FILTER_STOP

func set_font(font: Font) -> void:
    _font = font
    queue_redraw()

func consume_press() -> bool:
    if _edge_pending:
        _edge_pending = false
        return true
    return false

func reset() -> void:
    _touch_index = -1
    held = false
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        _press(event.index)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _press(_MOUSE_ID)
        accept_event()

func _input(event: InputEvent) -> void:
    if _touch_index == -1:
        return
    if not is_visible_in_tree():
        reset()
        return
    if event is InputEventScreenTouch and not event.pressed and event.index == _touch_index:
        reset()
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _touch_index == _MOUSE_ID:
        reset()
        accept_event()

func _press(id: int) -> void:
    if _touch_index != -1:
        return
    _touch_index = id
    held = true
    _edge_pending = true
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var radius := minf(size.x, size.y) * 0.5 - 3.0
    draw_circle(center, radius, Color(accent, 0.34 if held else 0.14))
    draw_arc(center, radius, 0.0, TAU, 44, Color(accent, 0.95 if held else 0.60), 3.0, true)
    var font := _font if _font != null else ThemeDB.fallback_font
    var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
    var origin := center + Vector2(-text_size.x * 0.5, text_size.y * 0.36)
    draw_string(font, origin + Vector2(1.5, 1.5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.0, 0.0, 0.0, 0.6))
    draw_string(font, origin, caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 1.0, 1.0, 0.96))
