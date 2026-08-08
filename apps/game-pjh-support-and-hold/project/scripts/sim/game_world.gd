extends RefCounted

const SeededRng = preload("res://scripts/sim/seeded_rng.gd")
const EventLog = preload("res://scripts/sim/event_log.gd")

const TICK_RATE := 60
const DT := 1.0 / 60.0
const WORLD_SIZE := Vector2(1600.0, 900.0)
const BASE_POS := Vector2(95.0, 450.0)
const HIVE_POS := Vector2(1510.0, 450.0)
const LANE_Y: Array[float] = [250.0, 450.0, 650.0]
const ACTOR_RADIUS := 18.0
const ENEMY_RADIUS := 14.0
const MAX_PHASES := 5
const START_COUNTDOWN_TICKS := 180
const ACTOR_ACCEL := 1700.0
const ACTOR_BRAKE := 2300.0

var world_size: Vector2 = WORLD_SIZE
var base_pos: Vector2 = BASE_POS
var hive_pos: Vector2 = HIVE_POS
var lane_y: Array[float] = LANE_Y
var actor_radius: float = ACTOR_RADIUS
var enemy_radius: float = ENEMY_RADIUS
var max_phases: int = MAX_PHASES

var tick: int = 0
var seed: int
var rng
var log
var result: StringName = &"playing"
var phase: int = 1
var phase_tick: int = 0
var phase_spawned: int = 0
var phase_target: int = 0
var base_hp: float = 1500.0
var base_hp_max: float = 1500.0
var hive_hp: float = 900.0
var hive_hp_max: float = 900.0
var hive_vulnerable: bool = false
var actors: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var packages: Array[Dictionary] = []
var requests: Array[Dictionary] = []
var barriers: Array[Dictionary] = []
var damage_requests: Array[Dictionary] = []
var next_enemy_id: int = 1000
var next_projectile_id: int = 100000
var next_package_id: int = 200000
var next_request_id: int = 300000
var next_barrier_id: int = 400000
var request_seq: int = 0
var human_slot: int = 0
var recent_message: String = ""
var recent_message_until: int = 0
var deliveries_completed: int = 0
var deliveries_destroyed: int = 0
var base_breaches: int = 0
var impact_ticks: int = 0
var start_countdown_ticks: int = START_COUNTDOWN_TICKS
var party_ready: bool = false
var party_mode: bool = false
var party_target: int = 0
var team_morale: float = 50.0
var manual_detonations: int = 0
var friendly_blasts: int = 0
var clutch_detonations: int = 0
var botched_detonations: int = 0
var support_revives: int = 0
var lane_covers: int = 0

func _init(match_seed: int = 55001) -> void:
    seed = match_seed
    rng = SeededRng.new(seed)
    log = EventLog.new()
    reset()

func reset() -> void:
    tick = 0
    result = &"playing"
    phase = 1
    phase_tick = 0
    phase_spawned = 0
    phase_target = 0
    base_hp = base_hp_max
    hive_hp = hive_hp_max
    hive_vulnerable = false
    actors.clear()
    enemies.clear()
    projectiles.clear()
    packages.clear()
    requests.clear()
    barriers.clear()
    damage_requests.clear()
    next_enemy_id = 1000
    next_projectile_id = 100000
    next_package_id = 200000
    next_request_id = 300000
    next_barrier_id = 400000
    request_seq = 0
    human_slot = 0
    recent_message = ""
    recent_message_until = 0
    deliveries_completed = 0
    deliveries_destroyed = 0
    base_breaches = 0
    impact_ticks = 0
    start_countdown_ticks = START_COUNTDOWN_TICKS
    party_ready = false
    party_mode = false
    party_target = 0
    team_morale = 50.0
    manual_detonations = 0
    friendly_blasts = 0
    clutch_detonations = 0
    botched_detonations = 0
    support_revives = 0
    lane_covers = 0
    log.clear()
    for slot in range(6):
        var soldier := slot < 3
        var lane := slot % 3
        var pos := Vector2(360.0, LANE_Y[lane]) if soldier else Vector2(155.0, LANE_Y[lane])
        var profile := _cpu_profile(slot)
        actors.append({
            "id": slot,
            "slot": slot,
            "role": &"soldier" if soldier else &"supplier",
            "lane": lane,
            "home_lane": lane,
            "covering_lane": -1,
            "pos": pos,
            "vel": Vector2.ZERO,
            "aim": Vector2(900.0, LANE_Y[lane]),
            "hp": 260.0 if soldier else 210.0,
            "hp_max": 260.0 if soldier else 210.0,
            "alive": true,
            "respawn_tick": -1,
            "speed": 190.0 if soldier else 170.0,
            "ammo": 72 if soldier else 0,
            "ammo_max": 90 if soldier else 0,
            "attack_cd": 0,
            "ability_cd": 0,
            "shield": 0.0,
            "overcharge": 0,
            "recoil": 0,
            "hit_combo": 0,
            "combo_timer": 0,
            "jam_ticks": 0,
            "supply_heat": 0,
            "timely_deliveries": 0,
            "waste_deliveries": 0,
            "risky_deliveries": 0,
            "stock_ammo": 4 if not soldier else 0,
            "stock_med": 2 if not soldier else 0,
            "stock_barrier": 1 if not soldier else 0,
            "production_ammo": 0,
            "production_med": 0,
            "production_barrier": 0,
            "selected_supply": &"ammo",
            "decision_tick": 0,
            "reaction": profile["reaction"],
            "risk": profile["risk"],
            "prediction": profile["prediction"],
            "error_rate": profile["error_rate"],
            "kills": 0,
            "deliveries": 0,
            "revives": 0,
            "requests_sent": 0,
            "last_request_tick": -10000,
            "last_damage_tick": -10000,
            "desired_x": pos.x
        })
    _start_phase(1)

func _cpu_profile(slot: int) -> Dictionary:
    var profiles := [
        {"reaction": 9, "risk": 0.65, "prediction": 0.64, "error_rate": 0.08},
        {"reaction": 12, "risk": 0.52, "prediction": 0.72, "error_rate": 0.06},
        {"reaction": 8, "risk": 0.78, "prediction": 0.57, "error_rate": 0.11},
        {"reaction": 11, "risk": 0.38, "prediction": 0.80, "error_rate": 0.06},
        {"reaction": 14, "risk": 0.31, "prediction": 0.68, "error_rate": 0.08},
        {"reaction": 10, "risk": 0.48, "prediction": 0.74, "error_rate": 0.07}
    ]
    return profiles[slot % profiles.size()]

