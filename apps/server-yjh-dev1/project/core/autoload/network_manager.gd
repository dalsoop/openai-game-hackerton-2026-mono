extends Node
## 인게임 Colyseus 연결의 단일 소유자 — 공식 Godot SDK(native-sdk)를 쓴다.
## 로비·대기실은 React 페이지가 소유한다. 매치 시작 시 페이지가 방을 떠나며
## 재접속 토큰(KEY_RESUME)과 시작 정보(KEY_MATCH)를 localStorage 에 남기고,
## 이 노드가 client.reconnect(token) 으로 같은 세션·좌석을 이어받는다.
## 브릿지(window 전역)는 없다 — 핸드오프는 localStorage 1회, 이후는 자체 WebSocket.

signal status_changed(status: String)  # lint-gd: public-api
signal joined_room(room: Dictionary, players: Array, you: int)  # lint-gd: public-api
signal match_started(you: int, room: Dictionary)  # lint-gd: public-api
signal match_resumed(you: int, room: Dictionary, snap: Dictionary)  # lint-gd: public-api
signal snapshot_received(snap: Dictionary)  # lint-gd: public-api
signal left_room  # lint-gd: public-api
signal hub_error(message: String)  # lint-gd: public-api
signal peer_input_received(slot: int, input_data: Dictionary)  # lint-gd: public-api
# 좌석 이탈/복귀 통지 — 서버 state 의 connected 토글로 파생한다.
signal peer_parked_received(slot: int)  # lint-gd: public-api
signal peer_reclaimed_received(slot: int, player_name: String)  # lint-gd: public-api
signal host_changed(now_host: bool)  # lint-gd: public-api

# 좌석 정본 — preload 로 확정 참조(글로벌 클래스 캐시 갱신 시점과 무관).
const SeatCodec := preload("res://core/contract/seat_codec.gd")  # lint-gd: public-api

const STATUS_LOBBY := "로비"  # lint-gd: public-api
const STATUS_OFFLINE := "오프라인 로컬"  # lint-gd: public-api

var player_name := "플레이어"  # lint-gd: public-api
var mode := WebContract.DEFAULT_MODE  # lint-gd: public-api
var status := STATUS_OFFLINE  # lint-gd: public-api
var players: Array = []  # lint-gd: public-api
var room: Dictionary = {}  # lint-gd: public-api
var you := -1  # lint-gd: public-api
var in_room := false  # lint-gd: public-api
var match_running := false  # lint-gd: public-api
var is_host := false  # lint-gd: public-api
var rtt_ms: int = 0  # lint-gd: public-api
var resume_token := ""  # lint-gd: public-api

var _client: Colyseus.Client = null
var _colyseus_room = null
var _last_phase := ""
var _deliberate_leave := false

func _ready() -> void:
    var hub_name := get_hub_name()
    if hub_name != "":
        player_name = hub_name
    # 재접속은 부트 씬이 아니라 매치 셸이 start_handoff 로 연다.
    # 부트 중 소켓을 열면 씬 전환과 겹쳐 remove_child 가 거절되고,
    # MATCH 소비가 리스너보다 앞선다.

## 셸이 match_started 를 붙인 뒤에만 호출한다.
func start_handoff() -> void:  # lint-gd: public-api
    if _client != null:
        return
    _connect()

func _connect() -> void:
    if not OS.has_feature("web"):
        return
    var token := _read_ls(WebContract.KEY_RESUME)
    if token == "":
        hub_error.emit("재접속 토큰이 없습니다 — 허브 페이지에서 시작해야 합니다")
        return
    resume_token = token
    var endpoint := str(JavaScriptBridge.eval(
        "location.origin.replace(/^http/, 'ws')", true))
    _client = Colyseus.Client.new(endpoint)
    _colyseus_room = _client.reconnect(resume_token)
    if _colyseus_room == null:
        hub_error.emit("서버에 재접속하지 못했습니다")
        return
    _wire_room(_colyseus_room)
    _set_status(STATUS_LOBBY)
    # MATCH 소비는 셸이 match_started 를 붙인 뒤(consume_pending_match) 또는
    # 재접속 합류(_on_joined)에서 한다. 부트 씬에서 여기서 지우면 신호가 공중분해된다.

func _wire_room(colyseus_room) -> void:
    colyseus_room.joined.connect(_on_joined)
    colyseus_room.state_changed.connect(_on_state_changed)
    colyseus_room.message_received.connect(_on_message)
    colyseus_room.error.connect(func(_code: int, message: String) -> void:
        hub_error.emit(message))
    colyseus_room.left.connect(_on_left)

func _on_joined() -> void:
    in_room = true
    _sync_state(_colyseus_room.get_state())
    consume_pending_match()

func _on_state_changed() -> void:
    _sync_state(_colyseus_room.get_state())

func _on_left(_code: int, _reason: String) -> void:
    in_room = false
    match_running = false
    _set_status(STATUS_OFFLINE)
    left_room.emit()

