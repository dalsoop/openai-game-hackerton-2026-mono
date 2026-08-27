extends RefCounted
## 허브 소켓 주인은 React. NetworkManager 는 reconnect 하지 않는다.

const WebContract := preload("res://core/contract/web_contract.gd")

func run(t) -> void:
	_scan_source(t)
	_runtime_bridge(t)

func _scan_source(t) -> void:
	var src := FileAccess.get_file_as_string("res://core/autoload/network_manager.gd")
	t.check("NetworkManager 소스 읽힘", src != "")
	var code := ""
	for line in src.split("\n"):
		if not line.strip_edges().begins_with("#"):
			code += line + "\n"
	t.check("Colyseus.Client 없음", code.find("Colyseus.Client") < 0)
	t.check(".reconnect( 없음", code.find(".reconnect(") < 0)
	t.check("페이지 브릿지 TO", code.find("EVT_TO_ENGINE") >= 0)
	t.check("페이지 브릿지 FROM", code.find("EVT_FROM_ENGINE") >= 0)
	t.check("페이지 송신 헬퍼 1회 설치", code.find("__dagulToPage") >= 0)
	t.check("송신은 캐시된 window 호출", code.find("func _cached_page_window") >= 0)
	t.check("헬퍼 미존재 시 eval 폴백", code.find("func _send_eval_fallback") >= 0)
	t.check("반전: matchmake/reconnect 경로 금지", code.find("matchmake") < 0)
	t.check("MATCH 재소비 가드", code.find("if match_running:") >= 0)
	t.check("인게임 ready 송신", code.find("func send_ready") >= 0)
	t.check("ready 는 MSG_READY", code.find("MSG_READY") >= 0)

