extends RefCounted
## 가상 패드 표시 여부 — 웹 데스크톱은 거친 포인터(터치폰)일 때만 켠다.

static func wants_overlay(is_mobile: bool, is_web: bool, pointer_coarse: bool) -> bool:
	if is_mobile:
		return true
	if is_web:
		return pointer_coarse
	return pointer_coarse


## 패드가 켜진 동안 터치는 LMB 로 흉내 난다. 스틱을 잡으면 자동으로 쏜다.
static func action_held(pad_on: bool, mouse_held: bool, pad_held: bool) -> bool:
	if pad_on:
		return pad_held
	return mouse_held or pad_held
