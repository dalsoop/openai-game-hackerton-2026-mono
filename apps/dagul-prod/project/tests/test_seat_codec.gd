extends RefCounted
## SeatCodec 좌석 정본 — START/state 양쪽 파싱과 이탈·복귀 판정을 검증한다.

const Codec := preload("res://core/contract/seat_codec.gd")

func run(t) -> void:
	# from_start — START seats 를 통일 좌석 형태로
	var seats := Codec.from_start([
		{"slot": 0, "name": "하나", "connected": true},
		{"slot": 3, "name": "셋", "connected": false},
	])
	t.check("from_start 개수", seats.size() == 2)
	t.check("from_start slot", int(seats[0]["slot"]) == 0)
	t.check("from_start connected→dropped 반전", bool(seats[1]["dropped"]) == true)
	t.check("from_start connected 유지", bool(seats[0]["dropped"]) == false)
	var with_char := Codec.from_start([{"slot": 0, "name": "하나", "connected": true, "characterId": "a3"}])
	t.check("from_start character_id", str(with_char[0]["character_id"]) == "a3")

	# from_state — state players 를 같은 형태로 (session_id 보존)
	var state_players := Codec.from_state([
		{"slot": 1, "name": "둘", "connected": true, "sessionId": "s2"},
	])
	t.check("from_state session_id 보존", str(state_players[0]["session_id"]) == "s2")
	t.check("from_state dropped", bool(state_players[0]["dropped"]) == false)

	# from_start/from_state 같은 인물이면 같은 좌석 형태
	var a := Codec.from_start([{"slot": 2, "name": "넷", "connected": true}])
	var b := Codec.from_state([{"slot": 2, "name": "넷", "connected": true, "sessionId": "x"}])
	t.check("양쪽 파싱 동일 좌석", a[0]["slot"] == b[0]["slot"] and a[0]["name"] == b[0]["name"] and a[0]["dropped"] == b[0]["dropped"])

	# diff_dropped — 이탈(parked)/복귀(reclaimed) 판정
	var before := Codec.from_state([
		{"slot": 0, "name": "하나", "connected": true, "sessionId": "a"},
		{"slot": 1, "name": "둘", "connected": false, "sessionId": "b"},
	])
	var after := Codec.from_state([
		{"slot": 0, "name": "하나", "connected": false, "sessionId": "a"},
		{"slot": 1, "name": "둘", "connected": true, "sessionId": "b"},
	])
	var events: Array = Codec.diff_dropped(before, after)
	t.check("이탈/복귀 각 1건", events.size() == 2)
	var parked_count := 0
	var reclaimed_count := 0
	for ev in events:
		if ev["kind"] == "parked":
			parked_count += 1
		else:
			reclaimed_count += 1
	t.check("slot0 parked", parked_count == 1 and events[0]["slot"] == 0)
	t.check("slot1 reclaimed", reclaimed_count == 1)

	# 변화 없으면 이벤트 없음
	t.check("변화 없으면 0건", Codec.diff_dropped(before, before).is_empty())

	# 빈 입력 방어
	t.check("빈 배열 방어", Codec.from_start([]).is_empty() and Codec.from_state([]).is_empty())

	# COW 안전성 — diff_dropped 호출 뒤 원본이 변형되지 않아야 한다
	var cow_before := Codec.from_state([
		{"slot": 0, "name": "A", "connected": true, "sessionId": "a"},
	])
	var cow_after := Codec.from_state([
		{"slot": 0, "name": "A", "connected": false, "sessionId": "a"},
	])
	var cow_snap := cow_before.duplicate(true)
	Codec.diff_dropped(cow_before, cow_after)
	t.check("diff_dropped 후 before 원본 보존", cow_before.size() == cow_snap.size() and str(cow_before[0]) == str(cow_snap[0]))

	# duplicate(true) 독립성 — 복사본 수정이 원본에 영향 없음
	var orig := Codec.from_state([{"slot": 0, "name": "X", "connected": true, "sessionId": "s"}])
	var copy := orig.duplicate(true)
	copy[0]["name"] = "Y"
	t.check("deep copy 독립성", str(orig[0]["name"]) == "X")
