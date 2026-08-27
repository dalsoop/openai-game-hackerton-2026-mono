extends RefCounted

const EventLogScript = preload("res://games/dagul/sim/event_log.gd")
const ArenaGeo = preload("res://games/dagul/sim/arena_geometry.gd")
const NetSnapParser = preload("res://games/dagul/net/net_snap_parser.gd")
const SnapContract = preload("res://games/dagul/net/snap_contract.gd")
const SfxDerive = preload("res://games/dagul/net/net_sfx_derive.gd")
const NetPred = preload("res://games/dagul/net/net_pred.gd")
const EquipRegScript = preload("res://games/dagul/sim/equipment_registry.gd")
const GunSigScript = preload("res://games/dagul/sim/gun_signature.gd")

const PLAYER_COUNT := 8
const ARENA_SIZE := ArenaGeo.ARENA_SIZE
const ARENA_CENTER := ArenaGeo.ARENA_CENTER
const ARENA_MARGIN := ArenaGeo.ARENA_MARGIN
const HERO_RADIUS := ArenaGeo.HERO_RADIUS
const FIXED_DT := 1.0 / 60.0
const TICK_RATE := 60.0  # 서버 고정 시뮬 틱레이트 (FIXED_DT 의 역수)
const INTERP_SEC := 0.06
const DASH_DISTANCE := 138.0
const DASH_COOLDOWN := 5.0
const PRED_FIRE_SKIP := 0.18
const MATCH_TIME_LIMIT := 210.0
const ULTIMATE_MAX := 100.0
const SAFE_ZONE_MIN_RADIUS := 90.0
const SAFE_ZONE_INITIAL_RADIUS := 3304.0
const SAFE_ZONE_PHASES: Array = []
# 원본 sim: tick%2 샘플, cap 14, fade 0.34 (hero_movement / match_lifecycle).
const LAUNCH_TRAIL_CAP := 14
const LAUNCH_TRAIL_FADE := 0.34

var is_net := true
var local_slot: int = 0
var event_log
var tick: int = 0
var heroes: Array[Dictionary] = []
var cores: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var deployables: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var knockouts: Array[Dictionary] = []
var covers: Array[Dictionary] = []
var health_pickups: Array[Dictionary] = []
var crates: Array[Dictionary] = []
var crate_orbs: Array[Dictionary] = []
var mid_tower: Dictionary = {}
var result: StringName = &"playing"
var winner_slot: int = -1
var result_reason: StringName = &""
var decision_hp_ratio: float = 0.0
var decision_core_ratio: float = 0.0
var match_time: float = 0.0
var wanted_slot: int = -1
var callout: String = ""
var callout_ticks: int = 0
var impact_ticks: int = 0
var impact_pos: Vector2 = ARENA_CENTER
var last_down_slot: int = -1
var last_down_ticks: int = 0
var start_countdown: float = 0.0
var ultimate_focus_slot: int = -1
var ultimate_focus_time: float = 0.0
var ultimate_focus_max: float = 0.48
var streak_callout: String = ""
var streak_subtitle: String = ""
var streak_callout_ticks: int = 0
var streak_callout_shutdown: bool = false
var finish_cine: Dictionary = {}
var safe_zone_center: Vector2 = ARENA_CENTER
var safe_zone_radius: float = SAFE_ZONE_INITIAL_RADIUS
var safe_zone_from_radius: float = SAFE_ZONE_INITIAL_RADIUS
var safe_zone_target_radius: float = SAFE_ZONE_INITIAL_RADIUS
var safe_zone_phase: int = 0
var safe_zone_phase_time: float = 0.0
var safe_zone_shrinking: bool = false
var safe_zone_complete: bool = false
var mode: String = "classic"
var local_fire_shake: int = 0
var local_mouse_kick: Vector2 = Vector2.ZERO
var local_hit_shake: int = 0

