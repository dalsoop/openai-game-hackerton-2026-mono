extends RefCounted

const EventLogScript = preload("res://scripts/sim/event_log.gd")

const PLAYER_COUNT := 8
const ARENA_SIZE := Vector2(7840.0, 4760.0)
const ARENA_CENTER := Vector2(3920.0, 2380.0)
const ARENA_MARGIN := 104.0
const HERO_RADIUS := 20.0
const FIXED_DT := 1.0 / 60.0
const SNAP_HZ := 20.0
const INTERP_SEC := 0.06
const MOVE_SPEED := 210.0
const DASH_SPEED := 520.0
const DASH_COOLDOWN := 1.6
const MATCH_TIME_LIMIT := 210.0
const ULTIMATE_MAX := 100.0
const SAFE_ZONE_MIN_RADIUS := 90.0
const SAFE_ZONE_PHASES: Array = []

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
var safe_zone_center: Vector2 = ARENA_CENTER
var safe_zone_radius: float = 420.0
var safe_zone_from_radius: float = 420.0
var safe_zone_target_radius: float = 420.0
var safe_zone_phase: int = 0
var safe_zone_phase_time: float = 0.0
var safe_zone_shrinking: bool = false
var safe_zone_complete: bool = false
var mode: String = "classic"

var _prev_bullets: Array[Dictionary] = []
var _deaths: Dictionary = {}
var _snaps: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _input_seq: int = 0
var _acked: int = 0
var _pred_pos: Vector2 = ARENA_CENTER
var _pred_aim: Vector2 = Vector2.RIGHT
var _pred_dash_cd: float = 0.0
var _has_pred: bool = false

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
    _prev_bullets.clear()
    _deaths.clear()
    _snaps.clear()
    _pending.clear()
    _input_seq = 0
    _acked = 0
    _pred_pos = ARENA_CENTER
    _pred_aim = Vector2.RIGHT
    _pred_dash_cd = 0.0
    _has_pred = false
    last_down_slot = -1
    last_down_ticks = 0
    callout = ""
    callout_ticks = 0
    event_log.clear()

static func _f(source: Dictionary, key: String, fallback: float) -> float:
    var v: Variant = source.get(key)
    if v is float or v is int:
        return float(v)
    return fallback

func push_snap(snap: Dictionary) -> void:
    if snap.is_empty():
        return
    var next_tick := int(snap.get("tick", -1))
    if not _snaps.is_empty() and next_tick <= int(_snaps.back().get("tick", -1)):
        return
    _snaps.append(snap)
    while _snaps.size() > 16:
        _snaps.pop_front()
    if heroes.is_empty():
        apply_snap(snap)
        _seed_prediction(snap)

func predict_local(move: Vector2, dash: bool, aim: Vector2, dt: float) -> int:
    _input_seq += 1
    var mx := move.x
    var my := move.y
    _pending.append({"seq":_input_seq, "mx":mx, "my":my, "dash":dash, "aim":aim, "dt":dt})
    while _pending.size() > 90:
        _pending.pop_front()
    if not _has_pred and not heroes.is_empty() and local_slot >= 0 and local_slot < heroes.size():
        _pred_pos = Vector2(heroes[local_slot]["pos"])
        _has_pred = true
    _step_pred(mx, my, dash, aim, dt)
    _overlay_prediction()
    return _input_seq

func present(_dt: float) -> void:
    if _snaps.is_empty():
        return
    if _snaps.size() == 1:
        apply_snap(_snaps[0])
        _seed_prediction(_snaps[0])
        _overlay_prediction()
        return
    var latest: Dictionary = _snaps.back()
    var render_tick := float(int(latest.get("tick", 0))) - INTERP_SEC * SNAP_HZ
    var older: Dictionary = _snaps[0]
    var newer: Dictionary = latest
    for i in range(_snaps.size() - 1):
        var a: Dictionary = _snaps[i]
        var b: Dictionary = _snaps[i + 1]
        if float(int(b.get("tick", 0))) >= render_tick:
            older = a
            newer = b
            break
    apply_snap(newer)
    var from_tick := float(int(older.get("tick", 0)))
    var to_tick := float(int(newer.get("tick", 0)))
    var span := maxf(0.0001, to_tick - from_tick)
    var alpha := clampf((render_tick - from_tick) / span, 0.0, 1.0)
    if render_tick > to_tick:
        var extra := minf(0.08, (render_tick - to_tick) / SNAP_HZ)
        _extrapolate(extra)
    else:
        _lerp_motion(older, newer, alpha)
    _reconcile(newer)
    _overlay_prediction()
    while _snaps.size() > 2 and float(int(_snaps[1].get("tick", 0))) < render_tick:
        _snaps.pop_front()