func set_human_slot(slot: int) -> void:
    if slot < 0 or slot >= actors.size():
        return
    human_slot = slot
    _say("조작 대상 P%d / %s" % [slot + 1, String(actors[slot]["role"])], 120)

func step_tick(human_command: Dictionary, _dt: float = DT) -> void:
    if result != &"playing":
        return
    if not bool(human_command.get("party_ready", true)):
        party_ready = false
        return
    if not party_ready:
        party_ready = true
        log.add(tick, &"party_ready", 0, 3, {})
    party_mode = human_command.has("p2")
    if party_mode:
        var p2_command: Dictionary = human_command.get("p2", {})
        party_target = int(p2_command.get("target_actor", party_target))
    if start_countdown_ticks > 0:
        start_countdown_ticks -= 1
        for actor in actors:
            actor["vel"] = Vector2.ZERO
        tick += 1
        if start_countdown_ticks == 0:
            _say("GO!", 45)
            log.add(tick, &"operation_started", -1, -1, {})
        return
    if tick >= recent_message_until:
        recent_message = ""
    _tick_cooldowns_and_production()
    _update_phase_spawning()
    _refresh_auto_requests()
    for i in range(actors.size()):
        if not bool(actors[i]["alive"]):
            _try_respawn_actor(i)
            continue
        var command := _cpu_command(i)
        if i == human_slot:
            command = human_command.get("p1", human_command)
        elif i == 3 and party_mode:
            command = human_command.get("p2", {})
        _apply_actor_command(i, command)
    _update_projectiles()
    _update_packages()
    _update_barriers()
    _update_enemies()
    _resolve_damage()
    _cleanup()
    _update_phase_state()
    _check_result()
    _assert_finite()
    tick += 1
    phase_tick += 1

func _say(text: String, duration_ticks: int = 150) -> void:
    recent_message = text
    recent_message_until = tick + duration_ticks

func _start_phase(value: int) -> void:
    phase = value
    phase_tick = 0
    phase_spawned = 0
    phase_target = 14 + phase * 9
    if phase >= MAX_PHASES:
        phase_target -= 7
    hive_vulnerable = phase >= MAX_PHASES
    log.add(tick, &"phase_started", -1, -1, {"phase": phase, "target": phase_target})
    _say("PHASE %d — %s" % [phase, "HIVE PUSH" if hive_vulnerable else "HOLD"], 120)

func _tick_cooldowns_and_production() -> void:
    impact_ticks = maxi(0, impact_ticks - 1)
    for actor in actors:
        actor["attack_cd"] = maxi(0, int(actor["attack_cd"]) - 1)
        actor["ability_cd"] = maxi(0, int(actor["ability_cd"]) - 1)
        actor["shield"] = maxf(0.0, float(actor["shield"]) - 0.08)
        actor["overcharge"] = maxi(0, int(actor["overcharge"]) - 1)
        actor["recoil"] = maxi(0, int(actor["recoil"]) - 1)
        actor["combo_timer"] = maxi(0, int(actor["combo_timer"]) - 1)
        actor["jam_ticks"] = maxi(0, int(actor["jam_ticks"]) - 1)
        if int(actor["combo_timer"]) == 0:
            actor["hit_combo"] = 0
        if StringName(actor["role"]) == &"supplier":
            if int(actor["jam_ticks"]) > 0:
                continue
            actor["production_ammo"] = int(actor["production_ammo"]) + 1
            actor["production_med"] = int(actor["production_med"]) + 1
            actor["production_barrier"] = int(actor["production_barrier"]) + 1
            if int(actor["production_ammo"]) >= 180:
                actor["production_ammo"] = 0
                actor["stock_ammo"] = mini(8, int(actor["stock_ammo"]) + 1)
            if int(actor["production_med"]) >= 360:
                actor["production_med"] = 0
                actor["stock_med"] = mini(5, int(actor["stock_med"]) + 1)
            if int(actor["production_barrier"]) >= 600:
                actor["production_barrier"] = 0
                actor["stock_barrier"] = mini(3, int(actor["stock_barrier"]) + 1)

func _update_phase_spawning() -> void:
    if phase > MAX_PHASES or phase_spawned >= phase_target:
        return
    var interval := maxi(16, 48 - phase * 6)
    if phase_tick % interval != 0:
        return
    var lane := int(rng.next_u32() % 3)
    var elite: bool = phase >= 3 and rng.next_float() < 0.15 + float(phase) * 0.03
    _spawn_enemy(lane, elite)
    phase_spawned += 1

func _spawn_enemy(lane: int, elite: bool) -> void:
    var hp := (174.0 + phase * 29.0) if elite else (74.0 + phase * 13.0)
    var speed := (72.0 + phase * 2.6) if elite else (100.0 + phase * 3.2)
    var damage := (21.0 + phase * 1.9) if elite else (9.5 + phase * 1.1)
    enemies.append({
        "id": next_enemy_id,
        "lane": lane,
        "pos": Vector2(1560.0 + rng.rangef(-24.0, 24.0), LANE_Y[lane] + rng.rangef(-45.0, 45.0)),
        "vel": Vector2.ZERO,
        "hp": hp,
        "hp_max": hp,
        "speed": speed,
        "damage": damage,
        "attack_cd": 0,
        "breach_cd": 0,
        "elite": elite,
        "alive": true,
        "last_hits": []
    })
    next_enemy_id += 1

func _refresh_auto_requests() -> void:
    if tick % 30 != 0:
        return
    for i in range(3):
        var soldier: Dictionary = actors[i]
        if not bool(soldier["alive"]):
            continue
        if int(soldier["ammo"]) <= 24:
            _create_request(i, &"ammo", 1.0 - float(soldier["ammo"]) / float(soldier["ammo_max"]), false)
        if float(soldier["hp"]) <= float(soldier["hp_max"]) * 0.55:
            _create_request(i, &"med", 1.0 - float(soldier["hp"]) / float(soldier["hp_max"]), false)
        if _lane_enemy_count(int(soldier["lane"])) >= 7 and float(soldier["shield"]) < 1.0:
            _create_request(i, &"barrier", 0.72, false)

