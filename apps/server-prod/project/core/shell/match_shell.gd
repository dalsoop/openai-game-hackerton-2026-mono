extends Node
## 매치 셸 — 게임 무관 수명주기만 담당한다.
## 부팅 → 브릿지의 match 신호 → GameRegistry 로 게임 모듈 로드 → 위임 →
## 종료/이탈/끊김 시 웹 셸(React)에 복귀 통지.
## 게임 지식(월드·입력·카메라·HUD 내용)은 전부 games/<id>/game.gd 소유.

const TOUCH_CONTROLS_PATH := "res://addons/godot-touch-controls/touch_controls.gd"
# Autoload 전역명은 --script 단독 파스에서 안 잡힌다. 스크립트는 preload, 인스턴스는 싱글톤.
const GameStateScript := preload("res://core/autoload/game_state.gd")
const HeldInputScript := preload("res://core/input/held_input.gd")
const PlayChromeScript := preload("res://core/shell/play_chrome.gd")
const InGameSettingsScript := preload("res://core/ui/in_game_settings.gd")
const SettingsStoreScript := preload("res://core/ui/settings_store.gd")

@onready var world_view: Node2D = $WorldView
@onready var camera: Camera2D = $WorldView/Camera2D
@onready var hud: Control = $HUD/Overlay
@onready var hud_layer: CanvasLayer = $HUD

var hub: Node = null
var module: GameModule = null
var touch: CanvasLayer = null
var settings: CanvasLayer = null
var _ctx: Dictionary = {}
var _play_probe_acc := 0.0
var _js_visibility_cb = null

func _ready() -> void:
	hub = get_node_or_null("/root/NetworkManager")
	if "--server" in OS.get_cmdline_user_args():
		_start_dedicated_server()
		return
	_attach_touch()
	_attach_settings()
	_apply_sound(SettingsStoreScript.load_sound_on())
	Engine.max_fps = 60
	world_view.visible = false
	hud.visible = false
	_ctx = {
		"hub": hub, "world_view": world_view, "camera": camera,
		"hud": hud, "hud_layer": hud_layer, "touch": touch,
		"leave": Callable(self, "_leave_match"),
		"settings_open": false,
		"net_active": false,
	}
	if hub != null:
		hub.match_started.connect(_on_match_started)
		hub.match_resumed.connect(_on_match_resumed)
		hub.snapshot_received.connect(_on_snapshot_received)
		hub.host_changed.connect(_on_host_changed)
		hub.left_room.connect(_return_to_hub)
		hub.hub_error.connect(func(_msg: String): _return_to_hub())
		hub.joined_room.connect(func(_r, _p, _y): _return_to_hub())
		if hub.has_method("start_handoff"):
			hub.start_handoff()
		if hub.has_method("consume_pending_match"):
			hub.consume_pending_match()
	if OS.has_feature("web"):
		_bind_web_visibility()
		JavaScriptBridge.eval("window.glog && window.glog('godot','shell_ready')")

func _on_match_resumed(you: int, room: Dictionary, snap: Dictionary) -> void:
	_on_match_started(you, room)
	if not snap.is_empty():
		module.push_snap(snap)

func _on_snapshot_received(snap: Dictionary) -> void:
	if module != null:
		module.push_snap(snap)

func _game_state() -> Node:
	# 오토로드는 엔진 싱글톤 API 대상이 아니다. 그 경로로 찾으면
	# 웹에서 null 이 나와 매치 진입이 죽는다. /root 노드가 정본이다.
	return get_node_or_null("/root/GameState")

func _on_host_changed(now_host: bool) -> void:
	var gs := _game_state()
	if gs == null:
		return
	gs.set("net_host", now_host)
	if module == null:
		return
	if now_host:
		module.become_host(_ctx)
	else:
		module.become_guest(_ctx)

func _game_id() -> String:
	if not OS.has_feature("web"):
		return WebContract.DEFAULT_GAME
	var raw := str(JavaScriptBridge.eval(
		"try{localStorage.getItem('%s')||''}catch(e){''}" % WebContract.KEY_GAME, true)).strip_edges()
	if raw == "" or raw == "null" or raw == "undefined":
		return WebContract.DEFAULT_GAME
	return raw

func _on_match_started(you: int, room: Dictionary) -> void:
	var gs := _game_state()
	if gs == null:
		_return_to_hub()
		return
	gs.set("net_active", true)
	_ctx["net_active"] = true
	gs.set("net_host", hub.is_host)
	if module == null:
		module = GameRegistry.load_game(_game_id())
		if module == null:
			_return_to_hub()
			return
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.dispatchEvent(new CustomEvent('%s'))" % WebContract.EVT_MATCH_START)
	module.start({
		"you": you,
		"host": hub.is_host,
		"seed": int(room.get("seed", 0)),
		"mode": str(room.get("mode", WebContract.DEFAULT_MODE)),
		"seats": hub.players,
	}, _ctx)
	gs.request(GameStateScript.State.PLAYING)
	_apply_playing_visuals(true)
	if settings != null:
		if settings.has_method("select_mode"):
			settings.select_mode(SettingsStoreScript.load_control_mode())

