class_name GameServer
extends Node

const ServerMatchScript = preload("res://scripts/net/server_match.gd")

signal match_ended(room_id: String, standings: Array)

var _ws_peer := WebSocketMultiplayerPeer.new()
var _http_server := TCPServer.new()
var _matches: Dictionary = {}
var _port: int = 9121
var _http_port: int = 9122

func _ready() -> void:
	_port = _parse_arg("--port", 9121)
	_http_port = _parse_arg("--http-port", 9122)
	var err := _ws_peer.create_server(_port)
	if err != OK:
		push_error("GameServer: failed to create WS server on port %d: %s" % [_port, error_string(err)])
		return
	multiplayer.multiplayer_peer = _ws_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	var http_err := _http_server.listen(_http_port)
	if http_err != OK:
		push_warning("GameServer: HTTP listen on %d failed: %s" % [_http_port, error_string(http_err)])
	print("GameServer: WS on %d, HTTP on %d" % [_port, _http_port])

func _process(_delta: float) -> void:
	_poll_http()
	for room_id in _matches.keys():
		var m = _matches[room_id]
		if m.finished:
			match_ended.emit(room_id, m.final_standings())
			_matches.erase(room_id)

func _physics_process(_delta: float) -> void:
	for m in _matches.values():
		m.tick()

func _on_peer_connected(id: int) -> void:
	print("GameServer: peer %d connected" % id)

func _on_peer_disconnected(id: int) -> void:
	for m in _matches.values():
		m.on_peer_disconnected(id)

func start_match(room_id: String, players: Array, mode: String, seed_val: int) -> void:
	if _matches.has(room_id):
		return
	var m = ServerMatchScript.new(self, players, mode, seed_val)
	_matches[room_id] = m
	print("GameServer: match %s started (%d players, mode=%s)" % [room_id, players.size(), mode])

@rpc("any_peer", "call_remote", "unreliable")
func _submit_input(input_data: Dictionary) -> void:
	var sender := multiplayer.get_remote_sender_id()
	for m in _matches.values():
		m.on_peer_input(sender, input_data)

@rpc("any_peer", "call_remote", "reliable")
func _request_resume(token: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	for m in _matches.values():
		if m.try_resume(sender, token):
			return

@rpc("any_peer", "call_remote", "reliable")
func _request_spectate(room_id: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if _matches.has(room_id):
		_matches[room_id].add_spectator(sender)

@rpc("authority", "call_remote", "reliable")
func _receive_snapshot(_snap: Dictionary) -> void:
	pass

func _poll_http() -> void:
	if not _http_server.is_listening():
		return
	while _http_server.is_connection_available():
		var conn := _http_server.take_connection()
		if conn == null:
			continue
		_handle_http(conn)

func _handle_http(conn: StreamPeerTCP) -> void:
	conn.poll()
	var data := conn.get_utf8_string(conn.get_available_bytes())
	if data.is_empty():
		conn.disconnect_from_host()
		return
	var body_start := data.find("\r\n\r\n")
	if body_start < 0:
		_http_respond(conn, 400, "{\"error\":\"bad request\"}")
		return
	var body := data.substr(body_start + 4)
	var parsed = JSON.parse_string(body)
	if parsed == null or not parsed is Dictionary:
		_http_respond(conn, 400, "{\"error\":\"invalid json\"}")
		return
	if data.begins_with("POST /start-match"):
		_handle_start_match(conn, parsed)
	else:
		_http_respond(conn, 404, "{\"error\":\"not found\"}")

func _handle_start_match(conn: StreamPeerTCP, payload: Dictionary) -> void:
	var room_id := str(payload.get("room_id", ""))
	var players: Array = payload.get("players", [])
	var mode := str(payload.get("mode", "full"))
	var seed_val := int(payload.get("seed", randi()))
	if room_id.is_empty() or players.is_empty():
		_http_respond(conn, 400, "{\"error\":\"missing room_id or players\"}")
		return
	start_match(room_id, players, mode, seed_val)
	var game_url := "ws://127.0.0.1:%d" % _port
	_http_respond(conn, 200, JSON.stringify({"ok": true, "game_url": game_url}))

func _http_respond(conn: StreamPeerTCP, code: int, body: String) -> void:
	var status := "OK" if code == 200 else ("Bad Request" if code == 400 else "Not Found")
	var response := "HTTP/1.1 %d %s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [code, status, body.length(), body]
	conn.put_data(response.to_utf8_buffer())
	conn.disconnect_from_host()

func _parse_arg(flag: String, default_val: int) -> int:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == flag and i + 1 < args.size():
			return int(args[i + 1])
	return default_val