func _create_request(actor_index: int, kind: StringName, urgency: float, manual: bool) -> void:
    for request in requests:
        if not bool(request["fulfilled"]) and int(request["actor"]) == actor_index and StringName(request["kind"]) == kind:
            request["urgency"] = maxf(float(request["urgency"]), urgency)
            return
    var actor: Dictionary = actors[actor_index]
    if tick - int(actor["last_request_tick"]) < 45 and not manual:
        return
    requests.append({
        "id": next_request_id,
        "actor": actor_index,
        "kind": kind,
        "urgency": clampf(urgency + (0.15 if manual else 0.0), 0.0, 1.4),
        "created_tick": tick,
        "fulfilled": false,
        "assigned_supplier": -1
    })
    actor["last_request_tick"] = tick
    actor["requests_sent"] = int(actor["requests_sent"]) + 1
    log.add(tick, &"supply_requested", actor_index, -1, {"kind": kind, "urgency": urgency, "manual": manual})
    next_request_id += 1

func _cpu_command(index: int) -> Dictionary:
    var actor: Dictionary = actors[index]
    if StringName(actor["role"]) == &"soldier":
        return _cpu_soldier_command(index)
    return _cpu_supplier_command(index)

func _cpu_soldier_command(index: int) -> Dictionary:
    var actor: Dictionary = actors[index]
    var lane := _cover_lane_for_soldier(index)
    var previous_cover := int(actor["covering_lane"])
    var next_cover := lane if lane != int(actor["home_lane"]) else -1
    if next_cover >= 0 and previous_cover != next_cover:
        actor["covering_lane"] = next_cover
        lane_covers += 1
        _say("P%d LEAVES LANE %d TO COVER DOWNED LANE %d!" % [index + 1, int(actor["home_lane"]) + 1, next_cover + 1], 150)
        log.add(tick, &"lane_cover_started", index, next_cover, {"home_lane": actor["home_lane"]})
    elif next_cover < 0 and previous_cover >= 0:
        actor["covering_lane"] = -1
        log.add(tick, &"lane_cover_ended", index, previous_cover, {"home_lane": actor["home_lane"]})
    var target_index := _best_enemy_for_soldier(index, lane)
    var aim := Vector2(HIVE_POS.x, LANE_Y[lane])
    var desired := Vector2(430.0 + float(phase - 1) * 70.0, LANE_Y[lane])
    if hive_vulnerable and _lane_enemy_count(lane) <= 2:
        desired.x = 1060.0
        aim = HIVE_POS
    if target_index >= 0:
        var enemy: Dictionary = enemies[target_index]
        aim = Vector2(enemy["pos"])
        var d := Vector2(actor["pos"]).distance_to(aim)
        if d < 120.0:
            desired.x = maxf(250.0, Vector2(actor["pos"]).x - 90.0)
        elif d > 430.0:
            desired.x = minf(1120.0, Vector2(enemy["pos"]).x - 280.0)
    var move := Vector2(actor["pos"]).direction_to(desired)
    if Vector2(actor["pos"]).distance_to(desired) < 14.0:
        move = Vector2.ZERO
    var ability := target_index >= 0 and _count_enemies_near(aim, 125.0) >= 4 and int(actor["ability_cd"]) == 0
    if rng.next_float() < float(actor["error_rate"]) * 0.08:
        move.x *= -1.0
    return {
        "move": move,
        "aim": aim,
        "primary": int(actor["ammo"]) > 0,
        "ability": ability,
        "request_ammo": int(actor["ammo"]) <= 14,
        "request_med": float(actor["hp"]) <= float(actor["hp_max"]) * 0.35,
        "request_barrier": _lane_enemy_count(lane) >= 9
    }

func _cover_lane_for_soldier(index: int) -> int:
    var home_lane := int(actors[index]["home_lane"])
    var best_lane := home_lane
    var best_distance := 99
    for soldier_index in range(3):
        if soldier_index == index or bool(actors[soldier_index]["alive"]):
            continue
        var down_lane := int(actors[soldier_index]["home_lane"])
        var lane_distance := absi(home_lane - down_lane)
        if lane_distance == 1 and lane_distance < best_distance:
            best_distance = lane_distance
            best_lane = down_lane
    return best_lane

func _cpu_supplier_command(index: int) -> Dictionary:
    var actor: Dictionary = actors[index]
    var request_index := _best_request_for_supplier(index)
    var dispatch := false
    var target_actor := -1
    var kind: StringName = &"ammo"
    if request_index >= 0:
        var request: Dictionary = requests[request_index]
        kind = StringName(request["kind"])
        target_actor = int(request["actor"])
        dispatch = _supplier_has_stock(actor, kind)
    var lane := int(actor["lane"])
    var desired := Vector2(175.0, LANE_Y[lane])
    if _lane_enemy_count(lane) >= 2:
        desired.x = 110.0
    return {
        "move": Vector2(actor["pos"]).direction_to(desired) if Vector2(actor["pos"]).distance_to(desired) > 10.0 else Vector2.ZERO,
        "aim": Vector2(actors[target_actor]["pos"]) if target_actor >= 0 else Vector2(600.0, LANE_Y[lane]),
        "primary": dispatch,
        "supply_kind": kind,
        "target_actor": target_actor,
        "ability": false
    }

func _best_enemy_for_soldier(index: int, preferred_lane: int = -1) -> int:
    var actor: Dictionary = actors[index]
    var scoring_lane := int(actor["lane"]) if preferred_lane < 0 else preferred_lane
    var best := -1
    var best_score := -INF
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if not bool(enemy["alive"]):
            continue
        var lane_match := 1.0 if int(enemy["lane"]) == scoring_lane else -2.0
        var dist := Vector2(actor["pos"]).distance_to(Vector2(enemy["pos"]))
        var base_urgency := 1.0 - clampf((Vector2(enemy["pos"]).x - 100.0) / 1460.0, 0.0, 1.0)
        var score := lane_match * 4.0 + base_urgency * 5.0 - dist / 500.0 + (2.5 if bool(enemy["elite"]) else 0.0)
        if score > best_score:
            best_score = score
            best = i
    return best

