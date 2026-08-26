extends RefCounted
## 웹 데스크톱에 가상 패드를 덮지 않는다.

const Policy := preload("res://core/contract/touch_policy.gd")

func run(t) -> void:
	t.check("모바일은 패드 켬", Policy.wants_overlay(true, true, false) == true)
	t.check("웹+거친 포인터는 패드 켬", Policy.wants_overlay(false, true, true) == true)
	t.check("웹 데스크톱은 패드 끔", Policy.wants_overlay(false, true, false) == false)
	t.check("네이티브 터치는 패드 켬", Policy.wants_overlay(false, false, true) == true)
	t.check("패드 켜면 마우스 발사 무시", Policy.action_held(true, true, false) == false)
	t.check("패드 켜면 공격 버튼만", Policy.action_held(true, true, true) == true)
	t.check("패드 끄면 마우스 발사", Policy.action_held(false, true, false) == true)
	t.check("패드 꺼도 패드 발사", Policy.action_held(false, false, true) == true)
