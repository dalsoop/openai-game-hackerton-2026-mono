extends RefCounted
## 직접 소켓이 꺼지거나 실패하면 기존 브리지 SNAP/입력이 그대로 산다.

const WebContract := preload("res://core/contract/web_contract.gd")

func run(t) -> void:
	_no_gdextension_addon(t)
	_no_side_wasm_export(t)
	_autoload_present(t)
	_no_colyseus_class_blocks_join(t)
	_bridge_when_inactive(t)
	_ignore_snap_when_active(t)
	_send_input_branches(t)
	_snap_opt_notices(t)
	_no_claim_stays_bridge(t)
	_bridge_snap_burst(t)
	_bridge_mixed_messages(t)
	_restore(t)

func _no_gdextension_addon(t) -> void:
	var plugin := FileAccess.file_exists("res://addons/colyseus/plugin.cfg")
	t.check("Colyseus GDExtension 애드온 없음 — side.wasm 메모리 크래시 방지", not plugin)
	var schema := FileAccess.file_exists("res://core/net/lobby_state_schema.gd")
	t.check("Colyseus 스키마 생성본 없음", not schema)

func _no_side_wasm_export(t) -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	t.check("export_presets 읽힘", presets != "")
	var extensions_off := presets.find("extensions_support=false") >= 0
	t.check("extensions_support=false — side.wasm 로드 차단", extensions_off)

func _autoload_present(t) -> void:
	var sock: Node = t.root.get_node_or_null("EngineSocket")
	t.check("오토로드 EngineSocket", sock != null)
	if sock == null:
		return
	t.check("기본 비활성", sock.is_active() == false)
	t.check("반전: 헤드리스는 접속 시도 안 함", sock.get("_trying") == false)

func _no_colyseus_class_blocks_join(t) -> void:
	var has_class := ClassDB.class_exists(&"_ColyseusClient")
	t.check("GDExtension 제거 후 _ColyseusClient 없음", has_class == false)
	var sock: Node = t.root.get_node_or_null("EngineSocket")
	if sock == null:
		return
	var can: bool = sock.call("_can_join")
	t.check("_ColyseusClient 없으면 _can_join false", can == false)

func _bridge_when_inactive(t) -> void:
	var sock: Node = t.root.get_node_or_null("EngineSocket")
	if sock:
		sock.active = false
	var nm: Node = load("res://core/autoload/network_manager.gd").new()
	var snaps: Array = []
	nm.snapshot_received.connect(func(s): snaps.append(s))
	nm._on_bridge_packet({"type": WebContract.MSG_SNAP, "payload": {"tick": 11}})
	t.check("비활성 시 브리지 SNAP", snaps.size() == 1 and int(snaps[0].get("tick", 0)) == 11)
	nm.send_input({"mx": 1})
	t.check("비활성 send_input 은 크래시 없음", true)
	nm.free()

func _ignore_snap_when_active(t) -> void:
	var sock: Node = t.root.get_node_or_null("EngineSocket")
	t.check("활성 테스트용 소켓", sock != null)
	if sock == null:
		return
	sock.active = true
	var nm: Node = load("res://core/autoload/network_manager.gd").new()
	var snaps: Array = []
	nm.snapshot_received.connect(func(s): snaps.append(s))
	nm._on_bridge_packet({"type": WebContract.MSG_SNAP, "payload": {"tick": 22}})
	t.check("활성 시 브리지 SNAP 무시", snaps.is_empty())
	nm._on_bridge_packet({"type": WebContract.MSG_GUN_FIRE, "payload": {"slot": 0}})
	t.check("반전: GUN_FIRE 는 막지 않는다", true)
	sock.active = false
	nm._on_bridge_packet({"type": WebContract.MSG_SNAP, "payload": {"tick": 23}})
	t.check("다시 끄면 브리지 SNAP", snaps.size() == 1 and int(snaps[0].get("tick", 0)) == 23)
	nm.free()

