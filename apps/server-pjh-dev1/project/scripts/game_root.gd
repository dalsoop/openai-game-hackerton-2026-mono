extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")
const NetWorldScript = preload("res://scripts/net/net_world.gd")
const HubClientScript = preload("res://scripts/net/hub_client.gd")
const TOUCH_CONTROLS_PATH := "res://addons/godot-touch-controls/touch_controls.gd"

@onready var world_view: Node2D = $WorldView
@onready var camera: Camera2D = $WorldView/Camera2D
@onready var hud: Control = $HUD/Overlay
@onready var screens: Control = $HUD/Screens

var world
var hub
var net_active := false
var net_host := false
var hub_launched := false
var _snap_timer := 0.0
var _peer_seq: Dictionary = {}
const SNAP_SEND_HZ := 20.0
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
var tower_sfx: AudioStreamWAV
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
    _build_sfx()
    _attach_touch()
    _build_touch_buttons()
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
    screens.request_quit_to_intro.connect(func(): _return_to_hub())
    screens.control_mode_changed.connect(_apply_control_mode)
    _apply_control_mode(screens.control_mode)
    Engine.max_fps = 60
    hub_launched = hub.consume_hub_launch()
    if hub_launched:
        var hub_name := hub.get_hub_name()
        if hub_name != "":
            hub.player_name = hub_name
    _set_phase(&"lobby")

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
    _touch_rematch.visible = playing and finished and not net_active
    if touch != null and touch.has_method("set_playing"):
        touch.set_playing(playing and not finished)

func _on_start_match() -> void:
    net_active = false
    seed += 1
    _restart()
    _set_phase(&"play")

func _on_net_match_started(you: int, room: Dictionary) -> void:
    net_active = true
    net_host = hub.is_host
    if net_host:
        _cleanup_host_signals()
        _peer_seq.clear()
        seed += 1
        var host_world = WorldScript.new(seed)
        host_world.set_mode(str(room.get("mode", screens.selected_mode)))
        host_world.local_slot = you
        host_world.is_net = true
        host_world.reset()
        # Mark non-CPU slots as human (from room peers)
        for p in hub.players:
            var s := int(p.get("slot", -1))
            if s >= 0 and not bool(p.get("dropped", false)):
                host_world.human_slots[s] = true
        world = host_world
        _snap_timer = 0.0
        if not hub.peer_input_received.is_connected(_on_peer_input):
            hub.peer_input_received.connect(_on_peer_input)
        if not hub.peer_parked_received.is_connected(_on_peer_parked):
            hub.peer_parked_received.connect(_on_peer_parked)
        if not hub.peer_reclaimed_received.is_connected(_on_peer_reclaimed):
            hub.peer_reclaimed_received.connect(_on_peer_reclaimed)
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
            _return_to_hub()

