extends GameModule
## 다굴 게임 모듈 — 월드 생성·게임 루프·카메라·SFX·튜토리얼을 소유한다.
## 셸/네트워크/방 지식 없음: ctx 로 받은 자원만 쓴다.

const CharacterCatalogScript = preload("res://core/contract/character_catalog.gd")
const NetWorldScript = preload("res://games/dagul/net/net_world.gd")
const SfxCatalogScript = preload("res://games/dagul/audio/sfx_catalog.gd")
const KillFanfareScript = preload("res://games/dagul/render/kill_fanfare.gd")
const PerfOverlayScript = preload("res://games/dagul/render/perf_overlay.gd")
const CrosshairOverlayScript = preload("res://games/dagul/hud/crosshair_overlay.gd")
const MODE := "full"
const TICK := 1.0 / 60.0

var world
var seed_value: int = 2222
var _sfx: SfxManager = null
var _tutorial: TutorialOverlay = null
var _fanfare = null
var _perf = null
var _crosshair = null
var _last_local_kills: int = -1
var _is_host := false
var _input: PlayerInput
var last_event_id: int = 0
var hit_pause_frames: int = 0
var spectate_slot: int = 0
var hud_mode: int = 0
var _hud_redraw_acc: float = 0.0
var _hud_state_hash: int = 0

func id() -> String:
	return "dagul"

# --- 수명주기 ---

func start(payload: Dictionary, ctx: Dictionary) -> void:
	_is_host = bool(payload.get("host", false))
	var you := int(payload.get("you", 0))
	var mode := str(payload.get("mode", MODE))
	seed_value = int(payload.get("seed", seed_value))
	if seed_value <= 0:
		seed_value = 2222

	_ensure_overlays(ctx)
	var hud_layer: CanvasLayer = ctx["hud_layer"]
	# RefCounted 모듈은 트리 밖이다. 오토로드는 노드 절대경로로 찾는다.
	var audio := hud_layer.get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("register_catalog"):
		audio.register_catalog(SfxCatalogScript)
	if audio != null and audio.has_method("play_music"):
		audio.play_music("match")

	# 로비 방장 여부는 payload.host 에 남는다. 시뮬 원본은 허브이므로 전원 NetWorld.
	_start_as_guest(you, mode)

	var hud: Control = ctx["hud"]
	var world_view: Node2D = ctx["world_view"]
	world_view.world = world
	hud.world = world
	if _crosshair != null:
		_crosshair.world = world
	hud.mode_id = mode
	spectate_slot = you
	hud.spectate_slot = spectate_slot
	hud.hud_mode = hud_mode
	if hud.has_method("reset_match_visuals"):
		hud.reset_match_visuals()
	_last_local_kills = -1
	last_event_id = 0
	hit_pause_frames = 0
	_ensure_input()
	_input.reset()
	_bind_match_camera(ctx, audio, world_view)

func _bind_match_camera(ctx: Dictionary, audio: Node, world_view: Node2D) -> void:
	var camera: Camera2D = ctx["camera"]
	camera.position = _camera_target(camera)
	if audio != null and audio.has_method("attach_world"):
		audio.attach_world(world_view, camera)

func stop() -> void:
	var audio := Engine.get_main_loop()
	if audio is SceneTree:
		var node: Node = (audio as SceneTree).root.get_node_or_null("/root/Audio")
		if node != null and node.has_method("stop_music"):
			node.stop_music(0.2)

func push_snap(snap: Dictionary) -> void:
	if world != null and bool(world.get("is_net")):
		# 어댑터는 상주 Dictionary 를 제자리 갱신한다 — 사본 없이 넣으면 보간 버퍼의
		# from/to 가 같은 객체가 되어 원격 위치 보간이 통째로 무효가 된다.
		world.push_snap(snap.duplicate(true))

func push_gun_fire(fx: Dictionary) -> void:
	if world == null or world.event_log == null:
		return
	var slot := int(fx.get("slot", -1))
	world.event_log.emit(int(world.tick), &"gun_fire", slot, -1, {"equipment": str(fx.get("equipment", ""))})

func become_host(ctx: Dictionary) -> void:
	_is_host = true
	_bind_view(ctx)

func become_guest(ctx: Dictionary) -> void:
	if not _is_host:
		return
	var you := 0
	var mode := MODE
	if world != null:
		you = int(world.get("local_slot", 0))
		mode = str(world.get("mode", MODE))
	_is_host = false
	_start_as_guest(you, mode)
	_bind_view(ctx)

# --- 월드 생성 ---

func _bind_view(ctx: Dictionary) -> void:
	if world == null or not ctx.has("world_view"):
		return
	ctx["world_view"].world = world
	if ctx.has("hud"):
		ctx["hud"].world = world
	if _crosshair != null:
		_crosshair.world = world

