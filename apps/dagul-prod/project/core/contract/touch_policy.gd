extends RefCounted
## 가상 패드 표시 여부 — 웹 데스크톱은 거친 포인터(터치폰)일 때만 켠다.

static func wants_overlay(is_mobile: bool, is_web: bool, pointer_coarse: bool) -> bool:
	if is_mobile:
		return true
	if is_web:
		return pointer_coarse
	return pointer_coarse


## 패드가 켜진 동안 터치는 LMB 로 흉내 난다. 조준 스틱을 밀면 그게 곧 발사다.
static func action_held(pad_on: bool, mouse_held: bool, pad_held: bool) -> bool:
	if pad_on:
		return pad_held
	return mouse_held or pad_held

## 조준 스틱을 툭 친 건지 민 건지. 끈 거리와 누른 시간이 둘 다 임계값 안이면 탭 —
## 탭은 마지막으로 보던 방향으로 한 발이 된다.
## 정본은 tools/godot-touch-controls/virtual_stick.gd 의 is_tap 이고 여기 값과 같아야 한다.
static func is_aim_tap(travel: float, elapsed_msec: int, max_travel: float, max_msec: int) -> bool:
	return travel <= max_travel and elapsed_msec <= max_msec
