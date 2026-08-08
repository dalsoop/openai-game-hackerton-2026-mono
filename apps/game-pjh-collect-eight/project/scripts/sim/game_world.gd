class_name CollectEightGameWorld
extends RefCounted

const SeededRngScript = preload("res://scripts/sim/seeded_rng.gd")
const EventLogScript = preload("res://scripts/sim/event_log.gd")

const PLAYER_COUNT := 6
const RUNNER_RADIUS := 20.0
const BASE_SPEED := 335.0
const DASH_SPEED := 780.0
const PLAYER_ACCEL := 2450.0
const PLAYER_BRAKE := 3200.0
const MINE_POS := Vector2(1450.0, 450.0)
const FINAL_MINE_POS := Vector2(1050.0, 450.0)
const FIXED_DT := 1.0 / 60.0
const ARENA_MIN := Vector2(32.0, 32.0)
const ARENA_MAX := Vector2(1568.0, 868.0)
const PATH_CLEARANCE := 28.0
const PICKUP_GRACE := 0.55
const START_COUNTDOWN := 3.0
const WIN_SCORE := 8
const GOLDEN_HEIST_TIME := 75.0

var rng
var event_log
var tick: int = 0
var runners: Array[Dictionary] = []
var banks: Array[Dictionary] = []
var mineral: Dictionary = {}
var obstacles: Array[Rect2] = []
var next_entity_id: int = 100
var result: StringName = &"playing"
var winner_slot: int = -1
var round_time: float = 0.0
var seven_alarm_slot: int = -1
var callout: String = ""
var callout_ticks: int = 0
var impact_ticks: int = 0
var start_countdown: float = START_COUNTDOWN
var party_ready: bool = false
var party_mode: bool = false
var golden_heist: bool = false

func _init(seed: int = 3333) -> void:
    rng = SeededRngScript.new(seed)
    event_log = EventLogScript.new()
    reset()

func reset() -> void:
    tick = 0
    round_time = 0.0
    result = &"playing"
    winner_slot = -1
    seven_alarm_slot = -1
    callout = "FIRST TO 8! STEAL, DASH, ESCAPE!"
    callout_ticks = 210
    impact_ticks = 0
    start_countdown = START_COUNTDOWN
    party_ready = false
    party_mode = false
    golden_heist = false
    runners.clear()
    banks.clear()
    # The mine and every bank live on opposite ends of the arena. Two long
    # blocks turn the return trip into three readable chase corridors, so all
    # five pursuers keep converging on the same carrier instead of scattering
    # into six harmless radial spokes.
    obstacles = [
        Rect2(560.0, 180.0, 520.0, 160.0),
        Rect2(560.0, 560.0, 520.0, 160.0)
    ]
    next_entity_id = 100
    event_log.clear()
    var bank_rows: Array[float] = [120.0, 245.0, 370.0, 530.0, 655.0, 780.0]
    for slot in range(PLAYER_COUNT):
        var bank_pos := Vector2(105.0, bank_rows[slot])
        banks.append({"slot":slot, "pos":bank_pos, "radius":55.0})
        runners.append({
            "slot":slot,
            "pos":bank_pos.lerp(MINE_POS, 0.12),
            "vel":Vector2.ZERO,
            "facing":bank_pos.direction_to(MINE_POS),
            "score":0,
            "dash_cd":0.0,
            "dash_time":0.0,
            "dash_dir":Vector2.ZERO,
            "dash_hit_mask":0,
            "dash_speed":DASH_SPEED,
            "stun":0.0,
            "revenge_time":0.0,
            "hype_time":0.0,
            "winded":0.0,
            "dash_buffer":0.0,
            "buffer_dir":Vector2.ZERO,
            "hit_confirmed":false,
            "last_hit_target":-1,
            "repeat_hit_window":0.0,
            "foul_strikes":0,
            "foul_lock":0.0,
            "robberies":0,
            "hot_banks":0,
            "bumps":0,
            "whiffs":0,
            "fouls":0,
            "claim_progress":0.0,
            "deposit_progress":0.0,
            "think":0.10 + slot * 0.03,
            "cpu_move":Vector2.ZERO,
            "action":&"RACE_MINE"
        })
    mineral = {
        "id":next_entity_id,
        "state":&"mine",
        "pos":MINE_POS,
        "owner":-1,
        "respawn":0.0,
        "drop_lock":0.0,
        "secure_time":0.0,
        "last_owner":-1,
        "steal_chain":0
    }
    next_entity_id += 1
    event_log.emit(tick, &"round_started", -1, -1, {})