func _seed_prediction(snap: Dictionary) -> void:
    if _has_pred:
        return
    var me := _player_in(snap, local_slot)
    if me.is_empty():
        return
    _pred_pos = Vector2(_f(me, "x", ARENA_CENTER.x), _f(me, "y", ARENA_CENTER.y))
    _pred_aim = Vector2(_f(me, "aimX", _pred_pos.x + 1.0), _f(me, "aimY", _pred_pos.y)) - _pred_pos
    if _pred_aim.length_squared() < 0.01:
        _pred_aim = Vector2.RIGHT
    else:
        _pred_aim = _pred_aim.normalized()
    _has_pred = true

func _player_in(snap: Dictionary, slot: int) -> Dictionary:
    for raw in snap.get("players", []):
        var p: Dictionary = raw
        if int(p.get("slot", -1)) == slot:
            return p
    return {}

func _lerp_motion(older: Dictionary, newer: Dictionary, alpha: float) -> void:
    var from_map := {}
    for raw in older.get("players", []):
        var p: Dictionary = raw
        from_map[int(p.get("slot", -1))] = p
    var to_map := {}
    for raw in newer.get("players", []):
        var p: Dictionary = raw
        to_map[int(p.get("slot", -1))] = p
    for hero in heroes:
        var slot := int(hero["slot"])
        if not from_map.has(slot) or not to_map.has(slot):
            continue
        var a: Dictionary = from_map[slot]
        var b: Dictionary = to_map[slot]
        var from_pos := Vector2(_f(a, "x", 0.0), _f(a, "y", 0.0))
        var to_pos := Vector2(_f(b, "x", 0.0), _f(b, "y", 0.0))
        hero["pos"] = from_pos.lerp(to_pos, alpha)
        hero["vel"] = (to_pos - from_pos) * SNAP_HZ
        var from_aim := Vector2(_f(a, "aimX", from_pos.x + 1.0), _f(a, "aimY", from_pos.y))
        var to_aim := Vector2(_f(b, "aimX", to_pos.x + 1.0), _f(b, "aimY", to_pos.y))
        var aim_point := from_aim.lerp(to_aim, alpha)
        if Vector2(hero["pos"]).distance_squared_to(aim_point) > 1.0:
            hero["aim"] = Vector2(hero["pos"]).direction_to(aim_point)
    var old_bullets: Array = older.get("bullets", [])
    var new_bullets: Array = newer.get("bullets", [])
    if old_bullets.size() == new_bullets.size() and projectiles.size() == new_bullets.size():
        for i in range(projectiles.size()):
            var ob: Dictionary = old_bullets[i]
            var nb: Dictionary = new_bullets[i]
            var from_b := Vector2(_f(ob, "x", 0.0), _f(ob, "y", 0.0))
            var to_b := Vector2(_f(nb, "x", 0.0), _f(nb, "y", 0.0))
            projectiles[i]["pos"] = from_b.lerp(to_b, alpha)
            projectiles[i]["vel"] = (to_b - from_b) * SNAP_HZ
    safe_zone_radius = lerpf(_f(older, "zoneR", safe_zone_radius), _f(newer, "zoneR", safe_zone_radius), alpha)

func _extrapolate(extra: float) -> void:
    for hero in heroes:
        hero["pos"] = _clamp_arena(Vector2(hero["pos"]) + Vector2(hero["vel"]) * extra)
    for shot in projectiles:
        shot["pos"] = Vector2(shot["pos"]) + Vector2(shot.get("vel", Vector2.ZERO)) * extra

func _reconcile(snap: Dictionary) -> void:
    var me := _player_in(snap, local_slot)
    if me.is_empty() or not bool(me.get("alive", true)):
        _has_pred = false
        _pending.clear()
        return
    var ack := int(me.get("ack", 0))
    if ack < _acked:
        return
    _acked = ack
    var keep: Array[Dictionary] = []
    for item in _pending:
        if int(item.get("seq", 0)) > ack:
            keep.append(item)
    _pending = keep
    _pred_pos = Vector2(_f(me, "x", _pred_pos.x), _f(me, "y", _pred_pos.y))
    _has_pred = true
    for item in _pending:
        _step_pred(_f(item, "mx", 0.0), _f(item, "my", 0.0), bool(item.get("dash", false)), Vector2(item.get("aim", _pred_pos)), _f(item, "dt", 1.0 / 60.0))