func _physics_process(delta: float) -> void:
	var gs := _game_state()
	if gs == null or not gs.is_state(GameStateScript.State.PLAYING) or module == null:
		return
	module.tick(delta, _ctx)
	_emit_play_probe(delta)

func _emit_play_probe(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_play_probe_acc += delta
	if _play_probe_acc < 0.2:
		return
	_play_probe_acc = 0.0
	var world = module.get("world")
	if world == null:
		return
	var slot := int(world.get("local_slot"))
	var heroes = world.get("heroes")
	var x := 0.0
	var y := 0.0
	if heroes is Array and slot >= 0 and slot < heroes.size():
		var pos := Vector2(heroes[slot]["pos"])
		x = pos.x
		y = pos.y
	var js := "window.__dagulPlay={t:%d,c:%f,time:%f,h:%d,x:%f,y:%f}" % [
		int(world.get("tick")),
		float(world.get("start_countdown")),
		float(world.get("match_time")),
		1 if hub != null and bool(hub.is_host) else 0,
		x, y,
	]
	JavaScriptBridge.eval(js)

func _leave_match() -> void:
	var gs := _game_state()
	if gs != null:
		gs.set("net_active", false)
		gs.set("net_host", false)
	_ctx["net_active"] = false
	if hub != null and hub.in_room:
		hub.leave_room()
	_return_to_hub()

## 매치가 끝나거나 연결이 사라지면 웹 셸에 복귀를 알린다.
func _return_to_hub() -> void:
	if module != null:
		module.stop()
	var gs := _game_state()
	if gs != null:
		gs.request(GameStateScript.State.BOOT)
	_ctx["net_active"] = false
	_apply_playing_visuals(false)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.dispatchEvent(new CustomEvent('%s', {detail: {}}))" % WebContract.EVT_MATCH_END)

## 매치 표시 전환 — 상태 판정은 GameState(SSOT)가, 화면 반영은 여기가 담당한다.
func _apply_playing_visuals(playing: bool) -> void:
	world_view.visible = playing
	hud.visible = playing
	if settings != null and settings.has_method("set_playing"):
		settings.call("set_playing", playing)
	_sync_play_chrome()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.glog && window.glog('shell.phase','%s')" % ("play" if playing else "boot"))


func _sync_play_chrome() -> void:
	var playing := world_view.visible
	var menu_open := settings != null and bool(settings.get("is_open"))
	_ctx["settings_open"] = menu_open
	if touch != null:
		touch.set_playing(PlayChromeScript.touch_playing(playing, menu_open))
	Input.set_mouse_mode(
		Input.MOUSE_MODE_HIDDEN if PlayChromeScript.mouse_hidden(playing, menu_open)
		else Input.MOUSE_MODE_VISIBLE)

func _attach_touch() -> void:
	if not ResourceLoader.exists(TOUCH_CONTROLS_PATH):
		return
	var script = load(TOUCH_CONTROLS_PATH)
	if script == null:
		return
	touch = script.new()
	touch.name = "TouchControls"
	hud_layer.add_child(touch)
	if touch.has_method("set_control_mode"):
		touch.set_control_mode(SettingsStoreScript.load_control_mode())


func _attach_settings() -> void:
	settings = InGameSettingsScript.new()
	settings.name = "InGameSettings"
	add_child(settings)
	settings.connect("open_changed", func(_open: bool) -> void: _sync_play_chrome())
	settings.connect("mode_picked", _on_control_mode)
	settings.connect("sound_changed", _on_sound)
	settings.connect("leave_requested", _leave_match)


func _on_control_mode(mode: String) -> void:
	SettingsStoreScript.save(mode, SettingsStoreScript.load_sound_on())
	if touch != null and touch.has_method("set_control_mode"):
		touch.set_control_mode(mode)


func _on_sound(on: bool) -> void:
	SettingsStoreScript.save(SettingsStoreScript.load_control_mode(), on)
	_apply_sound(on)


func _apply_sound(on: bool) -> void:
	AudioServer.set_bus_mute(0, not on)


func _bind_web_visibility() -> void:
	_js_visibility_cb = JavaScriptBridge.create_callback(_on_web_visibility)
	var doc = JavaScriptBridge.get_interface("document")
	if doc == null:
		return
	doc.addEventListener("visibilitychange", _js_visibility_cb)


func _on_web_visibility(_args: Array) -> void:
	var doc = JavaScriptBridge.get_interface("document")
	if doc != null and bool(doc.hidden):
		HeldInputScript.release_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT \
			or what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		HeldInputScript.release_all()


func _start_dedicated_server() -> void:
	world_view.visible = false
	hud.visible = false
	module = GameRegistry.load_game(_game_id())
	if module != null:
		module.start_dedicated(self)