func _best_request_for_supplier(index: int) -> int:
    var supplier: Dictionary = actors[index]
    var best := -1
    var best_score := -INF
    for i in range(requests.size()):
        var request: Dictionary = requests[i]
        if bool(request["fulfilled"]):
            continue
        var target := int(request["actor"])
        if target < 0 or target >= actors.size():
            continue
        var kind := StringName(request["kind"])
        if not bool(actors[target]["alive"]) and kind != &"med":
            continue
        if not _supplier_has_stock(supplier, kind):
            continue
        var lane_match := 1.0 if int(actors[target]["lane"]) == int(supplier["lane"]) else 0.0
        var age := clampf(float(tick - int(request["created_tick"])) / 600.0, 0.0, 1.0)
        var route_risk := float(_lane_enemy_count(int(actors[target]["lane"]))) * 0.12
        var score := float(request["urgency"]) * 6.0 + age * 2.0 + lane_match - route_risk * (1.0 - float(supplier["risk"]))
        if score > best_score:
            best_score = score
            best = i
    return best

func _supplier_has_stock(supplier: Dictionary, kind: StringName) -> bool:
    if kind == &"ammo":
        return int(supplier["stock_ammo"]) > 0
    if kind == &"med":
        return int(supplier["stock_med"]) > 0
    return int(supplier["stock_barrier"]) > 0

func _apply_actor_command(index: int, command: Dictionary) -> void:
    var actor: Dictionary = actors[index]
    var move: Vector2 = command.get("move", Vector2.ZERO)
    if move.length_squared() > 1.0:
        move = move.normalized()
    var target_velocity := move * float(actor["speed"])
    var rate := ACTOR_ACCEL if move.length_squared() > 0.01 else ACTOR_BRAKE
    actor["vel"] = Vector2(actor["vel"]).move_toward(target_velocity, rate * DT)
    var pos := Vector2(actor["pos"]) + Vector2(actor["vel"]) * DT
    pos.x = clampf(pos.x, 55.0, 1515.0)
    pos.y = clampf(pos.y, 145.0, 755.0)
    actor["pos"] = pos
    actor["lane"] = _closest_lane(pos.y)
    actor["aim"] = command.get("aim", Vector2(pos.x + 100.0, pos.y))
    if StringName(actor["role"]) == &"soldier":
        _apply_soldier_actions(index, command)
    else:
        _apply_supplier_actions(index, command)

func _apply_soldier_actions(index: int, command: Dictionary) -> void:
    var actor: Dictionary = actors[index]
    if bool(command.get("request_ammo", false)):
        _create_request(index, &"ammo", 1.0, true)
    if bool(command.get("request_med", false)):
        _create_request(index, &"med", 1.0, true)
    if bool(command.get("request_barrier", false)):
        _create_request(index, &"barrier", 1.0, true)
    if bool(command.get("primary", false)) and int(actor["attack_cd"]) == 0 and int(actor["ammo"]) > 0:
        _soldier_fire(index, Vector2(command.get("aim", actor["aim"])))
    if bool(command.get("ability", false)) and int(actor["ability_cd"]) == 0:
        _soldier_grenade(index, Vector2(command.get("aim", actor["aim"])))

func _human_damage_scale(index: int) -> float:
    if index == human_slot or (party_mode and index == 3):
        return 1.0
    return 0.65

func _soldier_fire(index: int, aim: Vector2) -> void:
    var actor: Dictionary = actors[index]
    var origin := Vector2(actor["pos"])
    var direction := origin.direction_to(aim)
    if direction == Vector2.ZERO:
        direction = Vector2.RIGHT
    projectiles.append({
        "id": next_projectile_id,
        "owner": index,
        "pos": origin + direction * 24.0,
        "vel": direction * 760.0,
        "damage": (36.0 if int(actor["overcharge"]) > 0 else 24.0) * _human_damage_scale(index) * (0.90 + team_morale * 0.002),
        "life": 70,
        "radius": 6.0,
        "kind": &"bullet"
    })
    next_projectile_id += 1
    actor["ammo"] = maxi(0, int(actor["ammo"]) - (2 if int(actor["overcharge"]) > 0 else 1))
    actor["attack_cd"] = 7 if int(actor["overcharge"]) > 0 else 10
    actor["recoil"] = 5
    log.add(tick, &"soldier_fired", index, -1, {})

func _soldier_grenade(index: int, aim: Vector2) -> void:
    var actor: Dictionary = actors[index]
    var center := aim
    if Vector2(actor["pos"]).distance_to(center) > 430.0:
        center = Vector2(actor["pos"]) + Vector2(actor["pos"]).direction_to(center) * 430.0
    var hits := 0
    for i in range(enemies.size()):
        if bool(enemies[i]["alive"]) and Vector2(enemies[i]["pos"]).distance_to(center) <= 125.0:
            _request_damage(index, &"enemy", i, 82.0 * _human_damage_scale(index), &"grenade")
            hits += 1
    actor["ability_cd"] = 480
    log.add(tick, &"grenade_cast", index, -1, {"center": center, "hits": hits})
    if hits >= 4:
        _say("P%d 수류탄 %d명 적중" % [index + 1, hits], 90)

func _apply_supplier_actions(index: int, command: Dictionary) -> void:
    var actor: Dictionary = actors[index]
    if bool(command.get("cycle_supply", false)):
        var order := [&"ammo", &"med", &"barrier"]
        var current := order.find(StringName(actor["selected_supply"]))
        actor["selected_supply"] = order[(current + 1) % order.size()]
        _say("P%d 선택: %s" % [index + 1, String(actor["selected_supply"])], 80)
    if not bool(command.get("primary", false)) or int(actor["attack_cd"]) > 0:
        return
    var kind := StringName(command.get("supply_kind", actor["selected_supply"]))
    var target_actor := int(command.get("target_actor", -1))
    if target_actor < 0:
        target_actor = _nearest_soldier_to(Vector2(command.get("aim", actor["aim"])))
    if target_actor < 0:
        return
    _dispatch_supply(index, target_actor, kind, bool(command.get("overcharge", false)))

