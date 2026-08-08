extends RefCounted

const SeededRng = preload("res://scripts/sim/seeded_rng.gd")
const EventLog = preload("res://scripts/sim/event_log.gd")

const TICK_RATE := 60
const DT := 1.0 / 60.0
const WORLD_SIZE := Vector2(1600.0, 900.0)
const CENTER := Vector2(800.0, 450.0)
const HERO_RADIUS := 18.0
const ENEMY_RADIUS := 14.0
const VILLAGE_RADIUS := 92.0
const MAX_WAVES := 12
const START_COUNTDOWN_TICKS := 180
const HERO_ACCEL := 1850.0
const HERO_BRAKE := 2500.0
const GATE_DISTANCE := 185.0
const GATE_HP_MAX := 160.0

var world_size: Vector2 = WORLD_SIZE
var center: Vector2 = CENTER
var village_radius: float = VILLAGE_RADIUS
var hero_radius: float = HERO_RADIUS
var enemy_radius: float = ENEMY_RADIUS
var max_waves: int = MAX_WAVES

var tick: int = 0
var seed: int
var rng
var log
var result: StringName = &"playing"
var heroes: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var stasis_zones: Array[Dictionary] = []
var damage_requests: Array[Dictionary] = []
var village_hp: float = 900.0
var village_hp_max: float = 900.0
var wave_index: int = 0
var wave_tick: int = 0
var wave_spawned: int = 0
var wave_target: int = 0
var next_enemy_id: int = 1000
var next_projectile_id: int = 100000
var next_zone_id: int = 200000
var request_seq: int = 0
var lane_pressure: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var match_start_tick: int = 0
var recent_message: String = ""
var recent_message_until: int = 0
var panic_cd: int = 0
var impact_ticks: int = 0
var start_countdown_ticks: int = START_COUNTDOWN_TICKS
var party_ready: bool = false
var party_mode: bool = false
var bell_tokens: int = 1
var role_synergies: int = 0
var stasis_breakouts: int = 0
var combat_revives: int = 0
var gate_hp: Array[float] = []
var gate_fortify_ticks: Array[int] = []
var gate_collapses: int = 0
var gate_repairs: int = 0

var lane_spawns: Array[Vector2] = [
    Vector2(800.0, 36.0),
    Vector2(1564.0, 450.0),
    Vector2(800.0, 864.0),
    Vector2(36.0, 450.0)
]

func _init(match_seed: int = 12345) -> void:
    seed = match_seed
    rng = SeededRng.new(seed)
    log = EventLog.new()
    reset()

func reset() -> void:
    tick = 0
    result = &"playing"
    heroes.clear()
    enemies.clear()
    projectiles.clear()
    stasis_zones.clear()
    damage_requests.clear()
    village_hp = village_hp_max
    wave_index = 0
    wave_tick = 0
    wave_spawned = 0
    wave_target = 0
    next_enemy_id = 1000
    next_projectile_id = 100000
    next_zone_id = 200000
    request_seq = 0
    recent_message = ""
    recent_message_until = 0
    panic_cd = 0
    impact_ticks = 0
    start_countdown_ticks = START_COUNTDOWN_TICKS
    party_ready = false
    party_mode = false
    bell_tokens = 1
    role_synergies = 0
    stasis_breakouts = 0
    combat_revives = 0
    gate_hp = [GATE_HP_MAX, GATE_HP_MAX, GATE_HP_MAX, GATE_HP_MAX]
    gate_fortify_ticks = [0, 0, 0, 0]
    gate_collapses = 0
    gate_repairs = 0
    log.clear()
    for slot in range(6):
        var angle := -PI * 0.5 + TAU * float(slot) / 6.0
        var profile := _cpu_profile(slot)
        var role: StringName = StringName([&"hunter", &"mage", &"guardian", &"priest", &"engineer", &"lancer"][slot])
        var role_stats: Dictionary = _role_stats(role)
        heroes.append({
            "id": slot,
            "slot": slot,
            "human": slot < 2,
            "role": role,
            "pos": CENTER + Vector2.from_angle(angle) * 150.0,
            "vel": Vector2.ZERO,
            "aim": CENTER + Vector2.from_angle(angle) * 300.0,
            "hp": role_stats["hp"],
            "hp_max": role_stats["hp"],
            "alive": true,
            "respawn_tick": -1,
            "move_speed": role_stats["speed"],
            "attack_damage": role_stats["damage"],
            "attack_range": role_stats["range"],
            "attack_cd": 0,
            "skill_cd": 0,
            "stasis_cd": 0,
            "kills": 0,
            "assists": 0,
            "coins": 0,
            "level": 0,
            "lane": slot % 4,
            "desired_lane": slot % 4,
            "decision_tick": 0,
            "greed": profile["greed"],
            "bravery": profile["bravery"],
            "reaction": profile["reaction"],
            "error_rate": profile["error_rate"],
            "last_damage_tick": -10000,
            "last_attacker": -1,
            "no_death": true,
            "upgrade_attack": 0,
            "upgrade_guard": 0,
            "recoil": 0,
            "combo": 0,
            "combo_timer": 0,
            "chaos_debt": 0,
            "contribution": 0,
            "synergies": 0,
            "rescues": 0,
            "stasis_struggle": 0,
            "stasis_immunity": 0
        })
    _start_next_wave()

func _cpu_profile(slot: int) -> Dictionary:
    var profiles := [
        {"greed": 0.35, "bravery": 0.68, "reaction": 11, "error_rate": 0.08},
        {"greed": 0.72, "bravery": 0.74, "reaction": 8, "error_rate": 0.10},
        {"greed": 0.18, "bravery": 0.52, "reaction": 14, "error_rate": 0.06},
        {"greed": 0.58, "bravery": 0.82, "reaction": 7, "error_rate": 0.13},
        {"greed": 0.28, "bravery": 0.61, "reaction": 12, "error_rate": 0.09},
        {"greed": 0.46, "bravery": 0.69, "reaction": 10, "error_rate": 0.08}
    ]
    return profiles[slot % profiles.size()]

