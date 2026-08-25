extends RefCounted
## 웹과 같이 자리(physical)만 이동으로 친다. 글자·자모는 무시한다.

const Held := preload("res://core/input/held_input.gd")
const Keys := preload("res://core/input/layout_keys.gd")


func run(t) -> void:
	_reset()
	t.check("대기 시 이동 없음", Keys.move_axis() == Vector2.ZERO)

	_press(KEY_W, KEY_W)
	t.check("QWERTY W 자리는 위", Keys.held(KEY_W) and Keys.move_axis().y < 0.0)
	_reset()

	# 한글 IME: 글자는 ㅈ, 자리는 여전히 W (KeyboardEvent.code = KeyW).
	_press(KEY_W, KEY_NONE, 0x3148)
	t.check("한글 ㅈ이어도 자리 W 는 위", Keys.held(KEY_W) and Keys.move_axis().y < 0.0)
	t.check("한글 자모만으로는 안 움직임", not _jamo_only_moves())
	_reset()

	_press(KEY_A, KEY_NONE, 0x3141)
	t.check("한글 ㅁ이어도 자리 A 는 왼쪽", Keys.held(KEY_A) and Keys.move_axis().x < 0.0)
	_reset()

	_press(KEY_S, KEY_NONE, 0x3134)
	t.check("한글 ㄴ이어도 자리 S 는 아래", Keys.held(KEY_S) and Keys.move_axis().y > 0.0)
	_reset()

	_press(KEY_D, KEY_NONE, 0x3147)
	t.check("한글 ㅇ이어도 자리 D 는 오른쪽", Keys.held(KEY_D) and Keys.move_axis().x > 0.0)
	_reset()

	# AZERTY: WASD 자리에 Z 글자.
	_press(KEY_W, KEY_Z)
	t.check("AZERTY 자리 W(글자 Z) 는 위", Keys.held(KEY_W) and Keys.move_axis().y < 0.0)
	_reset()

	# AZERTY: 글자 W 는 다른 자리(물리 Z). 자리 정본이면 위가 아니다.
	_press(KEY_Z, KEY_W)
	t.check("AZERTY 글자 W(자리 Z) 는 위가 아님", not Keys.held(KEY_W) and Keys.move_axis() == Vector2.ZERO)
	_reset()

	_press(KEY_W, KEY_W)
	_press(KEY_D, KEY_D)
	var diag := Keys.move_axis()
	t.check("대각 정규화", is_equal_approx(diag.length(), 1.0) and diag.x > 0.0 and diag.y < 0.0)
	_reset()

	_press(KEY_W, KEY_NONE, 0x3148)
	Held.release_all()
	t.check("해제 후 이동 없음", not Keys.held(KEY_W) and Keys.move_axis() == Vector2.ZERO)


func _jamo_only_moves() -> bool:
	_reset()
	var jamo := InputEventKey.new()
	jamo.keycode = KEY_NONE
	jamo.physical_keycode = KEY_NONE
	jamo.unicode = 0x3148
	jamo.pressed = true
	Input.parse_input_event(jamo)
	Input.flush_buffered_events()
	var moved := Keys.held(KEY_W)
	_reset()
	return moved


func _press(physical: Key, logical: Key, unicode: int = 0) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = logical
	ev.unicode = unicode
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _reset() -> void:
	Held.release_all()