var _prev_bullets: Array[Dictionary] = []
var _deaths: Dictionary = {}
var _snaps: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _input_seq: int = 0
var _acked: int = 0
var _pred_pos: Vector2 = ARENA_CENTER
var _pred_aim: Vector2 = Vector2.RIGHT
var _pred_dash_cd: float = 0.0
var _pred_fire_skip_left: float = 0.0
var _equip_reg = EquipRegScript.new()
var _has_pred: bool = false
var _bullets_ready: bool = false
var _fight_countdown_fired: bool = false
var _applied_tick: int = -1
var _server_events_active: bool = false
var _snap_had_gun_fire: bool = false
var _launch_trails: Dictionary = {}
var _pred_fire_tick: int = 0
var _lerp_from_slot: Dictionary = {}
var _lerp_to_slot: Dictionary = {}
var _lerp_old_bullets: Dictionary = {}
var _lerp_new_bullets: Dictionary = {}

func _init() -> void:
    event_log = EventLogScript.new()

func set_mode(next_mode: String) -> void:
    mode = next_mode

func reset() -> void:
    tick = 0
    match_time = 0.0
    result = &"playing"
    winner_slot = -1
    result_reason = &""
    decision_hp_ratio = 0.0
    heroes.clear()
    projectiles.clear()
    effects.clear()
    health_pickups.clear()
    crates.clear()
    crate_orbs.clear()
    knockouts.clear()
    _reset_net_session()
    last_down_slot = -1
    last_down_ticks = 0
    callout = ""
    callout_ticks = 0
    streak_callout = ""
    streak_subtitle = ""
    streak_callout_ticks = 0
    streak_callout_shutdown = false
    finish_cine = {}
    cores.clear()
    zones.clear()
    deployables.clear()
    covers.clear()
    mid_tower = {}
    event_log.clear()

func _reset_net_session() -> void:
    _prev_bullets.clear()
    _deaths.clear()
    _snaps.clear()
    _pending.clear()
    _input_seq = 0
    _acked = 0
    _pred_pos = ARENA_CENTER
    _pred_aim = Vector2.RIGHT
    _pred_dash_cd = 0.0
    _pred_fire_skip_left = 0.0
    _has_pred = false
    _bullets_ready = false
    _fight_countdown_fired = false
    _applied_tick = -1
    _server_events_active = false
    _snap_had_gun_fire = false
    _pred_fire_tick = 0
    _launch_trails.clear()
    _lerp_from_slot.clear()
    _lerp_to_slot.clear()
    _lerp_old_bullets.clear()
    _lerp_new_bullets.clear()

static func _f(source: Dictionary, key: String, fallback: float) -> float:
    var v: Variant = source.get(key)
    if v is float or v is int:
        return float(v)
    return fallback

static func snap_per_sec(from_tick: float, to_tick: float) -> float:
    return TICK_RATE / maxf(1.0, to_tick - from_tick)

func push_snap(snap: Dictionary) -> void:
    if snap.is_empty():
        return
    var next_tick := int(snap.get(SnapContract.TICK, -1))
    if not _snaps.is_empty() and next_tick <= int(_snaps.back().get(SnapContract.TICK, -1)):
        return
    _snaps.append(snap)
    while _snaps.size() > 16:
        _snaps.pop_front()
    if heroes.is_empty():
        apply_snap(snap)
        _seed_prediction(snap)

func predict_local(move: Vector2, dash: bool, aim: Vector2, dt: float) -> int:
    # 대기(카운트다운)·종료 중엔 서버가 입력을 무시한다 — 예측도 얼려서 유령 이동을 막는다.
    if heroes.is_empty() or start_countdown > 0.0 or result != &"playing":
        return _input_seq
    _input_seq += 1
    var mx := move.x
    var my := move.y
    _pending.append({"seq":_input_seq, "mx":mx, "my":my, "dash":dash, "aim":aim, "dt":dt})
    while _pending.size() > 90:
        _pending.pop_front()
    if not _has_pred:
        var seed := hero_at_slot(local_slot)
        if not seed.is_empty():
            _pred_pos = Vector2(seed["pos"])
            _has_pred = true
    _step_pred(mx, my, dash, aim, dt)
    _overlay_prediction()
    return _input_seq