# --- 수신 ---

func _on_message(type: Variant, data: Variant) -> void:
    var msg: Dictionary = data if data is Dictionary else {}
    match str(type):
        WebContract.MSG_START:
            _apply_start(msg)
        WebContract.MSG_SNAP:
            if not msg.is_empty():
                snapshot_received.emit(msg)
        WebContract.MSG_PEER_INPUT:
            peer_input_received.emit(int(msg.get("slot", -1)), msg)
        WebContract.MSG_ERROR:
            hub_error.emit(str(msg.get("msg", "")))

## Godot 는 START 이후에 부팅하므로, 페이지가 남겨둔 시작 정보를 가져온다.
## 셸이 신호를 붙인 뒤에만 호출한다 — 부트 씬 _connect 에서 부르면 안 된다.
func consume_pending_match() -> void:  # lint-gd: public-api
    if match_started.get_connections().is_empty():
        return
    var raw := _read_ls(WebContract.KEY_MATCH)
    if raw == "":
        return
    var parsed: Variant = JSON.parse_string(raw)
    JavaScriptBridge.eval(
        "try{localStorage.removeItem('%s')}catch(e){}" % WebContract.KEY_MATCH, true)
    if parsed is Dictionary:
        _apply_start(parsed)

func _apply_start(msg: Dictionary) -> void:
    match_running = true
    in_room = true
    you = int(msg.get("you", you))
    is_host = bool(msg.get("host", false))
    # 서버가 시작 순간 박제한 좌석 확정본 — 호스트 월드의 사람 좌석 배정에 쓴다.
    var seats: Array = msg.get("seats", [])
    if not seats.is_empty():
        players = SeatCodec.from_start(seats)
    if msg.has("room"):
        room = msg.get("room", room)
    if msg.has("seed"):
        room["seed"] = int(msg["seed"])
    match_started.emit(you, room)

## 방 state 를 우리 인터페이스로 번역한다 — 로스터·페이즈·호스트의 단일 원본.
func _sync_state(state: Variant) -> void:
    if not state is Dictionary:
        return
    var phase := str(state.get("phase", ""))
    var host_sid := str(state.get("hostSessionId", ""))
    var my_sid := str(_colyseus_room.get_session_id())
    var next_host: bool = host_sid == my_sid
    if match_running and is_host != next_host:
        is_host = next_host
        host_changed.emit(is_host)
    else:
        is_host = next_host
    var raw_players: Array = state.get("players") if state.get("players") is Array else []
    var next_players: Array = SeatCodec.from_state(raw_players)
    # 이탈/복귀 파생 — connected 토글을 좌석별 통지로 바꾼다.
    for ev in SeatCodec.diff_dropped(players, next_players):
        if ev.get("kind") == "parked":
            peer_parked_received.emit(int(ev.get("slot", -1)))
        else:
            peer_reclaimed_received.emit(int(ev.get("slot", -1)), str(ev.get("name", "")))
    players = next_players
    # 매치 종료 감지: playing → 다른 페이즈.
    if _last_phase == "playing" and phase != "playing":
        match_running = false
        joined_room.emit(room, players, you)
    _last_phase = phase

# --- 송신 (인게임 메시지만 — 로비 동사는 React 소유) ---

func send_input(msg: Dictionary) -> void:  # lint-gd: public-api
    _send(WebContract.MSG_INPUT, msg)

func send_snap(snap: Dictionary) -> void:  # lint-gd: public-api
    _send(WebContract.MSG_HOST_SNAP, snap)

func leave_room() -> void:  # lint-gd: public-api
    _deliberate_leave = true
    if _colyseus_room != null:
        _colyseus_room.leave()
    in_room = false
    match_running = false
    left_room.emit()

func _send(type: String, msg: Dictionary) -> void:
    if _colyseus_room != null:
        _colyseus_room.send_message(type, msg)

# --- 상태 · 유틸 ---

func is_open() -> bool:  # lint-gd: public-api
    return _colyseus_room != null and _colyseus_room.connected

func _set_status(next: String) -> void:
    if status == next:
        return
    status = next
    status_changed.emit(status)

func consume_hub_launch() -> bool:  # lint-gd: public-api
    if not OS.has_feature("web"):
        return false
    return JavaScriptBridge.eval(
        "try{localStorage.getItem('%s')}catch(e){''}" % WebContract.KEY_FROM_HUB, true) != null

func get_hub_name() -> String:  # lint-gd: public-api
    return _read_ls(WebContract.KEY_NAME)

func _read_ls(key: String) -> String:
    if not OS.has_feature("web"):
        return ""
    var text := str(JavaScriptBridge.eval(
        "try{localStorage.getItem('%s')||''}catch(e){''}" % key, true)).strip_edges()
    if text == "<null>" or text == "null" or text == "undefined":
        return ""
    return text