func _start_as_guest(you: int, mode: String) -> void:
	var net_world = NetWorldScript.new()
	net_world.local_slot = you
	net_world.set_mode(mode)
	net_world.reset()
	# 첫 스냅이 startCountdown 을 싣는다. playing 재입장은 0, 신규는 3.
	net_world.start_countdown = 0.0
	world = net_world

func _ensure_overlays(ctx: Dictionary) -> void:
	var hud_layer: CanvasLayer = ctx["hud_layer"]
	if _sfx == null:
		_sfx = SfxManager.new()
		_sfx.setup(hud_layer)
	if _tutorial == null:
		_tutorial = TutorialOverlay.new()
		_tutorial.name = "TutorialOverlay"
		hud_layer.add_child(_tutorial)
		_tutorial.z_index = 30
	if _fanfare == null:
		_attach_kill_fanfare(hud_layer)
	if _perf == null:
		_perf = PerfOverlayScript.new()
		_perf.name = "PerfOverlay"
		hud_layer.add_child(_perf)
		_perf.z_index = 100
	if _crosshair == null:
		_crosshair = CrosshairOverlayScript.new()
		_crosshair.name = "CrosshairOverlay"
		# HUD 본체는 상태 해시 스로틀로 5Hz 까지 떨어진다 — 조준점은 HUD 자식으로
		# 붙여 가시성은 따라가되 매 프레임 스스로 다시 그린다.
		ctx["hud"].add_child(_crosshair)

# --- 게임 루프 ---

func tick(_delta: float, ctx: Dictionary) -> void:
	if world == null:
		return
	var hud: Control = ctx["hud"]
	var world_view: Node2D = ctx["world_view"]
	var camera: Camera2D = ctx["camera"]
	var hub: Node = ctx["hub"]
	_ensure_input()
	_input.bind_layer(ctx["touch"])
	var touch: CanvasLayer = ctx.get("touch")
	if hud != null and touch != null and touch.has_method("is_enabled"):
		hud.touch_hints = bool(touch.is_enabled()) and not bool(ctx.get("settings_open", false))

	_poll_debug_keys(hud)
	_update_spectator()
	if hit_pause_frames > 0:
		hit_pause_frames -= 1
	var command := _local_command(ctx, world_view)
	_tick_world(command, hub, hud, world_view)
	_tick_match_audio(ctx)
	# 허브 권위라 월드는 히트 포즈에도 계속 흐른다 — 카메라를 얼리면 풀릴 때마다
	# 따라잡기 점프가 난다("화면 튐"). 히트스톱 체감은 셰이크가 담당한다.
	_tick_presentation(camera, hud)
	world_view.queue_redraw()
	_maybe_redraw_hud(hud, TICK)


func _poll_debug_keys(hud: Control) -> void:
	if _input.edge(KEY_ESCAPE) and bool(world.finish_cine.get("on", false)):
		world.finish_cine = {}
	if _input.edge(KEY_F1):
		hud_mode = (hud_mode + 1) % 3
		hud.hud_mode = hud_mode
		hud.queue_redraw()
	if _input.edge(KEY_F3) and _perf != null:
		_perf.toggle()


func _tick_match_audio(ctx: Dictionary) -> void:
	if _sfx == null:
		return
	var sfx_result := _sfx.process_events(world, int(world.get("local_slot")), last_event_id)
	last_event_id = sfx_result["last_event_id"]
	hit_pause_frames = maxi(hit_pause_frames, sfx_result["hit_pause"])
	var audio_tick: Node = ctx["hud_layer"].get_node_or_null("/root/Audio")
	if audio_tick != null and audio_tick.has_method("tick_world_sfx"):
		audio_tick.tick_world_sfx(world)

func _local_command(ctx: Dictionary, world_view: Node2D) -> Dictionary:
	if bool(ctx.get("settings_open", false)):
		return _input.idle_command(_local_player_pos())
	return _input.poll(world_view, _local_player_pos())


func _ensure_input() -> void:
	if _input == null:
		_input = PlayerInput.new()


func _tick_presentation(camera: Camera2D, hud: Control) -> void:
	_check_tutorial_hints()
	_check_my_kill_fanfare()
	_update_spectator()
	_drive_camera(camera)
	hud.spectate_slot = spectate_slot

func _maybe_redraw_hud(hud: Control, dt: float) -> void:
	_hud_redraw_acc += dt
	var state := _hud_state_hash_now()
	if state == _hud_state_hash and _hud_redraw_acc < 0.2:
		return
	_hud_state_hash = state
	_hud_redraw_acc = 0.0
	hud.queue_redraw()