func predict_local_fire(aim_point: Vector2 = Vector2.ZERO) -> bool:
    if start_countdown > 0.0 or result != &"playing":
        return false
    if _pred_fire_skip_left > 0.0:
        return false
    var me := hero_at_slot(local_slot)
    if me.is_empty() or not bool(me.get("alive", true)):
        return false
    if int(me.get("mag", 0)) <= 0:
        return false
    if float(me.get("reload_left", 0.0)) > 0.0:
        return false
    _spawn_pred_fire_fx(me, aim_point)
    _pred_fire_skip_left = PRED_FIRE_SKIP
    _pred_fire_tick = tick
    return true

## 클릭 프레임의 실제 조준점(aim_point, 월드 좌표)으로 방향을 잡는다 — 직전 스냅의
## 낡은 aim 을 쓰면 방향 전환 직후 트레이서가 옛 방향으로 나가 실탄과 어긋난다.
func _spawn_pred_fire_fx(me: Dictionary, aim_point: Vector2 = Vector2.ZERO) -> void:
    var eq: Dictionary = me.get("equipment", {})
    var eq_id := str(eq.get("id", ""))
    var origin: Vector2 = _pred_pos if _has_pred else Vector2(me.get("pos", _pred_pos))
    var aim: Vector2 = me.get("aim", _pred_aim)
    if aim_point != Vector2.ZERO and aim_point.distance_squared_to(origin) > 1.0:
        aim = origin.direction_to(aim_point)
    if aim.length_squared() < 0.0001:
        aim = Vector2.RIGHT
    else:
        aim = aim.normalized()
    var muzzle: Vector2 = GunSigScript.muzzle_world_pos(origin, aim, eq_id)
    me["muzzle_time"] = maxf(float(me.get("muzzle_time", 0.0)), 0.12)
    _add_effect(&"local_tracer", muzzle, 120.0, 0.12, Color(1.0, 0.95, 0.75, 1.0), aim)
    event_log.emit(tick, &"gun_fire", local_slot, -1, {"equipment": eq_id, "predicted": true})

func present(_dt: float) -> void:
    var step := maxf(_dt, FIXED_DT)
    if _pred_fire_skip_left > 0.0:
        _pred_fire_skip_left = maxf(0.0, _pred_fire_skip_left - step)
    local_fire_shake = maxi(0, local_fire_shake - 1)
    local_hit_shake = maxi(0, local_hit_shake - 1)
    if not _snaps.is_empty():
        _present_from_snaps()
    _synth_launch_trails(step)

func _present_from_snaps() -> void:
    if _snaps.size() == 1:
        _apply_if_new(_snaps[0])
        _seed_prediction(_snaps[0])
        _overlay_prediction()
        return
    var latest: Dictionary = _snaps.back()
    var render_tick := float(int(latest.get(SnapContract.TICK, 0))) - INTERP_SEC * TICK_RATE
    var older: Dictionary = _snaps[0]
    var newer: Dictionary = latest
    for i in range(_snaps.size() - 1):
        var a: Dictionary = _snaps[i]
        var b: Dictionary = _snaps[i + 1]
        if float(int(b.get(SnapContract.TICK, 0))) >= render_tick:
            older = a
            newer = b
            break
    _apply_if_new(newer)
    var from_tick := float(int(older.get(SnapContract.TICK, 0)))
    var to_tick := float(int(newer.get(SnapContract.TICK, 0)))
    var span := maxf(0.0001, to_tick - from_tick)
    var alpha := clampf((render_tick - from_tick) / span, 0.0, 1.0)
    if render_tick > to_tick:
        var extra := minf(0.08, (render_tick - to_tick) / TICK_RATE)
        _extrapolate(extra)
    else:
        _lerp_motion(older, newer, alpha)
    _reconcile(newer)
    _overlay_prediction()
    while _snaps.size() > 2 and float(int(_snaps[1].get(SnapContract.TICK, 0))) < render_tick:
        _snaps.pop_front()

