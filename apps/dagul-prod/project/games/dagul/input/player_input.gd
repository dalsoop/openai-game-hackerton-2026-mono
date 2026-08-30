class_name PlayerInput
extends RefCounted
## 한 틱 입력을 모은다. 패드가 켜지면 마우스 흉내 발사를 쓰지 않는다.

const LayoutKeysScript := preload("res://core/input/layout_keys.gd")
const TouchPolicy := preload("res://core/contract/touch_policy.gd")
const TouchPadScript := preload("res://games/dagul/input/touch_pad.gd")

## 패드 애드온은 심링크라 체크아웃에 따라 없을 수 있다. preload 하면 게임이 통째로 죽으므로
## 상수만 여기 둔다. tools/godot-touch-controls/touch_controls.gd 의 AIM_RANGE 와 같은 값.
const AIM_RANGE := 400.0

var pad: TouchPadScript
var previous_keys: Dictionary = {}
var previous_right_mouse: bool = false
var previous_left_mouse: bool = false


func _init(touch_pad = null) -> void:
	pad = touch_pad if touch_pad != null else TouchPadScript.new()


func reset() -> void:
	previous_keys.clear()
	previous_right_mouse = false
	previous_left_mouse = false


func bind_layer(layer: CanvasLayer) -> void:
	pad.bind(layer)


func edge(keycode: int) -> bool:
	var now := LayoutKeysScript.held(keycode as Key)
	var was := bool(previous_keys.get(keycode, false))
	previous_keys[keycode] = now
	return now and not was


func read_move() -> Vector2:
	var keyboard_move := LayoutKeysScript.move_axis()
	if keyboard_move.length() > 0.1:
		return keyboard_move
	return pad.move()


## 패드가 켜지면 마우스 좌표는 의미가 없다. 스틱을 놓아도 마지막 방향을 계속 본다.
func read_aim(space: CanvasItem, local_player_pos: Vector2) -> Vector2:
	if pad.is_on():
		return local_player_pos + pad.aim_last() * AIM_RANGE
	return space.get_global_mouse_position()


func read_primary() -> bool:
	return TouchPolicy.action_held(
		pad.is_on(), Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), pad.fire())


## 스킬 버튼은 패드에서 뺐다. 마우스 우클릭만 남는다.
func read_equipment() -> bool:
	return not pad.is_on() and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)


func poll(space: CanvasItem, local_player_pos: Vector2) -> Dictionary:
	return build_command(
		read_move(),
		read_aim(space, local_player_pos),
		read_primary(),
		read_equipment())


## 설정이 열려 있을 때. 전투 입력은 버리고 키 엣지만 삼켜 메뉴를 닫아도 한 틱이 나가지 않게 한다.
func idle_command(aim: Vector2) -> Dictionary:
	for keycode in [KEY_Q, KEY_SHIFT, KEY_E, KEY_SPACE, KEY_R, KEY_F, KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_4]:
		previous_keys[keycode] = LayoutKeysScript.held(keycode as Key)
	previous_right_mouse = false
	previous_left_mouse = false
	return {
		"move": Vector2.ZERO, "aim": aim,
		"primary": false, "primary_pressed": false,
		"equipment": false, "equipment_pressed": false, "equipment_released": false,
		"ultimate": false, "mobility": false,
		"hop": false, "medkit": false, "reload": false, "finish": false,
		"emote": -1,
	}


func build_command(move: Vector2, aim: Vector2, primary: bool, equipment_held: bool) -> Dictionary:
	var ultimate_edge: bool = edge(KEY_Q) or bool(pad.consume_ult())
	var mobility_edge: bool = edge(KEY_SHIFT) or bool(pad.consume_dash())
	var medkit_edge: bool = edge(KEY_E)
	# 탭은 한 틱짜리 발사다. 엣지라 여기서 딱 한 번만 읽는다.
	var tap: bool = bool(pad.consume_aim_tap())
	var primary_now: bool = primary or tap
	var cmd := {
		"move": move, "aim": aim,
		"primary": primary_now,
		"primary_pressed": tap or (primary_now and not previous_left_mouse),
		"equipment": equipment_held,
		"equipment_pressed": equipment_held and not previous_right_mouse,
		"equipment_released": not equipment_held and previous_right_mouse,
		"ultimate": ultimate_edge, "mobility": mobility_edge,
		"hop": edge(KEY_SPACE), "medkit": medkit_edge,
		"reload": edge(KEY_R), "finish": edge(KEY_F),
		"emote": _read_emote(),
	}
	previous_right_mouse = equipment_held
	previous_left_mouse = primary_now
	return cmd


func _read_emote() -> int:
	for emote_index in range(4):
		if edge(KEY_1 + emote_index):
			return emote_index
	return -1
