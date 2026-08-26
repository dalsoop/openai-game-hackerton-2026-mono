class_name PlayerInput
extends RefCounted
## 한 틱 입력을 모은다. 패드가 켜지면 마우스 흉내 발사를 쓰지 않는다.

const LayoutKeysScript := preload("res://core/input/layout_keys.gd")
const TouchPolicy := preload("res://core/contract/touch_policy.gd")
const TouchPadScript := preload("res://games/dagul/input/touch_pad.gd")

var pad
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


func read_aim(viewport: Viewport, local_player_pos: Vector2) -> Vector2:
	var aim_world := viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	if pad.aiming():
		aim_world = local_player_pos + pad.aim_dir() * 400.0
	return aim_world


func read_primary() -> bool:
	return TouchPolicy.action_held(
		pad.is_on(), Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), pad.fire())


func read_equipment() -> bool:
	return TouchPolicy.action_held(
		pad.is_on(), Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT), pad.skill())


func poll(viewport: Viewport, local_player_pos: Vector2) -> Dictionary:
	return build_command(
		read_move(),
		read_aim(viewport, local_player_pos),
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
	var medkit_edge: bool = edge(KEY_E) or bool(pad.consume_medkit())
	var cmd := {
		"move": move, "aim": aim,
		"primary": primary,
		"primary_pressed": primary and not previous_left_mouse,
		"equipment": equipment_held,
		"equipment_pressed": equipment_held and not previous_right_mouse,
		"equipment_released": not equipment_held and previous_right_mouse,
		"ultimate": ultimate_edge, "mobility": mobility_edge,
		"hop": edge(KEY_SPACE), "medkit": medkit_edge,
		"reload": edge(KEY_R), "finish": edge(KEY_F),
		"emote": _read_emote(),
	}
	previous_right_mouse = equipment_held
	previous_left_mouse = primary
	return cmd


func _read_emote() -> int:
	for emote_index in range(4):
		if edge(KEY_1 + emote_index):
			return emote_index
	return -1
