extends Node
## Steam/네이티브 빌드용 Colyseus 0.18 클라이언트.
## 웹 빌드에서는 생성되지 않는다 — network_manager 가 OS.has_feature("web") 로 분기한다.
##
## 매치메이킹: POST /matchmake/<method>/<roomName> (JSON HTTP)
## 방 소켓: ws(s)://host/<roomId>?sessionId=<sid> (바이너리 WebSocket)
##
## Colyseus 0.18 바이너리 프로토콜:
##   클라→서버 room.send: [ROOM_DATA(13)] [msgpack(type)] [msgpack(payload)]
##   서버→클라 ROOM_DATA: [13] [msgpack(type)] [msgpack(payload)]
##   서버→클라 JOIN_ROOM: [10] [rt_len] [reconnectionToken] [sid_len] [serializerId] [...]
##   서버→클라 ROOM_STATE / ROOM_STATE_PATCH: 무시 (A 전략: schema 디코더 안 씀)
##
## 공식 GDExtension SDK 사용 불가 (웹 WASM dlopen 크래시, 2년 방치, 테스트 게이트).

signal connected
signal disconnected
signal message_received(type: String, payload: Dictionary)
signal state_received(state: Dictionary)
signal room_listed(rooms: Array)
signal room_joined(room_data: Dictionary)
signal room_left
signal error_received(msg: String)

enum Phase { IDLE, MATCHMAKING, WS_JOINING, IN_ROOM }

const _MsgPack := preload("res://core/net/msgpack.gd")
const _ROOM_NAME := "dagul-prod-lobby"
const _HTTP_TIMEOUT_SEC := 8.0

var _phase: Phase = Phase.IDLE
var _ws := WebSocketPeer.new()  # lint-gd: ws-ok — 네이티브 전용, 페이지 브릿지 없음  # lint-gd: i18n-ok
var _http: HTTPRequest = null
var _hub_url := ""
var _session_id := ""
var _reconnection_token := ""
var _room_id := ""
var _pending := ""


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = _HTTP_TIMEOUT_SEC
	add_child(_http)
	_http.request_completed.connect(_on_http_done)


func get_phase() -> Phase:
	return _phase


func is_in_room() -> bool:
	return _phase == Phase.IN_ROOM


func session_id() -> String:
	return _session_id


func reconnection_token() -> String:
	return _reconnection_token


# ── 접속 ──

func set_hub_url(url: String) -> void:
	_hub_url = url.rstrip("/")
	connected.emit()


func list_rooms() -> void:
	if _hub_url == "":
		error_received.emit("hub URL 미설정")  # lint-gd: i18n-ok
		return
	_pending = "list"
	var err := _http.request(_hub_url + "/rooms")
	if err != OK:
		_pending = ""
		error_received.emit("방 목록 요청 실패: %d" % err)  # lint-gd: i18n-ok


# ── 매치메이킹 (JSON HTTP — Colyseus matchmaker는 JSON) ──

func join_or_create(options: Dictionary = {}) -> void:
	_matchmake("joinOrCreate", options)


func create_room(options: Dictionary = {}) -> void:
	_matchmake("create", options)


func join_by_id(room_id: String, options: Dictionary = {}) -> void:
	options["roomId"] = room_id
	_matchmake("joinById", options)


func reconnect(token: String) -> void:
	_matchmake("reconnect", {"reconnectionToken": token})


func _matchmake(method: String, options: Dictionary) -> void:
	if _hub_url == "":
		error_received.emit("hub URL 미설정")  # lint-gd: i18n-ok
		return
	if _phase != Phase.IDLE:
		error_received.emit("이미 매치메이킹 중이거나 방에 있다")  # lint-gd: i18n-ok
		return
	_phase = Phase.MATCHMAKING
	_pending = "matchmake"
	var url := "%s/matchmake/%s/%s" % [_hub_url, method, _ROOM_NAME]
	var body := JSON.stringify(options)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_reset()
		error_received.emit("매치메이킹 요청 실패: %d" % err)  # lint-gd: i18n-ok


# ── 메시지 전송 (MsgPack 바이너리) ──

func send(type: String, payload: Dictionary = {}) -> void:
	if _phase != Phase.IN_ROOM:
		return
	var frame := _MsgPack.encode_room_data(type, payload)
	_ws.send(frame)


func send_input(input: Dictionary) -> void:
	send(WebContract.MSG_INPUT, input)


func send_ready() -> void:
	send(WebContract.MSG_READY, {})


func send_set_character(character_id: String) -> void:
	send(WebContract.MSG_SET_CHARACTER, {"characterId": character_id})


func leave_room() -> void:
	if _phase != Phase.IN_ROOM:
		return
	var frame := PackedByteArray([_MsgPack.LEAVE_ROOM])
	_ws.send(frame)
	_ws.close(1000, "leave")
	_reset()
	room_left.emit()


# ── HTTP 응답 ──

func _on_http_done(
	result: int, code: int, _h: PackedStringArray, body: PackedByteArray
) -> void:
	if _pending == "list":
		_on_list_done(result, code, body)
	elif _pending == "matchmake":
		_on_matchmake_done(result, code, body)
	_pending = ""