func _step_pred(mx: float, my: float, _dash: bool, aim: Vector2, dt: float) -> void:
    _pred_dash_cd = maxf(0.0, _pred_dash_cd - dt)
    var speed := MOVE_SPEED
    var move := Vector2(mx, my)
    var mlen := move.length()
    if mlen > 0.05:
        _pred_pos += move / maxf(1.0, mlen) * speed * dt
    _pred_pos = _clamp_arena(_pred_pos)
    if aim.distance_squared_to(_pred_pos) > 1.0:
        _pred_aim = _pred_pos.direction_to(aim)

func _clamp_arena(pos: Vector2) -> Vector2:
    return Vector2(
        clampf(pos.x, ARENA_MARGIN + HERO_RADIUS, ARENA_SIZE.x - ARENA_MARGIN - HERO_RADIUS),
        clampf(pos.y, ARENA_MARGIN + HERO_RADIUS, ARENA_SIZE.y - ARENA_MARGIN - HERO_RADIUS)
    )

func _overlay_prediction() -> void:
    if not _has_pred or heroes.is_empty():
        return
    if local_slot < 0 or local_slot >= heroes.size():
        return
    var me: Dictionary = heroes[local_slot]
    if not bool(me.get("alive", true)):
        return
    me["pos"] = _pred_pos
    me["aim"] = _pred_aim
    heroes[local_slot] = me

func _make_equipment(weapon_name: String, player_name: String) -> Dictionary:
    return NetSnapParser.make_equipment(weapon_name, player_name)

func apply_snap(snap: Dictionary) -> void:
    var prev_tick := tick
    tick = int(snap.get("tick", tick))
    var snap_dt := maxf(0.0, float(tick - prev_tick)) / SNAP_HZ
    match_time = _f(snap, "time", match_time)
    var prev_result := result
    var snap_result := str(snap.get("result", "playing"))
    winner_slot = int(snap.get("winner", -1))
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
    safe_zone_radius = _f(snap, "zoneR", safe_zone_radius)
    safe_zone_shrinking = bool(snap.get("shrinking", false))
    if safe_zone_shrinking:
        safe_zone_target_radius = maxf(SAFE_ZONE_MIN_RADIUS, safe_zone_radius * 0.62)
    else:
        safe_zone_target_radius = safe_zone_radius
    if snap.has("zoneCX") and snap.has("zoneCY"):
        safe_zone_center = Vector2(_f(snap, "zoneCX", ARENA_CENTER.x), _f(snap, "zoneCY", ARENA_CENTER.y))
    else:
        safe_zone_center = ARENA_CENTER
    if snap.has("zonePhase"):
        safe_zone_phase = int(snap["zonePhase"])
    if snap.has("startCountdown"):
        start_countdown = _f(snap, "startCountdown", 0.0)
    if snap.has("wantedSlot"):
        wanted_slot = int(snap["wantedSlot"])
    _apply_world_extras(snap)
    _apply_players(snap.get("players", []))
    _apply_bullets(snap.get("bullets", []))
    _apply_loot(snap.get("loot", []))
    _decay_effects(snap_dt)
    if last_down_ticks > 0:
        last_down_ticks = maxi(0, last_down_ticks - maxi(1, tick - prev_tick))
    if prev_result == &"playing" and result != &"playing":
        if winner_slot >= 0 and winner_slot < heroes.size():
            decision_hp_ratio = clampf(float(heroes[winner_slot]["hp"]) / 100.0, 0.0, 1.0)
            impact_pos = heroes[winner_slot]["pos"]
        impact_ticks = 26
        event_log.emit(tick, &"match_won", winner_slot, -1, {"reason":result_reason})

func _apply_world_extras(snap: Dictionary) -> void:
    zones = NetSnapParser.parse_zones(snap)
    deployables = NetSnapParser.parse_deployables(snap)
    cores = NetSnapParser.parse_cores(snap)
    covers = NetSnapParser.parse_covers(snap)
    knockouts = NetSnapParser.parse_knockouts(snap)
    crates = NetSnapParser.parse_crates(snap)
    crate_orbs = NetSnapParser.parse_crate_orbs(snap)
    var tower := NetSnapParser.parse_mid_tower(snap)
    if not tower.is_empty():
        mid_tower = tower