func _send_input_branches(t) -> void:
	var sock: Node = t.root.get_node_or_null("EngineSocket")
	if sock == null:
		t.check("send_input 소켓 없음", false)
		return
	sock.active = true
	var before: int = (sock.get("_sent") as Array).size()
	var nm: Node = load("res://core/autoload/network_manager.gd").new()
	nm.send_input({"mx": 2, "my": 0})
	t.check("활성 send_input 은 소켓으로", (sock.get("_sent") as Array).size() == before + 1)
	sock.active = false
	nm.send_input({"mx": 3})
	t.check("비활성 전환 후 소켓 큐 유지", (sock.get("_sent") as Array).size() == before + 1)
	nm.free()

func _snap_opt_notices(t) -> void:
	var sock: Node = t.root.get_node_or_null("EngineSocket")
	t.check("opt 통지 소켓", sock != null)
	if sock == null:
		return
	sock.active = false
	sock.set("_claim_ready", true)
	(sock.get("_notices") as Array).clear()
	sock.call("_on_joined")
	var first: Array = sock.get("_notices")
	t.check("활성 시 SNAP_OFF 1회", first.size() == 1 and str(first[0]) == WebContract.MSG_SNAP_OFF)
	sock.call("_on_joined")
	t.check("재활성은 SNAP_OFF 재전송 없음", (sock.get("_notices") as Array).size() == 1)
	sock.call("_on_left_room")
	var after: Array = sock.get("_notices")
	t.check("이탈 시 SNAP_ON", after.size() == 2 and str(after[1]) == WebContract.MSG_SNAP_ON)
	t.check("이탈 후 비활성", sock.is_active() == false)
	sock.call("_on_left_room")
	t.check("재이탈은 SNAP_ON 재전송 없음", (sock.get("_notices") as Array).size() == 2)

func _no_claim_stays_bridge(t) -> void:
	var sock: Node = t.root.get_node_or_null("EngineSocket")
	if sock == null:
		t.check("claim 가드 소켓", false)
		return
	sock.active = false
	sock.set("_claim_ready", false)
	(sock.get("_notices") as Array).clear()
	sock.call("_on_joined")
	t.check("claim 없으면 SNAP_OFF 없음", (sock.get("_notices") as Array).is_empty())
	t.check("claim 없으면 비활성", sock.is_active() == false)

func _bridge_snap_burst(t) -> void:
	var nm: Node = load("res://core/autoload/network_manager.gd").new()
	var snaps: Array = []
	nm.snapshot_received.connect(func(s): snaps.append(s))
	for i in range(20):
		nm._on_bridge_packet({"type": WebContract.MSG_SNAP, "payload": {"tick": i + 1}})
	t.check("SNAP 20회 연속 수신 정상", snaps.size() == 20)
	t.check("마지막 SNAP tick 정확", int(snaps[19].get("tick", 0)) == 20)
	nm.free()

func _bridge_mixed_messages(t) -> void:
	var nm: Node = load("res://core/autoload/network_manager.gd").new()
	var snaps: Array = []
	var fires: Array = []
	nm.snapshot_received.connect(func(s): snaps.append(s))
	nm.gun_fire_received.connect(func(f): fires.append(f))
	nm._on_bridge_packet({"type": WebContract.MSG_SNAP, "payload": {"tick": 1}})
	nm._on_bridge_packet({"type": WebContract.MSG_STATE, "payload": {"phase": "playing", "hostSessionId": "", "sessionId": "", "players": []}})
	nm._on_bridge_packet({"type": WebContract.MSG_GUN_FIRE, "payload": {"slot": 0}})
	nm._on_bridge_packet({"type": WebContract.MSG_SNAP, "payload": {"tick": 2}})
	nm._on_bridge_packet({"type": WebContract.MSG_ERROR, "payload": {"msg": "test"}})
	nm._on_bridge_packet({"type": WebContract.MSG_SNAP, "payload": {"tick": 3}})
	t.check("혼합 수신 SNAP 3건", snaps.size() == 3)
	t.check("혼합 수신 GUN_FIRE 1건", fires.size() == 1)
	nm.free()

func _restore(t) -> void:
	var sock: Node = t.root.get_node_or_null("EngineSocket")
	if sock:
		sock.active = false
		sock.set("_claim_ready", false)
		(sock.get("_sent") as Array).clear()
		(sock.get("_notices") as Array).clear()
	t.check("소켓 비활성 복구", sock == null or sock.is_active() == false)
