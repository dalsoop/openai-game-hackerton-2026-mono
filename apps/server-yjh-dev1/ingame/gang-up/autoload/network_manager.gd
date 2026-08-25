extends Node

signal status_changed(status: String)
signal rooms_updated(rooms: Array)
signal joined_room(room: Dictionary, players: Array, you: int)
signal peers_updated(players: Array, room: Dictionary)
signal match_started(you: int, room: Dictionary)
signal match_resumed(you: int, room: Dictionary, snap: Dictionary)
signal snapshot_received(snap: Dictionary)
signal left_room
signal hub_error(message: String)
signal hub_notice(message: String)
signal chat_received(from_name: String, slot: int, text: String)
signal peer_input_received(slot: int, input_data: Dictionary)
signal peer_parked_received(slot: int)
signal peer_reclaimed_received(slot: int, player_name: String)

const STATUS_CONNECTING := "연결 중"
const STATUS_RECONNECTING := "다시 연결 중"
const STATUS_LOBBY := "로비"
const STATUS_CLOSED := "끊김"
const STATUS_OFFLINE := "오프라인 로컬"
const MAX_ATTEMPTS := 3
const RETRY_BASE := 1.0
const RETRY_MAX := 6.0
const PING_EVERY := 2.0

var player_name := "플레이어"
var mode := "classic"
var status := STATUS_OFFLINE
var client_id := ""
var resume_token := ""
var rooms: Array = []
var players: Array = []
var room: Dictionary = {}
var you := -1
var in_room := false
var match_running := false
var holding_seat := false
var is_host := false

var _ws := WebSocketPeer.new()
var _want_connection := false
var _was_open := false
var _connecting := false
var _attempts := 0
var _retry_wait := 0.0
var _ping_wait := 0.0
var _ping_sent_ms: int = 0
var rtt_ms: int = -1

func _ready() -> void:
    resume_token = _load_resume()
    var hub_name := get_hub_name()
    if hub_name != "":
        player_name = hub_name
    ensure_connected()

func _js_text(code: String) -> String:
    if not OS.has_feature("web"):
        return ""
    var text := str(JavaScriptBridge.eval(code, true)).strip_edges()
    if text.begins_with("\"") and text.ends_with("\"") and text.length() >= 2:
        text = text.substr(1, text.length() - 2)
    if text == "<null>" or text == "null" or text == "undefined":
        return ""
    return text

func _public_game_url(raw: String) -> String:
    var url := raw.strip_edges()
    if url == "":
        return ""
    if url.find("127.0.0.1") >= 0 or url.find("localhost") >= 0 or url.find("/game-ws") >= 0:
        push_warning("NetworkManager: ignore unrouted game-ws %s" % url)
        return ""
    return url

func _resolve_url() -> String:
    var env := OS.get_environment("GANG_UP_WS")
    if env.strip_edges() != "":
        return env.strip_edges()
    if OS.has_feature("web"):
        var origin := _js_text("String(window.location.origin)")
        if origin.begins_with("https://"):
            return "wss://%s/gang-up" % origin.substr(8)
        if origin.begins_with("http://"):
            return "ws://%s/gang-up" % origin.substr(7)
        var host := _js_text("String(window.location.host)")
        if host != "":
            return "wss://%s/gang-up" % host
    return "ws://127.0.0.1:9120"

func is_open() -> bool:
    return _ws.get_ready_state() == WebSocketPeer.STATE_OPEN

func ensure_connected() -> void:
    _want_connection = true
    if is_open() or _connecting:
        return
    if status == STATUS_OFFLINE:
        _attempts = 0
        _retry_wait = 0.0
    if _retry_wait <= 0.0:
        _connect_now()

func reconnect_now() -> void:
    _attempts = 0
    _retry_wait = 0.0
    _connecting = false
    _ws.close()
    _want_connection = true
    _connect_now()

func _connect_now() -> void:
    _ws = WebSocketPeer.new()
    var err := _ws.connect_to_url(_resolve_url())
    if err != OK:
        _on_closed()
        return
    _connecting = true
    if holding_seat:
        _set_status(STATUS_RECONNECTING)
    else:
        _set_status(STATUS_CONNECTING)

