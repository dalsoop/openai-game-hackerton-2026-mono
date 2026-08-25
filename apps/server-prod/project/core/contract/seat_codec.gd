class_name SeatCodec
extends RefCounted
## 좌석 명단 직렬화의 단일 정본 — START payload 의 seats 와 방 state 의
## players 를 같은 좌석 형태로 통일한다. 어디서 파싱해도 이 객체 하나로.
## 좌석 형태: { slot: int, name: String, dropped: bool, session_id: String }

const FIELDS := ["slot", "name", "dropped", "session_id"]

## 매치 시작(START) 좌석 확정본 — 서버가 시작 순간 박제한 스냅샷.
static func from_start(seats: Array) -> Array:
	var out: Array = []
	for seat in seats:
		out.append(_seat(
			int(seat.get("slot", -1)),
			str(seat.get("name", "")),
			not bool(seat.get("connected", true)),
			"",
		))
	return out

## 방 state 의 players 배열 — 실시간 로스터(이탈/복귀가 connected 로 반영).
static func from_state(players: Array) -> Array:
	var out: Array = []
	for p in players:
		out.append(_seat(
			int(p.get("slot", -1)),
			str(p.get("name", "")),
			not bool(p.get("connected", true)),
			str(p.get("sessionId", "")),
		))
	return out

## 두 명단의 같은 좌석 비교 — dropped 토글로 이탈/복귀를 판정한다.
## 반환: [{ slot, kind: "parked"|"reclaimed", name }]
static func diff_dropped(before: Array, after: Array) -> Array:
	var old_by_slot := {}
	for old in before:
		old_by_slot[int(old.get("slot", -1))] = old
	var events: Array = []
	for p in after:
		var slot := int(p.get("slot", -1))
		var old = old_by_slot.get(slot)
		if old == null:
			continue
		var was_dropped := bool(old.get("dropped", false))
		var now_dropped := bool(p.get("dropped", false))
		if not was_dropped and now_dropped:
			events.append({"slot": slot, "kind": "parked", "name": str(p.get("name", ""))})
		elif was_dropped and not now_dropped:
			events.append({"slot": slot, "kind": "reclaimed", "name": str(p.get("name", ""))})
	return events

static func _seat(slot: int, player_name: String, dropped: bool, session_id: String) -> Dictionary:
	return {
		"slot": slot,
		"name": player_name,
		"dropped": dropped,
		"session_id": session_id,
	}
