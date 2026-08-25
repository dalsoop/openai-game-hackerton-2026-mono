class_name HeldInput
extends RefCounted
## 브라우저가 캔버스 포커스를 빼앗을 때 Godot 의 물리 키 상태를 비운다.
## 이 게임은 InputMap 이 아니라 is_key_pressed 를 읽는다. 액션만 해제하면 부족하다.

const KEYS: Array[Key] = [
	KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E, KEY_R, KEY_F, KEY_SHIFT, KEY_SPACE,
]
const BUTTONS: Array[MouseButton] = [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]


static func release_all() -> void:
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			Input.action_release(action)
	for key in KEYS:
		_release_key(key)
	for button in BUTTONS:
		_release_button(button)
	Input.flush_buffered_events()


static func _release_key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = false
	ev.echo = false
	Input.parse_input_event(ev)


static func _release_button(button: MouseButton) -> void:
	if not Input.is_mouse_button_pressed(button):
		return
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = false
	Input.parse_input_event(ev)