func _role_stats(role: StringName) -> Dictionary:
    match role:
        &"guardian":
            return {"hp": 390.0, "speed": 180.0, "damage": 28.0, "range": 250.0}
        &"mage":
            return {"hp": 205.0, "speed": 205.0, "damage": 31.0, "range": 420.0}
        &"priest":
            return {"hp": 245.0, "speed": 210.0, "damage": 17.0, "range": 360.0}
        &"engineer":
            return {"hp": 270.0, "speed": 195.0, "damage": 22.0, "range": 380.0}
        &"lancer":
            return {"hp": 320.0, "speed": 235.0, "damage": 30.0, "range": 290.0}
        _:
            return {"hp": 235.0, "speed": 220.0, "damage": 27.0, "range": 470.0}

func step_tick(human_command: Dictionary, _dt: float = DT) -> void:
    if result != &"playing":
        return
    if not bool(human_command.get("party_ready", true)):
        party_ready = false
        return
    if not party_ready:
        party_ready = true
        log.add(tick, &"party_ready", 0, 1, {})
    party_mode = human_command.has("p2")
    if start_countdown_ticks > 0:
        start_countdown_ticks -= 1
        for hero in heroes:
            hero["vel"] = Vector2.ZERO
        tick += 1
        if start_countdown_ticks == 0:
            _say("GO!", 45)
            log.add(tick, &"defense_started", -1, -1, {})
        return
    _clear_expired_message()
    _tick_cooldowns()
    _update_wave_spawning()
    _recalculate_lane_pressure()
    for i in range(heroes.size()):
        if not bool(heroes[i]["alive"]):
            _try_respawn_hero(i)
            continue
        var command := _cpu_command(i)
        if i == 0:
            command = human_command.get("p1", human_command)
        elif i == 1 and party_mode:
            command = human_command.get("p2", {})
        _apply_hero_command(i, command)
    _update_projectiles()
    _update_stasis_zones()
    _update_enemies()
    _resolve_damage()
    _cleanup_dead()
    _update_wave_state()
    _check_result()
    _assert_finite()
    tick += 1
    wave_tick += 1

func _clear_expired_message() -> void:
    if tick >= recent_message_until:
        recent_message = ""

func _say(text: String, duration_ticks: int = 150) -> void:
    recent_message = text
    recent_message_until = tick + duration_ticks

func _tick_cooldowns() -> void:
    panic_cd = maxi(0, panic_cd - 1)
    impact_ticks = maxi(0, impact_ticks - 1)
    for lane in range(gate_fortify_ticks.size()):
        gate_fortify_ticks[lane] = maxi(0, gate_fortify_ticks[lane] - 1)
    for h in heroes:
        h["attack_cd"] = maxi(0, int(h["attack_cd"]) - 1)
        h["skill_cd"] = maxi(0, int(h["skill_cd"]) - 1)
        h["stasis_cd"] = maxi(0, int(h["stasis_cd"]) - 1)
        h["recoil"] = maxi(0, int(h["recoil"]) - 1)
        h["combo_timer"] = maxi(0, int(h["combo_timer"]) - 1)
        h["stasis_immunity"] = maxi(0, int(h["stasis_immunity"]) - 1)
        if int(h["combo_timer"]) == 0:
            h["combo"] = 0

func _start_next_wave() -> void:
    wave_index += 1
    if wave_index > 1:
        village_hp = maxf(0.0, village_hp - 4.0)
        log.add(tick, &"siege_fatigue", -1, -1, {"damage": 4.0, "wave": wave_index})
    wave_tick = 0
    wave_spawned = 0
    wave_target = 8 + wave_index * 4
    if wave_index == MAX_WAVES:
        wave_target += 1
    log.add(tick, &"wave_started", -1, -1, {"wave": wave_index, "target": wave_target})
    _say("WAVE %d" % wave_index, 90)

func _update_wave_spawning() -> void:
    if wave_index > MAX_WAVES:
        return
    var interval := maxi(18, 58 - wave_index * 3)
    if wave_spawned >= wave_target or wave_tick % interval != 0:
        return
    if wave_index == MAX_WAVES and wave_spawned == wave_target - 1:
        _spawn_enemy((wave_index + 1) % 4, true)
    else:
        # Each late wave announces one readable siege threat on a repeating lane.
        # Random siege units still appear, but this guarantees gates remain a
        # real target-priority problem instead of decorative scenery.
        var lane := wave_index % 4 if wave_index >= 4 and wave_spawned == 0 else int(rng.next_u32() % 4)
        _spawn_enemy(lane, false)
    wave_spawned += 1

func _spawn_enemy(lane: int, boss: bool) -> void:
    var jitter := Vector2(rng.rangef(-34.0, 34.0), rng.rangef(-34.0, 34.0))
    var siege: bool = boss or (wave_index >= 4 and wave_spawned == 0) or (wave_index >= 4 and rng.next_float() < 0.14)
    var hp := (720.0 + wave_index * 105.0) if boss else (62.0 + wave_index * 13.0)
    var speed := 54.0 if boss else (82.0 + wave_index * 2.0)
    var damage := 55.0 if boss else (9.2 + wave_index * 1.15)
    if siege and not boss:
        hp *= 1.28
        speed *= 0.88
        damage *= 1.15
    enemies.append({
        "id": next_enemy_id,
        "lane": lane,
        "pos": lane_spawns[lane] + jitter,
        "vel": Vector2.ZERO,
        "hp": hp,
        "hp_max": hp,
        "speed": speed,
        "damage": damage,
        "attack_cd": 0,
        "boss": boss,
        "siege": siege,
        "alive": true,
        "stasis": 0,
        "panic_time": 0,
        "last_hits": [],
        "last_skill_actor": -1,
        "last_skill_role": &"none",
        "last_skill_tick": -10000,
        "enrage_time": 0,
        "spawn_tick": tick
    })
    log.add(tick, &"enemy_spawned", next_enemy_id, -1, {"lane": lane, "boss": boss})
    next_enemy_id += 1

func _recalculate_lane_pressure() -> void:
    lane_pressure = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
    for lane in range(4):
        var gate_ratio := gate_hp[lane] / GATE_HP_MAX
        lane_pressure[lane] += (1.0 - gate_ratio) * 4.0
        if gate_hp[lane] <= 0.0:
            lane_pressure[lane] += 6.0
    for enemy in enemies:
        if not bool(enemy["alive"]):
            continue
        var lane := int(enemy["lane"])
        var distance_factor := 1.0 + (1.0 - clampf(Vector2(enemy["pos"]).distance_to(CENTER) / 820.0, 0.0, 1.0)) * 2.3
        var boss_factor := 7.0 if bool(enemy["boss"]) else 1.0
        lane_pressure[lane] += distance_factor * boss_factor