func step_tick(command: Dictionary, dt: float = FIXED_DT) -> void:
    if result != &"playing":
        return
    if not bool(command.get("party_ready", true)):
        party_ready = false
        return
    if not party_ready:
        party_ready = true
        event_log.emit(tick, &"party_ready", 0, 1, {})
    party_mode = command.has("p2")
    tick += 1
    if start_countdown > 0.0:
        start_countdown = maxf(0.0, start_countdown - dt)
        for index in range(runners.size()):
            var waiting_runner: Dictionary = runners[index]
            waiting_runner["vel"] = Vector2.ZERO
            waiting_runner["action"] = &"READY"
            runners[index] = waiting_runner
        if start_countdown > 0.0001:
            return
        start_countdown = 0.0
        _announce("GO!", 45)
        event_log.emit(tick, &"race_started", -1, -1, {})
    round_time += dt
    if not golden_heist and round_time >= GOLDEN_HEIST_TIME:
        golden_heist = true
        if mineral["state"] == &"carried" and int(mineral["owner"]) >= 0:
            var golden_owner := int(mineral["owner"])
            mineral["secure_time"] = 3.0
            runners[golden_owner]["dash_cd"] = 0.0
            runners[golden_owner]["hype_time"] = 3.0
        _announce("GOLDEN HEIST! HOT COINS SCORE DOUBLE — BUT 7 MUST STAND!", 180)
        event_log.emit(tick, &"golden_heist", -1, -1, {})
    _update_timers(dt)
    var p1_command: Dictionary = command.get("p1", command)
    _apply_human_slot(0, p1_command)
    if party_mode:
        var p2_command: Dictionary = command.get("p2", {})
        _apply_human_slot(1, p2_command)
    _update_cpus(dt)
    _move_runners(dt)
    _resolve_dash_hits()
    _update_mineral(command, dt)
    _check_win()

func _update_timers(dt: float) -> void:
    callout_ticks = maxi(0, callout_ticks - 1)
    impact_ticks = maxi(0, impact_ticks - 1)
    for i in range(runners.size()):
        var r: Dictionary = runners[i]
        var was_dashing := float(r["dash_time"]) > 0.0
        r["dash_cd"] = maxf(0.0, float(r["dash_cd"]) - dt * (1.55 if golden_heist else 1.0))
        r["dash_time"] = maxf(0.0, float(r["dash_time"]) - dt)
        r["stun"] = maxf(0.0, float(r["stun"]) - dt)
        r["revenge_time"] = maxf(0.0, float(r["revenge_time"]) - dt)
        r["hype_time"] = maxf(0.0, float(r["hype_time"]) - dt)
        r["winded"] = maxf(0.0, float(r["winded"]) - dt)
        r["foul_lock"] = maxf(0.0, float(r["foul_lock"]) - dt)
        r["repeat_hit_window"] = maxf(0.0, float(r["repeat_hit_window"]) - dt)
        r["dash_buffer"] = maxf(0.0, float(r["dash_buffer"]) - dt)
        if float(r["dash_time"]) <= 0.0:
            r["dash_hit_mask"] = 0
        if was_dashing and float(r["dash_time"]) <= 0.0 and not bool(r["hit_confirmed"]):
            r["winded"] = maxf(float(r["winded"]), 0.32)
            r["whiffs"] = int(r["whiffs"]) + 1
            event_log.emit(tick, &"dash_whiffed", i, -1, {})
        if was_dashing and float(r["dash_time"]) <= 0.0:
            r["hit_confirmed"] = false
        var buffered_dash := float(r["dash_buffer"]) > 0.0 and float(r["dash_cd"]) <= 0.0
        runners[i] = r
        if buffered_dash:
            _start_dash(i, Vector2(r["buffer_dir"]))
    mineral["drop_lock"] = maxf(0.0, float(mineral["drop_lock"]) - dt)
    mineral["secure_time"] = maxf(0.0, float(mineral["secure_time"]) - dt)
    if mineral["state"] == &"respawn":
        mineral["respawn"] = float(mineral["respawn"]) - dt
        if float(mineral["respawn"]) <= 0.0:
            mineral["state"] = &"mine"
            mineral["pos"] = FINAL_MINE_POS if seven_alarm_slot >= 0 else MINE_POS
            mineral["owner"] = -1
            mineral["steal_chain"] = 0
            event_log.emit(tick, &"mineral_respawned", -1, int(mineral["id"]), {})

