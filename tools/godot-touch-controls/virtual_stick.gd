extends Control

signal output_changed(value: Vector2)

@export var base_radius := 125.0
@export var knob_radius := 54.0
@export var deadzone := 0.12
@export var ring_color := Color(1.0, 1.0, 1.0, 0.34)
@export var fill_color := Color(1.0, 1.0, 1.0, 0.07)
## 탭 판정 — 이만큼 안 끌고 이 시간 안에 떼면 탭이다.
@export var tap_max_travel := 24.0
@export var tap_max_msec := 250

var output := Vector2.ZERO
var active := false
## 마지막으로 밀었던 방향. 손을 떼도 남아서 "지금 보는 방향"이 된다.
var last_dir := Vector2.RIGHT
## 스틱을 원점으로 잡고 그릴지. 조준 스틱만 켠다.
var show_aim_indicator := false

var _touch_index := -1
var _knob_offset := Vector2.ZERO
var _origin := Vector2.ZERO
var _press_msec := 0
var _travel := 0.0
var _tap_pending := false

const _MOUSE_ID := -1000


## 끈 거리·시간이 둘 다 임계값 안이면 탭. 순수 함수라 테스트가 붙는다.
## 앱 쪽 core/contract/touch_policy.gd 의 is_aim_tap 과 같은 규칙이다 (애드온은 앱을 preload 하지 않는다).
static func is_tap(travel: float, elapsed_msec: int, max_travel: float, max_msec: int) -> bool:
	return travel <= max_travel and elapsed_msec <= max_msec


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP


## 방향은 남긴다 — 설정창을 닫고 돌아와도 보던 쪽을 계속 본다.
func reset() -> void:
	_touch_index = -1
	active = false
	output = Vector2.ZERO
	_knob_offset = Vector2.ZERO
	_travel = 0.0
	_tap_pending = false
	queue_redraw()


func consume_tap() -> bool:
	if _tap_pending:
		_tap_pending = false
		return true
	return false


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
		_release()
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _touch_index == _MOUSE_ID:
		_release()
		accept_event()


## 누른 지점을 원점으로 삼는다. 예전처럼 노브를 손가락으로 끌어당기지 않는다 —
## 가장자리를 처음 찍었다고 최대 편향이 나오면 안 된다.
func _begin(id: int, local_point: Vector2) -> void:
	if _touch_index != -1:
		return
	_touch_index = id
	active = true
	_origin = local_point
	_press_msec = Time.get_ticks_msec()
	_travel = 0.0
	_tap_pending = false
	_knob_offset = Vector2.ZERO
	output = Vector2.ZERO
	output_changed.emit(output)
	queue_redraw()


func _drag(local_point: Vector2) -> void:
	var offset := local_point - _origin
	_travel = maxf(_travel, offset.length())
	if offset.length() > base_radius:
		offset = offset.normalized() * base_radius
	_knob_offset = offset
	var raw := offset / base_radius
	output = raw if raw.length() >= deadzone else Vector2.ZERO
	if output != Vector2.ZERO:
		last_dir = output.normalized()
	output_changed.emit(output)
	queue_redraw()


func _release() -> void:
	var elapsed := Time.get_ticks_msec() - _press_msec
	var tapped := is_tap(_travel, elapsed, tap_max_travel, tap_max_msec)
	reset()
	_tap_pending = tapped


func _to_local_point(viewport_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_point


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius, fill_color)
	draw_arc(center, base_radius, 0.0, TAU, 56, ring_color, 3.0, true)
	if show_aim_indicator and not active:
		_draw_aim_hint(center)
	var origin := _origin if active else center
	var knob_alpha := 0.30 if active else 0.16
	draw_circle(origin + _knob_offset, knob_radius, Color(1.0, 1.0, 1.0, knob_alpha))
	draw_arc(origin + _knob_offset, knob_radius, 0.0, TAU, 40, Color(ring_color, 0.6), 2.0, true)


## 손을 뗀 뒤에도 어디를 보는지 보여준다. 탭하면 이 방향으로 나간다.
func _draw_aim_hint(center: Vector2) -> void:
	var tip := center + last_dir * (base_radius - 12.0)
	draw_line(center + last_dir * knob_radius, tip, Color(1.0, 1.0, 1.0, 0.22), 4.0, true)
	draw_circle(tip, 7.0, Color(1.0, 1.0, 1.0, 0.28))