func _cpu_command(index: int) -> Dictionary:
    var hero: Dictionary = heroes[index]
    var reaction := int(hero["reaction"])
    if tick >= int(hero["decision_tick"]):
        hero["decision_tick"] = tick + reaction + int(rng.next_u32() % 8)
        var chosen_lane := _choose_cpu_lane(index)
        hero["desired_lane"] = chosen_lane
    var target_index := _choose_cpu_target(index)
    var aim := CENTER
    var move_target := _lane_hold_point(int(hero["desired_lane"]), 225.0)
    var primary := false
    var skill := false
    var stasis := false
    var panic := false
    if target_index >= 0:
        var enemy: Dictionary = enemies[target_index]
        aim = Vector2(enemy["pos"])
        primary = true
        var dist := Vector2(hero["pos"]).distance_to(aim)
        if int(hero["skill_cd"]) == 0 and dist < 220.0:
            skill = true
        if int(hero["stasis_cd"]) == 0 and _count_enemies_near(aim, 155.0) >= 4:
            stasis = true
        if dist > float(hero["attack_range"]) * 0.80:
            move_target = aim + aim.direction_to(Vector2(hero["pos"])) * 180.0
        elif dist < 95.0:
            move_target = Vector2(hero["pos"]) + aim.direction_to(Vector2(hero["pos"])) * 130.0
    if village_hp < 320.0:
        move_target = CENTER + CENTER.direction_to(Vector2(hero["pos"])) * 120.0
    if StringName(hero["role"]) == &"priest":
        var rescue_target := _nearest_down_hero(Vector2(hero["pos"]))
        if rescue_target >= 0:
            aim = Vector2(heroes[rescue_target]["pos"])
            move_target = aim
            primary = false
            stasis = false
            if Vector2(hero["pos"]).distance_to(aim) <= 205.0 and int(hero["skill_cd"]) == 0:
                skill = true
                move_target = Vector2(hero["pos"])
    if StringName(hero["role"]) == &"engineer":
        var broken_lane := _nearest_broken_gate(Vector2(hero["pos"]))
        if broken_lane >= 0:
            aim = _gate_pos(broken_lane)
            move_target = aim
            primary = false
            stasis = false
            if Vector2(hero["pos"]).distance_to(aim) <= 270.0 and int(hero["skill_cd"]) == 0:
                skill = true
                move_target = Vector2(hero["pos"])
    var error_roll: float = rng.next_float()
    if error_roll < float(hero["error_rate"]):
        move_target += Vector2(rng.rangef(-180.0, 180.0), rng.rangef(-180.0, 180.0))
        if rng.next_float() < 0.45:
            primary = false
    var move := Vector2(hero["pos"]).direction_to(move_target)
    if Vector2(hero["pos"]).distance_to(move_target) < 16.0:
        move = Vector2.ZERO
    return {
        "move": move,
        "aim": aim,
        "primary": primary,
        "skill": skill,
        "stasis": stasis,
        "panic": panic,
        "upgrade": int(hero["coins"]) >= _upgrade_cost(hero)
    }

func _nearest_down_hero(pos: Vector2) -> int:
    var best := -1
    var best_distance := INF
    for hero_index in range(heroes.size()):
        var candidate: Dictionary = heroes[hero_index]
        if bool(candidate["alive"]) or int(candidate["respawn_tick"]) <= tick:
            continue
        var distance := pos.distance_to(Vector2(candidate["pos"]))
        if distance < best_distance:
            best_distance = distance
            best = hero_index
    return best

func _nearest_broken_gate(pos: Vector2) -> int:
    var best := -1
    var best_distance := INF
    for lane in range(gate_hp.size()):
        if gate_hp[lane] > 0.0:
            continue
        var distance := pos.distance_to(_gate_pos(lane))
        if distance < best_distance:
            best_distance = distance
            best = lane
    return best

func _choose_cpu_lane(index: int) -> int:
    var hero: Dictionary = heroes[index]
    var best_lane := int(hero["lane"])
    var best_score := -INF
    for lane in range(4):
        var occupants := 0
        for other in heroes:
            if bool(other["alive"]) and int(other["desired_lane"]) == lane:
                occupants += 1
        var score := float(lane_pressure[lane]) * 1.8 - float(occupants) * 1.5
        if lane == int(hero["lane"]):
            score += 0.8
        if rng.next_float() < float(hero["greed"]) * 0.12:
            score += _low_hp_enemy_score(lane) * 1.2
        if score > best_score:
            best_score = score
            best_lane = lane
    return best_lane

func _low_hp_enemy_score(lane: int) -> float:
    var score := 0.0
    for enemy in enemies:
        if bool(enemy["alive"]) and int(enemy["lane"]) == lane:
            score += 1.0 - float(enemy["hp"]) / maxf(1.0, float(enemy["hp_max"]))
    return score

func _choose_cpu_target(index: int) -> int:
    var hero: Dictionary = heroes[index]
    var best := -1
    var best_score := -INF
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if not bool(enemy["alive"]):
            continue
        var dist := Vector2(hero["pos"]).distance_to(Vector2(enemy["pos"]))
        if dist > float(hero["attack_range"]) * 1.45:
            continue
        var urgency := 1.0 - clampf(Vector2(enemy["pos"]).distance_to(CENTER) / 820.0, 0.0, 1.0)
        var finish := 1.0 - float(enemy["hp"]) / maxf(1.0, float(enemy["hp_max"]))
        var lane_bonus := 1.0 if int(enemy["lane"]) == int(hero["desired_lane"]) else 0.0
        var score := urgency * 4.0 + lane_bonus * 2.2 + finish * float(hero["greed"]) * 4.0 - dist / 420.0
        if bool(enemy["boss"]):
            score += 5.0
        elif bool(enemy.get("siege", false)):
            score += 3.5
        if score > best_score:
            best_score = score
            best = i
    return best