func _apply_human_slot(slot: int, command: Dictionary) -> void:
    var r: Dictionary = runners[slot]
    if float(r["stun"]) > 0.0:
        r["vel"] = Vector2.ZERO
        runners[slot] = r
        return
    var move: Vector2 = command.get("move", Vector2.ZERO)
    if move.length_squared() > 1.0:
        move = move.normalized()
    if move.length_squared() > 0.01:
        r["facing"] = move
    var speed := BASE_SPEED * (_carrier_speed_scale(slot) if int(mineral["owner"]) == slot else 1.0)
    if float(r["hype_time"]) > 0.0:
        speed *= 1.10
    if float(r["winded"]) > 0.0 or float(r["foul_lock"]) > 0.0:
        speed *= 0.48
    var target_velocity := move * speed
    var rate := PLAYER_ACCEL if move.length_squared() > 0.01 else PLAYER_BRAKE
    r["vel"] = Vector2(r["vel"]).move_toward(target_velocity, rate * FIXED_DT)
    r["action"] = &"PLAYER"
    runners[slot] = r
    if bool(command.get("dash", false)):
        _try_dash(slot, move if move.length_squared() > 0.01 else Vector2(r["facing"]))

func _update_cpus(dt: float) -> void:
    var first_cpu := 2 if party_mode else 1
    for slot in range(first_cpu, runners.size()):
        var r: Dictionary = runners[slot]
        if float(r["stun"]) > 0.0:
            r["vel"] = Vector2.ZERO
            runners[slot] = r
            continue
        r["think"] = float(r["think"]) - dt
        if float(r["think"]) <= 0.0:
            r["think"] = 0.15 + rng.rangef(0.0, 0.10)
            var desired := Vector2.ZERO
            var state: StringName = mineral["state"]
            var owner := int(mineral["owner"])
            if owner == slot:
                var bank_pos: Vector2 = banks[slot]["pos"]
                desired = _path_direction(Vector2(r["pos"]), bank_pos, slot)
                r["action"] = &"CARRY_HOME"
                if Vector2(r["pos"]).distance_to(bank_pos) > 170.0 and float(r["dash_cd"]) <= 0.0:
                    runners[slot] = r
                    _try_dash(slot, desired)
                    r = runners[slot]
            elif state == &"carried" and owner >= 0:
                var carrier: Dictionary = runners[owner]
                var carrier_pos: Vector2 = carrier["pos"]
                var carrier_bank: Vector2 = banks[owner]["pos"]
                var chase_rank := _chaser_rank(slot, owner)
                if chase_rank == 0:
                    desired = _path_direction(Vector2(r["pos"]), _formation_target(carrier_pos, slot, 40.0), slot)
                    r["action"] = &"CHASE_CARRIER"
                else:
                    var intercept_amount := 0.30 + 0.14 * float(chase_rank - 1)
                    var predicted := carrier_pos.lerp(carrier_bank, clampf(intercept_amount, 0.28, 0.82))
                    desired = _path_direction(Vector2(r["pos"]), _formation_target(predicted, slot, 54.0), slot)
                    r["action"] = &"CUT_OFF"
                if chase_rank == 0 and Vector2(r["pos"]).distance_to(carrier_pos) < 145.0 and float(r["dash_cd"]) <= 0.0 and float(mineral["secure_time"]) <= 0.0 and rng.chance(0.34):
                    runners[slot] = r
                    _try_dash(slot, Vector2(r["pos"]).direction_to(carrier_pos))
                    r = runners[slot]
            elif state == &"dropped":
                desired = _path_direction(Vector2(r["pos"]), _formation_target(Vector2(mineral["pos"]), slot, 30.0), slot)
                r["action"] = &"STEAL_DROP"
            elif state == &"mine":
                desired = _path_direction(Vector2(r["pos"]), _formation_target(Vector2(mineral["pos"]), slot, 46.0), slot)
                r["action"] = &"RACE_MINE"
            else:
                desired = _path_direction(Vector2(r["pos"]), _formation_target(Vector2(mineral["pos"]), slot, 46.0), slot)
                r["action"] = &"RECOVER"
            desired = (desired + desired.orthogonal() * rng.rangef(-0.04, 0.04)).normalized()
            r["cpu_move"] = desired
        if float(r["dash_time"]) <= 0.0:
            var speed := BASE_SPEED * (_carrier_speed_scale(slot) if int(mineral["owner"]) == slot else 1.0)
            r["vel"] = Vector2(r["cpu_move"]) * speed
            if Vector2(r["cpu_move"]).length_squared() > 0.01:
                r["facing"] = Vector2(r["cpu_move"])
        runners[slot] = r