func _synth_launch_trails(dt: float) -> void:
    var live := {}
    for hero in heroes:
        var slot := int(hero["slot"])
        var st: Dictionary = _launch_trails.get(slot, {"pts": [], "fade": 0.0, "tick": -1})
        _advance_launch_trail(hero, st, dt)
        hero["launch_trail"] = st["pts"]
        hero["launch_trail_fade"] = st["fade"]
        live[slot] = st
    _launch_trails = live

func _advance_launch_trail(hero: Dictionary, st: Dictionary, dt: float) -> void:
    if float(hero.get("launch_time", 0.0)) > 0.0:
        st["fade"] = LAUNCH_TRAIL_FADE
        _sample_launch_trail(hero, st)
        return
    st["fade"] = maxf(0.0, float(st["fade"]) - dt)
    if float(st["fade"]) <= 0.0:
        st["pts"] = []
        st["tick"] = -1

func _sample_launch_trail(hero: Dictionary, st: Dictionary) -> void:
    var pts: Array = st["pts"]
    var pos := Vector2(hero["pos"])
    if pts.is_empty():
        st["pts"] = [pos]
        st["tick"] = tick
        return
    if tick % 2 != 0 or tick == int(st["tick"]):
        return
    pts.append(pos)
    if pts.size() > LAUNCH_TRAIL_CAP:
        pts.pop_front()
    st["pts"] = pts
    st["tick"] = tick

func _apply_if_new(snap: Dictionary) -> void:
    var next_tick := int(snap.get(SnapContract.TICK, -1))
    if next_tick == _applied_tick:
        return
    apply_snap(snap)

func _seed_prediction(snap: Dictionary) -> void:
    if _has_pred:
        return
    var me := _player_in(snap, local_slot)
    if me.is_empty():
        return
    _pred_pos = Vector2(_f(me, SnapContract.P_X, ARENA_CENTER.x), _f(me, SnapContract.P_Y, ARENA_CENTER.y))
    _pred_aim = Vector2(_f(me, SnapContract.P_AIM_X, _pred_pos.x + 1.0), _f(me, SnapContract.P_AIM_Y, _pred_pos.y)) - _pred_pos
    if _pred_aim.length_squared() < 0.01:
        _pred_aim = Vector2.RIGHT
    else:
        _pred_aim = _pred_aim.normalized()
    _has_pred = true

func _fill_bullet_wire_by_id(list: Array, dest: Dictionary) -> void:
    dest.clear()
    for i in range(list.size()):
        var raw: Variant = list[i]
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var b: Dictionary = raw
        dest[int(b.get(SnapContract.B_ID, i))] = b

func _player_in(snap: Dictionary, slot: int) -> Dictionary:
    for raw in snap.get(SnapContract.PLAYERS, []):
        var p: Dictionary = raw
        if int(p.get(SnapContract.P_SLOT, -1)) == slot:
            return p
    return {}

func _fill_player_wire_by_slot(snap: Dictionary, dest: Dictionary) -> void:
    dest.clear()
    for raw in snap.get(SnapContract.PLAYERS, []):
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var p: Dictionary = raw
        dest[int(p.get(SnapContract.P_SLOT, -1))] = p