func _apply_hero_command(index: int, command: Dictionary) -> void:
    var hero: Dictionary = heroes[index]
    var pos := Vector2(hero["pos"])
    var move: Vector2 = command.get("move", Vector2.ZERO)
    if move.length_squared() > 1.0:
        move = move.normalized()
    var stasis_owner := _stasis_owner_at(pos)
    var frozen := stasis_owner >= 0 and int(hero["stasis_immunity"]) == 0
    if frozen:
        var can_breakout := index == 0 or (party_mode and index == 1)
        if can_breakout and move.length_squared() > 0.25:
            hero["stasis_struggle"] = int(hero["stasis_struggle"]) + 1
        else:
            hero["stasis_struggle"] = maxi(0, int(hero["stasis_struggle"]) - 1)
        if can_breakout and int(hero["stasis_struggle"]) >= 36:
            _hero_stasis_breakout(index, stasis_owner)
            frozen = false
        move *= 0.18
    else:
        hero["stasis_struggle"] = maxi(0, int(hero["stasis_struggle"]) - 2)
    var target_velocity := move * float(hero["move_speed"])
    var rate := HERO_ACCEL if move.length_squared() > 0.01 else HERO_BRAKE
    var velocity := Vector2(hero["vel"]).move_toward(target_velocity, rate * DT)
    pos += velocity * DT
    pos.x = clampf(pos.x, 32.0, WORLD_SIZE.x - 32.0)
    pos.y = clampf(pos.y, 32.0, WORLD_SIZE.y - 32.0)
    hero["pos"] = pos
    hero["vel"] = velocity
    hero["lane"] = _closest_lane(pos)
    var aim: Vector2 = command.get("aim", pos + Vector2.RIGHT * 100.0)
    hero["aim"] = aim
    if not frozen and bool(command.get("primary", false)) and int(hero["attack_cd"]) == 0:
        _hero_primary(index, aim)
    if not frozen and bool(command.get("skill", false)) and int(hero["skill_cd"]) == 0:
        _hero_skill(index, aim)
    if bool(command.get("stasis", false)) and int(hero["stasis_cd"]) == 0:
        _hero_stasis(index, aim)
    if bool(command.get("panic", false)):
        _ring_panic_bell(index)
    if bool(command.get("upgrade", false)):
        _buy_upgrade(index)

func _hero_primary(index: int, aim: Vector2) -> void:
    var hero: Dictionary = heroes[index]
    var origin := Vector2(hero["pos"])
    var direction := origin.direction_to(aim)
    if direction == Vector2.ZERO:
        direction = Vector2.RIGHT
    projectiles.append({
        "id": next_projectile_id,
        "owner": index,
        "pos": origin + direction * 24.0,
        "vel": direction * 680.0,
        "damage": float(hero["attack_damage"]) * _human_damage_scale(index),
        "life": 58,
        "radius": 8.0,
        "pierce": 0
    })
    next_projectile_id += 1
    hero["attack_cd"] = maxi(8, 21 - int(hero["level"]) * 2)
    hero["recoil"] = 5
    log.add(tick, &"hero_fired", index, -1, {"aim": aim})

func _hero_skill(index: int, aim: Vector2) -> void:
    var hero: Dictionary = heroes[index]
    var role := StringName(hero["role"])
    var center := aim
    if Vector2(hero["pos"]).distance_to(center) > 280.0:
        center = Vector2(hero["pos"]) + Vector2(hero["pos"]).direction_to(center) * 280.0
    var radius := 145.0
    var damage_scale := 1.0
    var cooldown := 360
    if role == &"mage":
        radius = 190.0
        damage_scale = 1.55
        cooldown = 390
    elif role == &"guardian":
        center = Vector2(hero["pos"])
        radius = 185.0
        damage_scale = 1.20
        cooldown = 300
    elif role == &"hunter":
        radius = 115.0
        damage_scale = 1.85
        cooldown = 255
    elif role == &"lancer":
        hero["pos"] = center
        radius = 155.0
        damage_scale = 1.35
        cooldown = 300
    elif role == &"priest":
        center = Vector2(hero["pos"])
        radius = 210.0
        damage_scale = 0.55
        cooldown = 330
        var revive_target := _nearest_down_hero(center)
        if revive_target >= 0 and Vector2(heroes[revive_target]["pos"]).distance_to(center) <= radius:
            var revived: Dictionary = heroes[revive_target]
            revived["alive"] = true
            revived["hp"] = float(revived["hp_max"]) * 0.45
            revived["respawn_tick"] = -1
            revived["attack_cd"] = 60
            hero["rescues"] = int(hero["rescues"]) + 1
            hero["contribution"] = int(hero["contribution"]) + 8
            combat_revives += 1
            impact_ticks = maxi(impact_ticks, 18)
            log.add(tick, &"combat_revive", index, revive_target, {"hp": revived["hp"]})
            _say("P%d COMBAT REVIVES P%d!" % [index + 1, revive_target + 1], 150)
        for ally_index in range(heroes.size()):
            if bool(heroes[ally_index]["alive"]) and Vector2(heroes[ally_index]["pos"]).distance_to(center) <= radius:
                heroes[ally_index]["hp"] = minf(float(heroes[ally_index]["hp_max"]), float(heroes[ally_index]["hp"]) + 62.0 + float(hero["level"]) * 12.0)
    elif role == &"engineer":
        center = Vector2(hero["pos"])
        radius = 170.0
        damage_scale = 0.85
        cooldown = 300
        var repair_lane := _closest_lane(center)
        if center.distance_to(_gate_pos(repair_lane)) <= 270.0 and gate_hp[repair_lane] < GATE_HP_MAX:
            _repair_gate(repair_lane, 78.0 + float(hero["level"]) * 12.0, index)
    var hits := 0
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if bool(enemy["alive"]) and Vector2(enemy["pos"]).distance_to(center) <= radius:
            var skill_damage := (58.0 + float(hero["level"]) * 16.0) * damage_scale
            _request_damage(index, i, skill_damage * _human_damage_scale(index), &"skill")
            hits += 1
    hero["skill_cd"] = cooldown
    log.add(tick, &"hero_skill", index, -1, {"center": center, "hits": hits, "role": role})
    if hits >= 5:
        _say("P%d 광역기: %d명 적중" % [index + 1, hits])

func _human_damage_scale(index: int) -> float:
    if index == 0 or (party_mode and index == 1):
        return 1.15
    return 0.68 if party_mode else 0.42