func _dispatch_supply(supplier_index: int, target_actor: int, kind: StringName, risky: bool = false) -> void:
    var supplier: Dictionary = actors[supplier_index]
    if StringName(supplier["role"]) != &"supplier" or not _supplier_has_stock(supplier, kind) or int(supplier["jam_ticks"]) > 0:
        return
    if target_actor < 0 or target_actor >= 3:
        return
    if not bool(actors[target_actor]["alive"]) and kind != &"med":
        return
    var matching_request := -1
    for i in range(requests.size()):
        var request: Dictionary = requests[i]
        if not bool(request["fulfilled"]) and int(request["actor"]) == target_actor and StringName(request["kind"]) == kind:
            matching_request = i
            break
    if kind == &"ammo":
        supplier["stock_ammo"] = int(supplier["stock_ammo"]) - 1
    elif kind == &"med":
        supplier["stock_med"] = int(supplier["stock_med"]) - 1
    else:
        supplier["stock_barrier"] = int(supplier["stock_barrier"]) - 1
    var target_lane := int(actors[target_actor]["lane"])
    var rescue_delivery := kind == &"med" and not bool(actors[target_actor]["alive"])
    packages.append({
        "id": next_package_id,
        "supplier": supplier_index,
        "target": target_actor,
        "kind": kind,
        "pos": Vector2(supplier["pos"]),
        "lane": target_lane,
        "hp": 26.0 if rescue_delivery else (38.0 if kind != &"barrier" else 58.0),
        "hp_max": 26.0 if rescue_delivery else (38.0 if kind != &"barrier" else 58.0),
        "speed": (215.0 if risky else 125.0) if rescue_delivery else (385.0 if risky else 285.0),
        "alive": true,
        "overcharged": risky,
        "rescue_delivery": rescue_delivery,
        "request_index": matching_request,
        "bonked": [],
        "created_tick": tick
    })
    if matching_request >= 0:
        requests[matching_request]["assigned_supplier"] = supplier_index
        requests[matching_request]["fulfilled"] = true
    supplier["attack_cd"] = 24
    if risky:
        packages[packages.size() - 1]["hp"] = float(packages[packages.size() - 1]["hp"]) * 0.55
        packages[packages.size() - 1]["hp_max"] = packages[packages.size() - 1]["hp"]
        supplier["risky_deliveries"] = int(supplier["risky_deliveries"]) + 1
        supplier["supply_heat"] = int(supplier["supply_heat"]) + 1
    if matching_request < 0:
        supplier["waste_deliveries"] = int(supplier["waste_deliveries"]) + 1
        supplier["supply_heat"] = int(supplier["supply_heat"]) + 1
        team_morale = maxf(0.0, team_morale - 3.0)
    if int(supplier["supply_heat"]) >= 3:
        supplier["supply_heat"] = 0
        supplier["jam_ticks"] = 240
        _say("P%d SUPPLY LINE OVERHEATED!" % (supplier_index + 1), 120)
    log.add(tick, &"delivery_dispatched", supplier_index, target_actor, {"kind": kind, "lane": target_lane, "overcharged": risky})
    next_package_id += 1

func _nearest_soldier_to(pos: Vector2) -> int:
    var best := -1
    var best_d2 := INF
    for i in range(3):
        if not bool(actors[i]["alive"]):
            continue
        var d2 := pos.distance_squared_to(Vector2(actors[i]["pos"]))
        if d2 < best_d2:
            best_d2 = d2
            best = i
    return best

func _update_projectiles() -> void:
    for p in projectiles:
        p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * DT
        p["life"] = int(p["life"]) - 1
        if int(p["life"]) <= 0:
            continue
        var hit := false
        for package in packages:
            if not bool(package["alive"]):
                continue
            if Vector2(p["pos"]).distance_to(Vector2(package["pos"])) <= float(p["radius"]) + 15.0:
                package["alive"] = false
                p["life"] = 0
                deliveries_destroyed += 1
                manual_detonations += 1
                _package_pop(package, true, int(p["owner"]))
                log.add(tick, &"package_manual_detonation", int(p["owner"]), int(package["id"]), {"overcharged": package["overcharged"]})
                hit = true
                break
        if hit:
            continue
        for i in range(enemies.size()):
            if not bool(enemies[i]["alive"]):
                continue
            if Vector2(p["pos"]).distance_squared_to(Vector2(enemies[i]["pos"])) <= pow(float(p["radius"]) + ENEMY_RADIUS, 2.0):
                _request_damage(int(p["owner"]), &"enemy", i, float(p["damage"]), StringName(p["kind"]))
                p["life"] = 0
                hit = true
                break
        if hit:
            continue
        if hive_vulnerable and Vector2(p["pos"]).distance_to(HIVE_POS) <= 76.0:
            _request_damage(int(p["owner"]), &"hive", -1, float(p["damage"]), &"hive_shot")
            p["life"] = 0

func _update_packages() -> void:
    for package in packages:
        if not bool(package["alive"]):
            continue
        var target_index := int(package["target"])
        if target_index < 0 or target_index >= actors.size():
            package["alive"] = false
            continue
        if not bool(actors[target_index]["alive"]) and StringName(package["kind"]) != &"med":
            package["alive"] = false
            continue
        var pos := Vector2(package["pos"])
        var target := Vector2(actors[target_index]["pos"])
        pos += pos.direction_to(target) * float(package["speed"]) * DT
        package["pos"] = pos
        var bonked: Array = package["bonked"]
        for enemy_index in range(enemies.size()):
            var enemy: Dictionary = enemies[enemy_index]
            if not bool(enemy["alive"]) or bonked.has(int(enemy["id"])):
                continue
            if Vector2(enemy["pos"]).distance_to(pos) <= 25.0:
                bonked.append(int(enemy["id"]))
                enemy["hp"] = float(enemy["hp"]) - 30.0
                enemy["pos"] = Vector2(enemy["pos"]) + pos.direction_to(target) * 54.0
                if float(enemy["hp"]) <= 0.0:
                    enemy["alive"] = false
                    var supplier_index := int(package["supplier"])
                    actors[supplier_index]["kills"] = int(actors[supplier_index]["kills"]) + 1
                enemies[enemy_index] = enemy
                impact_ticks = maxi(impact_ticks, 7)
                log.add(tick, &"package_bonk", int(package["supplier"]), int(enemy["id"]), {"kind": package["kind"]})
        package["bonked"] = bonked
        var attackers := 0
        for enemy in enemies:
            if bool(enemy["alive"]) and int(enemy["lane"]) == int(package["lane"]) and Vector2(enemy["pos"]).distance_to(pos) <= 48.0:
                attackers += 1
        if attackers > 0:
            package["hp"] = float(package["hp"]) - float(attackers) * 0.85
        if float(package["hp"]) <= 0.0:
            package["alive"] = false
            deliveries_destroyed += 1
            _package_pop(package)
            log.add(tick, &"delivery_destroyed", -1, int(package["id"]), {"kind": package["kind"], "lane": package["lane"]})
            _say("%s 보급 파괴 — P%d 지원 실패" % [String(package["kind"]), target_index + 1], 100)
            continue
        if pos.distance_to(target) <= 24.0:
            _complete_delivery(package)

