extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")
const NetWorldScript = preload("res://scripts/net/net_world.gd")
const TOUCH_CONTROLS_PATH := "res://addons/godot-touch-controls/touch_controls.gd"

@onready var world_view: Node2D = $WorldView
@onready var camera: Camera2D = $WorldView/Camera2D
@onready var hud: Control = $HUD/Overlay
@onready var screens: Control = $HUD/Screens

var world
var hub: Node  # → NetworkManager autoload
var _host_ctrl: NetworkHost = null
var _sfx: SfxManager = null
var _input: PlayerInput = null
var _spectator: Spectator = null
var _match_cam: MatchCamera = null
var seed: int = 2222
var last_event_id: int = 0
var hit_pause_frames: int = 0
var hud_mode: int = 0
var touch: CanvasLayer = null
var _net_banner: Label = null
var _touch_exit: Button = null
var _touch_rematch: Button = null

func _ready() -> void:
	_sfx = SfxManager.new()
	_sfx.setup(self)
	_attach_touch()
	_input = PlayerInput.new(touch)
	_spectator = Spectator.new()
	_build_touch_buttons()
	hub = get_node("/root/NetworkManager")
	screens.bind_hub(hub)
	hub.match_started.connect(_on_net_match_started)
	hub.match_resumed.connect(_on_net_match_resumed)
	hub.snapshot_received.connect(_on_net_snapshot)
	hub.status_changed.connect(_on_hub_status)
	_restart()
	_match_cam = MatchCamera.new(camera)
	camera.position = _match_cam.target(world, _spectator.slot, _spectator.is_valid.bind(world))
	screens.start_match.connect(_on_start_match)
	screens.request_resume.connect(func(): _set_phase(GameState.State.PLAYING))
	screens.request_quit_to_intro.connect(func(): _return_to_hub())
	screens.control_mode_changed.connect(_apply_control_mode)
	_apply_control_mode(screens.control_mode)
	Engine.max_fps = 60
	if GameState.hub_launched:
		screens.visible = false
		world_view.visible = false
		hud.visible = false
		hub.left_room.connect(func(): _return_to_hub())
		hub.hub_error.connect(func(_msg: String): _return_to_hub())
	else:
		_set_phase(GameState.State.LOBBY)

# --- Touch controls ---

func _attach_touch() -> void:
	if not ResourceLoader.exists(TOUCH_CONTROLS_PATH):
		return
	var script = load(TOUCH_CONTROLS_PATH)
	if script == null:
		return
	touch = script.new()
	touch.name = "TouchControls"
	$HUD.add_child(touch)

func _apply_control_mode(mode: String) -> void:
	if touch == null or not touch.has_method("set_control_mode"):
		return
	touch.set_control_mode(mode)
	hud.touch_hints = bool(touch.is_enabled())
	hud.queue_redraw()
	_sync_touch_buttons()

func _build_touch_buttons() -> void:
	var refs := TouchButtons.build($HUD, func(): _set_phase(GameState.State.ROOM_WAIT), func():
		seed += 1
		_restart()
	)
	_touch_exit = refs["exit"]
	_touch_rematch = refs["rematch"]
	_sync_touch_buttons()

func _sync_touch_buttons() -> void:
	var phase_name := _phase_name()
	TouchButtons.sync(_touch_exit, _touch_rematch, touch, phase_name, world, GameState.net_active)

## Map GameState enum back to the StringName TouchButtons expects.
func _phase_name() -> StringName:
	match GameState.current_state:
		GameState.State.LOBBY: return &"lobby"
		GameState.State.ROOM_WAIT: return &"wait"
		GameState.State.PLAYING: return &"play"
		_: return &"select"

# --- Phase management ---

func _on_start_match() -> void:
	GameState.net_active = false
	seed += 1
	_restart()
	_set_phase(GameState.State.PLAYING)