func _on_list_done(
	result: int, code: int, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		error_received.emit("방 목록 실패: HTTP %d" % code)  # lint-gd: i18n-ok
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary:
		room_listed.emit(parsed.get("rooms", []))
	else:
		error_received.emit("방 목록 파싱 실패")  # lint-gd: i18n-ok


func _on_matchmake_done(
	result: int, code: int, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_reset()
		var text := body.get_string_from_utf8() if body.size() > 0 else ""
		error_received.emit("매치메이킹 실패: HTTP %d — %s" % [code, _err_text(text)])  # lint-gd: i18n-ok
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		_reset()
		error_received.emit("매치메이킹 응답 파싱 실패")  # lint-gd: i18n-ok
		return
	var data: Dictionary = parsed as Dictionary
	var room: Variant = data.get("room", {})
	_room_id = str(room.get("roomId", "")) if room is Dictionary else ""
	_session_id = str(data.get("sessionId", ""))
	if _room_id == "" or _session_id == "":
		_reset()
		error_received.emit("응답에 roomId/sessionId 없음")  # lint-gd: i18n-ok
		return
	_open_room_ws()


# ── WebSocket (바이너리) ──

func _open_room_ws() -> void:
	_phase = Phase.WS_JOINING
	var ws_url := "%s/%s?sessionId=%s" % [_to_ws(_hub_url), _room_id, _session_id]
	var err := _ws.connect_to_url(ws_url)
	if err != OK:
		_reset()
		error_received.emit("WebSocket 연결 실패: %d" % err)  # lint-gd: i18n-ok


func _process(_delta: float) -> void:
	if _phase == Phase.IDLE:
		return
	_ws.poll()
	var ws_state := _ws.get_ready_state()
	if ws_state == WebSocketPeer.STATE_OPEN:
		_drain()
	elif ws_state == WebSocketPeer.STATE_CLOSED and _phase != Phase.IDLE:
		_reset()
		disconnected.emit()


func _drain() -> void:
	while _ws.get_available_packet_count() > 0:
		var raw := _ws.get_packet()
		if raw.is_empty():
			continue
		_on_binary_frame(raw)


func _on_binary_frame(data: PackedByteArray) -> void:
	var code: int = data[0]
	match code:
		_MsgPack.JOIN_ROOM:
			_handle_join_room(data)
		_MsgPack.ROOM_DATA:
			_handle_room_data(data)
		_MsgPack.ERROR:
			_handle_error(data)
		_MsgPack.LEAVE_ROOM:
			_reset()
			room_left.emit()
		_MsgPack.ROOM_STATE, _MsgPack.ROOM_STATE_PATCH:
			pass
		_:
			pass


func _handle_join_room(data: PackedByteArray) -> void:
	if data.size() < 3:
		_reset()
		error_received.emit("JOIN_ROOM 프레임이 너무 짧다")  # lint-gd: i18n-ok
		return
	var pos := 1
	var rt_len: int = data[pos]
	pos += 1
	if pos + rt_len > data.size():
		_reset()
		error_received.emit("reconnectionToken 읽기 실패")  # lint-gd: i18n-ok
		return
	var rt_bytes := data.slice(pos, pos + rt_len)
	_reconnection_token = "%s:%s" % [_room_id, rt_bytes.get_string_from_utf8()]
	pos += rt_len
	_phase = Phase.IN_ROOM
	var ack := PackedByteArray([_MsgPack.JOIN_ROOM])
	_ws.send(ack)
	room_joined.emit({
		"roomId": _room_id,
		"sessionId": _session_id,
		"reconnectionToken": _reconnection_token,
	})


func _handle_room_data(data: PackedByteArray) -> void:
	var parsed: Variant = _MsgPack.decode_server_frame(data)
	if parsed == null:
		return
	var msg_type: String = str(parsed.get("type", ""))
	var payload: Variant = parsed.get("payload", {})
	var body: Dictionary = payload if payload is Dictionary else {}
	match msg_type:
		WebContract.MSG_STATE:
			state_received.emit(body)
		WebContract.MSG_SNAP, WebContract.MSG_GUN_FIRE:
			message_received.emit(msg_type, body)
		WebContract.MSG_ERROR:
			error_received.emit(str(body.get("msg", "서버 에러")))  # lint-gd: i18n-ok
		_:
			message_received.emit(msg_type, body)


func _handle_error(data: PackedByteArray) -> void:
	if data.size() < 2:
		error_received.emit("서버 에러 (코드 불명)")  # lint-gd: i18n-ok
		return
	var err_code: int = data[1]
	var msg := "서버 에러 코드: %d" % err_code  # lint-gd: i18n-ok
	if data.size() > 2:
		var text_part := _MsgPack.decode(data, 2)
		if text_part[0] is String:
			msg = str(text_part[0])
	error_received.emit(msg)


# ── 유틸 ──

func _reset() -> void:
	_phase = Phase.IDLE
	_session_id = ""
	_room_id = ""
	_reconnection_token = ""


func _to_ws(url: String) -> String:
	if url.begins_with("https://"):
		return "wss://" + url.substr(8)
	if url.begins_with("http://"):
		return "ws://" + url.substr(7)
	return url


func _err_text(text: String) -> String:
	if text.is_empty():
		return "응답 없음"  # lint-gd: i18n-ok
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return str(parsed.get("error", parsed.get("message", text)))
	return text.left(200)
