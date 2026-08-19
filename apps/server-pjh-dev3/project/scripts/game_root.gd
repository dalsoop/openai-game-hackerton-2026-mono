extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")
const NetWorldScript = preload("res://scripts/net/net_world.gd")
const HubClientScript = preload("res://scripts/net/hub_client.gd")
const TouchControlsScript = preload("res://addons/godot-touch-controls/touch_controls.gd")

@onready var world_view: Node2D = $WorldView
@onready var camera: Camera2D = $WorldView/Camera2D
@onready var hud: Control = $HUD/Overlay
@onready var screens: Control = $HUD/Screens

var world
var hub
var net_active := false
var previous_keys: Dictionary = {}
var seed: int = 2222
var last_event_id: int = 0
var hit_pause_frames: int = 0
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor: int = 0
var hit_sfx: AudioStreamWAV
var heavy_sfx: AudioStreamWAV
var ultimate_sfx: AudioStreamWAV
var down_sfx: AudioStreamWAV
var core_sfx: AudioStreamWAV
var spectate_slot: int = 0
var hud_mode: int = 0
var previous_right_mouse: bool = false
var phase: StringName = &"select"
var touch: CanvasLayer = null
var _net_banner: Label = null

func _ready() -> void:
    _build_sfx()
    touch = TouchControlsScript.new()
    touch.name = "TouchControls"
    $HUD.add_child(touch)
    hub = HubClientScript.new()
    hub.name = "HubClient"
    add_child(hub)
    screens.bind_hub(hub)
    hub.match_started.connect(_on_net_match_started)
    hub.match_resumed.connect(_on_net_match_resumed)
    hub.snapshot_received.connect(_on_net_snapshot)
    hub.status_changed.connect(_on_hub_status)
    _restart()
    camera.position = _camera_target()
    screens.start_match.connect(_on_start_match)
    screens.request_resume.connect(func(): _set_phase(&"play"))
    screens.request_quit_to_intro.connect(func(): _set_phase(&"lobby"))
    Engine.max_fps = 60
    _set_phase(&"lobby")

func _on_start_match() -> void:
    net_active = false
    seed += 1
    _restart()
    _set_phase(&"play")

func _on_net_match_started(you: int, room: Dictionary) -> void:
    net_active = true
    var net_world = NetWorldScript.new()
    net_world.local_slot = you
    net_world.set_mode(str(room.get("mode", screens.selected_mode)))
    net_world.reset()
    world = net_world
    world_view.world = world
    hud.world = world
    hud.mode_id = net_world.mode
    spectate_slot = you
    hud.spectate_slot = spectate_slot
    hud.hud_mode = hud_mode
    last_event_id = 0
    hit_pause_frames = 0
    previous_right_mouse = false
    camera.position = _camera_target()
    _set_phase(&"play")

func _on_net_match_resumed(you: int, room: Dictionary, snap: Dictionary) -> void:
    net_active = true
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
    if net_active and world != null and bool(world.get("is_net")):
        world.push_snap(snap)

func _on_hub_status(next_status: String) -> void:
    if next_status == "다시 연결 중":
        _set_net_banner("연결이 끊겼습니다. 같은 자리로 다시 붙는 중입니다.")
        return
    _set_net_banner("")
    if next_status != "끊김" and next_status != "오프라인 로컬":
        return
    if net_active:
        net_active = false
        if phase == &"play":
            _set_phase(&"lobby")

func _set_phase(next: StringName) -> void:
    phase = next
    var playing := next == &"play"
    world_view.visible = playing
    hud.visible = playing
    screens.visible = not playing
    if touch != null:
        touch.set_playing(playing)
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