func _on_net_match_started(you: int, room: Dictionary) -> void:
	GameState.net_active = true
	GameState.net_host = hub.is_host
	if GameState.net_host:
		if _host_ctrl != null:
			_host_ctrl.disconnect_signals()
		seed += 1
		var host_world = WorldScript.new(seed)
		host_world.set_mode(str(room.get("mode", screens.selected_mode)))
		host_world.local_slot = you
		host_world.is_net = true
		host_world.reset()
		for p in hub.players:
			var s := int(p.get("slot", -1))
			if s >= 0 and not bool(p.get("dropped", false)):
				host_world.human_slots[s] = true
				if s < host_world.heroes.size():
					host_world.heroes[s]["display_name"] = str(p.get("name", ""))
		world = host_world
		_host_ctrl = NetworkHost.new(hub, world)
		_host_ctrl.connect_signals()
	else:
		var net_world = NetWorldScript.new()
		net_world.local_slot = you
		net_world.set_mode(str(room.get("mode", screens.selected_mode)))
		net_world.reset()
		world = net_world
	world_view.world = world
	hud.world = world
	hud.mode_id = str(room.get("mode", screens.selected_mode))
	_spectator.slot = you
	hud.spectate_slot = _spectator.slot
	hud.hud_mode = hud_mode
	last_event_id = 0
	hit_pause_frames = 0
	_input.previous_right_mouse = false
	_input.previous_left_mouse = false
	camera.position = _match_cam.target(world, _spectator.slot, _spectator.is_valid.bind(world))
	_set_phase(GameState.State.PLAYING)

func _on_net_match_resumed(you: int, room: Dictionary, snap: Dictionary) -> void:
	GameState.net_active = true
	if world == null or not bool(world.get("is_net")):
		_on_net_match_started(you, room)
	else:
		world.local_slot = you
		_spectator.slot = you
		hud.spectate_slot = _spectator.slot
	if not snap.is_empty() and world != null and bool(world.get("is_net")):
		world.push_snap(snap)
		world.present(0.0)
	_set_phase(GameState.State.PLAYING)

func _on_net_snapshot(snap: Dictionary) -> void:
	if GameState.net_active and world != null and bool(world.get("is_net")):
		world.push_snap(snap)

func _on_hub_status(next_status: String) -> void:
	if next_status == NetworkManager.STATUS_RECONNECTING:
		_set_net_banner(tr("GAME_RECONNECTING"))
		return
	_set_net_banner("")
	if next_status != NetworkManager.STATUS_CLOSED and next_status != NetworkManager.STATUS_OFFLINE:
		return
	if GameState.hub_launched:
		_return_to_hub()
		return
	if GameState.net_active:
		GameState.net_active = false
		if GameState.is_state(GameState.State.PLAYING):
			_return_to_hub()

func _return_to_hub() -> void:
	if GameState.hub_launched and OS.has_feature("web"):
		JavaScriptBridge.eval("location.href='/gang-up/'")
	else:
		_set_phase(GameState.State.LOBBY)

func _set_phase(next: GameState.State) -> void:
	GameState.request(next)
	var playing := next == GameState.State.PLAYING
	world_view.visible = playing
	hud.visible = playing
	screens.visible = not playing
	if touch != null:
		touch.set_playing(playing)
	_sync_touch_buttons()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if playing else Input.MOUSE_MODE_VISIBLE)
	if not playing:
		var page := _phase_name()
		if page == &"play" or page == &"select" or page == &"intro":
			page = &"lobby"
		screens.show_page(page)

func _set_net_banner(text: String) -> void:
	if _net_banner == null:
		_net_banner = Label.new()
		_net_banner.name = "NetBanner"
		_net_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_net_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_net_banner.add_theme_font_size_override("font_size", 20)
		_net_banner.add_theme_color_override("font_color", Color("FFF6E5"))
		var wrap := Panel.new()
		wrap.name = "NetBannerWrap"
		wrap.set_anchors_preset(Control.PRESET_TOP_WIDE)
		wrap.offset_left = 180
		wrap.offset_right = -180
		wrap.offset_top = 18
		wrap.offset_bottom = 70
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.08, 0.04, 0.86)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		wrap.add_theme_stylebox_override("panel", sb)
		_net_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrap.add_child(_net_banner)
		$HUD.add_child(wrap)
		wrap.z_index = 20
	var wrap_node: CanvasItem = _net_banner.get_parent()
	wrap_node.visible = text != ""
	_net_banner.text = text

func _restart() -> void:
	world = WorldScript.new(seed)
	world.set_mode(screens.selected_mode)
	world.reset()
	world_view.world = world
	hud.world = world
	hud.mode_id = screens.selected_mode
	if _spectator != null:
		_spectator.slot = 0
	hud.spectate_slot = 0
	hud.hud_mode = hud_mode
	last_event_id = 0
	hit_pause_frames = 0
	if _input != null:
		_input.previous_right_mouse = false
		_input.previous_left_mouse = false

