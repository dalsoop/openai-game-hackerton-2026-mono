class_name GameClient
extends Node

signal connected
signal disconnected
signal snapshot_received(snap: Dictionary)

var _peer := WebSocketMultiplayerPeer.new()
var _connected := false
var _server_url := ""
var _resume_token := ""
var _spectator := false
var _reconnect_timer := 0.0
var _reconnect_attempts := 0
const MAX_RECONNECT := 24
const RECONNECT_BASE := 1.0
const RECONNECT_MAX := 6.0

func connect_to_server(url: String, resume_token: String = "", spectate: bool = false) -> void:
	_server_url = url
	_resume_token = resume_token
	_spectator = spectate
	_do_connect()

func _do_connect() -> void:
	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_client(_server_url)
	if err != OK:
		push_error("GameClient: connect failed: %s" % error_string(err))
		return
	multiplayer.multiplayer_peer = _peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.server_disconnected.connect(_on_disconnected)

func _on_connected() -> void:
	_connected = true
	_reconnect_attempts = 0
	_reconnect_timer = 0.0
	if _spectator:
		rpc_id(1, &"_request_spectate", "")
	elif _resume_token.length() == 32:
		rpc_id(1, &"_request_resume", _resume_token)
	connected.emit()

func _on_disconnected() -> void:
	_connected = false
	disconnected.emit()
	if _spectator:
		return
	_reconnect_attempts = 0
	_reconnect_timer = RECONNECT_BASE

func is_connected_to_server() -> bool:
	return _connected

func is_spectator() -> bool:
	return _spectator

func send_input(input_data: Dictionary) -> void:
	if not _connected or _spectator:
		return
	rpc_id(1, &"_submit_input", input_data)

func _process(delta: float) -> void:
	if _connected or _server_url.is_empty():
		return
	if _reconnect_timer <= 0.0:
		return
	_reconnect_timer -= delta
	if _reconnect_timer > 0.0:
		return
	_reconnect_attempts += 1
	if _reconnect_attempts > MAX_RECONNECT:
		return
	_do_connect()
	_reconnect_timer = minf(RECONNECT_MAX, RECONNECT_BASE * float(_reconnect_attempts))

func disconnect_from_server() -> void:
	_connected = false
	_server_url = ""
	_spectator = false
	if _peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		_peer.close()

@rpc("authority", "call_remote", "reliable")
func _receive_snapshot(snap: Dictionary) -> void:
	snapshot_received.emit(snap)

@rpc("any_peer", "call_remote", "unreliable")
func _submit_input(_input_data: Dictionary) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func _request_resume(_token: String) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func _request_spectate(_room_id: String) -> void:
	pass

static func resolve_game_url(hub_url: String) -> String:
	if hub_url.begins_with("wss://"):
		var host := hub_url.substr(6).split("/")[0]
		return "wss://%s/game-ws" % host
	if hub_url.begins_with("ws://"):
		var host := hub_url.substr(5).split("/")[0]
		return "ws://%s:9121" % host.split(":")[0]
	return "ws://127.0.0.1:9121"
