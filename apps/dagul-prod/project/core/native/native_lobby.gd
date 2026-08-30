extends Control
## Steam/네이티브 전용 로비 — 방 목록 + 입장 + 생성 MVP.
## NetworkManager의 네이티브 경로(NativeHubClient)에 위임한다.
## 웹 빌드에서는 로드하지 않는다(boot.gd 분기).

signal game_starting(room_data: Dictionary)

const _POLL_SEC := 5.0

var _poll_acc := 0.0
var _connected := false
var _player_name := "Player"
var _rooms: Array = []
var _hub: Node = null

@onready var _url_input: LineEdit = %UrlInput
@onready var _connect_btn: Button = %ConnectBtn
@onready var _status_label: Label = %StatusLabel
@onready var _room_list: ItemList = %RoomList
@onready var _room_name_input: LineEdit = %RoomNameInput
@onready var _create_btn: Button = %CreateBtn
@onready var _join_btn: Button = %JoinBtn
@onready var _name_input: LineEdit = %NameInput
@onready var _refresh_btn: Button = %RefreshBtn


func _ready() -> void:
	_hub = get_node_or_null("/root/NetworkManager")
	_url_input.text = _env_server_url()
	_connect_btn.pressed.connect(_on_connect_pressed)
	_create_btn.pressed.connect(_on_create_pressed)
	_join_btn.pressed.connect(_on_join_pressed)
	_refresh_btn.pressed.connect(_on_refresh_pressed)
	_room_list.item_selected.connect(_on_room_selected)
	_name_input.text = _player_name
	_name_input.text_changed.connect(func(t: String) -> void: _player_name = t.strip_edges())
	_set_lobby_ui(false)
	_set_status("서버 URL을 입력하고 연결을 누르세요")  # lint-gd: i18n-ok
	if _hub != null:
		_bind_hub_signals()


func _bind_hub_signals() -> void:
	if _hub._native_client == null:
		return
	var client: Node = _hub._native_client
	client.room_listed.connect(_on_rooms_listed)
	client.room_joined.connect(_on_room_joined)
	client.error_received.connect(_on_error)


func _process(delta: float) -> void:
	if not _connected:
		return
	_poll_acc += delta
	if _poll_acc >= _POLL_SEC:
		_poll_acc = 0.0
		_hub.native_list_rooms()


func _env_server_url() -> String:
	var env := OS.get_environment("DAGUL_SERVER_URL")
	if env != "":
		return env
	return "http://localhost:2567"


func _on_connect_pressed() -> void:
	var url := _url_input.text.strip_edges()
	if url == "":
		_set_status("URL을 입력하세요")  # lint-gd: i18n-ok
		return
	_set_status("연결 중...")  # lint-gd: i18n-ok
	_connect_btn.disabled = true
	_hub.connect_to_server(url)
	_connected = true
	_connect_btn.disabled = false
	_set_lobby_ui(true)
	_hub.native_list_rooms()


func _on_rooms_listed(rooms: Array) -> void:
	_rooms = rooms
	_render_rooms()
	_set_status("연결됨 · 방 %d개" % _rooms.size())  # lint-gd: i18n-ok


func _render_rooms() -> void:
	_room_list.clear()
	for r in _rooms:
		if not r is Dictionary:
			continue
		var meta: Dictionary = r.get("metadata", {})
		var title: String = str(meta.get("title", r.get("roomId", "?")))
		var clients: int = int(r.get("clients", 0))
		var max_c: int = int(r.get("maxClients", 0))
		var phase: String = str(meta.get("phase", ""))
		var label := "%s  [%d/%d]  %s" % [title, clients, max_c, phase]
		_room_list.add_item(label)


func _on_room_selected(_index: int) -> void:
	_join_btn.disabled = false


func _on_refresh_pressed() -> void:
	if not _connected:
		return
	_poll_acc = 0.0
	_hub.native_list_rooms()


func _on_create_pressed() -> void:
	if not _connected:
		return
	var room_title := _room_name_input.text.strip_edges()
	var opts := {
		"name": _player_name,
		"title": room_title if room_title != "" else null,
		"game": WebContract.DEFAULT_GAME,
	}
	_set_status("방 생성 중...")  # lint-gd: i18n-ok
	_hub.native_join_or_create(opts)


func _on_join_pressed() -> void:
	if not _connected:
		return
	var sel := _room_list.get_selected_items()
	if sel.is_empty():
		_set_status("방을 선택하세요")  # lint-gd: i18n-ok
		return
	var idx: int = sel[0]
	if idx >= _rooms.size():
		return
	var room: Dictionary = _rooms[idx]
	var room_id: String = str(room.get("roomId", ""))
	if room_id == "":
		return
	_set_status("입장 중...")  # lint-gd: i18n-ok
	_hub.native_join_by_id(room_id, {"name": _player_name})


func _on_room_joined(data: Dictionary) -> void:
	_set_status("입장 성공: %s" % str(data.get("roomId", "")))  # lint-gd: i18n-ok
	game_starting.emit(data)
	var game_id: String = str(data.get("game", WebContract.DEFAULT_GAME))
	var path := "res://games/%s/main.tscn" % game_id
	if not ResourceLoader.exists(path):
		path = "res://games/%s/main.tscn" % WebContract.DEFAULT_GAME
	get_tree().call_deferred("change_scene_to_file", path)


func _on_error(msg: String) -> void:
	_set_status("오류: %s" % msg)  # lint-gd: i18n-ok
	_connect_btn.disabled = false


func _set_lobby_ui(on: bool) -> void:
	_room_list.visible = on
	_room_name_input.visible = on
	_create_btn.visible = on
	_join_btn.visible = on
	_join_btn.disabled = true
	_refresh_btn.visible = on


func _set_status(msg: String) -> void:
	_status_label.text = msg