func _package_pop(package: Dictionary, manual: bool = false, trigger_actor: int = -1) -> void:
    var hits := 0
    var center := Vector2(package["pos"])
    var blast_damage := 82.0 if bool(package.get("overcharged", false)) else 42.0
    for enemy_index in range(enemies.size()):
        var enemy: Dictionary = enemies[enemy_index]
        if bool(enemy["alive"]) and Vector2(enemy["pos"]).distance_to(center) <= 105.0:
            enemy["hp"] = float(enemy["hp"]) - blast_damage
            if float(enemy["hp"]) <= 0.0:
                enemy["alive"] = false
            enemies[enemy_index] = enemy
            hits += 1
    var ally_hits := 0
    var supplier_index := int(package["supplier"])
    var special_manual_result := false
    if bool(package.get("overcharged", false)):
        for actor_index in range(actors.size()):
            if bool(actors[actor_index]["alive"]) and Vector2(actors[actor_index]["pos"]).distance_to(center) <= 92.0:
                _request_damage(int(package["supplier"]), &"actor", actor_index, 52.0, &"supply_blast")
                ally_hits += 1
        friendly_blasts += ally_hits
        actors[supplier_index]["jam_ticks"] = maxi(int(actors[supplier_index]["jam_ticks"]), 180)
        team_morale = maxf(0.0, team_morale - float(ally_hits) * 5.0)
    if manual and hits >= 3 and ally_hits == 0:
        special_manual_result = true
        clutch_detonations += 1
        team_morale = minf(100.0, team_morale + 7.0)
        actors[supplier_index]["jam_ticks"] = maxi(0, int(actors[supplier_index]["jam_ticks"]) - 120)
        actors[supplier_index]["supply_heat"] = maxi(0, int(actors[supplier_index]["supply_heat"]) - 1)
        if trigger_actor >= 0:
            actors[trigger_actor]["hit_combo"] = int(actors[trigger_actor]["hit_combo"]) + hits
            actors[trigger_actor]["combo_timer"] = 120
        _say("CLUTCH DETONATION! %d ENEMIES - BOTH PLAYERS CASH IN!" % hits, 120)
        log.add(tick, &"clutch_detonation", trigger_actor, supplier_index, {"hits":hits})
    elif manual and (hits == 0 or ally_hits > 0):
        special_manual_result = true
        botched_detonations += 1
        team_morale = maxf(0.0, team_morale - 6.0)
        actors[supplier_index]["supply_heat"] = int(actors[supplier_index]["supply_heat"]) + 1
        if int(actors[supplier_index]["supply_heat"]) >= 3:
            actors[supplier_index]["supply_heat"] = 0
            actors[supplier_index]["jam_ticks"] = maxi(int(actors[supplier_index]["jam_ticks"]), 240)
        if trigger_actor >= 0:
            actors[trigger_actor]["hit_combo"] = 0
        _say("BOTCHED DETONATION! THE TEAM PAYS FOR IT!", 120)
        log.add(tick, &"botched_detonation", trigger_actor, supplier_index, {"hits":hits, "ally_hits":ally_hits})
    impact_ticks = 15
    if not special_manual_result:
        _say("%s DELIVERY BLAST: %d ENEMIES / %d ALLIES!" % ["MANUAL" if manual else "FAILED", hits, ally_hits], 100)
    log.add(tick, &"package_pop", int(package["supplier"]), -1, {"hits": hits, "ally_hits": ally_hits, "manual": manual})

func _complete_delivery(package: Dictionary) -> void:
    var target_index := int(package["target"])
    var actor: Dictionary = actors[target_index]
    var kind := StringName(package["kind"])
    var potency := 1.6 if bool(package.get("overcharged", false)) else 1.0
    var revived := false
    if kind == &"ammo":
        actor["ammo"] = mini(int(actor["ammo_max"]), int(actor["ammo"]) + int(48.0 * potency))
    elif kind == &"med":
        if not bool(actor["alive"]) and StringName(actor["role"]) == &"soldier":
            actor["alive"] = true
            actor["hp"] = float(actor["hp_max"]) * minf(0.52, 0.30 + 0.08 * potency)
            actor["ammo"] = mini(int(actor["ammo"]), 12)
            actor["respawn_tick"] = -1
            actor["attack_cd"] = 120
            actor["shield"] = 0.0
            revived = true
        else:
            actor["hp"] = minf(float(actor["hp_max"]), float(actor["hp"]) + 125.0 * potency)
    else:
        barriers.append({
            "id": next_barrier_id,
            "owner": target_index,
            "pos": Vector2(actor["pos"]) + Vector2(90.0, 0.0),
            "lane": int(actor["lane"]),
            "hp": 240.0 * potency,
            "hp_max": 240.0 * potency,
            "life": 720
        })
        next_barrier_id += 1
        actor["shield"] = maxf(float(actor["shield"]), 80.0 * potency)
    if int(package["request_index"]) < 0:
        actor["overcharge"] = 300
        impact_ticks = 10
        _say("UNREQUESTED %s! P%d OVERCHARGED!" % [String(kind).to_upper(), target_index + 1], 110)
        log.add(tick, &"delivery_overcharge", int(package["supplier"]), target_index, {"kind": kind})
    package["alive"] = false
    deliveries_completed += 1
    var supplier := int(package["supplier"])
    if supplier >= 0 and supplier < actors.size():
        actors[supplier]["deliveries"] = int(actors[supplier]["deliveries"]) + 1
        if revived:
            actors[supplier]["revives"] = int(actors[supplier]["revives"]) + 1
            support_revives += 1
            team_morale = minf(100.0, team_morale + 5.0)
            impact_ticks = maxi(impact_ticks, 18)
            _say("P%d FIELD REVIVES P%d — LANE RESTORED!" % [supplier + 1, target_index + 1], 150)
            log.add(tick, &"field_revive", supplier, target_index, {"kind": kind, "overcharged": package.get("overcharged", false)})
        if int(package["request_index"]) >= 0:
            actors[supplier]["timely_deliveries"] = int(actors[supplier]["timely_deliveries"]) + 1
            team_morale = minf(100.0, team_morale + 4.0)
    log.add(tick, &"delivery_completed", supplier, target_index, {"kind": kind, "travel_ticks": tick - int(package["created_tick"])})

