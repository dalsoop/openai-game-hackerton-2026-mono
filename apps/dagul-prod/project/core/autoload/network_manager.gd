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
var match_ready := false  # lint-gd: public-api
var load_held := false  # lint-gd: public-api

var _last_phase := ""
var _to_engine_cb = null
var _page_window = null
var _ready_repeat := false
var _ready_sent := false
var _ready_acc := 0.0
const READY_RETRY_SEC := 0.5  # lint-gd: public-api

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
    _page_window = JavaScriptBridge.get_interface("window")
    if _page_window == null:
        return
    _page_window.addEventListener(WebContract.EVT_TO_ENGINE, _to_engine_cb)
    _install_to_page_helper()

func _install_to_page_helper() -> void:
    JavaScriptBridge.eval(
        "window.__dagulToPage = window.__dagulToPage || function(s){ window.dispatchEvent(new CustomEvent('%s', {detail: s})) }" % WebContract.EVT_FROM_ENGINE,
        true)

func _cached_page_window():
    if _page_window != null:
        return _page_window
    _page_window = JavaScriptBridge.get_interface("window")
    return _page_window

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
            if _engine_socket_active():
                pass
            elif not msg.is_empty():
                snapshot_received.emit(msg)
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
    match_ready = false
    load_held = true
    _ready_sent = false
    _ready_repeat = false
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
    match_ready = _own_match_ready(raw_players, my_sid)
    if phase == "playing" and state.has("loadHeld"):
        load_held = bool(state.get("loadHeld", false))
    if match_running and load_held and not match_ready and _ready_sent:
        _ready_repeat = true
    elif match_ready or (phase == "playing" and not load_held):
        _ready_repeat = false
    var next_players: Array = SeatCodec.from_state(raw_players)
    for ev in SeatCodec.diff_dropped(players, next_players):
        if ev.get("kind") == "parked":
            peer_parked_received.emit(int(ev.get("slot", -1)))
        else:
            peer_reclaimed_received.emit(int(ev.get("slot", -1)), str(ev.get("name", "")))
    players = next_players
    if HubStateSync.match_ended(_last_phase, phase):
        match_running = false
        _ready_repeat = false
        _ready_sent = false
        match_ready = false
        load_held = false
        joined_room.emit(room, players, you)
    _last_phase = HubStateSync.next_phase(_last_phase, phase)

func _own_match_ready(raw_players: Array, my_sid: String) -> bool:
    if my_sid == "":
        return false
    for p in raw_players:
        if not p is Dictionary:
            continue
        if str(p.get("sessionId", "")) != my_sid:
            continue
        return bool(p.get("matchReady", false))
    return false

## 오토로드는 바 식별자 파스가 안 된다(파스 게이트) — /root 조회가 정본.
func _engine_socket() -> Node:
    var ml := Engine.get_main_loop()
    if not (ml is SceneTree):
        return null
    return (ml as SceneTree).root.get_node_or_null("EngineSocket")

func _engine_socket_active() -> bool:
    var sock := _engine_socket()
    return sock != null and bool(sock.call("is_active"))

func send_input(msg: Dictionary) -> void:  # lint-gd: public-api
    if _engine_socket_active():
        _engine_socket().call("send_input", msg)
        return
    _send(WebContract.MSG_INPUT, msg)

## 인게임 모듈 로드가 끝난 뒤에만 보낸다. 엔진 소켓이 살아도 좌석은 React 세션이라 브릿지로 간다.
func send_ready() -> void:  # lint-gd: public-api
    match_ready = false
    load_held = true
    _ready_sent = true
    _ready_repeat = true
    _ready_acc = 0.0
    _send(WebContract.MSG_READY, {})

func _process(delta: float) -> void:
    if not _ready_repeat:
        return
    if match_ready or not match_running or not load_held:
        _ready_repeat = false
        return
    _ready_acc += delta
    if _ready_acc < READY_RETRY_SEC:
        return
    _ready_acc = 0.0
    _send(WebContract.MSG_READY, {})

func leave_room() -> void:  # lint-gd: public-api
    _ready_repeat = false
    _ready_sent = false
    match_ready = false
    load_held = false
    _send(WebContract.MSG_LEAVE, {})
    in_room = false
    match_running = false
    left_room.emit()

func _send(type: String, msg: Dictionary) -> void:
    if not OS.has_feature("web"):
        return
    var packet := JSON.stringify({"type": type, "payload": msg})
    var win = _cached_page_window()
    if win == null:
        return
    if win.__dagulToPage != null:
        win.__dagulToPage(packet)
        return
    _send_eval_fallback(packet)

func _send_eval_fallback(packet: String) -> void:
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
