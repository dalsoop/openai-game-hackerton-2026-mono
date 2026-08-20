extends Control

signal output_changed(value: Vector2)

@export var base_radius := 125.0
@export var knob_radius := 54.0
@export var deadzone := 0.12
@export var ring_color := Color(1.0, 1.0, 1.0, 0.34)
@export var fill_color := Color(1.0, 1.0, 1.0, 0.07)

var output := Vector2.ZERO
var active := false

var _touch_index := -1
var _knob_offset := Vector2.ZERO

const _MOUSE_ID := -1000

func _ready() -> void:
    mouse_filter = MOUSE_FILTER_STOP

func reset() -> void:
    _touch_index = -1
    active = false
    output = Vector2.ZERO
    _knob_offset = Vector2.ZERO
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        _begin(event.index, event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _begin(_MOUSE_ID, event.position)
        accept_event()

func _input(event: InputEvent) -> void:
    if _touch_index == -1:
        return
    if not is_visible_in_tree():
        reset()
        return
    if event is InputEventScreenDrag and event.index == _touch_index:
        _drag(_to_local_point(event.position))
        accept_event()
    elif event is InputEventMouseMotion and _touch_index == _MOUSE_ID:
        _drag(_to_local_point(event.position))
        accept_event()
    elif event is InputEventScreenTouch and not event.pressed and event.index == _touch_index:
        reset()
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _touch_index == _MOUSE_ID:
        reset()
        accept_event()

func _begin(id: int, local_point: Vector2) -> void:
    if _touch_index != -1:
        return
    _touch_index = id
    active = true
    _drag(local_point)

func _drag(local_point: Vector2) -> void:
    var center := size * 0.5
    var offset := local_point - center
    if offset.length() > base_radius:
        offset = offset.normalized() * base_radius
    _knob_offset = offset
    var raw := offset / base_radius
    output = raw if raw.length() >= deadzone else Vector2.ZERO
    output_changed.emit(output)
    queue_redraw()

func _to_local_point(viewport_point: Vector2) -> Vector2:
    return get_global_transform_with_canvas().affine_inverse() * viewport_point

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, base_radius, fill_color)
    draw_arc(center, base_radius, 0.0, TAU, 56, ring_color, 3.0, true)
    var knob_alpha := 0.30 if active else 0.16
    draw_circle(center + _knob_offset, knob_radius, Color(1.0, 1.0, 1.0, knob_alpha))
    draw_arc(center + _knob_offset, knob_radius, 0.0, TAU, 40, Color(ring_color, 0.6), 2.0, true)