func _update_barriers() -> void:
    for barrier in barriers:
        barrier["life"] = int(barrier["life"]) - 1

func _update_enemies() -> void:
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if not bool(enemy["alive"]):
            continue
        enemy["attack_cd"] = maxi(0, int(enemy["attack_cd"]) - 1)
        enemy["breach_cd"] = maxi(0, int(enemy["breach_cd"]) - 1)
        var pos := Vector2(enemy["pos"])
        var barrier_index := _nearest_barrier_in_lane(int(enemy["lane"]), pos, 62.0)
        var actor_index := _nearest_actor_in_lane(int(enemy["lane"]), pos, 82.0)
        if barrier_index >= 0:
            if int(enemy["attack_cd"]) == 0:
                barriers[barrier_index]["hp"] = float(barriers[barrier_index]["hp"]) - float(enemy["damage"])
                enemy["attack_cd"] = 36
            pos.x += float(enemy["speed"]) * 0.04 * DT
        elif actor_index >= 0:
            if int(enemy["attack_cd"]) == 0:
                _request_damage(int(enemy["id"]), &"actor", actor_index, float(enemy["damage"]), &"enemy_attack")
                enemy["attack_cd"] = 38
        else:
            pos.x -= float(enemy["speed"]) * DT
        enemy["pos"] = pos
        if pos.x <= BASE_POS.x + 360.0 and int(enemy["breach_cd"]) == 0:
            var morale_guard := clampf(1.15 - team_morale * 0.006, 0.55, 1.15)
            # Reaching the inner perimeter must be a team crisis, not a nearly
            # free warning ping. The long supply chain has already failed by
            # this point, so even a few breaches leave a visible scar.
            var breach_damage := float(enemy["damage"]) * (5.0 if bool(enemy["elite"]) else 4.0) * morale_guard
            base_hp = maxf(0.0, base_hp - breach_damage)
            enemy["breach_cd"] = 90
            base_breaches += 1
            impact_ticks = maxi(impact_ticks, 6)
            log.add(tick, &"base_pressure", int(enemy["id"]), -1, {"damage": breach_damage, "lane": int(enemy["lane"])})
        if pos.x <= BASE_POS.x + 72.0 and int(enemy["attack_cd"]) == 0:
            base_hp = maxf(0.0, base_hp - float(enemy["damage"]) * 1.35)
            enemy["attack_cd"] = 34
            base_breaches += 1
            log.add(tick, &"base_hit", int(enemy["id"]), -1, {"damage": float(enemy["damage"]), "lane": int(enemy["lane"])})

func _nearest_barrier_in_lane(lane: int, pos: Vector2, radius: float) -> int:
    var best := -1
    var best_d2 := radius * radius
    for i in range(barriers.size()):
        var barrier: Dictionary = barriers[i]
        if int(barrier["life"]) <= 0 or float(barrier["hp"]) <= 0.0 or int(barrier["lane"]) != lane:
            continue
        var d2 := pos.distance_squared_to(Vector2(barrier["pos"]))
        if d2 < best_d2:
            best_d2 = d2
            best = i
    return best

func _nearest_actor_in_lane(lane: int, pos: Vector2, radius: float) -> int:
    var best := -1
    var best_d2 := radius * radius
    for i in range(actors.size()):
        var actor: Dictionary = actors[i]
        if not bool(actor["alive"]) or int(actor["lane"]) != lane:
            continue
        var d2 := pos.distance_squared_to(Vector2(actor["pos"]))
        if d2 < best_d2:
            best_d2 = d2
            best = i
    return best

func _request_damage(actor: int, target_kind: StringName, target: int, amount: float, kind: StringName) -> void:
    request_seq += 1
    damage_requests.append({
        "seq": request_seq,
        "actor": actor,
        "target_kind": target_kind,
        "target": target,
        "amount": amount,
        "kind": kind
    })

func _resolve_damage() -> void:
    damage_requests.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if String(a["target_kind"]) == String(b["target_kind"]):
            if int(a["target"]) == int(b["target"]):
                return int(a["seq"]) < int(b["seq"])
            return int(a["target"]) < int(b["target"])
        return String(a["target_kind"]) < String(b["target_kind"])
    )
    for req in damage_requests:
        var kind := StringName(req["target_kind"])
        if kind == &"enemy":
            var idx := int(req["target"])
            if idx < 0 or idx >= enemies.size() or not bool(enemies[idx]["alive"]):
                continue
            var enemy: Dictionary = enemies[idx]
            enemy["hp"] = float(enemy["hp"]) - float(req["amount"])
            var attacker := int(req["actor"])
            if attacker >= 0 and attacker < actors.size():
                actors[attacker]["hit_combo"] = int(actors[attacker]["hit_combo"]) + 1
                actors[attacker]["combo_timer"] = 90
                actors[attacker]["recoil"] = maxi(int(actors[attacker]["recoil"]), 3)
            impact_ticks = maxi(impact_ticks, 4)
            var hits: Array = enemy["last_hits"]
            hits.append({"actor": int(req["actor"]), "tick": tick, "amount": float(req["amount"])})
            while hits.size() > 10:
                hits.pop_front()
            if float(enemy["hp"]) <= 0.0:
                _kill_enemy(idx, int(req["actor"]))
        elif kind == &"actor":
            var actor_idx := int(req["target"])
            if actor_idx < 0 or actor_idx >= actors.size() or not bool(actors[actor_idx]["alive"]):
                continue
            var target_actor: Dictionary = actors[actor_idx]
            var remaining := float(req["amount"])
            if float(target_actor["shield"]) > 0.0:
                var absorbed := minf(float(target_actor["shield"]), remaining)
                target_actor["shield"] = float(target_actor["shield"]) - absorbed
                remaining -= absorbed
            target_actor["hp"] = float(target_actor["hp"]) - remaining
            target_actor["last_damage_tick"] = tick
            if float(target_actor["hp"]) <= 0.0:
                _down_actor(actor_idx)
        elif kind == &"hive" and hive_vulnerable:
            hive_hp = maxf(0.0, hive_hp - float(req["amount"]))
            log.add(tick, &"hive_hit", int(req["actor"]), -1, {"damage": float(req["amount"])})
    damage_requests.clear()