func _hero_stasis(index: int, aim: Vector2) -> void:
    var hero: Dictionary = heroes[index]
    var coin_cost := 1 + int(hero["chaos_debt"])
    if int(hero["coins"]) < coin_cost:
        hero["stasis_cd"] = 60
        if index == 0 or (party_mode and index == 1):
            _say("P%d NEEDS %d COINS FOR STASIS" % [index + 1, coin_cost], 75)
        return
    var center := aim
    if Vector2(hero["pos"]).distance_to(center) > 340.0:
        center = Vector2(hero["pos"]) + Vector2(hero["pos"]).direction_to(center) * 340.0
    var ally_hits := 0
    for ally_index in range(heroes.size()):
        if ally_index != index and bool(heroes[ally_index]["alive"]) and Vector2(heroes[ally_index]["pos"]).distance_to(center) <= 150.0:
            ally_hits += 1
    var enemy_hits := _count_enemies_near(center, 150.0)
    stasis_zones.append({
        "id": next_zone_id,
        "owner": index,
        "pos": center,
        "radius": 150.0,
        "life": 150
    })
    next_zone_id += 1
    hero["coins"] = maxi(0, int(hero["coins"]) - coin_cost)
    hero["chaos_debt"] = clampi(int(hero["chaos_debt"]) + ally_hits - (1 if ally_hits == 0 and enemy_hits >= 4 else 0), 0, 5)
    hero["stasis_cd"] = 540 if enemy_hits >= 4 else 720
    if enemy_hits >= 4:
        hero["contribution"] = int(hero["contribution"]) + enemy_hits
    log.add(tick, &"stasis_cast", index, -1, {"center": center, "ally_hits": ally_hits, "enemy_hits": enemy_hits, "coin_cost": coin_cost})
    _say("P%d STASIS: %d ENEMIES / %d ALLIES / COST %d" % [index + 1, enemy_hits, ally_hits, coin_cost], 120)

func _ring_panic_bell(index: int) -> void:
    if panic_cd > 0 or bell_tokens <= 0:
        return
    var moved := 0
    var enraged := 0
    for enemy_index in range(enemies.size()):
        var enemy: Dictionary = enemies[enemy_index]
        if not bool(enemy["alive"]):
            continue
        var pos := Vector2(enemy["pos"])
        var distance := pos.distance_to(CENTER)
        if distance <= 360.0:
            var direction := CENTER.direction_to(pos)
            if direction.length_squared() < 0.01:
                direction = Vector2.RIGHT.rotated(float(enemy_index))
            enemy["pos"] = pos + direction * (125.0 - distance * 0.12)
            enemy["lane"] = (int(enemy["lane"]) + 1 + int(rng.next_u32() % 2)) % 4
            enemy["panic_time"] = 180
            if rng.next_float() < 0.30:
                enemy["enrage_time"] = 240
                enraged += 1
            enemies[enemy_index] = enemy
            moved += 1
    panic_cd = 720
    bell_tokens -= 1
    heroes[index]["contribution"] = int(heroes[index]["contribution"]) + moved
    impact_ticks = 18
    _say("P%d PANIC BELL: %d MOVED / %d ENRAGED!" % [index + 1, moved, enraged], 150)
    log.add(tick, &"panic_bell", index, -1, {"moved": moved, "enraged": enraged})

func _buy_upgrade(index: int) -> void:
    var hero: Dictionary = heroes[index]
    var cost := _upgrade_cost(hero)
    if int(hero["coins"]) < cost:
        return
    hero["coins"] = int(hero["coins"]) - cost
    if int(hero["upgrade_attack"]) <= int(hero["upgrade_guard"]):
        hero["upgrade_attack"] = int(hero["upgrade_attack"]) + 1
        hero["attack_damage"] = float(hero["attack_damage"]) * 1.10
    else:
        hero["upgrade_guard"] = int(hero["upgrade_guard"]) + 1
        hero["hp_max"] = float(hero["hp_max"]) + 25.0
        hero["hp"] = minf(float(hero["hp"]) + 25.0, float(hero["hp_max"]))
    log.add(tick, &"upgrade_bought", index, -1, {"cost": cost})

func _upgrade_cost(hero: Dictionary) -> int:
    return 5 + (int(hero["upgrade_attack"]) + int(hero["upgrade_guard"])) * 4

func _update_projectiles() -> void:
    for p in projectiles:
        p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * DT
        p["life"] = int(p["life"]) - 1
        if int(p["life"]) <= 0:
            continue
        for i in range(enemies.size()):
            var enemy: Dictionary = enemies[i]
            if not bool(enemy["alive"]):
                continue
            if Vector2(p["pos"]).distance_squared_to(Vector2(enemy["pos"])) <= pow(float(p["radius"]) + ENEMY_RADIUS, 2.0):
                _request_damage(int(p["owner"]), i, float(p["damage"]), &"primary")
                p["life"] = 0
                break

func _update_stasis_zones() -> void:
    for zone in stasis_zones:
        zone["life"] = int(zone["life"]) - 1
    for enemy in enemies:
        enemy["stasis"] = maxi(0, int(enemy["stasis"]) - 1)
        for zone in stasis_zones:
            if int(zone["life"]) > 0 and Vector2(enemy["pos"]).distance_to(Vector2(zone["pos"])) <= float(zone["radius"]):
                enemy["stasis"] = 2
                break

func _hero_in_stasis(pos: Vector2) -> bool:
    return _stasis_owner_at(pos) >= 0

func _stasis_owner_at(pos: Vector2) -> int:
    for zone in stasis_zones:
        if int(zone["life"]) > 0 and pos.distance_to(Vector2(zone["pos"])) <= float(zone["radius"]):
            return int(zone["owner"])
    return -1