func _physics_process(_delta: float) -> void:
    if phase != &"play":
        if _edge(KEY_ESCAPE):
            if screens.page == &"wait":
                _escape_wait()
            else:
                screens.pop_page()
        return
    if _edge(KEY_ESCAPE):
        _set_phase(&"wait")
        return
    if not net_active and _edge(KEY_R):
        seed += 1
        _restart()
        return
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
    if net_active:
        var dash_held: bool = Input.is_key_pressed(KEY_SPACE) or (touch != null and touch.dash_held)
        var use_held: bool = Input.is_key_pressed(KEY_E) or (touch != null and touch.medkit_held)
        world.present(1.0 / 60.0)
        var seq: int = int(world.predict_local(move, dash_held, aim_world, 1.0 / 60.0))
        hub.send_input(move, primary, dash_held, use_held, aim_world, seq)
        previous_right_mouse = equipment_held
    else:
        var ultimate_edge := _edge(KEY_Q)
        var mobility_edge := _edge(KEY_SPACE)
        var medkit_edge := _edge(KEY_E)
        if touch != null:
            ultimate_edge = touch.consume_ult() or ultimate_edge
            mobility_edge = touch.consume_dash() or mobility_edge
            medkit_edge = touch.consume_medkit() or medkit_edge
        var command := {
            "move":move,
            "aim":aim_world,
            "primary":primary,
            "equipment":equipment_held,
            "equipment_pressed":equipment_held and not previous_right_mouse,
            "equipment_released":not equipment_held and previous_right_mouse,
            "ultimate":ultimate_edge,
            "mobility":mobility_edge,
            "medkit":medkit_edge
        }
        previous_right_mouse = equipment_held
        world.step_tick(command, 1.0 / 60.0)
    _play_new_events()
    _update_spectator()
    var shake := Vector2.ZERO
    if world.impact_ticks > 0:
        var impact_distance := _camera_target().distance_to(Vector2(world.impact_pos))
        var attenuation := 1.0 - clampf(impact_distance / 900.0, 0.0, 0.90)
        shake = Vector2(sin(float(world.tick) * 2.8), cos(float(world.tick) * 4.1)) * (2.0 + world.impact_ticks * 0.4) * attenuation
    var zoom_target := _camera_zoom_target()
    camera.zoom = camera.zoom.lerp(Vector2.ONE * zoom_target, 0.065)
    var camera_follow := 0.24 if world.ultimate_focus_time > 0.0 else 0.42
    camera.position = camera.position.lerp(_camera_target(), camera_follow) + shake
    hud.spectate_slot = spectate_slot
    world_view.queue_redraw()
    hud.queue_redraw()

func _build_sfx() -> void:
    for index in range(8):
        var player := AudioStreamPlayer.new()
        player.name = "ImpactSfx%d" % index
        add_child(player)
        sfx_players.append(player)
    hit_sfx = _make_impact_stream(185.0, 0.075, 0.22)
    heavy_sfx = _make_impact_stream(105.0, 0.14, 0.52)
    ultimate_sfx = _make_impact_stream(72.0, 0.24, 0.38)
    down_sfx = _make_impact_stream(48.0, 0.34, 0.60)
    core_sfx = _make_impact_stream(255.0, 0.10, 0.12)

