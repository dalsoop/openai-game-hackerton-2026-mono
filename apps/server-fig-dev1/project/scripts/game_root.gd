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
var previous_keys: Dictionary = {}
var seed: int = 2222
var last_event_id: int = 0
var hit_pause_frames: int = 0
var spectate_slot: int = 0
var hud_mode: int = 0
var previous_right_mouse: bool = false
var previous_left_mouse: bool = false
var phase: StringName = &"select"
var touch: CanvasLayer = null
var _net_banner: Label = null
var _touch_exit: Button = null
var _touch_rematch: Button = null

func _ready() -> void:
	_sfx = SfxManager.new()
	_sfx.setup(self)
	_attach_touch()
	_build_touch_buttons()
	hub = get_node("/root/NetworkManager")
	screens.bind_hub(hub)
	hub.match_started.connect(_on_net_match_started)
	hub.match_resumed.connect(_on_net_match_resumed)
	hub.snapshot_received.connect(_on_net_snapshot)
	hub.status_changed.connect(_on_hub_status)
	_restart()
	camera.position = _camera_target()
	screens.start_match.connect(_on_start_match)
	screens.request_resume.connect(func(): _set_phase(&"play"))
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
		hub.joined_room.connect(func(_r, _p, _y): pass)
	else:
		_set_phase(&"lobby")

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
	var layer := CanvasLayer.new()
	layer.name = "TouchMenu"
	layer.layer = 3
	$HUD.add_child(layer)
	_touch_exit = _touch_button("나가기", Color("3D4654"))
	_touch_exit.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_touch_exit.offset_left = -120
	_touch_exit.offset_right = -16
	_touch_exit.offset_top = 14
	_touch_exit.offset_bottom = 58
	_touch_exit.pressed.connect(func(): _set_phase(&"wait"))
	layer.add_child(_touch_exit)
	_touch_rematch = _touch_button("재경기", Color("2F6BFF"))
	_touch_rematch.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_touch_rematch.offset_left = -110
	_touch_rematch.offset_right = 110
	_touch_rematch.offset_top = -160
	_touch_rematch.offset_bottom = -104
	_touch_rematch.pressed.connect(func():
		seed += 1
		_restart()
	)
	layer.add_child(_touch_rematch)
	_sync_touch_buttons()

func _touch_button(text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.visible = false
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, 0.92)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func _sync_touch_buttons() -> void:
	if _touch_exit == null:
		return
	var playing: bool = phase == &"play"
	var touch_on: bool = touch != null and touch.has_method("is_enabled") and bool(touch.is_enabled())
	var finished: bool = world != null and world.get("result") != null and world.result != &"playing"
	_touch_exit.visible = playing and (touch_on or finished)
	_touch_exit.text = "대기실로" if finished else "나가기"
	_touch_rematch.visible = playing and finished and not GameState.net_active
	if touch != null and touch.has_method("set_playing"):
		touch.set_playing(playing and not finished)

# --- Phase management ---

func _on_start_match() -> void:
	GameState.net_active = false
	seed += 1
	_restart()
	_set_phase(&"play")

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
	spectate_slot = you
	hud.spectate_slot = spectate_slot
	hud.hud_mode = hud_mode
	last_event_id = 0
	hit_pause_frames = 0
	previous_right_mouse = false
	previous_left_mouse = false
	camera.position = _camera_target()
	_set_phase(&"play")

func _on_net_match_resumed(you: int, room: Dictionary, snap: Dictionary) -> void:
	GameState.net_active = true
	if world == null or not bool(world.get("is_net")):
		_on_net_match_started(you, room)
	else:
		world.local_slot = you
		spectate_slot = you
		hud.spectate_slot = spectate_slot
	if not snap.is_empty() and world != null and bool(world.get("is_net")):
		world.push_snap(snap)
		world.present(0.0)
	_set_phase(&"play")

func _on_net_snapshot(snap: Dictionary) -> void:
	if GameState.net_active and world != null and bool(world.get("is_net")):
		world.push_snap(snap)

func _on_hub_status(next_status: String) -> void:
	if next_status == "다시 연결 중":
		_set_net_banner("연결이 끊겼습니다. 같은 자리로 다시 붙는 중입니다.")
		return
	_set_net_banner("")
	if next_status != "끊김" and next_status != "오프라인 로컬":
		return
	if GameState.hub_launched:
		_return_to_hub()
		return
	if GameState.net_active:
		GameState.net_active = false
		if phase == &"play":
			_return_to_hub()

func _return_to_hub() -> void:
	if GameState.hub_launched and OS.has_feature("web"):
		JavaScriptBridge.eval("location.href='/gang-up/'")
	else:
		_set_phase(&"lobby")

func _set_phase(next: StringName) -> void:
	phase = next
	var playing := next == &"play"
	world_view.visible = playing
	hud.visible = playing
	screens.visible = not playing
	if touch != null:
		touch.set_playing(playing)
	_sync_touch_buttons()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if playing else Input.MOUSE_MODE_VISIBLE)
	if not playing:
		var page := next
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
	spectate_slot = 0
	hud.spectate_slot = spectate_slot
	hud.hud_mode = hud_mode
	last_event_id = 0
	hit_pause_frames = 0
	previous_right_mouse = false
	previous_left_mouse = false

