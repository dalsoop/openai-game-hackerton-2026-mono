extends RefCounted
## 재접속 직후 빈 state 가 호스트를 뒤집거나 매치를 끝내지 않는지.

const Sync := preload("res://core/contract/hub_state_sync.gd")

func run(t) -> void:
	var keep := Sync.host_decision("", "sess-a", true)
	t.check("빈 host 는 적용 안 함", keep["apply"] == false and keep["is_host"] == true)
	var take := Sync.host_decision("sess-a", "sess-a", false)
	t.check("같은 세션이면 호스트", take["apply"] == true and take["is_host"] == true)
	var guest := Sync.host_decision("sess-b", "sess-a", true)
	t.check("다른 세션이면 게스트", guest["apply"] == true and guest["is_host"] == false)
	t.check("빈 phase 는 종료 아님", Sync.match_ended("playing", "") == false)
	t.check("lobby 는 종료", Sync.match_ended("playing", "lobby") == true)
	t.check("playing 유지", Sync.match_ended("playing", "playing") == false)
	t.check("빈 phase 는 last 유지", Sync.next_phase("playing", "") == "playing")
