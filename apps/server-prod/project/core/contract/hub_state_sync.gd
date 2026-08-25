extends RefCounted
## 방 state 패치의 호스트·페이즈 판정 — 재접속 직후 빈 스키마를 튕김으로 보지 않는다.

## 빈 hostSessionId 는 현재 호스트를 유지한다. apply 가 거짓이면 신호를 내지 않는다.
static func host_decision(host_sid: String, my_sid: String, current: bool) -> Dictionary:
	if host_sid == "" or my_sid == "":
		return {"apply": false, "is_host": current}
	return {"apply": true, "is_host": host_sid == my_sid}

## playing 에서 알려진 다른 페이즈로만 매치 종료. 빈 phase 는 무시한다.
static func match_ended(last_phase: String, phase: String) -> bool:
	if phase == "" or last_phase != "playing":
		return false
	return phase != "playing"

static func next_phase(last_phase: String, phase: String) -> String:
	return last_phase if phase == "" else phase
