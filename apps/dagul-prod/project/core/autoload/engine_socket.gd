extends Node
## 매치 중 Colyseus 직접 접속. 실패·차단이면 브리지 경로를 그대로 둔다.

const _FLAG_KEY := "dagul.engineSocket"
const _JOIN_TIMEOUT_SEC := 3.0
const _AdapterScript := preload("res://core/net/match_snap_adapter.gd")

var active := false  # lint-gd: public-api
var _adapter = _AdapterScript.new()
var _client = null
var _room = null
var _trying := false
var _deadline_ms: int = 0
var _sent: Array = []
var _notices: Array = []
var _claim_ready := false

func is_active() -> bool:  # lint-gd: public-api
	return active

func send_input(msg: Dictionary) -> void:  # lint-gd: public-api
	if not active:
		return
	_sent.append(msg)
	if _sent.size() > 8:
		_sent.pop_front()
	if _room != null and _room.has_method("send_message"):
		_room.send_message(WebContract.MSG_INPUT, msg)

func _ready() -> void:
	var hub := get_node_or_null("/root/NetworkManager")
	if hub == null:
		return
	if not hub.match_started.is_connected(_on_match_started):
		hub.match_started.connect(_on_match_started)
	if not hub.left_room.is_connected(_on_left_room):
		hub.left_room.connect(_on_left_room)
	if bool(hub.get("match_running")):
		_try_connect()

func _process(_delta: float) -> void:
	if not _trying or active:
		return
	if Time.get_ticks_msec() < _deadline_ms:
		return
	_abort_join()

func _on_match_started(_you: int, _room: Dictionary) -> void:
	_try_connect()

func _on_left_room() -> void:
	_trying = false
	_set_live(false)

func _try_connect() -> void:
	if active or _trying:
		return
	if _flag_off():
		return
	var room_id := _room_id()
	if room_id == "":
		return
	if not _can_join():
		return
	_begin_join(room_id)

func _can_join() -> bool:
	if not OS.has_feature("web"):
		return false
	return ClassDB.class_exists(&"_ColyseusClient")

func _flag_off() -> bool:
	return _js("try{sessionStorage.getItem('%s')||''}catch(e){''}" % _FLAG_KEY) == "off"

func _begin_join(room_id: String) -> void:
	if not _has_claim():
		return
	var endpoint := _ws_endpoint()
	if endpoint == "":
		return
	_trying = true
	_deadline_ms = Time.get_ticks_msec() + int(_JOIN_TIMEOUT_SEC * 1000.0)
	_client = Colyseus.Client.new(endpoint)
	_room = _client.join_by_id(room_id, _join_options())
	if _room == null:
		_trying = false
		return
	_bind_room(_room)

func _bind_room(room) -> void:
	if room.has_method("set_state_type"):
		room.set_state_type(LobbyColyseus.LobbyState)
	if room.has_signal("joined"):
		room.joined.connect(_on_joined)
	if room.has_signal("error"):
		room.error.connect(_on_room_error)
	if room.has_signal("state_changed"):
		room.state_changed.connect(_on_state_changed)
	if room.has_signal("left"):
		room.left.connect(func(_c, _r): _on_left_room())

func _on_joined() -> void:
	_trying = false
	if not _claim_ok():
		_set_live(false)
		return
	_set_live(true)
	_on_state_changed()

func _on_room_error(_code: int, _message: String) -> void:
	_trying = false
	_set_live(false)

func _set_live(on: bool) -> void:
	if on:
		if active:
			return
		active = true
		_notify_page(WebContract.MSG_SNAP_OFF)
		return
	if not active:
		_drop_room()
		return
	active = false
	_adapter.reset()
	_notify_page(WebContract.MSG_SNAP_ON)
	_drop_room()

func _notify_page(type: String) -> void:
	_notices.append(type)
	var hub := get_node_or_null("/root/NetworkManager")
	if hub == null:
		return
	hub.call("_send", type, {})

func _abort_join() -> void:
	_trying = false
	if active:
		return
	_drop_room()

func _drop_room() -> void:
	var room = _room
	_room = null
	_client = null
	if room != null and room.has_method("leave"):
		room.leave()

func _on_state_changed() -> void:
	if not active or _room == null:
		return
	var match_state: Variant = _match_of(_room.get_state())
	if not _adapter.ingest(match_state):
		return
	_emit_snap()

func _emit_snap() -> void:
	var hub := get_node_or_null("/root/NetworkManager")
	if hub == null:
		return
	hub.snapshot_received.emit(_adapter.snap())

func _match_of(state: Variant) -> Variant:
	if state == null:
		return {}
	var d := _as_dict(state)
	if d.has("match"):
		return d["match"]
	if typeof(state) == TYPE_OBJECT and state.get("match") != null:
		return state.get("match")
	return {}

func _as_dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	if v != null and typeof(v) == TYPE_OBJECT and v.has_method("to_dictionary"):
		return v.to_dictionary()
	return {}

func _join_options() -> Dictionary:
	var opts := {"engine": true}
	_claim_ready = _has_claim()
	if not _claim_ready:
		return opts
	opts["guestId"] = int(_cookie(WebContract.KEY_GUEST_ID))
	opts["guestKey"] = _cookie(WebContract.KEY_GUEST_KEY)
	return opts

func _has_claim() -> bool:
	return _cookie(WebContract.KEY_GUEST_ID) != "" and _cookie(WebContract.KEY_GUEST_KEY) != ""

func _claim_ok() -> bool:
	return _claim_ready or _has_claim()

func _room_id() -> String:
	var parsed: Variant = JSON.parse_string(_read_ls(WebContract.KEY_MATCH))
	if not parsed is Dictionary:
		return ""
	var join: Variant = parsed.get("engineJoin", {})
	if not join is Dictionary:
		return ""
	return str(join.get("roomId", "")).strip_edges()

func _ws_endpoint() -> String:
	var origin := _js("location.origin||''")
	if origin == "":
		origin = _engine_endpoint()
	return _to_ws(origin)

func _engine_endpoint() -> String:
	var parsed: Variant = JSON.parse_string(_read_ls(WebContract.KEY_MATCH))
	if not parsed is Dictionary:
		return ""
	var join: Variant = parsed.get("engineJoin", {})
	if not join is Dictionary:
		return ""
	return str(join.get("endpoint", "")).strip_edges()

func _to_ws(origin: String) -> String:
	if origin.begins_with("https://"):
		return "wss://" + origin.substr(8)
	if origin.begins_with("http://"):
		return "ws://" + origin.substr(7)
	return origin

func _read_ls(key: String) -> String:
	return _js("try{sessionStorage.getItem('%s')||''}catch(e){''}" % key)

func _cookie(name: String) -> String:
	var expr := "(function(){var n='%s=';var p=document.cookie.split(';');for(var i=0;i<p.length;i++){var t=p[i].trim();if(t.indexOf(n)===0)return decodeURIComponent(t.slice(n.length));}return '';})()" % name
	return _js(expr)

func _js(expr: String) -> String:
	if not OS.has_feature("web"):
		return ""
	var text := str(JavaScriptBridge.eval(expr, true)).strip_edges()
	if text == "<null>" or text == "null" or text == "undefined":
		return ""
	return text
