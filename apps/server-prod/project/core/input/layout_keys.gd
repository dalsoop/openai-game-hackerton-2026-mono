extends RefCounted
## 웹 정본: KeyboardEvent.code → Godot physical_keycode.
## 이동은 자리만 본다. 글자(keycode/unicode/IME)는 읽지 않는다.

static func held(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)


static func seat_label(key: Key) -> String:
	var labeled: Key = DisplayServer.keyboard_get_label_from_physical(key)
	if labeled == KEY_NONE:
		labeled = key
	var text := OS.get_keycode_string(labeled)
	return text if not text.is_empty() else OS.get_keycode_string(key)


static func move_axis() -> Vector2:
	var axis := Vector2(
		float(held(KEY_D)) - float(held(KEY_A)),
		float(held(KEY_S)) - float(held(KEY_W))
	)
	if axis.length_squared() > 1.0:
		axis = axis.normalized()
	return axis