func _leader_slot() -> int:
    var best := -1
    var best_score := -1
    for r in runners:
        if int(r["score"]) > best_score:
            best_score = int(r["score"])
            best = int(r["slot"])
    return best

func _carrier_speed_scale(slot: int) -> float:
    var scale := maxf(0.78, 0.88 - float(runners[slot]["score"]) * 0.04)
    if int(runners[slot]["score"]) == WIN_SCORE - 1:
        # At seven, the whole arena is hunting this runner. A visible clutch
        # gear keeps the finale winnable without removing the incoming hits.
        return 1.42 if golden_heist else 1.16
    if golden_heist:
        return 1.25
    return scale * maxf(0.88, 1.0 - float(mineral.get("steal_chain", 0)) * 0.04)

func _chaser_rank(slot: int, owner: int) -> int:
    var carrier_pos := Vector2(runners[owner]["pos"])
    var my_distance := Vector2(runners[slot]["pos"]).distance_squared_to(carrier_pos)
    var rank := 0
    for other in range(runners.size()):
        if other == owner or other == slot:
            continue
        var other_distance := Vector2(runners[other]["pos"]).distance_squared_to(carrier_pos)
        if other_distance < my_distance or (is_equal_approx(other_distance, my_distance) and other < slot):
            rank += 1
    return rank

func _try_dash(slot: int, direction: Vector2) -> void:
    var r: Dictionary = runners[slot]
    if float(r["stun"]) > 0.0 or float(r["foul_lock"]) > 0.0:
        return
    if float(r["dash_cd"]) > 0.0:
        if float(r["dash_cd"]) <= 0.16:
            r["dash_buffer"] = 0.18
            r["buffer_dir"] = direction
            runners[slot] = r
        return
    _start_dash(slot, direction)

func _start_dash(slot: int, direction: Vector2) -> void:
    var r: Dictionary = runners[slot]
    var dir := direction.normalized()
    if dir.length_squared() < 0.01:
        dir = Vector2.RIGHT
    r["dash_time"] = 0.18
    r["dash_cd"] = 4.2
    r["dash_speed"] = DASH_SPEED
    if float(r["revenge_time"]) > 0.0:
        r["dash_time"] = 0.24
        r["dash_speed"] = DASH_SPEED * 1.18
        r["revenge_time"] = 0.0
        event_log.emit(tick, &"revenge_dash", slot, -1, {})
    r["dash_dir"] = dir
    r["vel"] = dir * float(r["dash_speed"])
    r["dash_hit_mask"] = 0
    r["dash_buffer"] = 0.0
    r["hit_confirmed"] = false
    runners[slot] = r
    event_log.emit(tick, &"dash_started", slot, -1, {})