func _hero_stasis_breakout(index: int, zone_owner: int) -> void:
    var hero: Dictionary = heroes[index]
    hero["stasis_struggle"] = 0
    hero["stasis_immunity"] = 120
    hero["recoil"] = 10
    hero["contribution"] = int(hero["contribution"]) + 2
    if zone_owner >= 0 and zone_owner < heroes.size() and zone_owner != index:
        heroes[zone_owner]["chaos_debt"] = mini(5, int(heroes[zone_owner]["chaos_debt"]) + 1)
    var hits := 0
    var center := Vector2(hero["pos"])
    for enemy_index in range(enemies.size()):
        if bool(enemies[enemy_index]["alive"]) and Vector2(enemies[enemy_index]["pos"]).distance_to(center) <= 120.0:
            _request_damage(index, enemy_index, 34.0 * _human_damage_scale(index), &"stasis_breakout")
            var away := center.direction_to(Vector2(enemies[enemy_index]["pos"]))
            enemies[enemy_index]["pos"] = Vector2(enemies[enemy_index]["pos"]) + away * 34.0
            hits += 1
    stasis_breakouts += 1
    impact_ticks = 14
    _say("P%d BROKE STASIS AND HIT %d - GRIEF REVERSED!" % [index + 1, hits], 120)
    log.add(tick, &"stasis_breakout", index, zone_owner, {"hits":hits})

func _update_enemies() -> void:
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if not bool(enemy["alive"]):
            continue
        enemy["attack_cd"] = maxi(0, int(enemy["attack_cd"]) - 1)
        enemy["panic_time"] = maxi(0, int(enemy["panic_time"]) - 1)
        enemy["enrage_time"] = maxi(0, int(enemy["enrage_time"]) - 1)
        var pos := Vector2(enemy["pos"])
        var speed_scale := 0.12 if int(enemy["stasis"]) > 0 else (1.28 if int(enemy["panic_time"]) > 0 else 1.0)
        var lane := int(enemy["lane"])
        var target_hero := _nearest_hero_index(pos, 90.0 if not bool(enemy["boss"]) else 135.0)
        var siege_gate := bool(enemy.get("siege", false)) and gate_hp[lane] > 0.0 and pos.distance_to(CENTER) <= 610.0
        if siege_gate:
            var siege_target := _gate_pos(lane)
            if pos.distance_to(siege_target) > 360.0:
                pos += pos.direction_to(siege_target) * float(enemy["speed"]) * speed_scale * DT
            if int(enemy["attack_cd"]) == 0:
                var siege_damage := float(enemy["damage"]) * (1.8 if bool(enemy["boss"]) else 1.25) * (1.35 if int(enemy["enrage_time"]) > 0 else 1.0)
                var gate_before := gate_hp[lane]
                _damage_gate(lane, siege_damage, int(enemy["id"]))
                if gate_before > 0.0 and gate_hp[lane] <= 0.0:
                    # A breaching unit joins the village assault after doing its
                    # job; it cannot farm collapse/reopen events at one gate.
                    enemy["siege"] = false
                enemy["attack_cd"] = 44 if not bool(enemy["boss"]) else 28
        elif target_hero >= 0:
            var hero: Dictionary = heroes[target_hero]
            if int(enemy["attack_cd"]) == 0:
                var enrage_damage := 1.35 if int(enemy["enrage_time"]) > 0 else 1.0
                _request_hero_damage(int(enemy["id"]), target_hero, float(enemy["damage"]) * enrage_damage)
                enemy["attack_cd"] = 44 if not bool(enemy["boss"]) else 32
            var away := Vector2(hero["pos"]).direction_to(pos)
            pos += away * float(enemy["speed"]) * 0.18 * speed_scale * DT
        else:
            var gate_blocking := gate_hp[lane] > 0.0 and pos.distance_to(CENTER) <= GATE_DISTANCE + 36.0
            if gate_blocking:
                var gate_pos := _gate_pos(lane)
                var outside := CENTER.direction_to(lane_spawns[lane])
                pos = gate_pos + outside * (ENEMY_RADIUS + 12.0)
                if int(enemy["attack_cd"]) == 0:
                    var gate_damage := float(enemy["damage"]) * (1.8 if bool(enemy["boss"]) else 1.0) * (1.35 if int(enemy["enrage_time"]) > 0 else 1.0)
                    _damage_gate(lane, gate_damage, int(enemy["id"]))
                    enemy["attack_cd"] = 42 if not bool(enemy["boss"]) else 30
            else:
                var direction := pos.direction_to(CENTER)
                pos += direction * float(enemy["speed"]) * speed_scale * DT
        enemy["pos"] = pos
        if pos.distance_to(CENTER) <= VILLAGE_RADIUS + ENEMY_RADIUS and int(enemy["attack_cd"]) == 0:
            var amount := float(enemy["damage"]) * (2.2 if bool(enemy["boss"]) else 1.0) * (1.35 if int(enemy["enrage_time"]) > 0 else 1.0) * 1.30
            village_hp = maxf(0.0, village_hp - amount)
            enemy["attack_cd"] = 38
            log.add(tick, &"village_hit", int(enemy["id"]), -1, {"damage": amount, "lane": int(enemy["lane"])})
            if amount >= 30.0:
                _say("보스가 마을을 공격 중!", 90)

func _damage_gate(lane: int, amount: float, attacker: int) -> void:
    if lane < 0 or lane >= gate_hp.size() or gate_hp[lane] <= 0.0:
        return
    if gate_fortify_ticks[lane] > 0:
        amount *= 0.22
    var previous := gate_hp[lane]
    gate_hp[lane] = maxf(0.0, previous - amount)
    log.add(tick, &"gate_hit", attacker, lane, {"damage": amount, "hp": gate_hp[lane]})
    if previous > 0.0 and gate_hp[lane] <= 0.0:
        gate_collapses += 1
        impact_ticks = 18
        _say("GATE %d COLLAPSED — OTHER LANES ROTATE NOW!" % (lane + 1), 180)
        log.add(tick, &"gate_collapsed", attacker, lane, {})

func _repair_gate(lane: int, amount: float, engineer: int) -> void:
    if lane < 0 or lane >= gate_hp.size() or gate_hp[lane] >= GATE_HP_MAX:
        return
    var was_broken := gate_hp[lane] <= 0.0
    gate_hp[lane] = minf(GATE_HP_MAX, gate_hp[lane] + amount)
    if engineer >= 0 and engineer < heroes.size():
        heroes[engineer]["contribution"] = int(heroes[engineer]["contribution"]) + 4
    log.add(tick, &"gate_repaired", engineer, lane, {"amount": amount, "hp": gate_hp[lane]})
    if was_broken and gate_hp[lane] >= GATE_HP_MAX * 0.35:
        gate_repairs += 1
        gate_fortify_ticks[lane] = 480
        impact_ticks = 12
        _say("ENGINEER REOPENED GATE %d!" % (lane + 1), 140)
        log.add(tick, &"gate_reopened", engineer, lane, {"hp": gate_hp[lane]})