func _hud_state_hash_now() -> int:
	if world == null or world.heroes.is_empty():
		if world == null:
			return 0
		return int(float(world.start_countdown) * 10.0)
	var me: Dictionary = world.heroes[clampi(int(world.local_slot), 0, world.heroes.size() - 1)]
	var h := int(float(me.get("hp", 0.0)))
	h = h * 31 + int(me.get("mag", 0))
	h = h * 31 + int(float(me.get("mobility_cd", 0.0)) * 10.0)
	h = h * 31 + int(float(world.start_countdown) * 10.0)
	h = h * 31 + spectate_slot * 17 + hud_mode
	h = h * 31 + int(me.get("kills", 0)) + (1 if bool(me.get("alive", true)) else 0)
	return h

func _tick_world(command: Dictionary, hub: Node, hud: Control, world_view: Node2D) -> void:
	hud.net_rtt_ms = int(hub.rtt_ms)
	hud.net_connected = bool(hub.is_open())
	_try_local_fire_conceal(command)
	world.present(TICK)
	if world.heroes.is_empty():
		return
	var move: Vector2 = command.get("move", Vector2.ZERO)
	var aim_world: Vector2 = command.get("aim", Vector2.ZERO)
	var seq: int = int(world.predict_local(move, bool(command.get("mobility", false)), aim_world, TICK))
	hub.send_input(_peer_input_packet(command, seq))
	_apply_recoil_mouse(world_view)

func _try_local_fire_conceal(command: Dictionary) -> void:
	var pressed := bool(command.get("primary_pressed", false))
	var held := bool(command.get("primary", false))
	if not pressed and not held:
		return
	if world == null or not world.has_method("predict_local_fire"):
		return
	var aim: Vector2 = Vector2(command.get("aim", Vector2.ZERO))
	# pressed 가 아니라 쥐고만 있는 프레임이면 연사(auto) 예측 경로로 보낸다 —
	# 그래야 이동하며 연사할 때 첫 발 이후에도 예측 위치에서 계속 나간다.
	if not bool(world.predict_local_fire(aim, held and not pressed)):
		return
	if world.get("local_fire_shake") != null:
		world.local_fire_shake = maxi(int(world.local_fire_shake), 4)

func _peer_input_packet(command: Dictionary, seq: int) -> Dictionary:
	var move: Vector2 = command.get("move", Vector2.ZERO)
	var aim: Vector2 = command.get("aim", Vector2.ZERO)
	return {
		"mx": move.x, "my": move.y,
		"aimX": aim.x, "aimY": aim.y,
		"fire": bool(command.get("primary", false)),
		"firePressed": bool(command.get("primary_pressed", false)),
		"equipment": bool(command.get("equipment", false)),
		"equipmentPressed": bool(command.get("equipment_pressed", false)),
		"equipmentReleased": bool(command.get("equipment_released", false)),
		"dash": bool(command.get("mobility", false)),
		"use": bool(command.get("medkit", false)),
		"reload": bool(command.get("reload", false)),
		"ultimate": bool(command.get("ultimate", false)),
		"hop": bool(command.get("hop", false)),
		"finish": bool(command.get("finish", false)),
		"emote": int(command.get("emote", -1)),
		"seq": seq,
	}

func _check_tutorial_hints() -> void:
	if _tutorial == null or world == null or world.heroes.is_empty():
		return
	var ls: int = clampi(int(world.get("local_slot")), 0, world.heroes.size() - 1)
	var h: Dictionary = world.heroes[ls]
	if bool(h.get("downed", false)):
		_tutorial.show_hint("down")
	if float(h.get("hp", 999)) < float(h.get("max_hp", 999)):
		_tutorial.show_hint("hit")
	if float(h.get("ultimate_charge", 0)) >= 100.0:
		_tutorial.show_hint("ultimate_ready")
	var safe_r := float(world.get("safe_zone_radius"))
	var safe_c: Vector2 = world.get("safe_zone_center")
	if safe_r > 0.0 and Vector2(h["pos"]).distance_to(safe_c) > safe_r:
		_tutorial.show_hint("outside_zone")

func _apply_recoil_mouse(world_view: Node2D) -> void:
	if OS.has_feature("web"):
		return
	var kick: Vector2 = world.local_mouse_kick
	world.local_mouse_kick = Vector2.ZERO
	if kick.length_squared() < 0.01:
		return
	var vp := world_view.get_viewport()
	var rect := vp.get_visible_rect()
	var next: Vector2 = vp.get_mouse_position() + kick
	next.x = clampf(next.x, 10.0, rect.size.x - 10.0)
	next.y = clampf(next.y, 10.0, rect.size.y - 10.0)
	vp.warp_mouse(next)