func _move_runners(dt: float) -> void:
    for i in range(runners.size()):
        var r: Dictionary = runners[i]
        if float(r["dash_time"]) > 0.0:
            r["vel"] = Vector2(r["dash_dir"]) * float(r["dash_speed"])
        var pos: Vector2 = Vector2(r["pos"]) + Vector2(r["vel"]) * dt
        pos = _project_out_of_obstacles(pos)
        r["pos"] = pos
        runners[i] = r
    # Runners may squeeze past one another. Dashes, not passive body blocking,
    # are the deliberate way to ruin another player's route.
    for _pass in range(1):
        for a in range(runners.size()):
            for b in range(a + 1, runners.size()):
                var ra: Dictionary = runners[a]
                var rb: Dictionary = runners[b]
                var delta := Vector2(rb["pos"]) - Vector2(ra["pos"])
                var min_dist := RUNNER_RADIUS * 1.18
                if delta.length_squared() < min_dist * min_dist:
                    var fallback_angle := TAU * float((a * PLAYER_COUNT + b) % PLAYER_COUNT) / float(PLAYER_COUNT)
                    var n := delta.normalized() if delta.length_squared() > 0.001 else Vector2.RIGHT.rotated(fallback_angle)
                    var push := minf(1.25, (min_dist - delta.length()) * 0.35)
                    ra["pos"] = _project_out_of_obstacles(Vector2(ra["pos"]) - n * push)
                    rb["pos"] = _project_out_of_obstacles(Vector2(rb["pos"]) + n * push)
                    runners[a] = ra
                    runners[b] = rb

func _project_out_of_obstacles(pos: Vector2) -> Vector2:
    var out := _clamp_to_arena(pos)
    for rect in obstacles:
        var expanded := rect.grow(RUNNER_RADIUS)
        if expanded.has_point(out):
            var left := absf(out.x - expanded.position.x)
            var right := absf(expanded.end.x - out.x)
            var top := absf(out.y - expanded.position.y)
            var bottom := absf(expanded.end.y - out.y)
            var smallest := minf(minf(left, right), minf(top, bottom))
            if smallest == left:
                out.x = expanded.position.x
            elif smallest == right:
                out.x = expanded.end.x
            elif smallest == top:
                out.y = expanded.position.y
            else:
                out.y = expanded.end.y
    return _clamp_to_arena(out)

func _clamp_to_arena(pos: Vector2) -> Vector2:
    return Vector2(
        clampf(pos.x, ARENA_MIN.x, ARENA_MAX.x),
        clampf(pos.y, ARENA_MIN.y, ARENA_MAX.y)
    )

func _formation_target(base: Vector2, slot: int, radius: float) -> Vector2:
    var angle := -PI * 0.5 + TAU * float(slot) / float(PLAYER_COUNT)
    return _clamp_to_arena(base + Vector2.RIGHT.rotated(angle) * radius)