func _apply_players(list: Array) -> void:
    var prev := {}
    for hero in heroes:
        prev[int(hero["slot"])] = hero
    var next: Array[Dictionary] = []
    for raw in list:
        var p: Dictionary = raw
        var slot := int(p.get("slot", next.size()))
        var pos := Vector2(_f(p, "x", 0.0), _f(p, "y", 0.0))
        var old: Dictionary = prev.get(slot, {})
        var old_pos: Vector2 = old.get("pos", pos)
        var vel := (pos - old_pos) * SNAP_HZ
        var aim_point := Vector2(_f(p, "aimX", pos.x + 1.0), _f(p, "aimY", pos.y))
        var aim := Vector2(old.get("aim", Vector2.RIGHT))
        if pos.distance_squared_to(aim_point) > 1.0:
            aim = pos.direction_to(aim_point)
        var alive := bool(p.get("alive", true))
        var was_alive := bool(old.get("alive", true))
        var deaths := int(_deaths.get(slot, 0))
        if was_alive and not alive:
            deaths += 1
            _deaths[slot] = deaths
            last_down_slot = slot
            last_down_ticks = 18
            impact_pos = pos
            impact_ticks = maxi(impact_ticks, 10)
            event_log.emit(tick, &"hero_downed", slot, -1, {})
            _add_effect(&"death_burst", pos, 120.0, 0.5, Color("#ff3349"))
        var player_name := str(p.get("name", "P%d" % (slot + 1)))
        var item_name := str(p.get("item", ""))
        var kills := int(p.get("kills", 0))
        next.append({
            "slot":slot,
            "alive":alive,
            "eliminated":not alive,
            "pos":pos,
            "vel":vel,
            "aim":aim,
            "hp":_f(p, "hp", 0.0),
            "max_hp":100.0,
            "kills":kills,
            "deaths":deaths,
            "score":float(kills) * 100.0 + (500.0 if alive and result != &"playing" and slot == winner_slot else 0.0),
            "eliminations":kills,
            "damage_dealt":0.0,
            "core_damage":0.0,
            "ultimates":0,
            "equipment_hits":0,
            "equipment":_make_equipment(str(p.get("weapon", "")), player_name),
            "display_name":player_name,
            "cpu":bool(p.get("cpu", false)),
            "parked":bool(p.get("parked", false)),
            "ultimate_charge":0.0,
            "mobility_cd":0.0,
            "medkits":1 if item_name != "" else 0,
            "cc_time":0.0,
            "stun_time":0.0,
            "root_time":0.0,
            "guard_time":0.0,
            "super_armor_time":0.0,
            "charging_skill":false,
            "charge_time":0.0,
            "kill_streak":0,
            "best_kill_streak":0,
            "launch_trail":[],
            "launch_trail_fade":0.0,
            "launch_time":0.0,
            "launch_vel":Vector2.ZERO,
            "action":&"READY"
        })
    heroes = next

func _apply_bullets(list: Array) -> void:
    var next := NetSnapParser.parse_bullets(list, _prev_bullets, SNAP_HZ)
    _prev_bullets = next.duplicate()
    projectiles = next

func _apply_loot(list: Array) -> void:
    health_pickups = NetSnapParser.parse_loot(list)

func _add_effect(kind: StringName, pos: Vector2, radius: float, duration: float, color: Color) -> void:
    effects.append({
        "kind":kind,
        "pos":pos,
        "radius":radius,
        "time":duration,
        "max_time":duration,
        "color":color,
        "direction":Vector2.RIGHT,
        "label":""
    })

func _decay_effects(dt: float) -> void:
    if dt <= 0.0:
        dt = 1.0 / SNAP_HZ
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
    for slot in range(heroes.size()):
        var hero: Dictionary = heroes[slot]
        rows.append({"slot":slot, "score":float(hero["score"]), "kills":int(hero["kills"]), "deaths":int(hero["deaths"]), "streak":0, "best_streak":0, "eliminations":int(hero["eliminations"]), "damage":0.0, "core_damage":0.0})
    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
    return rows

func final_standings() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for slot in range(heroes.size()):
        var hero: Dictionary = heroes[slot]
        rows.append({
            "slot":slot,
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