func _return_to_hub() -> void:
    if hub_launched and OS.has_feature("web"):
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
    if not net_active and world != null and world.result != &"playing":
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
    if net_active and net_host:
        # Host: run real simulation + send snapshots
        var ultimate_edge := _edge(KEY_Q)
        var mobility_edge := _edge(KEY_SHIFT)
        var hop_edge := _edge(KEY_SPACE)
        var medkit_edge := _edge(KEY_E)
        var reload_edge := _edge(KEY_R)
        if touch != null:
            ultimate_edge = touch.consume_ult() or ultimate_edge
            mobility_edge = touch.consume_dash() or mobility_edge
            medkit_edge = touch.consume_medkit() or medkit_edge
        var primary_pressed := primary and not previous_left_mouse
        var command := {
            "move":move,
            "aim":aim_world,
            "primary":primary,
            "primary_pressed":primary_pressed,
            "equipment":equipment_held,
            "equipment_pressed":equipment_held and not previous_right_mouse,
            "equipment_released":not equipment_held and previous_right_mouse,
            "ultimate":ultimate_edge,
            "mobility":mobility_edge,
            "hop":hop_edge,
            "medkit":medkit_edge,
            "reload":reload_edge,
            "finish":_edge(KEY_F)
        }
        previous_right_mouse = equipment_held
        previous_left_mouse = primary
        world.step_tick(command, 1.0 / 60.0)
        _snap_timer += 1.0 / 60.0
        if _snap_timer >= 1.0 / SNAP_SEND_HZ:
            _snap_timer -= 1.0 / SNAP_SEND_HZ
            hub.send_snap(_build_host_snapshot())
        hud.net_rtt_ms = int(hub.rtt_ms)
        hud.net_connected = bool(hub.is_open())
        _apply_recoil_mouse()
    elif net_active:
        # Non-host: receive snapshots
        var dash_held: bool = Input.is_key_pressed(KEY_SHIFT) or (touch != null and touch.dash_held)
        var use_held: bool = Input.is_key_pressed(KEY_E) or (touch != null and touch.medkit_held)
        world.present(1.0 / 60.0)
        hud.net_rtt_ms = int(hub.rtt_ms)
        hud.net_connected = bool(hub.is_open())
        var seq: int = int(world.predict_local(move, dash_held, aim_world, 1.0 / 60.0))
        hub.send_input(move, primary, dash_held, use_held, aim_world, seq)
        previous_right_mouse = equipment_held
    else:
        var ultimate_edge := _edge(KEY_Q)
        var mobility_edge := _edge(KEY_SHIFT)
        var hop_edge := _edge(KEY_SPACE)
        var medkit_edge := _edge(KEY_E)
        var reload_edge := _edge(KEY_R)
        if not net_active and world != null:
            if _edge(KEY_BRACKETLEFT):
                world.cycle_local_animal(-1)
            if _edge(KEY_BRACKETRIGHT):
                world.cycle_local_animal(1)
        if touch != null:
            ultimate_edge = touch.consume_ult() or ultimate_edge
            mobility_edge = touch.consume_dash() or mobility_edge
            medkit_edge = touch.consume_medkit() or medkit_edge
        var primary_pressed := primary and not previous_left_mouse
        var command := {
            "move":move,
            "aim":aim_world,
            "primary":primary,
            "primary_pressed":primary_pressed,
            "equipment":false,
            "equipment_pressed":false,
            "equipment_released":false,
            "ultimate":ultimate_edge,
            "mobility":mobility_edge,
            "hop":hop_edge,
            "medkit":medkit_edge,
            "reload":reload_edge,
            "finish":_edge(KEY_F)
        }
        previous_right_mouse = equipment_held
        previous_left_mouse = primary
        world.step_tick(command, 1.0 / 60.0)
        _apply_recoil_mouse()
    _play_new_events()
    _update_spectator()
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
    var zoom_target := _camera_zoom_target()
    camera.zoom = camera.zoom.lerp(Vector2.ONE * zoom_target, 0.065)
    var camera_follow := 0.24 if world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot == world.local_slot else 0.42
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
    tower_sfx = _make_impact_stream(92.0, 0.16, 0.18)

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
        if event_type == &"tower_fire":
            _play_sfx(tower_sfx, -3.0)
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
    _cleanup_host_signals()
    net_active = false
    net_host = false
    if hub.in_room:
        hub.leave_room()
    _return_to_hub()

func _cleanup_host_signals() -> void:
    _peer_seq.clear()
    if hub == null:
        return
    if hub.peer_input_received.is_connected(_on_peer_input):
        hub.peer_input_received.disconnect(_on_peer_input)
    if hub.peer_parked_received.is_connected(_on_peer_parked):
        hub.peer_parked_received.disconnect(_on_peer_parked)
    if hub.peer_reclaimed_received.is_connected(_on_peer_reclaimed):
        hub.peer_reclaimed_received.disconnect(_on_peer_reclaimed)

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

# --- Host relay helpers ---

func _on_peer_input(slot: int, input_data: Dictionary) -> void:
    if world != null and net_host:
        world.peer_commands[slot] = input_data
        var seq := int(input_data.get("seq", 0))
        if seq > _peer_seq.get(slot, 0):
            _peer_seq[slot] = seq

func _on_peer_parked(slot: int) -> void:
    if world != null and net_host and world.human_slots.has(slot):
        world.human_slots.erase(slot)

func _on_peer_reclaimed(slot: int, player_name: String) -> void:
    if world != null and net_host:
        world.human_slots[slot] = true

func _snap_hex(c: Variant) -> String:
    if c is Color:
        return "#" + (c as Color).to_html(false)
    var s := str(c)
    return s if s.begins_with("#") else "#ffffff"