func _process(delta: float) -> void:
    _ws.poll()
    var state := _ws.get_ready_state()
    if state == WebSocketPeer.STATE_OPEN:
        if not _was_open:
            _on_open()
        while _ws.get_available_packet_count() > 0:
            var parsed: Variant = JSON.parse_string(_ws.get_packet().get_string_from_utf8())
            if parsed is Dictionary:
                _on_msg(parsed)
        _ping_wait -= delta
        if _ping_wait <= 0.0:
            _ping_wait = PING_EVERY
            _ping_sent_ms = Time.get_ticks_msec()
            _send({"t":"ping"})
    elif state == WebSocketPeer.STATE_CLOSED:
        if _was_open or _connecting:
            _connecting = false
            _on_closed()
        elif _want_connection and status != STATUS_OFFLINE:
            _retry_wait -= delta
            if _retry_wait <= 0.0:
                _connect_now()

func _on_open() -> void:
    _was_open = true
    _connecting = false
    _attempts = 0
    _ping_wait = 0.25
    var hello := {"t":"hello", "name":player_name, "mode":mode, "wantResume": holding_seat}
    if resume_token.length() == 32:
        hello["resume"] = resume_token
    _send(hello)
    if not holding_seat:
        _set_status(STATUS_LOBBY)
        _send({"t":"rooms"})

func _on_closed() -> void:
    var dropped := _was_open
    _was_open = false
    if in_room or match_running:
        holding_seat = true
        _set_status(STATUS_RECONNECTING)
        _want_connection = true
        _attempts = 0
        _retry_wait = RETRY_BASE
        return
    if dropped:
        _attempts = 0
        _set_status(STATUS_CLOSED)
        _retry_wait = RETRY_BASE
        return
    _attempts += 1
    var limit: int = 24 if holding_seat else MAX_ATTEMPTS
    if _attempts >= limit:
        _want_connection = false
        _give_up_seat()
        _set_status(STATUS_OFFLINE)
    else:
        _set_status(STATUS_RECONNECTING if holding_seat else STATUS_CONNECTING)
        _retry_wait = minf(RETRY_MAX, RETRY_BASE * float(_attempts))

func _give_up_seat() -> void:
    if not holding_seat and not in_room:
        return
    holding_seat = false
    in_room = false
    match_running = false
    players = []
    room = {}
    left_room.emit()

func _set_status(next: String) -> void:
    if status == next:
        return
    status = next
    status_changed.emit(status)

func _send(msg: Dictionary) -> void:
    if is_open():
        _ws.put_packet(JSON.stringify(msg).to_utf8_buffer())

func request_rooms() -> void:
    _send({"t":"rooms"})

func create_room(title: String = "") -> void:
    var msg := {"t":"create"}
    if title.strip_edges() != "":
        msg["title"] = title.strip_edges()
    _send(msg)

func join_room(room_id: String) -> void:
    _send({"t":"join", "roomId":room_id})

func leave_room() -> void:
    if is_open() and (in_room or holding_seat):
        _send({"t":"leave"})
    _give_up_seat()

func start_match() -> void:
    _send({"t":"start"})

func set_room_mode(mode_id: String) -> void:
    mode = mode_id
    _send({"t":"mode", "mode": mode_id})

func kick_player(slot: int) -> void:
    _send({"t":"kick", "slot":slot})

func send_chat(text: String) -> void:
    if not in_room:
        return
    _send({"t":"chat", "text":text})

func send_hello() -> void:
    var hello := {"t":"hello", "name":player_name, "mode":mode, "wantResume": holding_seat}
    if resume_token.length() == 32:
        hello["resume"] = resume_token
    _send(hello)

func send_input(move: Vector2, fire: bool, dash: bool, use: bool, aim: Vector2, seq: int = 0) -> void:
    var msg := {"t":"input", "mx":move.x, "my":move.y, "fire":fire, "dash":dash, "use":use, "aimX":aim.x, "aimY":aim.y}
    if seq > 0:
        msg["seq"] = seq
    _send(msg)

func send_snap(snap: Dictionary) -> void:
    var msg := snap.duplicate()
    msg["t"] = "host_snap"
    _send(msg)