func _kill_enemy(index: int, killer: int) -> void:
    var enemy: Dictionary = enemies[index]
    if not bool(enemy["alive"]):
        return
    enemy["alive"] = false
    if killer >= 0 and killer < actors.size():
        actors[killer]["kills"] = int(actors[killer]["kills"]) + 1
    log.add(tick, &"enemy_killed", killer, int(enemy["id"]), {"lane": int(enemy["lane"]), "elite": bool(enemy["elite"])})

func _down_actor(index: int) -> void:
    var actor: Dictionary = actors[index]
    actor["alive"] = false
    actor["hp"] = 0.0
    actor["respawn_tick"] = tick + (600 if StringName(actor["role"]) == &"soldier" else 480)
    if StringName(actor["role"]) == &"soldier":
        _create_request(index, &"med", 1.4, true)
    log.add(tick, &"actor_down", -1, index, {"role": actor["role"], "lane": actor["lane"]})
    _say("P%d 쓰러짐 — %s 공백" % [index + 1, String(actor["role"])], 100)

func _try_respawn_actor(index: int) -> void:
    var actor: Dictionary = actors[index]
    if tick < int(actor["respawn_tick"]):
        return
    actor["alive"] = true
    actor["hp"] = float(actor["hp_max"]) * 0.75
    actor["pos"] = Vector2(280.0 if StringName(actor["role"]) == &"soldier" else 145.0, LANE_Y[int(actor["lane"])])
    actor["ammo"] = 42 if StringName(actor["role"]) == &"soldier" else 0
    actor["attack_cd"] = 60
    log.add(tick, &"actor_respawned", index, -1, {})

func _cleanup() -> void:
    projectiles = projectiles.filter(func(p: Dictionary) -> bool:
        var pos := Vector2(p["pos"])
        return int(p["life"]) > 0 and pos.x > -60.0 and pos.x < 1660.0 and pos.y > 80.0 and pos.y < 820.0
    )
    packages = packages.filter(func(p: Dictionary) -> bool: return bool(p["alive"]))
    barriers = barriers.filter(func(b: Dictionary) -> bool: return int(b["life"]) > 0 and float(b["hp"]) > 0.0)
    if enemies.size() > 500:
        enemies = enemies.filter(func(e: Dictionary) -> bool: return bool(e["alive"]))
    if requests.size() > 120:
        requests = requests.filter(func(r: Dictionary) -> bool: return not bool(r["fulfilled"]) and tick - int(r["created_tick"]) < 1800)

func _update_phase_state() -> void:
    if phase_spawned < phase_target:
        return
    var alive_count := 0
    for enemy in enemies:
        if bool(enemy["alive"]):
            alive_count += 1
    if phase < MAX_PHASES:
        if alive_count == 0 and phase_tick >= 300:
            _start_phase(phase + 1)
    elif hive_hp <= 0.0:
        result = &"victory"
        log.add(tick, &"hive_destroyed", -1, -1, {"base_hp": base_hp, "deliveries": deliveries_completed})
        _say("HIVE 파괴 — 지원 작전 성공!", 100000)

func _check_result() -> void:
    if base_hp <= 0.0 and result == &"playing":
        result = &"defeat"
        log.add(tick, &"base_destroyed", -1, -1, {"phase": phase})
        _say("기지 파괴 — R로 재시작", 100000)

func _lane_enemy_count(lane: int) -> int:
    var count := 0
    for enemy in enemies:
        if bool(enemy["alive"]) and int(enemy["lane"]) == lane:
            count += 1
    return count

func _count_enemies_near(pos: Vector2, radius: float) -> int:
    var count := 0
    for enemy in enemies:
        if bool(enemy["alive"]) and Vector2(enemy["pos"]).distance_to(pos) <= radius:
            count += 1
    return count

func _closest_lane(y: float) -> int:
    var best := 0
    var best_distance := INF
    for i in range(3):
        var d := absf(y - LANE_Y[i])
        if d < best_distance:
            best_distance = d
            best = i
    return best

func camera_target() -> Vector2:
    if actors.is_empty():
        return Vector2(800.0, 450.0)
    var human := Vector2(actors[human_slot]["pos"])
    return Vector2(800.0, 450.0).lerp(human, 0.28)

func summary() -> Dictionary:
    var alive_enemies := 0
    for enemy in enemies:
        if bool(enemy["alive"]):
            alive_enemies += 1
    return {
        "tick": tick,
        "result": String(result),
        "phase": phase,
        "base_hp": snappedf(base_hp, 0.01),
        "hive_hp": snappedf(hive_hp, 0.01),
        "alive_enemies": alive_enemies,
        "deliveries_completed": deliveries_completed,
        "deliveries_destroyed": deliveries_destroyed,
        "base_breaches": base_breaches,
        "start_countdown": float(start_countdown_ticks) / 60.0,
        "party_ready": party_ready,
        "party_mode": party_mode,
        "team_morale": snappedf(team_morale, 0.1),
        "manual_detonations": manual_detonations,
        "friendly_blasts": friendly_blasts,
        "clutch_detonations": clutch_detonations,
        "botched_detonations": botched_detonations,
        "support_revives": support_revives,
        "lane_covers": lane_covers,
        "p1_combo": int(actors[0]["hit_combo"]),
        "p2_heat": int(actors[3]["supply_heat"]),
        "p2_jam": int(actors[3]["jam_ticks"]),
        "events": log.events.size()
    }

func has_invalid_numbers() -> bool:
    if not is_finite(base_hp) or not is_finite(hive_hp):
        return true
    for actor in actors:
        var p := Vector2(actor["pos"])
        if not is_finite(p.x) or not is_finite(p.y) or not is_finite(float(actor["hp"])):
            return true
    for enemy in enemies:
        var p := Vector2(enemy["pos"])
        if not is_finite(p.x) or not is_finite(p.y) or not is_finite(float(enemy["hp"])):
            return true
    return false

func _assert_finite() -> void:
    if has_invalid_numbers():
        result = &"invalid"
        push_error("SupportWorld invalid number at tick %d" % tick)