func _build_host_snapshot() -> Dictionary:
    var players_arr: Array = []
    for h in world.heroes:
        players_arr.append({
            "slot": int(h["slot"]),
            "name": str(h.get("display_name", str(h.get("equipment", {}).get("character_name", "P%d" % (int(h["slot"]) + 1))))),
            "cpu": not world.human_slots.has(int(h["slot"])) and int(h["slot"]) != world.local_slot,
            "parked": false,
            "x": Vector2(h["pos"]).x,
            "y": Vector2(h["pos"]).y,
            "aimX": Vector2(h["pos"]).x + Vector2(h["aim"]).x * 100.0,
            "aimY": Vector2(h["pos"]).y + Vector2(h["aim"]).y * 100.0,
            "hp": float(h["hp"]),
            "alive": bool(h["alive"]),
            "weapon": str(h.get("equipment", {}).get("name", "")),
            "item": "medkit" if int(h.get("medkits", 0)) > 0 else "",
            "kills": int(h["kills"]),
            "ack": _peer_seq.get(int(h["slot"]), 0)
        })
    var bullets_arr: Array = []
    for proj in world.projectiles:
        bullets_arr.append({
            "x": Vector2(proj["pos"]).x,
            "y": Vector2(proj["pos"]).y,
            "owner": int(proj["owner"])
        })
    var loot_arr: Array = []
    for pickup in world.health_pickups:
        if not bool(pickup.get("active", false)):
            continue
        var entry := {
            "id": str(pickup.get("id", "")),
            "kind": "gun" if pickup.has("gun_name") else "item",
            "x": Vector2(pickup["pos"]).x,
            "y": Vector2(pickup["pos"]).y,
            "n": str(pickup.get("gun_name", ""))
        }
        loot_arr.append(entry)
    var zones_arr: Array = []
    for z in world.zones:
        var zp := Vector2(z["pos"])
        zones_arr.append({
            "x": zp.x, "y": zp.y, "radius": float(z["radius"]),
            "owner": int(z["owner"]), "delay": float(z.get("delay", 0)),
            "warning_duration": float(z.get("warning_duration", 0)),
            "color": _snap_hex(z.get("color", Color.WHITE)),
            "effect_kind": str(z.get("effect_kind", "explosion")),
            "label": str(z.get("label", ""))
        })
    var deploys_arr: Array = []
    for d in world.deployables:
        var dp := Vector2(d["pos"])
        var dd := Vector2(d.get("direction", Vector2.RIGHT))
        var td := Vector2(d.get("travel_direction", Vector2.RIGHT))
        deploys_arr.append({
            "type": str(d.get("type", "mine")), "owner": int(d["owner"]),
            "x": dp.x, "y": dp.y, "dx": dd.x, "dy": dd.y, "tdx": td.x, "tdy": td.y,
            "half_length": float(d.get("half_length", 0)),
            "lifetime": float(d.get("lifetime", 0)),
            "max_lifetime": float(d.get("max_lifetime", 0)),
            "arm_time": float(d.get("arm_time", 0)),
            "arm_duration": float(d.get("arm_duration", 0)),
            "triggered": bool(d.get("triggered", false)),
            "trigger_radius": float(d.get("trigger_radius", 0)),
            "blast_radius": float(d.get("blast_radius", 0)),
            "fuse_time": float(d.get("fuse_time", 0)),
            "fuse_duration": float(d.get("fuse_duration", 0))
        })
    var cores_arr: Array = []
    for c in world.cores:
        var cp := Vector2(c["pos"])
        cores_arr.append({
            "slot": int(c["slot"]), "x": cp.x, "y": cp.y,
            "hp": float(c.get("hp", 0)), "max_hp": float(c.get("max_hp", 1)),
            "alive": bool(c.get("alive", true))
        })
    var covers_arr: Array = []
    for cv in world.covers:
        var rect: Rect2 = cv["rect"]
        covers_arr.append({"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y})
    var knockouts_arr: Array = []
    for ko in world.knockouts:
        var kp := Vector2(ko["pos"])
        knockouts_arr.append({
            "slot": int(ko["slot"]), "x": kp.x, "y": kp.y,
            "time": float(ko["time"]), "max_time": float(ko.get("max_time", 2.15))
        })
    var crates_arr: Array = []
    for cr in world.crates:
        var crp := Vector2(cr["pos"])
        crates_arr.append({
            "id": int(cr.get("id", 0)), "x": crp.x, "y": crp.y,
            "hp": float(cr.get("hp", 0)), "max_hp": float(cr.get("max_hp", 48)),
            "alive": bool(cr.get("alive", false))
        })
    var orbs_arr: Array = []
    for orb in world.crate_orbs:
        var op := Vector2(orb["pos"])
        orbs_arr.append({
            "x": op.x, "y": op.y,
            "red": bool(orb.get("red", true)),
            "active": bool(orb.get("active", true))
        })
    var tower_dict: Dictionary = {}
    if not world.mid_tower.is_empty():
        var tp := Vector2(world.mid_tower.get("pos", Vector2.ZERO))
        tower_dict = {
            "alive": bool(world.mid_tower.get("alive", false)),
            "x": tp.x, "y": tp.y,
            "hp": float(world.mid_tower.get("hp", 0)),
            "max_hp": float(world.mid_tower.get("max_hp", 1)),
            "boing": float(world.mid_tower.get("boing", 0))
        }
    return {
        "tick": world.tick,
        "time": world.match_time,
        "result": str(world.result),
        "winner": world.winner_slot,
        "zoneR": world.safe_zone_radius,
        "shrinking": world.safe_zone_shrinking,
        "zoneCX": Vector2(world.safe_zone_center).x,
        "zoneCY": Vector2(world.safe_zone_center).y,
        "zonePhase": world.safe_zone_phase,
        "startCountdown": world.start_countdown,
        "wantedSlot": world.wanted_slot,
        "mode": world.mode,
        "players": players_arr,
        "bullets": bullets_arr,
        "loot": loot_arr,
        "zones": zones_arr,
        "deployables": deploys_arr,
        "cores": cores_arr,
        "covers": covers_arr,
        "knockouts": knockouts_arr,
        "crates": crates_arr,
        "crate_orbs": orbs_arr,
        "mid_tower": tower_dict
    }