func _nearest_hero_index(pos: Vector2, radius: float) -> int:
    var best := -1
    var best_d2 := radius * radius
    for i in range(heroes.size()):
        var hero: Dictionary = heroes[i]
        if not bool(hero["alive"]):
            continue
        var d2 := pos.distance_squared_to(Vector2(hero["pos"]))
        if d2 < best_d2:
            best_d2 = d2
            best = i
    return best

func _request_damage(actor: int, enemy_index: int, amount: float, kind: StringName) -> void:
    request_seq += 1
    damage_requests.append({
        "seq": request_seq,
        "actor": actor,
        "target_kind": &"enemy",
        "target": enemy_index,
        "amount": amount,
        "kind": kind
    })

func _request_hero_damage(actor: int, hero_index: int, amount: float) -> void:
    request_seq += 1
    damage_requests.append({
        "seq": request_seq,
        "actor": actor,
        "target_kind": &"hero",
        "target": hero_index,
        "amount": amount,
        "kind": &"enemy_attack"
    })

func _resolve_damage() -> void:
    damage_requests.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if int(a["target"]) == int(b["target"]):
            return int(a["seq"]) < int(b["seq"])
        return int(a["target"]) < int(b["target"])
    )
    for req in damage_requests:
        if StringName(req["target_kind"]) == &"enemy":
            var idx := int(req["target"])
            if idx < 0 or idx >= enemies.size() or not bool(enemies[idx]["alive"]):
                continue
            var enemy: Dictionary = enemies[idx]
            var resolved_amount := float(req["amount"])
            var attacker := int(req["actor"])
            if StringName(req["kind"]) == &"skill" and attacker >= 0 and attacker < heroes.size():
                var attacker_role := StringName(heroes[attacker]["role"])
                if int(enemy["last_skill_actor"]) >= 0 and int(enemy["last_skill_actor"]) != attacker and tick - int(enemy["last_skill_tick"]) <= 120 and StringName(enemy["last_skill_role"]) != attacker_role and (_is_human_actor(attacker) or _is_human_actor(int(enemy["last_skill_actor"]))):
                    resolved_amount *= 1.25
                    var partner := int(enemy["last_skill_actor"])
                    heroes[attacker]["synergies"] = int(heroes[attacker]["synergies"]) + 1
                    heroes[partner]["synergies"] = int(heroes[partner]["synergies"]) + 1
                    heroes[attacker]["contribution"] = int(heroes[attacker]["contribution"]) + 1
                    heroes[partner]["contribution"] = int(heroes[partner]["contribution"]) + 1
                    role_synergies += 1
                    impact_ticks = maxi(impact_ticks, 9)
                    log.add(tick, &"role_synergy", attacker, partner, {"enemy": enemy["id"]})
                enemy["last_skill_actor"] = attacker
                enemy["last_skill_role"] = attacker_role
                enemy["last_skill_tick"] = tick
            enemy["hp"] = float(enemy["hp"]) - resolved_amount
            var hits: Array = enemy["last_hits"]
            hits.append({"actor": int(req["actor"]), "tick": tick, "amount": float(req["amount"])})
            while hits.size() > 12:
                hits.pop_front()
            if float(enemy["hp"]) <= 0.0:
                _kill_enemy(idx, int(req["actor"]), StringName(req["kind"]))
        else:
            var hero_idx := int(req["target"])
            if hero_idx < 0 or hero_idx >= heroes.size() or not bool(heroes[hero_idx]["alive"]):
                continue
            var hero: Dictionary = heroes[hero_idx]
            hero["hp"] = float(hero["hp"]) - float(req["amount"])
            hero["last_damage_tick"] = tick
            hero["last_attacker"] = int(req["actor"])
            if float(hero["hp"]) <= 0.0:
                _down_hero(hero_idx)
    damage_requests.clear()

func _kill_enemy(enemy_index: int, killer: int, kind: StringName) -> void:
    var enemy: Dictionary = enemies[enemy_index]
    if not bool(enemy["alive"]):
        return
    enemy["alive"] = false
    if killer >= 0 and killer < heroes.size():
        var hero: Dictionary = heroes[killer]
        hero["kills"] = int(hero["kills"]) + 1
        hero["combo"] = int(hero["combo"]) + 1
        hero["combo_timer"] = 150
        hero["coins"] = int(hero["coins"]) + (6 if bool(enemy["boss"]) else 1)
        if int(hero["combo"]) % 5 == 0:
            hero["coins"] = int(hero["coins"]) + 1
            _say("P%d COMBO x%d!" % [killer + 1, int(hero["combo"])], 80)
        _check_evolution(killer)
        var assists := {}
        for hit in enemy["last_hits"]:
            var actor := int(hit["actor"])
            if actor != killer and tick - int(hit["tick"]) <= 240:
                assists[actor] = true
        for actor in assists.keys():
            if int(actor) >= 0 and int(actor) < heroes.size():
                heroes[int(actor)]["assists"] = int(heroes[int(actor)]["assists"]) + 1
                if _is_human_actor(int(actor)):
                    heroes[int(actor)]["coins"] = int(heroes[int(actor)]["coins"]) + (2 if bool(enemy["boss"]) else 1)
                heroes[int(actor)]["contribution"] = int(heroes[int(actor)]["contribution"]) + 1
        if assists.size() >= 1:
            log.add(tick, &"kill_contested", killer, int(enemy["id"]), {"assists": assists.keys(), "kind": kind})
    log.add(tick, &"enemy_killed", killer, int(enemy["id"]), {"boss": bool(enemy["boss"]), "lane": int(enemy["lane"])})

func _check_evolution(hero_index: int) -> void:
    var hero: Dictionary = heroes[hero_index]
    var thresholds := [8, 24, 52]
    var level := int(hero["level"])
    if level >= thresholds.size() or int(hero["kills"]) < thresholds[level]:
        return
    hero["level"] = level + 1
    hero["attack_damage"] = float(hero["attack_damage"]) * 1.24
    hero["move_speed"] = float(hero["move_speed"]) * 1.04
    hero["hp_max"] = float(hero["hp_max"]) + 55.0
    hero["hp"] = float(hero["hp_max"])
    log.add(tick, &"hero_evolved", hero_index, -1, {"level": int(hero["level"])})
    _say("P%d 진화! Lv.%d" % [hero_index + 1, int(hero["level"])])