func _path_direction(from: Vector2, target: Vector2, slot: int) -> Vector2:
    if from.distance_squared_to(target) < 4.0:
        return Vector2.ZERO
    if _segment_is_clear(from, target):
        return from.direction_to(target)

    var lane_offset := -28.0 if slot % 2 == 0 else 28.0
    var nodes: Array[Vector2] = [
        from,
        target,
        Vector2(420.0, 118.0 + lane_offset),
        Vector2(820.0, 118.0 + lane_offset),
        Vector2(1210.0, 118.0 + lane_offset),
        Vector2(420.0, 450.0 + lane_offset),
        Vector2(820.0, 450.0 + lane_offset),
        Vector2(1210.0, 450.0 + lane_offset),
        Vector2(420.0, 782.0 + lane_offset),
        Vector2(820.0, 782.0 + lane_offset),
        Vector2(1210.0, 782.0 + lane_offset)
    ]
    var node_count := nodes.size()
    var distances: Array[float] = []
    var previous: Array[int] = []
    var visited: Array[bool] = []
    distances.resize(node_count)
    previous.resize(node_count)
    visited.resize(node_count)
    distances.fill(INF)
    previous.fill(-1)
    visited.fill(false)
    distances[0] = 0.0

    for _iteration in range(node_count):
        var current := -1
        var current_distance := INF
        for node_index in range(node_count):
            if not visited[node_index] and distances[node_index] < current_distance:
                current = node_index
                current_distance = distances[node_index]
        if current < 0:
            break
        if current == 1:
            break
        visited[current] = true
        for next_index in range(node_count):
            if next_index == current or visited[next_index]:
                continue
            if not _segment_is_clear(nodes[current], nodes[next_index]):
                continue
            var alternate := distances[current] + nodes[current].distance_to(nodes[next_index])
            if alternate < distances[next_index]:
                distances[next_index] = alternate
                previous[next_index] = current

    if previous[1] < 0:
        return from.direction_to(target)
    var cursor := 1
    while previous[cursor] > 0:
        cursor = previous[cursor]
    return from.direction_to(nodes[cursor])

func _segment_is_clear(from: Vector2, target: Vector2) -> bool:
    for rect in obstacles:
        var expanded := rect.grow(PATH_CLEARANCE)
        if expanded.has_point(from) or expanded.has_point(target):
            return false
        var corners: Array[Vector2] = [
            expanded.position,
            Vector2(expanded.end.x, expanded.position.y),
            expanded.end,
            Vector2(expanded.position.x, expanded.end.y)
        ]
        for edge_index in range(4):
            var next_edge := (edge_index + 1) % 4
            if Geometry2D.segment_intersects_segment(from, target, corners[edge_index], corners[next_edge]) != null:
                return false
    return true

func _resolve_dash_hits() -> void:
    for attacker in range(runners.size()):
        var a: Dictionary = runners[attacker]
        if float(a["dash_time"]) <= 0.0:
            continue
        for target in range(runners.size()):
            if target == attacker:
                continue
            var bit := 1 << target
            if (int(a["dash_hit_mask"]) & bit) != 0:
                continue
            var b: Dictionary = runners[target]
            if Vector2(a["pos"]).distance_to(Vector2(b["pos"])) <= RUNNER_RADIUS * 2.15:
                a["dash_hit_mask"] = int(a["dash_hit_mask"]) | bit
                a["hit_confirmed"] = true
                a["bumps"] = int(a["bumps"]) + 1
                var dir := Vector2(a["dash_dir"])
                var protected_carrier := int(mineral["owner"]) == target and float(mineral["secure_time"]) > 0.0
                var knockback := 26.0 if protected_carrier else 58.0
                b["pos"] = _project_out_of_obstacles(Vector2(b["pos"]) + dir * knockback)
                b["stun"] = 0.06 if protected_carrier else 0.14
                b["vel"] = dir * 220.0
                runners[target] = b
                impact_ticks = 8
                event_log.emit(tick, &"carrier_hit" if int(mineral["owner"]) == target else &"runner_hit", attacker, target, {})
                if protected_carrier:
                    _announce("P%d BLOCKED THE STEAL!" % (target + 1), 70)
                elif int(mineral["owner"]) == target:
                    a["robberies"] = int(a["robberies"]) + 1
                    a["hype_time"] = 1.25
                    _drop_mineral(target, Vector2(b["pos"]) + dir * 36.0, attacker)
                else:
                    var repeated := int(a["last_hit_target"]) == target and float(a["repeat_hit_window"]) > 0.0
                    a["last_hit_target"] = target
                    a["repeat_hit_window"] = 12.0
                    if repeated:
                        a["foul_strikes"] = int(a["foul_strikes"]) + 1
                        a["fouls"] = int(a["fouls"]) + 1
                        event_log.emit(tick, &"foul", attacker, target, {"strikes": a["foul_strikes"]})
                        if int(a["foul_strikes"]) >= 3:
                            a["foul_lock"] = 3.0
                            a["dash_cd"] = maxf(float(a["dash_cd"]), 3.0)
                            a["foul_strikes"] = 0
                            _announce("P%d FOUL! DASH LOCKED FOR BULLYING P%d!" % [attacker + 1, target + 1], 120)
        runners[attacker] = a