func _lerp_motion(older: Dictionary, newer: Dictionary, alpha: float) -> void:
    var vel_scale := snap_per_sec(float(int(older.get(SnapContract.TICK, 0))), float(int(newer.get(SnapContract.TICK, 0))))
    _fill_player_wire_by_slot(older, _lerp_from_slot)
    _fill_player_wire_by_slot(newer, _lerp_to_slot)
    for hero in heroes:
        var slot := int(hero["slot"])
        if not _lerp_from_slot.has(slot) or not _lerp_to_slot.has(slot):
            continue
        var a: Dictionary = _lerp_from_slot[slot]
        var b: Dictionary = _lerp_to_slot[slot]
        var from_pos := Vector2(_f(a, SnapContract.P_X, 0.0), _f(a, SnapContract.P_Y, 0.0))
        var to_pos := Vector2(_f(b, SnapContract.P_X, 0.0), _f(b, SnapContract.P_Y, 0.0))
        hero["pos"] = from_pos.lerp(to_pos, alpha)
        hero["vel"] = (to_pos - from_pos) * vel_scale
        var from_aim := Vector2(_f(a, SnapContract.P_AIM_X, from_pos.x + 1.0), _f(a, SnapContract.P_AIM_Y, from_pos.y))
        var to_aim := Vector2(_f(b, SnapContract.P_AIM_X, to_pos.x + 1.0), _f(b, SnapContract.P_AIM_Y, to_pos.y))
        var aim_point := from_aim.lerp(to_aim, alpha)
        if Vector2(hero["pos"]).distance_squared_to(aim_point) > 1.0:
            hero["aim"] = Vector2(hero["pos"]).direction_to(aim_point)
    _lerp_shots(older, newer, alpha, vel_scale)
    safe_zone_radius = lerpf(_f(older, SnapContract.ZONE_R, safe_zone_radius), _f(newer, SnapContract.ZONE_R, safe_zone_radius), alpha)

func _lerp_shots(older: Dictionary, newer: Dictionary, alpha: float, vel_scale: float) -> void:
    _fill_bullet_wire_by_id(older.get(SnapContract.BULLETS, []), _lerp_old_bullets)
    _fill_bullet_wire_by_id(newer.get(SnapContract.BULLETS, []), _lerp_new_bullets)
    for shot in projectiles:
        var bid := int(shot.get("id", -1))
        if not _lerp_old_bullets.has(bid) or not _lerp_new_bullets.has(bid):
            continue
        var ob: Dictionary = _lerp_old_bullets[bid]
        var nb: Dictionary = _lerp_new_bullets[bid]
        var from_b := Vector2(_f(ob, SnapContract.B_X, 0.0), _f(ob, SnapContract.B_Y, 0.0))
        var to_b := Vector2(_f(nb, SnapContract.B_X, 0.0), _f(nb, SnapContract.B_Y, 0.0))
        shot["pos"] = from_b.lerp(to_b, alpha)
        shot["vel"] = (to_b - from_b) * vel_scale

func _extrapolate(extra: float) -> void:
    for hero in heroes:
        hero["pos"] = clamp_arena(Vector2(hero["pos"]) + Vector2(hero["vel"]) * extra)
    for shot in projectiles:
        shot["pos"] = Vector2(shot["pos"]) + Vector2(shot.get("vel", Vector2.ZERO)) * extra

func _reconcile(snap: Dictionary) -> void:
    var me := _player_in(snap, local_slot)
    if me.is_empty() or not bool(me.get(SnapContract.P_ALIVE, true)):
        _has_pred = false
        _pending.clear()
        return
    var ack := int(me.get(SnapContract.P_ACK, 0))
    if ack < _acked:
        return
    _acked = ack
    var keep: Array[Dictionary] = []
    for item in _pending:
        if int(item.get("seq", 0)) > ack:
            keep.append(item)
    _pending = keep
    _pred_pos = Vector2(_f(me, SnapContract.P_X, _pred_pos.x), _f(me, SnapContract.P_Y, _pred_pos.y))
    _has_pred = true
    if me.has(SnapContract.P_MOB_CD):
        _pred_dash_cd = _f(me, SnapContract.P_MOB_CD, 0.0)
    else:
        _pred_dash_cd = 0.0
    for item in _pending:
        _step_pred(_f(item, "mx", 0.0), _f(item, "my", 0.0), bool(item.get("dash", false)), Vector2(item.get("aim", _pred_pos)), _f(item, "dt", 1.0 / 60.0))

