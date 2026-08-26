class_name HeldInput
extends RefCounted
## 탭이 숨으면 물리 키 상태를 비운다. 이 게임은 InputMap 이 아니라
## is_physical_key_pressed 를 읽으므로 액션만 해제하면 부족하다.
## 마우스 버튼은 풀지 않는다. 사격 클릭과 섞이면 이동·발사가 같이 끊긴다.

const KEYS: Array[Key] = [
	KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E, KEY_R, KEY_F, KEY_SHIFT, KEY_SPACE,
]


static func release_keys() -> void:
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			Input.action_release(action)
	for key in KEYS:
		_release_key(key)
	Input.flush_buffered_events()


static func release_all() -> void:
	release_keys()


static func _release_key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = false
	ev.echo = false
	Input.parse_input_event(ev)