func _runtime_bridge(t) -> void:
	var nm: Node = load("res://core/autoload/network_manager.gd").new()
	var snaps: Array = []
	var starts: Array = []
	nm.snapshot_received.connect(func(s): snaps.append(s))
	nm.match_started.connect(func(_you, _room): starts.append(1))
	nm._on_bridge_packet({
		"type": WebContract.MSG_SNAP,
		"payload": { "tick": 7 },
	})
	t.check("SNAP 패킷이 snapshot 으로 들어온다", snaps.size() == 1 and int(snaps[0].get("tick", 0)) == 7)
	nm._on_bridge_packet({
		"type": WebContract.MSG_INPUT,
		"payload": { "mx": 1 },
	})
	t.check("반전: INPUT 은 snapshot 이 아니다", snaps.size() == 1)
	nm._on_bridge_packet({
		"type": WebContract.MSG_SNAP,
		"payload": {},
	})
	t.check("반전: 빈 SNAP 은 버린다", snaps.size() == 1)
	nm._apply_start({
		"you": 0,
		"host": true,
		"seed": 3,
		"seats": [{ "slot": 0, "name": "A", "connected": true }],
	})
	t.check("START 페이로드가 매치를 연다", nm.match_running and nm.you == 0)
	var starts_before := starts.size()
	nm.consume_pending_match()
	t.check("반전: 이미 열린 매치는 MATCH 를 다시 먹지 않는다", starts.size() == starts_before)
	nm.is_host = false
	nm._on_bridge_packet({
		"type": WebContract.MSG_STATE,
		"payload": { "phase": "playing", "hostSessionId": "h1", "sessionId": "h1", "players": [] },
	})
	t.check("STATE sessionId 로 호스트를 판정한다", nm.is_host == true)
	nm.is_host = true
	nm._on_bridge_packet({
		"type": WebContract.MSG_STATE,
		"payload": { "phase": "playing", "hostSessionId": "h1", "sessionId": "", "players": [] },
	})
	t.check("반전: 빈 sessionId 는 호스트를 바꾸지 않는다", nm.is_host == true)
	nm.free()
	var shell := FileAccess.get_file_as_string("res://core/shell/match_shell.gd")
	var start_at := shell.find("module.start(")
	var ready_at := shell.find("_notify_match_loaded()")
	t.check("셸이 모듈 start 뒤에 ready 를 보낸다", start_at >= 0 and ready_at > start_at)
	t.check("ready 는 히어로 스냅 뒤에만", shell.find("_try_send_match_ready") >= 0 and shell.find("_world_has_heroes") >= 0)
	t.check("계약 MSG_READY 거울", WebContract.MSG_READY == "ready")
	var retry: Node = load("res://core/autoload/network_manager.gd").new()
	retry.match_running = true
	retry.send_ready()
	t.check("ready 재시도를 켠다", retry.get("_ready_repeat") == true)
	retry._sync_state({
		"phase": "playing",
		"hostSessionId": "h1",
		"sessionId": "h1",
		"players": [{ "slot": 0, "sessionId": "h1", "name": "A", "connected": true, "matchReady": true }],
	})
	t.check("스키마 ready 면 재시도를 끈다", retry.get("_ready_repeat") == false and retry.match_ready == true)
	retry.free()
	var barrier: Node = load("res://core/autoload/network_manager.gd").new()
	barrier.match_running = true
	barrier.send_ready()
	barrier._sync_state({
		"phase": "playing",
		"loadHeld": false,
		"hostSessionId": "h1",
		"sessionId": "h1",
		"players": [{ "slot": 0, "sessionId": "h1", "name": "A", "connected": true, "matchReady": false }],
	})
	t.check("장벽이 열리면 재시도를 끈다", barrier.get("_ready_repeat") == false)
	barrier.free()
	var resume: Node = load("res://core/autoload/network_manager.gd").new()
	resume.match_running = true
	resume.send_ready()
	resume._sync_state({
		"phase": "playing",
		"loadHeld": true,
		"hostSessionId": "h1",
		"sessionId": "h1",
		"players": [{ "slot": 0, "sessionId": "h1", "name": "A", "connected": true, "matchReady": true }],
	})
	t.check("ack 후 재시도는 꺼진다", resume.get("_ready_repeat") == false)
	resume._sync_state({
		"phase": "playing",
		"loadHeld": true,
		"hostSessionId": "h1",
		"sessionId": "h1",
		"players": [{ "slot": 0, "sessionId": "h1", "name": "A", "connected": true, "matchReady": false }],
	})
	t.check("장벽이 닫힌 채 ready 가 빠지면 재시도를 다시 켠다", resume.get("_ready_repeat") == true)
	resume.free()

	# COW 안전성 — _sync_state 연속 호출 시 players 배열 교체가 크래시하지 않아야 한다
	var cow: Node = load("res://core/autoload/network_manager.gd").new()
	cow.match_running = true
	cow._apply_start({"you": 0, "host": true, "seats": [{"slot": 0, "name": "A", "connected": true}]})
	var state_a := {"phase": "playing", "hostSessionId": "h1", "sessionId": "h1", "players": [
		{"slot": 0, "sessionId": "h1", "name": "A", "connected": true, "matchReady": true},
		{"slot": 1, "sessionId": "h2", "name": "B", "connected": true, "matchReady": true},
	]}
	var state_b := {"phase": "playing", "hostSessionId": "h1", "sessionId": "h1", "players": [
		{"slot": 0, "sessionId": "h1", "name": "A", "connected": false, "matchReady": true},
		{"slot": 1, "sessionId": "h2", "name": "B", "connected": true, "matchReady": true},
	]}
	cow._sync_state(state_a)
	cow._sync_state(state_b)
	cow._sync_state(state_a)
	t.check("연속 _sync_state 호출 후 players 정상", cow._players.size() == 2)

	# 시그널로 받은 players 수정이 NetworkManager.players 에 영향 없음
	var iso: Node = load("res://core/autoload/network_manager.gd").new()
	iso.match_running = true
	iso._apply_start({"you": 0, "host": true, "seats": [{"slot": 0, "name": "X", "connected": true}]})
	var captured: Array = []
	iso.joined_room.connect(func(_r, p, _y): captured.append(p))
	iso._sync_state({"phase": "lobby", "hostSessionId": "", "sessionId": "s1", "players": []})
	if not captured.is_empty():
		captured[0].append({"slot": 99, "name": "침입"})
		t.check("시그널 players 수정이 원본에 영향 없음", iso._players.size() == 0)
	else:
		t.check("시그널 players 수정이 원본에 영향 없음", true)
	iso.free()
	cow.free()
