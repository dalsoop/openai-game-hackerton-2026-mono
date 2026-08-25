extends RefCounted
## 가상 패드 표시 여부 — 웹 데스크톱은 거친 포인터(터치폰)일 때만 켠다.

static func wants_overlay(is_mobile: bool, is_web: bool, pointer_coarse: bool) -> bool:
	if is_mobile:
		return true
	if is_web:
		return pointer_coarse
	return pointer_coarse