func _update_mineral(command: Dictionary, dt: float) -> void:
    var state: StringName = mineral["state"]
    if state == &"respawn":
        return
    if state == &"carried":
        var owner := int(mineral["owner"])
        if owner < 0:
            mineral["state"] = &"dropped"
            return
        mineral["pos"] = Vector2(runners[owner]["pos"])
        var bank_pos: Vector2 = banks[owner]["pos"]
        var r: Dictionary = runners[owner]
        if Vector2(r["pos"]).distance_to(bank_pos) <= float(banks[owner]["radius"]):
            var contesters := 0
            for other in range(runners.size()):
                if other != owner and Vector2(runners[other]["pos"]).distance_to(Vector2(r["pos"])) <= 135.0:
                    contesters += 1
            r["deposit_progress"] = float(r["deposit_progress"]) + dt / (1.0 + float(contesters) * 0.65)
            if float(r["deposit_progress"]) >= (0.25 if golden_heist else 0.45):
                _deposit(owner)
        else:
            r["deposit_progress"] = maxf(0.0, float(r["deposit_progress"]) - dt * 0.5)
        runners[owner] = r
        return
    var candidates: Array[Dictionary] = []
    for slot in range(runners.size()):
        var r: Dictionary = runners[slot]
        var distance := Vector2(r["pos"]).distance_to(Vector2(mineral["pos"]))
        var wants := _slot_wants_interact(slot, command)
        var radius := 58.0 if state == &"mine" else 48.0
        if wants and distance <= radius and float(mineral["drop_lock"]) <= 0.0:
            var claim_rate := 1.0
            if state == &"mine":
                var leader_score := int(runners[_leader_slot()]["score"])
                if int(r["score"]) == WIN_SCORE - 1:
                    claim_rate += 0.35
                elif leader_score < WIN_SCORE - 1:
                    claim_rate += float(maxi(0, leader_score - int(r["score"]))) * 0.14
            r["claim_progress"] = float(r["claim_progress"]) + dt * claim_rate
            candidates.append({"slot":slot, "progress":float(r["claim_progress"]), "distance":distance})
            if float(r["claim_progress"]) == dt:
                event_log.emit(tick, &"mining_started", slot, int(mineral["id"]), {"state":state})
        else:
            r["claim_progress"] = maxf(0.0, float(r["claim_progress"]) - dt * 1.5)
        runners[slot] = r
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if absf(float(a["progress"]) - float(b["progress"])) > 0.0001:
            return float(a["progress"]) > float(b["progress"])
        if absf(float(a["distance"]) - float(b["distance"])) > 0.001:
            return float(a["distance"]) < float(b["distance"])
        return int(a["slot"]) < int(b["slot"])
    )
    if not candidates.is_empty():
        var required := 0.24 if state == &"mine" else 0.10
        if float(candidates[0]["progress"]) >= required:
            _claim_mineral(int(candidates[0]["slot"]), state)

func _claim_mineral(slot: int, previous_state: StringName) -> void:
    mineral["state"] = &"carried"
    mineral["owner"] = slot
    mineral["last_owner"] = slot
    mineral["pos"] = Vector2(runners[slot]["pos"])
    mineral["secure_time"] = (3.0 if golden_heist else PICKUP_GRACE + float(runners[slot]["score"]) * 0.14)
    for i in range(runners.size()):
        var r: Dictionary = runners[i]
        r["claim_progress"] = 0.0
        runners[i] = r
    event_log.emit(tick, &"mineral_claimed" if previous_state == &"mine" else &"mineral_stolen", slot, int(mineral["id"]), {"from_state":previous_state})
    _announce("P%d GOT THE COIN - CUT THEM OFF!" % (slot + 1), 95)

func _slot_wants_interact(slot: int, command: Dictionary) -> bool:
    if slot == 0:
        return bool(command.get("p1", command).get("interact", false))
    if slot == 1 and party_mode:
        return bool(command.get("p2", {}).get("interact", false))
    return true