func _step_pred(mx: float, my: float, dash: bool, aim: Vector2, dt: float) -> void:
    NetPred.step(self, mx, my, dash, aim, dt)

static func clamp_arena(pos: Vector2) -> Vector2:
    return Vector2(
        clampf(pos.x, ARENA_MARGIN + HERO_RADIUS, ARENA_SIZE.x - ARENA_MARGIN - HERO_RADIUS),
        clampf(pos.y, ARENA_MARGIN + HERO_RADIUS, ARENA_SIZE.y - ARENA_MARGIN - HERO_RADIUS)
    )

func hero_at_slot(slot: int) -> Dictionary:
    for hero in heroes:
        if int(hero.get("slot", -1)) == slot:
            return hero
    return {}

func _overlay_prediction() -> void:
    if not _has_pred or heroes.is_empty():
        return
    var me := hero_at_slot(local_slot)
    if me.is_empty() or not bool(me.get("alive", true)):
        return
    me["pos"] = _pred_pos
    me["aim"] = _pred_aim
    me["mobility_cd"] = _pred_dash_cd

func apply(snap: Dictionary) -> void:
    apply_snap(snap)

func seed(snap: Dictionary) -> void:
    reset()
    push_snap(snap)

func apply_snap(snap: Dictionary) -> void:
    var prev_tick := tick
    var prev_countdown := start_countdown
    var prev_shrinking := safe_zone_shrinking
    SnapContract.apply_header(self, snap)
    _apply_world_extras(snap)
    var rate := snap_per_sec(float(prev_tick), float(tick))
    var snap_dt := maxf(0.0, float(tick - prev_tick)) / TICK_RATE
    var prev_result := result
    _apply_result(snap)
    _ingest_events(snap)
    SfxDerive.header_events(self, prev_countdown, prev_shrinking)
    _fight_countdown_fired = SfxDerive.countdown_event(self, _fight_countdown_fired)
    _derive_zone_target()
    _apply_players(snap.get(SnapContract.PLAYERS, []), rate)
    _apply_bullets(snap.get(SnapContract.BULLETS, []), rate)
    _apply_loot(snap.get(SnapContract.LOOT, []))
    _decay_effects(snap_dt)
    _replace_server_effects(snap)
    if last_down_ticks > 0:
        last_down_ticks = maxi(0, last_down_ticks - maxi(1, tick - prev_tick))
    if prev_result == &"playing" and result != &"playing":
        _on_match_ended()
    _applied_tick = tick

func _apply_result(snap: Dictionary) -> void:
    var snap_result := str(snap.get(SnapContract.RESULT, "playing"))
    winner_slot = int(snap.get(SnapContract.WINNER, winner_slot))
    if snap_result == "playing":
        result = &"playing"
        result_reason = &""
    elif snap_result == "draw":
        result = &"draw"
        result_reason = &"no_survivors"
        winner_slot = -1
    else:
        result = &"won" if winner_slot == local_slot else &"lost"
        result_reason = &"last_survivor"

func _derive_zone_target() -> void:
    if safe_zone_shrinking:
        safe_zone_target_radius = maxf(SAFE_ZONE_MIN_RADIUS, safe_zone_radius * 0.62)
    else:
        safe_zone_target_radius = safe_zone_radius

func _on_match_ended() -> void:
    var winner := hero_at_slot(winner_slot)
    if not winner.is_empty():
        decision_hp_ratio = clampf(float(winner["hp"]) / 100.0, 0.0, 1.0)
        impact_pos = winner["pos"]
    impact_ticks = 26
    event_log.emit(tick, &"match_won", winner_slot, -1, {"reason":result_reason})

