extends Node
## 매치 셸 — 게임 무관 수명주기만 담당한다.
## 부팅 → 브릿지의 match 신호 → GameRegistry 로 게임 모듈 로드 → 위임 →
## 종료/이탈/끊김 시 웹 셸(React)에 복귀 통지.
## 게임 지식(월드·입력·카메라·HUD 내용)은 전부 games/<id>/game.gd 소유.

const TOUCH_CONTROLS_PATH := "res://addons/godot-touch-controls/touch_controls.gd"
# Autoload 전역명은 --script 단독 파스에서 안 잡힌다. 스크립트는 preload, 인스턴스는 싱글톤.
const GameStateScript := preload("res://core/autoload/game_state.gd")

@onready var world_view: Node2D = $WorldView
@onready var camera: Camera2D = $WorldView/Camera2D
@onready var hud: Control = $HUD/Overlay
@onready var hud_layer: CanvasLayer = $HUD

var hub: Node = null
var module: GameModule = null
var touch: CanvasLayer = null
var _ctx: Dictionary = {}
var _play_probe_acc := 0.0

func _ready() -> void:
	hub = get_node_or_null("/root/NetworkManager")
	if "--server" in OS.get_cmdline_user_args():
		_start_dedicated_server()
		return
	_attach_touch()
	Engine.max_fps = 60
	world_view.visible = false
	hud.visible = false
	_ctx = {
		"hub": hub, "world_view": world_view, "camera": camera,
		"hud": hud, "hud_layer": hud_layer, "touch": touch,
		"leave": Callable(self, "_leave_match"),
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
		JavaScriptBridge.eval("window.glog && window.glog('godot','shell_ready')")

func _on_match_resumed(you: int, room: Dictionary, snap: Dictionary) -> void:
	_on_match_started(you, room)
	if not snap.is_empty():
		module.push_snap(snap)

func _on_snapshot_received(snap: Dictionary) -> void:
	if module != null:
		module.push_snap(snap)

func _game_state() -> Node:
	return Engine.get_singleton("GameState") as Node

func _on_host_changed(now_host: bool) -> void:
	_game_state().set("net_host", now_host)
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
	_game_state().set("net_active", true)
	_game_state().set("net_host", hub.is_host)
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
	_game_state().request(GameStateScript.State.PLAYING)
	_apply_playing_visuals(true)

func _physics_process(delta: float) -> void:
	if not _game_state().is_state(GameStateScript.State.PLAYING) or module == null:
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
	_game_state().set("net_active", false)
	_game_state().set("net_host", false)
	if hub != null and hub.in_room:
		hub.leave_room()
	_return_to_hub()

## 매치가 끝나거나 연결이 사라지면 웹 셸에 복귀를 알린다.
func _return_to_hub() -> void:
	if module != null:
		module.stop()
	_game_state().request(GameStateScript.State.BOOT)
	_apply_playing_visuals(false)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.dispatchEvent(new CustomEvent('%s', {detail: {}}))" % WebContract.EVT_MATCH_END)

## 매치 표시 전환 — 상태 판정은 GameState(SSOT)가, 화면 반영은 여기가 담당한다.
func _apply_playing_visuals(playing: bool) -> void:
	world_view.visible = playing
	hud.visible = playing
	if touch != null:
		touch.set_playing(playing)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if playing else Input.MOUSE_MODE_VISIBLE)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.glog && window.glog('shell.phase','%s')" % ("play" if playing else "boot"))

func _attach_touch() -> void:
	if not ResourceLoader.exists(TOUCH_CONTROLS_PATH):
		return
	var script = load(TOUCH_CONTROLS_PATH)
	if script == null:
		return
	touch = script.new()
	touch.name = "TouchControls"
	hud_layer.add_child(touch)

func _start_dedicated_server() -> void:
	world_view.visible = false
	hud.visible = false
	module = GameRegistry.load_game(_game_id())
	if module != null:
		module.start_dedicated(self)