func _is_human_actor(index: int) -> bool:
    return index == 0 or (party_mode and index == 1)

func _down_hero(index: int) -> void:
    var hero: Dictionary = heroes[index]
    hero["alive"] = false
    hero["hp"] = 0.0
    hero["respawn_tick"] = tick + 300
    hero["no_death"] = false
    var gasp_hits := 0
    for enemy_index in range(enemies.size()):
        var enemy: Dictionary = enemies[enemy_index]
        if bool(enemy["alive"]) and Vector2(enemy["pos"]).distance_to(Vector2(hero["pos"])) <= 170.0:
            enemy["hp"] = float(enemy["hp"]) - 46.0 - float(hero["level"]) * 8.0
            var away := Vector2(hero["pos"]).direction_to(Vector2(enemy["pos"]))
            enemy["pos"] = Vector2(enemy["pos"]) + away * 48.0
            if float(enemy["hp"]) <= 0.0:
                enemy["alive"] = false
                hero["kills"] = int(hero["kills"]) + 1
            enemies[enemy_index] = enemy
            gasp_hits += 1
    heroes[index] = hero
    impact_ticks = 14
    log.add(tick, &"hero_down", int(hero["last_attacker"]), index, {})
    _say("P%d LAST GASP HIT %d ENEMIES!" % [index + 1, gasp_hits], 120)

func _try_respawn_hero(index: int) -> void:
    var hero: Dictionary = heroes[index]
    if tick < int(hero["respawn_tick"]):
        return
    hero["alive"] = true
    hero["hp"] = float(hero["hp_max"]) * 0.75
    hero["pos"] = CENTER + Vector2.from_angle(TAU * float(index) / 6.0) * 125.0
    hero["attack_cd"] = 60
    log.add(tick, &"hero_respawned", index, -1, {})

func _cleanup_dead() -> void:
    projectiles = projectiles.filter(func(p: Dictionary) -> bool:
        var pos := Vector2(p["pos"])
        return int(p["life"]) > 0 and pos.x > -50.0 and pos.x < 1650.0 and pos.y > -50.0 and pos.y < 950.0
    )
    stasis_zones = stasis_zones.filter(func(z: Dictionary) -> bool: return int(z["life"]) > 0)
    if enemies.size() > 120 or tick % 300 == 0:
        enemies = enemies.filter(func(e: Dictionary) -> bool: return bool(e["alive"]))

func _update_wave_state() -> void:
    if wave_spawned < wave_target:
        return
    var alive_count := 0
    for enemy in enemies:
        if bool(enemy["alive"]):
            alive_count += 1
    if alive_count > 0:
        return
    if wave_index >= MAX_WAVES:
        result = &"victory"
        log.add(tick, &"village_saved", -1, -1, {"wave": wave_index, "hp": village_hp})
        _say("마을 방어 성공!", 100000)
        return
    if wave_tick >= 240:
        bell_tokens = mini(3, bell_tokens + 1)
        for hero_index in range(heroes.size()):
            if bool(heroes[hero_index]["alive"]):
                heroes[hero_index]["contribution"] = int(heroes[hero_index]["contribution"]) + 1
        _start_next_wave()

func _check_result() -> void:
    if village_hp <= 0.0 and result == &"playing":
        result = &"defeat"
        log.add(tick, &"village_destroyed", -1, -1, {"wave": wave_index})
        _say("마을 파괴 — R로 재시작", 100000)

func _lane_hold_point(lane: int, distance: float) -> Vector2:
    return CENTER + CENTER.direction_to(lane_spawns[lane]) * distance

func _gate_pos(lane: int) -> Vector2:
    return _lane_hold_point(lane, GATE_DISTANCE)

func _closest_lane(pos: Vector2) -> int:
    var delta := pos - CENTER
    if absf(delta.x) > absf(delta.y):
        return 1 if delta.x > 0.0 else 3
    return 2 if delta.y > 0.0 else 0

func _count_enemies_near(pos: Vector2, radius: float) -> int:
    var count := 0
    for enemy in enemies:
        if bool(enemy["alive"]) and Vector2(enemy["pos"]).distance_to(pos) <= radius:
            count += 1
    return count

func camera_target() -> Vector2:
    if heroes.is_empty():
        return CENTER
    var human := Vector2(heroes[0]["pos"])
    return CENTER.lerp(human, 0.28)

func summary() -> Dictionary:
    var alive_enemies := 0
    for enemy in enemies:
        if bool(enemy["alive"]):
            alive_enemies += 1
    return {
        "tick": tick,
        "result": String(result),
        "wave": wave_index,
        "village_hp": snappedf(village_hp, 0.01),
        "alive_enemies": alive_enemies,
        "hero_kills": _hero_kill_array(),
        "start_countdown": float(start_countdown_ticks) / 60.0,
        "party_ready": party_ready,
        "party_mode": party_mode,
        "bell_tokens": bell_tokens,
        "role_synergies": role_synergies,
        "stasis_breakouts": stasis_breakouts,
        "combat_revives": combat_revives,
        "gate_hp": gate_hp.duplicate(),
        "gate_collapses": gate_collapses,
        "gate_repairs": gate_repairs,
        "p1_combo": int(heroes[0]["combo"]),
        "p2_combo": int(heroes[1]["combo"]),
        "p1_debt": int(heroes[0]["chaos_debt"]),
        "p2_debt": int(heroes[1]["chaos_debt"]),
        "events": log.events.size()
    }

func _hero_kill_array() -> Array[int]:
    var out: Array[int] = []
    for hero in heroes:
        out.append(int(hero["kills"]))
    return out

func has_invalid_numbers() -> bool:
    if not is_finite(village_hp):
        return true
    for hero in heroes:
        var p := Vector2(hero["pos"])
        if not is_finite(p.x) or not is_finite(p.y) or not is_finite(float(hero["hp"])):
            return true
    for enemy in enemies:
        var p := Vector2(enemy["pos"])
        if not is_finite(p.x) or not is_finite(p.y) or not is_finite(float(enemy["hp"])):
            return true
    return false

func _assert_finite() -> void:
    if has_invalid_numbers():
        result = &"invalid"
        push_error("VillageWorld invalid number at tick %d" % tick)
