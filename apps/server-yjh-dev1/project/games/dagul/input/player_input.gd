class_name PlayerInput
extends RefCounted

## Builds per-tick input commands from keyboard + touch.

const LayoutKeysScript := preload("res://core/input/layout_keys.gd")

var previous_keys: Dictionary = {}
var previous_right_mouse: bool = false
var previous_left_mouse: bool = false

var touch: CanvasLayer  # nullable


func _init(touch_layer: CanvasLayer = null) -> void:
	touch = touch_layer


func edge(keycode: int) -> bool:
	var now := LayoutKeysScript.held(keycode as Key)
	var was := bool(previous_keys.get(keycode, false))
	previous_keys[keycode] = now
	return now and not was


func read_move() -> Vector2:
	var keyboard_move := LayoutKeysScript.move_axis()
	if touch != null and keyboard_move.length() <= 0.1:
		return touch.move
	return keyboard_move


func read_aim(viewport: Viewport, local_player_pos: Vector2) -> Vector2:
	var aim_world := viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	if touch != null and touch.aiming:
		aim_world = local_player_pos + touch.aim_dir * 400.0
	return aim_world


func read_primary() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or (touch != null and touch.fire)


func read_equipment() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or (touch != null and touch.skill)


func read_dash() -> bool:
	return LayoutKeysScript.held(KEY_SHIFT) or (touch != null and touch.dash_held)


func read_use() -> bool:
	return LayoutKeysScript.held(KEY_E) or (touch != null and touch.medkit_held)


func build_command(move: Vector2, aim: Vector2, primary: bool, equipment_held: bool) -> Dictionary:
	var ultimate_edge := edge(KEY_Q)
	var mobility_edge := edge(KEY_SHIFT)
	var hop_edge := edge(KEY_SPACE)
	var medkit_edge := edge(KEY_E)
	var reload_edge := edge(KEY_R)
	if touch != null:
		ultimate_edge = touch.consume_ult() or ultimate_edge
		mobility_edge = touch.consume_dash() or mobility_edge
		medkit_edge = touch.consume_medkit() or medkit_edge
	var cmd := {
		"move": move, "aim": aim,
		"primary": primary,
		"primary_pressed": primary and not previous_left_mouse,
		"equipment": equipment_held,
		"equipment_pressed": equipment_held and not previous_right_mouse,
		"equipment_released": not equipment_held and previous_right_mouse,
		"ultimate": ultimate_edge, "mobility": mobility_edge,
		"hop": hop_edge, "medkit": medkit_edge,
		"reload": reload_edge, "finish": edge(KEY_F)
	}
	previous_right_mouse = equipment_held
	previous_left_mouse = primary
	return cmd
