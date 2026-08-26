extends RefCounted
## HeldInput 은 액션뿐 아니라 is_key_pressed 물리 키까지 푼다.

const Held := preload("res://core/input/held_input.gd")

func run(t) -> void:
	Input.action_press("ui_left")
	t.check("액션 고착 재현", Input.is_action_pressed("ui_left"))
	Held.release_keys()
	t.check("액션 해제", not Input.is_action_pressed("ui_left"))

	var down := InputEventKey.new()
	down.keycode = KEY_W
	down.physical_keycode = KEY_W
	down.pressed = true
	Input.parse_input_event(down)
	Input.flush_buffered_events()
	t.check("물리 키 고착 재현", Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_W))
	Held.release_keys()
	t.check("물리 키 해제", not Input.is_key_pressed(KEY_W) and not Input.is_physical_key_pressed(KEY_W))