func _local_player_pos() -> Vector2:
	if world == null or world.heroes.is_empty():
		return Vector2.ZERO
	var me: Dictionary = world.heroes[clampi(world.local_slot, 0, world.heroes.size() - 1)]
	return Vector2(me["pos"])

# --- 관전 ---

func _spectator_valid(slot: int) -> bool:
	return slot >= 0 and slot != world.local_slot and slot < world.heroes.size() \
		and bool(world.heroes[slot]["alive"]) and not bool(world.heroes[slot]["eliminated"])

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
	if _input.edge(KEY_A):
		_cycle_spectator(-1)
	if _input.edge(KEY_D):
		_cycle_spectator(1)
	if _input.edge(KEY_SPACE):
		spectate_slot = _best_spectator()

# --- 카메라 ---

func _drive_camera(camera: Camera2D) -> void:
	var shake := _compute_shake(camera)
	var zoom_target := _camera_zoom_target(camera)
	camera.zoom = camera.zoom.lerp(Vector2.ONE * zoom_target, 0.065)
	var follow := 0.24 if world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot == world.local_slot else 0.42
	camera.position = camera.position.lerp(_camera_target(camera), follow) + shake

func _compute_shake(camera: Camera2D) -> Vector2:
	var shake := Vector2.ZERO
	if int(world.get("local_hit_shake")) > 0:
		var hit_n: int = int(world.local_hit_shake)
		shake = Vector2(sin(float(world.tick) * 5.2), cos(float(world.tick) * 7.1)) * (8.2 + float(hit_n) * 1.05)
	var fire_n: int = int(world.local_fire_shake)
	if fire_n > 0:
		shake += Vector2(sin(float(world.tick) * 11.0), cos(float(world.tick) * 13.4)) * (5.5 + float(fire_n) * 0.95)
	elif world.impact_ticks > 0:
		var impact_distance := _camera_target(camera).distance_to(Vector2(world.impact_pos))
		var attenuation := 1.0 - clampf(impact_distance / 900.0, 0.0, 0.90)
		shake = Vector2(sin(float(world.tick) * 2.8), cos(float(world.tick) * 4.1)) * (2.0 + world.impact_ticks * 0.4) * attenuation
	return shake

func _camera_zoom_target(_camera: Camera2D) -> float:
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

func _camera_target(camera: Camera2D) -> Vector2:
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
	var cinematic: bool = (world.ultimate_focus_time > 0.0 and focus_slot == world.ultimate_focus_slot) \
		or (world.result != &"playing" and focus_slot == world.winner_slot)
	var look_ahead := Vector2(focus["aim"]) * (52.0 if cinematic else (85.0 if focus_slot != world.local_slot else 135.0))
	look_ahead += Vector2(focus["vel"]) * 0.16
	look_ahead.y = maxf(look_ahead.y, -28.0)
	var zoom_value := maxf(1.10, camera.zoom.x)
	var hud_reserve := 150.0 / zoom_value
	var desired := Vector2(focus["pos"]) + look_ahead + Vector2(0.0, hud_reserve * 0.45)
	var half_view := Vector2(800.0, 450.0) / zoom_value
	var min_y := half_view.y + hud_reserve * 0.15
	return Vector2(
		clampf(desired.x, half_view.x, world.ARENA_SIZE.x - half_view.x),
		clampf(desired.y, min_y, world.ARENA_SIZE.y - half_view.y))


func _attach_kill_fanfare(hud_layer: CanvasLayer) -> void:
	var host: Node = hud_layer.get_parent()
	if host == null:
		host = hud_layer
	var fanfare_layer := CanvasLayer.new()
	fanfare_layer.layer = 80
	fanfare_layer.name = "KillFanfareLayer"
	fanfare_layer.follow_viewport_enabled = false
	fanfare_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(fanfare_layer)
	_fanfare = KillFanfareScript.new()
	_fanfare.name = "KillFanfare"
	fanfare_layer.add_child(_fanfare)


func _check_my_kill_fanfare() -> void:
	if _fanfare == null or world == null or world.heroes.is_empty():
		_last_local_kills = -1
		return
	var me := clampi(int(world.get("local_slot")), 0, world.heroes.size() - 1)
	var kills := int(world.heroes[me].get("kills", 0))
	if _last_local_kills < 0:
		_last_local_kills = kills
		return
	if kills > _last_local_kills:
		_fanfare.burst()
		_play_kill_fanfare_sfx()
	_last_local_kills = kills


func _play_kill_fanfare_sfx() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var audio: Node = tree.root.get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("play_sfx"):
		audio.play_sfx("kill_fanfare", -2.0, 0.0)