# --- Physics process ---

func _physics_process(_delta: float) -> void:
	if phase != &"play":
		if _edge(KEY_ESCAPE):
			if screens.page == &"wait":
				_escape_wait()
			else:
				screens.pop_page()
		return
	if _edge(KEY_ESCAPE):
		if world != null and bool(world.finish_cine.get("on", false)):
			world.finish_cine = {}
			return
		_set_phase(&"wait")
		return
	if not GameState.net_active and world != null and world.result != &"playing":
		if _edge(KEY_R):
			seed += 1
			_restart()
			return
	_sync_touch_buttons()
	if _edge(KEY_F1):
		hud_mode = (hud_mode + 1) % 3
		hud.hud_mode = hud_mode
		hud.queue_redraw()
	_update_spectator()
	if hit_pause_frames > 0:
		hit_pause_frames -= 1
		world_view.queue_redraw()
		hud.queue_redraw()
		return
	var keyboard_move := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	if keyboard_move.length_squared() > 1.0:
		keyboard_move = keyboard_move.normalized()
	var move := keyboard_move
	if touch != null and keyboard_move.length() <= 0.1:
		move = touch.move
	var aim_world := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	if touch != null and touch.aiming:
		aim_world = _local_player_pos() + touch.aim_dir * 400.0
	var primary: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or (touch != null and touch.fire)
	var equipment_held: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or (touch != null and touch.skill)
	if GameState.net_active and GameState.net_host:
		var command := _build_command(move, aim_world, primary, equipment_held)
		previous_right_mouse = equipment_held
		previous_left_mouse = primary
		world.step_tick(command, 1.0 / 60.0)
		if _host_ctrl != null:
			_host_ctrl.tick(1.0 / 60.0)
		hud.net_rtt_ms = int(hub.rtt_ms)
		hud.net_connected = bool(hub.is_open())
		_apply_recoil_mouse()
	elif GameState.net_active:
		var dash_held: bool = Input.is_key_pressed(KEY_SHIFT) or (touch != null and touch.dash_held)
		var use_held: bool = Input.is_key_pressed(KEY_E) or (touch != null and touch.medkit_held)
		world.present(1.0 / 60.0)
		hud.net_rtt_ms = int(hub.rtt_ms)
		hud.net_connected = bool(hub.is_open())
		var seq: int = int(world.predict_local(move, dash_held, aim_world, 1.0 / 60.0))
		hub.send_input(move, primary, dash_held, use_held, aim_world, seq)
		previous_right_mouse = equipment_held
	else:
		var command := _build_command(move, aim_world, primary, equipment_held)
		if not GameState.net_active and world != null:
			if _edge(KEY_BRACKETLEFT):
				world.cycle_local_animal(-1)
			if _edge(KEY_BRACKETRIGHT):
				world.cycle_local_animal(1)
		previous_right_mouse = equipment_held
		previous_left_mouse = primary
		world.step_tick(command, 1.0 / 60.0)
		_apply_recoil_mouse()
	# SFX
	var sfx_result := _sfx.process_events(world, int(world.get("local_slot")) if world != null else 0, last_event_id)
	last_event_id = sfx_result["last_event_id"]
	hit_pause_frames = maxi(hit_pause_frames, sfx_result["hit_pause"])
	# Camera
	_update_spectator()
	var shake := _compute_shake()
	var zoom_target := _camera_zoom_target()
	camera.zoom = camera.zoom.lerp(Vector2.ONE * zoom_target, 0.065)
	var camera_follow := 0.24 if world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot == world.local_slot else 0.42
	camera.position = camera.position.lerp(_camera_target(), camera_follow) + shake
	hud.spectate_slot = spectate_slot
	world_view.queue_redraw()
	hud.queue_redraw()

# --- Helpers ---

func _build_command(move: Vector2, aim: Vector2, primary: bool, equipment_held: bool) -> Dictionary:
	var ultimate_edge := _edge(KEY_Q)
	var mobility_edge := _edge(KEY_SHIFT)
	var hop_edge := _edge(KEY_SPACE)
	var medkit_edge := _edge(KEY_E)
	var reload_edge := _edge(KEY_R)
	if touch != null:
		ultimate_edge = touch.consume_ult() or ultimate_edge
		mobility_edge = touch.consume_dash() or mobility_edge
		medkit_edge = touch.consume_medkit() or medkit_edge
	return {
		"move": move, "aim": aim,
		"primary": primary,
		"primary_pressed": primary and not previous_left_mouse,
		"equipment": equipment_held,
		"equipment_pressed": equipment_held and not previous_right_mouse,
		"equipment_released": not equipment_held and previous_right_mouse,
		"ultimate": ultimate_edge, "mobility": mobility_edge,
		"hop": hop_edge, "medkit": medkit_edge,
		"reload": reload_edge, "finish": _edge(KEY_F)
	}

