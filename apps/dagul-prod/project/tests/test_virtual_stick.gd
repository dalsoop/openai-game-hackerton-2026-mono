extends RefCounted
## 조준 스틱의 탭 판정. 짧고 안 끈 터치만 한 발이 된다.
## 애드온(tools/godot-touch-controls)은 심링크라 체크아웃에 따라 res:// 로 안 잡힌다.
## 그래서 같은 규칙을 들고 있는 앱 쪽 계약을 테스트한다.

const Policy := preload("res://core/contract/touch_policy.gd")

const TRAVEL := 24.0
const MSEC := 250

func run(t) -> void:
	t.check("가만히 툭 치면 탭", Policy.is_aim_tap(0.0, 40, TRAVEL, MSEC) == true)
	t.check("살짝 흔들려도 탭", Policy.is_aim_tap(9.0, 120, TRAVEL, MSEC) == true)
	t.check("멀리 끌면 탭 아님", Policy.is_aim_tap(180.0, 60, TRAVEL, MSEC) == false)
	t.check("오래 누르면 탭 아님", Policy.is_aim_tap(2.0, 900, TRAVEL, MSEC) == false)
	t.check("멀리 오래면 탭 아님", Policy.is_aim_tap(180.0, 900, TRAVEL, MSEC) == false)
	t.check("거리 경계는 탭", Policy.is_aim_tap(TRAVEL, 100, TRAVEL, MSEC) == true)
	t.check("거리 경계 넘으면 탭 아님", Policy.is_aim_tap(TRAVEL + 0.5, 100, TRAVEL, MSEC) == false)
	t.check("시간 경계는 탭", Policy.is_aim_tap(1.0, MSEC, TRAVEL, MSEC) == true)
	t.check("시간 경계 넘으면 탭 아님", Policy.is_aim_tap(1.0, MSEC + 1, TRAVEL, MSEC) == false)
