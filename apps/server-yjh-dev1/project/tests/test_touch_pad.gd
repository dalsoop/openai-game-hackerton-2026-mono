extends RefCounted
## TouchPad 는 레이어가 없거나 꺼져 있으면 발사를 주지 않는다.
## --script 러너는 global class_name 이 비어 있으므로 preload 로 붙인다.

const TouchPadScript := preload("res://games/dagul/input/touch_pad.gd")
const PlayerInputScript := preload("res://games/dagul/input/player_input.gd")

func run(t) -> void:
	var pad = TouchPadScript.new()
	t.check("미바인딩은 꺼짐", pad.is_on() == false)
	t.check("미바인딩은 발사 없음", pad.fire() == false)
	t.check("미바인딩은 스킬 없음", pad.skill() == false)
	t.check("미바인딩 이동은 0", pad.move() == Vector2.ZERO)
	var inp = PlayerInputScript.new(pad)
	t.check("패드 꺼면 마우스만", inp.read_primary() == Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	var idle: Dictionary = inp.idle_command(Vector2(3, 4))
	t.check("유휴 이동은 0", idle["move"] == Vector2.ZERO)
	t.check("유휴 발사는 꺼짐", idle["primary"] == false)
	t.check("유휴 대시는 꺼짐", idle["mobility"] == false)
	t.check("유휴 조준은 유지", idle["aim"] == Vector2(3, 4))
	t.check("유휴 이모트는 없음", int(idle.get("emote", 0)) == -1)
