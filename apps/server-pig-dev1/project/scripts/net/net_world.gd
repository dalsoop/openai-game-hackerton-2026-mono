extends RefCounted

const EventLogScript = preload("res://scripts/sim/event_log.gd")

const PLAYER_COUNT := 8
const ARENA_SIZE := Vector2(1600.0, 900.0)
const ARENA_CENTER := Vector2(800.0, 450.0)
const FIXED_DT := 1.0 / 60.0
const SNAP_HZ := 20.0
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
    knockouts.clear()
    _prev_bullets.clear()
    _deaths.clear()
    last_down_slot = -1
    last_down_ticks = 0
    callout = ""
    callout_ticks = 0
    event_log.clear()

func _make_equipment(weapon_name: String, player_name: String) -> Dictionary:
    return {
        "id":"net",
        "name":weapon_name if weapon_name != "" else "권총",
        "character_name":player_name,
        "role":"",
        "special_name":"",
        "ultimate_name":"",
        "badge":"",
        "normal_name":"",
        "skill_name":"",
        "skill_desc":"",
        "ultimate_desc":""
    }

func apply_snap(snap: Dictionary) -> void:
    var prev_tick := tick
    tick = int(snap.get("tick", tick))
    var snap_dt := maxf(0.0, float(tick - prev_tick)) / SNAP_HZ
    match_time = float(snap.get("time", match_time))
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
    safe_zone_radius = float(snap.get("zoneR", safe_zone_radius))
    safe_zone_shrinking = bool(snap.get("shrinking", false))
    if safe_zone_shrinking:
        safe_zone_target_radius = maxf(SAFE_ZONE_MIN_RADIUS, safe_zone_radius * 0.62)
    else:
        safe_zone_target_radius = safe_zone_radius
    safe_zone_center = ARENA_CENTER
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

func _apply_players(list: Array) -> void:
    var prev := {}
    for hero in heroes:
        prev[int(hero["slot"])] = hero
    var next: Array[Dictionary] = []
    for raw in list:
        var p: Dictionary = raw
        var slot := int(p.get("slot", next.size()))
        var pos := Vector2(float(p.get("x", 0.0)), float(p.get("y", 0.0)))
        var old: Dictionary = prev.get(slot, {})
        var old_pos: Vector2 = old.get("pos", pos)
        var vel := (pos - old_pos) * SNAP_HZ
        var aim_point := Vector2(float(p.get("aimX", pos.x + 1.0)), float(p.get("aimY", pos.y)))
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
            "hp":float(p.get("hp", 0.0)),
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
    var next: Array[Dictionary] = []
    for raw in list:
        var b: Dictionary = raw
        var pos := Vector2(float(b.get("x", 0.0)), float(b.get("y", 0.0)))
        var vel := Vector2.ZERO
        var best := 3600.0
        for prev_b in _prev_bullets:
            var d := pos.distance_squared_to(prev_b["pos"])
            if d < best:
                best = d
                vel = (pos - prev_b["pos"]) * SNAP_HZ
        next.append({
            "pos":pos,
            "vel":vel,
            "owner":int(b.get("owner", 0)),
            "kind":"bolt",
            "source":&"normal",
            "arc":false,
            "radius":5.0
        })
    _prev_bullets = next.duplicate()
    projectiles = next

func _apply_loot(list: Array) -> void:
    var next: Array[Dictionary] = []
    for raw in list:
        var drop: Dictionary = raw
        var entry := {
            "active":true,
            "pos":Vector2(float(drop.get("x", 0.0)), float(drop.get("y", 0.0))),
            "id":abs(hash(str(drop.get("id", "")))) % 1000,
            "magnet_slot":-1
        }
        if str(drop.get("kind", "")) == "gun":
            var compact_name := str(drop.get("n", ""))
            if compact_name != "":
                entry["gun_name"] = compact_name
            else:
                var weapon: Dictionary = drop.get("weapon", {})
                entry["gun_name"] = str(weapon.get("name", "총"))
        next.append(entry)
    health_pickups = next

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
