extends RefCounted
## 순환 이벤트 로그 — ID 단조 증가·최대치 순환·최근 조회·사본 격리.

const EventLogScript := preload("res://games/dagul/sim/event_log.gd")

func run(t) -> void:
	var log = EventLogScript.new()
	var first_id: int = log.emit(1, &"spawn", 3, 4)
	var second_id: int = log.emit(2, &"hit", 3, 5)
	t.check("ids increase", second_id == first_id + 1)

	var event: Dictionary = log.events[0]
	t.check("event fields", event["tick"] == 1 and event["actor_id"] == 3 and event["target_id"] == 4)

	# data/ causes 는 호출 쪽 변경과 격리(깊은 복사)
	var payload := {"hp": 10}
	log.emit(3, &"damage", 1, 2, payload)
	payload["hp"] = 999
	t.check("payload deep-copied", log.events[2]["data"]["hp"] == 10)

	# 최대치 초과 시 앞부분이 순환 삭제된다
	var small = EventLogScript.new()
	small.max_events = 3
	for i in range(6):
		small.emit(i, &"tick")
	t.check("capped at max_events", small.events.size() == 3)
	t.check("oldest dropped", small.events[0]["tick"] == 3)

	var recent: Array = small.recent(2)
	t.check("recent returns tail", recent.size() == 2 and recent[0]["tick"] == 4)

	small.clear()
	t.check("clear resets", small.events.is_empty() and small.next_id == 1)

	var cursor = EventLogScript.new()
	cursor.emit(1, &"a")
	cursor.emit(2, &"b")
	cursor.emit(3, &"c")
	t.check("first_index_after 1", cursor.first_index_after(1) == 1)
	cursor.discard_up_to(1)
	t.check("discard_up_to 앞부분 절단", cursor.events.size() == 2 and int(cursor.events[0]["tick"]) == 2)