func _drop_mineral(owner: int, pos: Vector2, attacker: int) -> void:
    mineral["state"] = &"dropped"
    mineral["owner"] = -1
    mineral["pos"] = _project_out_of_obstacles(pos)
    mineral["drop_lock"] = 0.42
    mineral["secure_time"] = 0.0
    mineral["steal_chain"] = int(mineral.get("steal_chain", 0)) + 1
    var r: Dictionary = runners[owner]
    r["deposit_progress"] = 0.0
    r["dash_cd"] = 0.0
    r["revenge_time"] = 3.0
    runners[owner] = r
    event_log.emit(tick, &"mineral_dropped", attacker, owner, {"pos":mineral["pos"]})
    impact_ticks = 12
    var chain := int(mineral["steal_chain"])
    _announce("P%d ROBBED P%d! HOT COIN x%d!" % [attacker + 1, owner + 1, chain], 100)

func _deposit(slot: int) -> void:
    var r: Dictionary = runners[slot]
    var chain := int(mineral.get("steal_chain", 0))
    var can_double_without_skipping_seven := int(r["score"]) <= WIN_SCORE - 3
    var value := 2 if can_double_without_skipping_seven and (golden_heist or (chain >= 3 and round_time >= 20.0)) else 1
    if value > 1:
        r["hot_banks"] = int(r["hot_banks"]) + 1
    r["score"] = mini(WIN_SCORE, int(r["score"]) + value)
    r["deposit_progress"] = 0.0
    runners[slot] = r
    mineral["state"] = &"respawn"
    mineral["owner"] = -1
    mineral["respawn"] = 0.45
    mineral["secure_time"] = 0.0
    mineral["steal_chain"] = 0
    event_log.emit(tick, &"coin_deposited", slot, int(mineral["id"]), {"score":r["score"], "value":value, "chain":chain})
    impact_ticks = 14
    _announce("P%d BANKED%s!  MINERALS %d / %d" % [slot + 1, " A GOLDEN DOUBLE" if golden_heist and value == 2 else (" A HOT DOUBLE" if value == 2 else " 1"), int(r["score"]), WIN_SCORE], 110)
    if int(r["score"]) == WIN_SCORE - 1:
        seven_alarm_slot = slot
        event_log.emit(tick, &"match_point_alarm", slot, -1, {})

func _check_win() -> void:
    for r in runners:
        if int(r["score"]) >= WIN_SCORE:
            winner_slot = int(r["slot"])
            result = &"won" if (winner_slot == 0 or (party_mode and winner_slot == 1)) else &"lost"
            event_log.emit(tick, &"winner", winner_slot, -1, {})
            return

func _announce(text: String, duration_ticks: int) -> void:
    callout = text
    callout_ticks = duration_ticks

func camera_target() -> Vector2:
    if int(mineral["owner"]) == 0:
        return Vector2(runners[0]["pos"]).lerp(Vector2(banks[0]["pos"]), 0.25)
    return Vector2(runners[0]["pos"]).lerp(Vector2(mineral["pos"]), 0.28)

func summary() -> Dictionary:
    var scores: Array[int] = []
    for r in runners:
        scores.append(int(r["score"]))
    var player_stats: Array[Dictionary] = []
    for r in runners:
        player_stats.append({"robberies":int(r["robberies"]), "hot_banks":int(r["hot_banks"]), "bumps":int(r["bumps"]), "whiffs":int(r["whiffs"]), "fouls":int(r["fouls"])})
    return {"tick":tick, "time":round_time, "scores":scores, "mineral_state":mineral["state"], "owner":mineral["owner"], "winner":winner_slot, "result":result, "start_countdown":start_countdown, "party_ready":party_ready, "party_mode":party_mode, "golden_heist":golden_heist, "player_stats":player_stats}

func has_invalid_numbers() -> bool:
    for r in runners:
        var pos: Vector2 = r["pos"]
        if not is_finite(pos.x) or not is_finite(pos.y):
            return true
    return false
