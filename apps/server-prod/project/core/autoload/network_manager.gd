extends Node
## 인게임 I/O — 허브 소켓은 React 만 연다.
## START 시 페이지가 MATCH/FROM_HUB 를 sessionStorage 에 남기고 좌석을 유지한다.
## 이 노드는 Colyseus.Client 를 만들지 않고, DOM 이벤트(EVT_TO_ENGINE / FROM_ENGINE)로만 말한다.

signal status_changed(status: String)  # lint-gd: public-api
signal joined_room(room: Dictionary, players: Array, you: int)  # lint-gd: public-api
signal match_started(you: int, room: Dictionary)  # lint-gd: public-api
signal match_resumed(you: int, room: Dictionary, snap: Dictionary)  # lint-gd: public-api
signal snapshot_received(snap: Dictionary)  # lint-gd: public-api
signal gun_fire_received(fx: Dictionary)  # lint-gd: public-api
signal left_room  # lint-gd: public-api
signal hub_error(message: String)  # lint-gd: public-api
signal peer_input_received(slot: int, input_data: Dictionary)  # lint-gd: public-api
signal peer_parked_received(slot: int)  # lint-gd: public-api
signal peer_reclaimed_received(slot: int, player_name: String)  # lint-gd: public-api
signal host_changed(now_host: bool)  # lint-gd: public-api

const SeatCodec := preload("res://core/contract/seat_codec.gd")  # lint-gd: public-api
const HubStateSync := preload("res://core/contract/hub_state_sync.gd")  # lint-gd: public-api

const STATUS_LOBBY := "로비"  # lint-gd: public-api
const STATUS_IDLE := "대기"  # lint-gd: public-api

var player_name := "플레이어"  # lint-gd: public-api
var mode := WebContract.DEFAULT_MODE  # lint-gd: public-api
var status := STATUS_IDLE  # lint-gd: public-api
var players: Array = []  # lint-gd: public-api
var room: Dictionary = {}  # lint-gd: public-api
var you := -1  # lint-gd: public-api
var in_room := false  # lint-gd: public-api
var match_running := false  # lint-gd: public-api
var is_host := false  # lint-gd: public-api
var rtt_ms: int = 0  # lint-gd: public-api
var resume_token := ""  # lint-gd: public-api

var _last_phase := ""
var _to_engine_cb = null

func _ready() -> void:
    var hub_name := get_hub_name()
    if hub_name != "":
        player_name = hub_name
    _bind_page_bridge()

## 셸이 match_started 를 붙인 뒤에만 호출한다.
func start_handoff() -> void:  # lint-gd: public-api
    _bind_page_bridge()
    consume_pending_match()

func _bind_page_bridge() -> void:
    if not OS.has_feature("web"):
        return
    if _to_engine_cb != null:
        return
    _to_engine_cb = JavaScriptBridge.create_callback(_on_to_engine)
    var win = JavaScriptBridge.get_interface("window")
    if win == null:
        return
    win.addEventListener(WebContract.EVT_TO_ENGINE, _to_engine_cb)

func _on_to_engine(args: Array) -> void:
    if args.is_empty():
        return
    var ev = args[0]
    var detail := ""
    if ev != null:
        detail = str(ev.detail)
    var parsed: Variant = JSON.parse_string(detail)
    if parsed is Dictionary:
        _on_bridge_packet(parsed)

func _on_bridge_packet(packet: Dictionary) -> void:
    var msg_type := str(packet.get("type", ""))
    var data: Variant = packet.get("payload", {})
    var msg: Dictionary = data if data is Dictionary else {}
    match msg_type:
        WebContract.MSG_SNAP:
            if not msg.is_empty():
                snapshot_received.emit(msg)
        WebContract.MSG_PEER_INPUT:
            peer_input_received.emit(int(msg.get("slot", -1)), msg)
        WebContract.MSG_GUN_FIRE:
            gun_fire_received.emit(msg)
        WebContract.MSG_ERROR:
            hub_error.emit(str(msg.get("msg", "")))
        WebContract.MSG_STATE:
            _sync_state(msg)