func _apply_world_extras(snap: Dictionary) -> void:
    SnapContract.apply_world(self, snap)

func _apply_players(list: Array, snap_per_sec: float) -> void:
    var prev := {}
    for hero in heroes:
        prev[int(hero["slot"])] = hero
    var next: Array[Dictionary] = []
    for raw in list:
        var p: Dictionary = raw
        var slot := int(p.get(SnapContract.P_SLOT, next.size()))
        var old: Dictionary = prev.get(slot, {})
        _check_death(p, old, slot)
        SfxDerive.player_events(self, p, old, slot)
        next.append(_build_hero(p, old, slot, snap_per_sec))
    heroes = next

func _check_death(p: Dictionary, old: Dictionary, slot: int) -> void:
    var alive := bool(p.get(SnapContract.P_ALIVE, true))
    var was_alive := bool(old.get("alive", true))
    if not was_alive or alive:
        return
    var deaths := int(_deaths.get(slot, 0)) + 1
    _deaths[slot] = deaths
    last_down_slot = slot
    last_down_ticks = 18
    var pos := Vector2(_f(p, SnapContract.P_X, 0.0), _f(p, SnapContract.P_Y, 0.0))
    impact_pos = pos
    impact_ticks = maxi(impact_ticks, 10)
    event_log.emit(tick, &"hero_downed", slot, -1, {})
    _add_effect(&"death_burst", pos, 120.0, 0.32, Color("#ff3349"))

func _build_hero(p: Dictionary, old: Dictionary, slot: int, snap_per_sec: float) -> Dictionary:
    var hero := SnapContract.unpack_player(p, old, slot, snap_per_sec)
    # deaths·score 는 스냅 값 우선 — 스냅에 키가 없을 때만 로컬 전이 카운터 폴백.
    if not p.has(SnapContract.P_DEATHS):
        hero["deaths"] = int(_deaths.get(slot, 0))
    hero["eliminations"] = int(hero["kills"])
    return hero

func _apply_bullets(list: Array, snap_per_sec: float) -> void:
    var next := NetSnapParser.parse_bullets(list, _prev_bullets, snap_per_sec)
    var local_new := _has_new_local_bullet(next)
    if _bullets_ready and not _snap_had_gun_fire:
        _emit_inferred_gun_fire(next)
    _bullets_ready = true
    _prev_bullets = next.duplicate()
    projectiles = next
    _resolve_pred_fire_skip(local_new)

func _emit_inferred_gun_fire(next: Array) -> void:
    var seen := {}
    for prev_b in _prev_bullets:
        seen[int(prev_b.get("id", -1))] = true
    for bullet in next:
        var bid := int(bullet.get("id", -1))
        if seen.has(bid):
            continue
        var owner := int(bullet.get("owner", -1))
        if _skip_local_pred_gun_fire(owner):
            continue
        event_log.emit(tick, &"gun_fire", owner, -1, {"equipment": ""})

func _ingest_events(snap: Dictionary) -> void:
    _snap_had_gun_fire = false
    if not snap.has(SnapContract.EVENTS):
        return
    _server_events_active = true
    for ev in NetSnapParser.parse_events(snap.get(SnapContract.EVENTS, [])):
        _ingest_one_event(ev)

func _ingest_one_event(ev: Dictionary) -> void:
    var kind := StringName(ev["kind"])
    var actor := int(ev["a"])
    if kind == &"gun_fire":
        _snap_had_gun_fire = true
        if _skip_local_pred_gun_fire(actor):
            return
    event_log.emit(int(ev["tick"]), kind, actor, int(ev["b"]), ev["data"])

func _skip_local_pred_gun_fire(slot: int) -> bool:
    return slot == local_slot and _pred_fire_skip_left > 0.0