func _compute_shake() -> Vector2:
	var shake := Vector2.ZERO
	if int(world.get("local_hit_shake")) > 0:
		var hit_n: int = int(world.local_hit_shake)
		shake = Vector2(sin(float(world.tick) * 5.2), cos(float(world.tick) * 7.1)) * (8.2 + float(hit_n) * 1.05)
	var fire_n: int = int(world.local_fire_shake)
	if fire_n > 0:
		shake += Vector2(sin(float(world.tick) * 11.0), cos(float(world.tick) * 13.4)) * (5.5 + float(fire_n) * 0.95)
	elif world.impact_ticks > 0:
		var impact_distance := _camera_target().distance_to(Vector2(world.impact_pos))
		var attenuation := 1.0 - clampf(impact_distance / 900.0, 0.0, 0.90)
		shake = Vector2(sin(float(world.tick) * 2.8), cos(float(world.tick) * 4.1)) * (2.0 + world.impact_ticks * 0.4) * attenuation
	return shake

func _edge(keycode: int) -> bool:
	var now := Input.is_key_pressed(keycode) or Input.is_physical_key_pressed(keycode)
	var was := bool(previous_keys.get(keycode, false))
	previous_keys[keycode] = now
	return now and not was

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

# --- Spectator ---

func _spectator_valid(slot: int) -> bool:
	return slot >= 0 and slot != world.local_slot and slot < world.heroes.size() and bool(world.heroes[slot]["alive"]) and not bool(world.heroes[slot]["eliminated"])

func _best_spectator() -> int:
	var best := -1
	var best_score := -1.0
	for slot in range(world.heroes.size()):
		if _spectator_valid(slot) and float(world.heroes[slot]["score"]) > best_score:
			best = slot
			best_score = float(world.heroes[slot]["score"])
	return best

func _cycle_spectator(direction: int) -> void:
	var current: int = spectate_slot if spectate_slot >= 0 else world.local_slot
	for offset in range(1, world.heroes.size() + 1):
		var candidate := posmod(current + direction * offset, world.heroes.size())
		if _spectator_valid(candidate):
			spectate_slot = candidate
			return

func _update_spectator() -> void:
	if world == null or world.heroes.is_empty():
		return
	var me_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
	if not bool(world.heroes[me_slot]["eliminated"]):
		spectate_slot = world.local_slot
		return
	if not _spectator_valid(spectate_slot):
		spectate_slot = _best_spectator()
	if _edge(KEY_A):
		_cycle_spectator(-1)
	if _edge(KEY_D) or _edge(KEY_TAB):
		_cycle_spectator(1)
	if _edge(KEY_SPACE):
		spectate_slot = _best_spectator()

# --- Camera ---

func _camera_zoom_target() -> float:
	if world == null or world.heroes.is_empty():
		return 1.38
	if world.result != &"playing" and world.winner_slot >= 0:
		return 1.52
	if world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot == world.local_slot:
		return 1.48
	var me_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
	if not bool(world.heroes[me_slot]["alive"]):
		return 1.18
	var focus_pos: Vector2 = world.heroes[me_slot]["pos"]
	var nearby := 0
	for hero in world.heroes:
		if bool(hero["alive"]) and Vector2(hero["pos"]).distance_to(focus_pos) < 470.0:
			nearby += 1
	if nearby >= 4:
		return 1.20
	if nearby >= 2:
		return 1.28
	return 1.38

func _camera_target() -> Vector2:
	if world == null:
		return Vector2(3920.0, 2380.0)
	if world.heroes.is_empty():
		return Vector2(world.ARENA_CENTER)
	var focus_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
	if world.result != &"playing" and world.winner_slot >= 0:
		focus_slot = world.winner_slot
	elif world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot == world.local_slot:
		focus_slot = world.local_slot
	elif bool(world.heroes[focus_slot]["eliminated"]) and _spectator_valid(spectate_slot):
		focus_slot = spectate_slot
	var focus: Dictionary = world.heroes[focus_slot]
	var cinematic: bool = (world.ultimate_focus_time > 0.0 and focus_slot == world.ultimate_focus_slot) or (world.result != &"playing" and focus_slot == world.winner_slot)
	var look_ahead := Vector2(focus["aim"]) * (52.0 if cinematic else (85.0 if focus_slot != world.local_slot else 135.0))
	look_ahead += Vector2(focus["vel"]) * 0.16
	look_ahead.y = maxf(look_ahead.y, -28.0)
	var zoom_value := maxf(1.10, camera.zoom.x)
	var hud_reserve := 150.0 / zoom_value
	var desired := Vector2(focus["pos"]) + look_ahead + Vector2(0.0, hud_reserve * 0.45)
	var half_view := Vector2(800.0, 450.0) / zoom_value
	var min_y := half_view.y + hud_reserve * 0.15
	return Vector2(clampf(desired.x, half_view.x, world.ARENA_SIZE.x - half_view.x), clampf(desired.y, min_y, world.ARENA_SIZE.y - half_view.y))