func _make_impact_stream(frequency: float, duration: float, noise_mix: float) -> AudioStreamWAV:
    var mix_rate := 22050
    var sample_count := maxi(1, roundi(duration * mix_rate))
    var pcm := PackedByteArray()
    pcm.resize(sample_count * 2)
    for sample in range(sample_count):
        var t := float(sample) / float(mix_rate)
        var progress := float(sample) / float(sample_count)
        var envelope := pow(1.0 - progress, 2.4)
        var pitch_drop := frequency * (1.0 - progress * 0.42)
        var tone := sin(TAU * pitch_drop * t)
        var grit := sin(TAU * (frequency * 7.13) * t + sin(t * 913.0))
        var value := clampf((tone * (1.0 - noise_mix) + grit * noise_mix) * envelope * 0.72, -1.0, 1.0)
        pcm.encode_s16(sample * 2, roundi(value * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = mix_rate
    stream.stereo = false
    stream.data = pcm
    return stream

func _play_sfx(stream: AudioStreamWAV, volume_db: float = -5.0) -> void:
    if sfx_players.is_empty():
        return
    var player := sfx_players[sfx_cursor]
    sfx_cursor = (sfx_cursor + 1) % sfx_players.size()
    player.stream = stream
    player.volume_db = volume_db
    player.pitch_scale = 0.96 + 0.025 * float(sfx_cursor % 4)
    player.play()

func _play_new_events() -> void:
    for event in world.event_log.events:
        var event_id := int(event["event_id"])
        if event_id <= last_event_id:
            continue
        last_event_id = event_id
        var event_type := StringName(event["type"])
        var actor := int(event["actor_id"])
        var target := int(event["target_id"])
        var me_slot := int(world.get("local_slot")) if world != null else 0
        var involves_player := actor == me_slot or target == me_slot
        if event_type == &"hero_hit" and involves_player:
            var source := StringName(event["data"].get("source", &"normal"))
            if source == &"ultimate":
                _play_sfx(ultimate_sfx, -2.0)
                hit_pause_frames = maxi(hit_pause_frames, 3)
                Input.start_joy_vibration(0, 0.55, 0.90, 0.28)
            elif source == &"equipment":
                _play_sfx(heavy_sfx, -3.0)
                hit_pause_frames = maxi(hit_pause_frames, 2)
                Input.start_joy_vibration(0, 0.36, 0.66, 0.18)
            else:
                _play_sfx(hit_sfx, -8.0)
                hit_pause_frames = maxi(hit_pause_frames, 1)
                Input.start_joy_vibration(0, 0.18, 0.34, 0.10)
        elif event_type == &"combo_finisher" and involves_player:
            _play_sfx(heavy_sfx, 0.0)
            hit_pause_frames = maxi(hit_pause_frames, 4)
            Input.start_joy_vibration(0, 0.78, 1.0, 0.30)
        elif event_type == &"ultimate_used" and (involves_player or actor == world.ultimate_focus_slot):
            _play_sfx(ultimate_sfx, -1.0)
            hit_pause_frames = maxi(hit_pause_frames, 1)
            if actor == me_slot:
                Input.start_joy_vibration(0, 0.30, 0.58, 0.18)
        elif event_type == &"attack_evaded" and involves_player:
            _play_sfx(hit_sfx, -10.0)
        elif event_type == &"wall_bounce" and involves_player:
            _play_sfx(heavy_sfx, -1.0)
            hit_pause_frames = maxi(hit_pause_frames, 3)
            Input.start_joy_vibration(0, 0.72, 1.0, 0.34)
        elif event_type == &"hero_downed":
            _play_sfx(down_sfx, -1.0)
            if involves_player:
                hit_pause_frames = maxi(hit_pause_frames, 5)
                Input.start_joy_vibration(0, 1.0, 1.0, 0.52)
        elif event_type == &"kill_streak":
            _play_sfx(heavy_sfx, -2.0)
            if involves_player:
                Input.start_joy_vibration(0, 0.42, 0.72, 0.22)
        elif event_type == &"streak_shutdown":
            _play_sfx(ultimate_sfx, 0.0)
            hit_pause_frames = maxi(hit_pause_frames, 3)
            if involves_player:
                Input.start_joy_vibration(0, 0.78, 1.0, 0.38)
        elif event_type == &"core_hit" and involves_player:
            _play_sfx(core_sfx, -5.0)
        elif event_type == &"gun_upgraded" and involves_player:
            _play_sfx(core_sfx, -2.0)
        elif event_type == &"medkit_used" and involves_player:
            _play_sfx(core_sfx, -7.0)
        elif event_type == &"match_won":
            _play_sfx(ultimate_sfx if actor == me_slot else down_sfx, 1.0 if actor == me_slot else -1.0)
            hit_pause_frames = maxi(hit_pause_frames, 6)
            Input.start_joy_vibration(0, 0.88, 1.0, 0.62)

func _edge(keycode: int) -> bool:
    var now := Input.is_key_pressed(keycode)
    var was := bool(previous_keys.get(keycode, false))
    previous_keys[keycode] = now
    return now and not was

func _local_player_pos() -> Vector2:
    if world == null or world.heroes.is_empty():
        return Vector2.ZERO
    var me: Dictionary = world.heroes[clampi(world.local_slot, 0, world.heroes.size() - 1)]
    return Vector2(me["pos"])

func _escape_wait() -> void:
    net_active = false
    if hub.in_room:
        hub.leave_room()
    _set_phase(&"lobby")

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
    if bool(world.heroes[me_slot]["alive"]):
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

func _camera_zoom_target() -> float:
    if world == null or world.heroes.is_empty():
        return 1.0
    if world.result != &"playing" and world.winner_slot >= 0:
        return 1.16
    if world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot >= 0:
        return 1.14
    var me_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
    if not bool(world.heroes[me_slot]["alive"]):
        return 0.84
    var focus_pos: Vector2 = world.heroes[me_slot]["pos"]
    var nearby := 0
    for hero in world.heroes:
        if bool(hero["alive"]) and Vector2(hero["pos"]).distance_to(focus_pos) < 470.0:
            nearby += 1
    if nearby >= 4:
        return 0.86
    if nearby >= 2:
        return 0.93
    return 1.0

func _camera_target() -> Vector2:
    if world == null:
        return Vector2(1960.0, 1190.0)
    if world.heroes.is_empty():
        return Vector2(world.ARENA_CENTER)
    var focus_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
    if world.result != &"playing" and world.winner_slot >= 0:
        focus_slot = world.winner_slot
    elif world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot >= 0 and world.ultimate_focus_slot < world.heroes.size():
        focus_slot = world.ultimate_focus_slot
    elif not bool(world.heroes[focus_slot]["alive"]) and _spectator_valid(spectate_slot):
        focus_slot = spectate_slot
    var focus: Dictionary = world.heroes[focus_slot]
    var cinematic: bool = (world.ultimate_focus_time > 0.0 and focus_slot == world.ultimate_focus_slot) or (world.result != &"playing" and focus_slot == world.winner_slot)
    var look_ahead := Vector2(focus["aim"]) * (52.0 if cinematic else (85.0 if focus_slot != world.local_slot else 135.0))
    look_ahead += Vector2(focus["vel"]) * 0.16
    var desired := Vector2(focus["pos"]) + look_ahead
    var zoom_value := maxf(0.82, camera.zoom.x)
    var half_view := Vector2(800.0, 450.0) / zoom_value
    return Vector2(clampf(desired.x, half_view.x, world.ARENA_SIZE.x - half_view.x), clampf(desired.y, half_view.y, world.ARENA_SIZE.y - half_view.y))