func _has_new_local_bullet(next: Array) -> bool:
    var seen := {}
    for prev_b in _prev_bullets:
        seen[int(prev_b.get("id", -1))] = true
    for bullet in next:
        if seen.has(int(bullet.get("id", -1))):
            continue
        if int(bullet.get("owner", -1)) == local_slot:
            return true
    return false

func _resolve_pred_fire_skip(local_new_bullet: bool) -> void:
    if _pred_fire_skip_left <= 0.0:
        return
    if _snap_had_gun_fire or local_new_bullet:
        return
    if tick < _pred_fire_tick + 3:
        return
    _pred_fire_skip_left = 0.0

func _replace_server_effects(snap: Dictionary) -> void:
    if not snap.has(SnapContract.EFFECTS):
        return
    var locals := _keep_local_effects()
    effects = NetSnapParser.parse_effects(snap.get(SnapContract.EFFECTS, []))
    for fx in locals:
        effects.append(fx)

func _keep_local_effects() -> Array[Dictionary]:
    var kept: Array[Dictionary] = []
    for fx in effects:
        if str(fx.get("kind", "")).begins_with("local_"):
            kept.append(fx)
    return kept

func _apply_loot(list: Array) -> void:
    var next := NetSnapParser.parse_loot(list)
    SfxDerive.loot_events(self, health_pickups, next)
    health_pickups = next

func _add_effect(kind: StringName, pos: Vector2, radius: float, duration: float, color: Color, direction: Vector2 = Vector2.RIGHT) -> void:
    effects.append({
        "kind":kind,
        "pos":pos,
        "radius":radius,
        "time":duration,
        "max_time":duration,
        "color":color,
        "direction":direction,
        "label":""
    })

func _decay_effects(dt: float) -> void:
    if dt <= 0.0:
        dt = 1.0 / TICK_RATE
    for i in range(effects.size() - 1, -1, -1):
        var effect: Dictionary = effects[i]
        effect["time"] = float(effect["time"]) - dt
        if float(effect["time"]) <= 0.0:
            effects.remove_at(i)
        else:
            effects[i] = effect
    if impact_ticks > 0:
        impact_ticks = maxi(0, impact_ticks - 1)

func summary() -> Dictionary:
    var alive := 0
    for hero in heroes:
        if bool(hero["alive"]) and not bool(hero["eliminated"]):
            alive += 1
    return {"tick":tick, "time":match_time, "time_limit":MATCH_TIME_LIMIT, "alive":alive, "winner":winner_slot, "result":result, "result_reason":result_reason, "decision_hp_ratio":decision_hp_ratio, "decision_core_ratio":0.0, "projectiles":projectiles.size(), "start_countdown":start_countdown, "core_hps":[], "ultimate_uses":0, "equipment_hits":0, "safe_zone_radius":safe_zone_radius, "safe_zone_target":safe_zone_target_radius, "safe_zone_shrinking":safe_zone_shrinking, "mode":mode}

func leaderboard() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for hero in heroes:
        var slot := int(hero.get("slot", -1))
        rows.append({"slot":slot, "score":float(hero["score"]), "kills":int(hero["kills"]), "deaths":int(hero["deaths"]), "streak":int(hero.get("kill_streak", 0)), "best_streak":int(hero.get("best_kill_streak", 0)), "eliminations":int(hero["eliminations"]), "damage":0.0, "core_damage":0.0})
    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
    return rows

func final_standings() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for hero in heroes:
        rows.append({
            "slot":int(hero.get("slot", -1)),
            "hp_ratio":clampf(float(hero["hp"]) / 100.0, 0.0, 1.0),
            "core_ratio":0.0,
            "score":float(hero["score"]),
            "core_alive":false,
            "hero_alive":bool(hero["alive"]) and not bool(hero["eliminated"])
        })
    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if int(a["slot"]) == winner_slot:
            return true
        if int(b["slot"]) == winner_slot:
            return false
        return float(a["score"]) > float(b["score"])
    )
    return rows