## Godot 는 START 이후에 부팅하므로, 페이지가 남겨둔 시작 정보를 가져온다.
func consume_pending_match() -> void:  # lint-gd: public-api
    if match_running:
        return
    if match_started.get_connections().is_empty():
        return
    var raw := _read_ls(WebContract.KEY_MATCH)
    if raw == "":
        return
    var parsed: Variant = JSON.parse_string(raw)
    if parsed is Dictionary:
        _apply_start(parsed)

func _apply_start(msg: Dictionary) -> void:
    match_running = true
    in_room = true
    you = int(msg.get("you", you))
    is_host = bool(msg.get("host", false))
    var seats: Array = msg.get("seats", [])
    if not seats.is_empty():
        players = SeatCodec.from_start(seats)
    if msg.has("room"):
        room = msg.get("room", room)
    if msg.has("seed"):
        room["seed"] = int(msg["seed"])
    resume_token = _read_ls(WebContract.KEY_RESUME)
    _set_status(STATUS_LOBBY)
    match_started.emit(you, room)

## 방 state 를 우리 인터페이스로 번역한다 — sessionId 는 React 가 패키지에 넣는다.
func _sync_state(state: Variant) -> void:
    if not state is Dictionary:
        return
    if state.has("rttMs"):
        rtt_ms = int(state.get("rttMs", 0))
    var phase := str(state.get("phase", ""))
    var host_sid := str(state.get("hostSessionId", ""))
    var my_sid := str(state.get("sessionId", ""))
    var host_dec: Dictionary = HubStateSync.host_decision(host_sid, my_sid, is_host)
    if host_dec["apply"]:
        var next_host: bool = bool(host_dec["is_host"])
        if match_running and is_host != next_host:
            is_host = next_host
            host_changed.emit(is_host)
        else:
            is_host = next_host
    var raw_players: Array = state.get("players") if state.get("players") is Array else []
    var next_players: Array = SeatCodec.from_state(raw_players)
    for ev in SeatCodec.diff_dropped(players, next_players):
        if ev.get("kind") == "parked":
            peer_parked_received.emit(int(ev.get("slot", -1)))
        else:
            peer_reclaimed_received.emit(int(ev.get("slot", -1)), str(ev.get("name", "")))
    players = next_players
    if HubStateSync.match_ended(_last_phase, phase):
        match_running = false
        joined_room.emit(room, players, you)
    _last_phase = HubStateSync.next_phase(_last_phase, phase)

func send_input(msg: Dictionary) -> void:  # lint-gd: public-api
    _send(WebContract.MSG_INPUT, msg)

func send_snap(snap: Dictionary) -> void:  # lint-gd: public-api
    _send(WebContract.MSG_HOST_SNAP, snap)

func leave_room() -> void:  # lint-gd: public-api
    _send(WebContract.MSG_LEAVE, {})
    in_room = false
    match_running = false
    left_room.emit()

func _send(type: String, msg: Dictionary) -> void:
    if not OS.has_feature("web"):
        return
    var packet := JSON.stringify({"type": type, "payload": msg})
    var escaped := packet.replace("\\", "\\\\").replace("'", "\\'")
    JavaScriptBridge.eval(
        "window.dispatchEvent(new CustomEvent('%s',{detail:'%s'}))" % [
            WebContract.EVT_FROM_ENGINE, escaped], true)

func is_open() -> bool:  # lint-gd: public-api
    return in_room

func _set_status(next: String) -> void:
    if status == next:
        return
    status = next
    status_changed.emit(status)

func consume_hub_launch() -> bool:  # lint-gd: public-api
    if not OS.has_feature("web"):
        return false
    return JavaScriptBridge.eval(
        "try{sessionStorage.getItem('%s')}catch(e){''}" % WebContract.KEY_FROM_HUB, true) != null

func get_hub_name() -> String:  # lint-gd: public-api
    return _read_ls(WebContract.KEY_NAME)

func _read_ls(key: String) -> String:
    if not OS.has_feature("web"):
        return ""
    var text := str(JavaScriptBridge.eval(
        "try{sessionStorage.getItem('%s')||''}catch(e){''}" % key, true)).strip_edges()
    if text == "<null>" or text == "null" or text == "undefined":
        return ""
    return text