func _on_msg(msg: Dictionary) -> void:
    match str(msg.get("t", "")):
        "welcome":
            if not holding_seat:
                client_id = str(msg.get("id", ""))
            var token := str(msg.get("resume", ""))
            if token.length() == 32 and not holding_seat:
                resume_token = token
                _save_resume(token)
        "rooms":
            rooms = msg.get("rooms", [])
            rooms_updated.emit(rooms)
        "joined":
            in_room = true
            holding_seat = true
            match_running = false
            you = int(msg.get("you", 0))
            room = msg.get("room", {})
            players = msg.get("players", [])
            _set_status(STATUS_LOBBY)
            joined_room.emit(room, players, you)
        "resume":
            in_room = true
            holding_seat = true
            if str(msg.get("id", "")) != "":
                client_id = str(msg.get("id", ""))
            you = int(msg.get("you", 0))
            is_host = bool(msg.get("host", false))
            room = msg.get("room", {})
            if typeof(room) != TYPE_DICTIONARY:
                room = {}
            room["game_url"] = _public_game_url(str(msg.get("gameServerUrl", "")))
            players = msg.get("players", [])
            _set_status(STATUS_LOBBY)
            if bool(msg.get("playing", false)):
                match_running = true
                var snap: Variant = msg.get("snap", {})
                if typeof(snap) != TYPE_DICTIONARY:
                    snap = {}
                match_resumed.emit(you, room, snap)
            else:
                match_running = false
                joined_room.emit(room, players, you)
            var notice := str(msg.get("notice", ""))
            if notice != "":
                hub_notice.emit(notice)
        "peers":
            players = msg.get("players", [])
            if msg.has("room"):
                room = msg.get("room", room)
            peers_updated.emit(players, room)
            var peer_notice := str(msg.get("notice", ""))
            if peer_notice != "":
                hub_notice.emit(peer_notice)
        "start":
            match_running = true
            holding_seat = true
            you = int(msg.get("you", you))
            is_host = bool(msg.get("host", false))
            if msg.has("room"):
                room = msg.get("room", room)
            if msg.has("gameServerUrl"):
                room["game_url"] = _public_game_url(str(msg["gameServerUrl"]))
            if msg.has("seed"):
                room["seed"] = int(msg["seed"])
            match_started.emit(you, room)
        "snap":
            snapshot_received.emit(msg)
        "peer_input":
            peer_input_received.emit(int(msg.get("slot", -1)), msg)
        "peer_parked":
            peer_parked_received.emit(int(msg.get("slot", -1)))
        "peer_reclaimed":
            peer_reclaimed_received.emit(int(msg.get("slot", -1)), str(msg.get("name", "")))
        "chat":
            chat_received.emit(str(msg.get("from", "?")), int(msg.get("slot", -1)), str(msg.get("text", "")))
        "pong":
            if _ping_sent_ms > 0:
                rtt_ms = Time.get_ticks_msec() - _ping_sent_ms
        "lobby":
            match_running = false
            if msg.has("room"):
                room = msg.get("room", room)
            joined_room.emit(room, players, you)
            var lobby_notice := str(msg.get("notice", ""))
            if lobby_notice != "":
                hub_notice.emit(lobby_notice)
        "left":
            _give_up_seat()
        "kicked":
            hub_error.emit(str(msg.get("msg", "방에서 내보내졌습니다.")))
            _give_up_seat()
        "dropped":
            var drop_msg := str(msg.get("msg", "연결이 만료되었습니다"))
            hub_error.emit(drop_msg)
            _give_up_seat()
            var fresh := str(msg.get("resume", ""))
            if fresh.length() == 32:
                resume_token = fresh
                _save_resume(fresh)
        "error":
            hub_error.emit(str(msg.get("msg", "")))

func _save_resume(token: String) -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("try{localStorage.setItem('gangup_resume','%s')}catch(e){}" % token)
        return
    var f := FileAccess.open("user://gangup_resume.txt", FileAccess.WRITE)
    if f != null:
        f.store_string(token)

func consume_hub_launch() -> bool:
    if not OS.has_feature("web"):
        return false
    var q := _js_text("String(window.location.search||'')")
    if q.find("from_hub=1") >= 0:
        return true
    var flag := _js_text("String(window.GANGUP_FROM_HUB||'')")
    if flag == "1" or flag == "true":
        return true
    var v := _js_text("try{var x=localStorage.getItem('gangup_from_hub')||'';localStorage.removeItem('gangup_from_hub');x}catch(e){''}")
    return v == "1"

func get_hub_name() -> String:
    if not OS.has_feature("web"):
        return ""
    return _js_text("try{localStorage.getItem('gangup_name')||''}catch(e){''}")

func _load_resume() -> String:
    if OS.has_feature("web"):
        var stored := _js_text("try{localStorage.getItem('gangup_resume')||''}catch(e){''}")
        if stored.length() == 32:
            return stored
        return ""
    if FileAccess.file_exists("user://gangup_resume.txt"):
        var f := FileAccess.open("user://gangup_resume.txt", FileAccess.READ)
        if f != null:
            var token := f.get_as_text().strip_edges()
            if token.length() == 32:
                return token
    return ""