# --- Physics process ---

func _physics_process(_delta: float) -> void:
	if not GameState.is_state(GameState.State.PLAYING):
		if _input.edge(KEY_ESCAPE):
			if screens.page == &"wait":
				_escape_wait()
			else:
				screens.pop_page()
		return
	if _input.edge(KEY_ESCAPE):
		if world != null and bool(world.finish_cine.get("on", false)):
			world.finish_cine = {}
			return
		_set_phase(GameState.State.ROOM_WAIT)
		return
	if not GameState.net_active and world != null and world.result != &"playing":
		if _input.edge(KEY_R):
			seed += 1
			_restart()
			return
	_sync_touch_buttons()
	if _input.edge(KEY_F1):
		hud_mode = (hud_mode + 1) % 3
		hud.hud_mode = hud_mode
		hud.queue_redraw()
	_spectator.update(world, _input)
	if hit_pause_frames > 0:
		hit_pause_frames -= 1
		world_view.queue_redraw()
		hud.queue_redraw()
		return
	var move := _input.read_move()
	var aim_world := _input.read_aim(get_viewport(), _local_player_pos())
	var primary := _input.read_primary()
	var equipment_held := _input.read_equipment()
	if GameState.net_active and GameState.net_host:
		var command := _input.build_command(move, aim_world, primary, equipment_held)
		world.step_tick(command, 1.0 / 60.0)
		if _host_ctrl != null:
			_host_ctrl.tick(1.0 / 60.0)
		hud.net_rtt_ms = int(hub.rtt_ms)
		hud.net_connected = bool(hub.is_open())
		_apply_recoil_mouse()
	elif GameState.net_active:
		var dash_held := _input.read_dash()
		var use_held := _input.read_use()
		world.present(1.0 / 60.0)
		hud.net_rtt_ms = int(hub.rtt_ms)
		hud.net_connected = bool(hub.is_open())
		var seq: int = int(world.predict_local(move, dash_held, aim_world, 1.0 / 60.0))
		hub.send_input(move, primary, dash_held, use_held, aim_world, seq)
		_input.previous_right_mouse = equipment_held
	else:
		var command := _input.build_command(move, aim_world, primary, equipment_held)
		if not GameState.net_active and world != null:
			if _input.edge(KEY_BRACKETLEFT):
				world.cycle_local_animal(-1)
			if _input.edge(KEY_BRACKETRIGHT):
				world.cycle_local_animal(1)
		world.step_tick(command, 1.0 / 60.0)
		_apply_recoil_mouse()
	# SFX
	var sfx_result := _sfx.process_events(world, int(world.get("local_slot")) if world != null else 0, last_event_id)
	last_event_id = sfx_result["last_event_id"]
	hit_pause_frames = maxi(hit_pause_frames, sfx_result["hit_pause"])
	# Camera
	_spectator.update(world, _input)
	_match_cam.update(world, _spectator.slot, _spectator.is_valid.bind(world))
	hud.spectate_slot = _spectator.slot
	world_view.queue_redraw()
	hud.queue_redraw()

# --- Helpers ---

func _local_player_pos() -> Vector2:
	if world == null or world.heroes.is_empty():
		return Vector2.ZERO
	var me: Dictionary = world.heroes[clampi(world.local_slot, 0, world.heroes.size() - 1)]
	return Vector2(me["pos"])

func _escape_wait() -> void:
	if _host_ctrl != null:
		_host_ctrl.disconnect_signals()
	GameState.net_active = false
	GameState.net_host = false
	if hub.in_room:
		hub.leave_room()
	_return_to_hub()

func _apply_recoil_mouse() -> void:
	if world == null:
		return
	var kick: Vector2 = world.local_mouse_kick
	world.local_mouse_kick = Vector2.ZERO
	if kick.length_squared() < 0.01:
		return
	var vp := get_viewport()
	var rect := vp.get_visible_rect()
	var next: Vector2 = vp.get_mouse_position() + kick
	next.x = clampf(next.x, 10.0, rect.size.x - 10.0)
	next.y = clampf(next.y, 10.0, rect.size.y - 10.0)
	vp.warp_mouse(next)
