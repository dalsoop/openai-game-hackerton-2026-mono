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
	t.check("반전: matchmake/reconnect 경로 금지", code.find("matchmake") < 0)
	t.check("MATCH 재소비 가드", code.find("if match_running:") >= 0)

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
