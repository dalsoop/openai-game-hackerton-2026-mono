class_name MountGameWorld
extends RefCounted

const SeededRngScript = preload("res://scripts/sim/seeded_rng.gd")
const EventLogScript = preload("res://scripts/sim/event_log.gd")

const PLAYER_COUNT := 6
const PLAYER_RADIUS := 22.0
const PLAYER_SPEED := 310.0
const PLAYER_ACCEL := 2400.0
const PLAYER_BRAKE := 3000.0
const WALL_RADIUS := 38.0
const FIXED_DT := 1.0 / 60.0
const START_COUNTDOWN := 3.0

var rng
var event_log
var tick: int = 0
var stage_index: int = 0
var stage_height: float = 3000.0
var stage_width: float = 1600.0
var players: Array[Dictionary] = []
var walls: Array[Dictionary] = []
var boulders: Array[Dictionary] = []
var flags: Array[Dictionary] = []
var web_zones: Array[Dictionary] = []
var spawn_timer: float = 1.8
var wipe_timer: float = -1.0
var stage_clear_timer: float = -1.0
var next_entity_id: int = 100
var result: StringName = &"playing"
var callout: String = ""
var callout_ticks: int = 0
var impact_ticks: int = 0
var start_countdown: float = START_COUNTDOWN
var party_ready: bool = false
var party_mode: bool = false
var contributions: Array[int] = []
var mischief: Array[int] = []
var rescues: Array[int] = []
var boulder_blocks: Array[int] = []
var chain_shoves: Array[int] = []

var stages := [
    {"height": 3900.0, "speed": 215.0, "interval": 2.85, "lane_jitter": 130.0},
    {"height": 4200.0, "speed": 238.0, "interval": 2.65, "lane_jitter": 180.0},
    {"height": 4500.0, "speed": 258.0, "interval": 2.45, "lane_jitter": 220.0},
    {"height": 4800.0, "speed": 276.0, "interval": 2.25, "lane_jitter": 260.0},
    {"height": 5200.0, "speed": 300.0, "interval": 2.05, "lane_jitter": 300.0}
]

func _init(seed: int = 12345) -> void:
    rng = SeededRngScript.new(seed)
    event_log = EventLogScript.new()
    reset()

func reset() -> void:
    tick = 0
    stage_index = 0
    result = &"playing"
    party_ready = false
    party_mode = false
    contributions = [0, 0, 0, 0, 0, 0]
    mischief = [0, 0, 0, 0, 0, 0]
    rescues = [0, 0, 0, 0, 0, 0]
    boulder_blocks = [0, 0, 0, 0, 0, 0]
    chain_shoves = [0, 0, 0, 0, 0, 0]
    callout = "CLIMB TOGETHER. SABOTAGE OPTIONAL."
    callout_ticks = 210
    impact_ticks = 0
    event_log.clear()
    _start_stage()

func _start_stage() -> void:
    var cfg: Dictionary = stages[stage_index]
    stage_height = float(cfg["height"])
    players.clear()
    walls.clear()
    boulders.clear()
    flags.clear()
    web_zones.clear()
    next_entity_id = 100
    spawn_timer = 2.2
    wipe_timer = -1.0
    stage_clear_timer = -1.0
    start_countdown = START_COUNTDOWN
    for slot in range(PLAYER_COUNT):
        players.append({
            "id": slot,
            "slot": slot,
            "pos": Vector2(510.0 + slot * 116.0, stage_height - 150.0 - absf(2.5 - slot) * 8.0),
            "vel": Vector2.ZERO,
            "alive": true,
            "charges": 4,
            "recharge": 0.0,
            "invuln": 0.75,
            "cpu_think": 0.08 + slot * 0.02,
            "cpu_move": Vector2.UP,
            "action": &"ADVANCE",
            "tool_cd": 0.0,
            "ghost_cd": 0.0,
            "spirit": 2,
            "last_interference_by": -1,
            "interference_time": 0.0,
            "shove_time": 0.0,
            "shove_owner": -1,
            "chain_mask": 0
        })
    event_log.emit(tick, &"stage_started", -1, -1, {"stage": stage_index + 1})

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
        for index in range(players.size()):
            var waiting_player: Dictionary = players[index]
            waiting_player["vel"] = Vector2.ZERO
            waiting_player["action"] = &"READY"
            players[index] = waiting_player
        if start_countdown > 0.0001:
            return
        start_countdown = 0.0
        _announce("GO!", 45)
        event_log.emit(tick, &"race_started", -1, -1, {"stage": stage_index + 1})
    _update_timers(dt)
    var p1_command: Dictionary = command.get("p1", command)
    var p2_command: Dictionary = command.get("p2", {})
    _apply_human_slot(0, p1_command, dt)
    if party_mode:
        _apply_human_slot(1, p2_command, dt)
    _update_cpus(dt)
    _move_players(dt)
    _update_boulders(dt)
    _update_webs(dt)
    _resolve_rescue(p1_command, p2_command, dt)
    _check_stage_state(dt)

func _update_timers(dt: float) -> void:
    callout_ticks = maxi(0, callout_ticks - 1)
    impact_ticks = maxi(0, impact_ticks - 1)
    for i in range(players.size()):
        var p: Dictionary = players[i]
        p["invuln"] = maxf(0.0, float(p["invuln"]) - dt)
        p["tool_cd"] = maxf(0.0, float(p["tool_cd"]) - dt)
        p["ghost_cd"] = maxf(0.0, float(p["ghost_cd"]) - dt)
        p["interference_time"] = maxf(0.0, float(p["interference_time"]) - dt)
        p["shove_time"] = maxf(0.0, float(p["shove_time"]) - dt)
        if float(p["shove_time"]) <= 0.0:
            p["shove_owner"] = -1
            p["chain_mask"] = 0
        if int(p["charges"]) < 4:
            p["recharge"] = float(p["recharge"]) + dt
            if float(p["recharge"]) >= 1.8:
                p["recharge"] = 0.0
                p["charges"] = int(p["charges"]) + 1
        players[i] = p

func _apply_human_slot(slot: int, command: Dictionary, dt: float) -> void:
    if slot < 0 or slot >= players.size():
        return
    var p: Dictionary = players[slot]
    if not bool(p["alive"]):
        p["vel"] = Vector2.ZERO
        players[slot] = p
        var ghost_move: Vector2 = command.get("move", Vector2.ZERO)
        if ghost_move.length_squared() > 1.0:
            ghost_move = ghost_move.normalized()
        for index in range(flags.size()):
            var flag: Dictionary = flags[index]
            if int(flag["owner"]) == slot:
                var ghost_pos := Vector2(flag["pos"]) + ghost_move * 190.0 * dt
                ghost_pos.x = clampf(ghost_pos.x, 230.0, 1370.0)
                ghost_pos.y = clampf(ghost_pos.y, 100.0, stage_height - 90.0)
                flag["pos"] = ghost_pos
                flags[index] = flag
                break
        if bool(command.get("build", false)):
            _ghost_gust(slot, ghost_move)
        return
    var move: Vector2 = command.get("move", Vector2.ZERO)
    if move.length_squared() > 1.0:
        move = move.normalized()
    var speed_scale := _web_speed_scale(Vector2(p["pos"]), slot)
    var target_velocity := move * PLAYER_SPEED * speed_scale
    var rate := PLAYER_ACCEL if move.length_squared() > 0.01 else PLAYER_BRAKE
    p["vel"] = Vector2(p["vel"]).move_toward(target_velocity, rate * dt)
    p["action"] = &"PLAYER"
    players[slot] = p
    if bool(command.get("build", false)):
        _try_build_wall(slot)
    if bool(command.get("bomb", false)):
        _try_bomb(slot)
    if bool(command.get("web", false)):
        _try_web(slot)

func _update_cpus(dt: float) -> void:
    var first_cpu := 2 if party_mode else 1
    for slot in range(first_cpu, players.size()):
        var p: Dictionary = players[slot]
        if not bool(p["alive"]):
            p["vel"] = Vector2.ZERO
            p["action"] = &"SPECTATE"
            players[slot] = p
            continue
        p["cpu_think"] = float(p["cpu_think"]) - dt
        if float(p["cpu_think"]) <= 0.0:
            p["cpu_think"] = 0.10 + rng.rangef(0.0, 0.08)
            var desired := Vector2.UP
            var nearest_danger: Dictionary = {}
            var best_eta := 99.0
            var best_impact_x := 0.0
            for b in boulders:
                if float(b["warning"]) > 0.0:
                    continue
                var boulder_pos := Vector2(b["pos"])
                var player_pos := Vector2(p["pos"])
                var vertical_gap := player_pos.y - boulder_pos.y
                if vertical_gap < -float(b["radius"]) or vertical_gap > 760.0:
                    continue
                var y_speed := maxf(1.0, float(Vector2(b["vel"]).y))
                var eta := maxf(0.0, vertical_gap / y_speed)
                var impact_x := boulder_pos.x + float(Vector2(b["vel"]).x) * eta
                var x_gap := absf(impact_x - player_pos.x)
                if eta >= 0.0 and eta < best_eta and x_gap < float(b["radius"]) + PLAYER_RADIUS + 48.0:
                    best_eta = eta
                    nearest_danger = b
                    best_impact_x = impact_x
            var flag_target := _best_flag_for(slot)
            if not flag_target.is_empty() and Vector2(p["pos"]).distance_to(Vector2(flag_target["pos"])) < 430.0 and best_eta > 0.85:
                desired = Vector2(p["pos"]).direction_to(Vector2(flag_target["pos"]))
                p["action"] = &"RESCUE_APPROACH"
            elif not nearest_danger.is_empty() and best_eta < 1.45:
                var player_x := float(Vector2(p["pos"]).x)
                var side := signf(player_x - best_impact_x)
                if side == 0.0:
                    var left_space := player_x - (220.0 + PLAYER_RADIUS)
                    var right_space := (1380.0 - PLAYER_RADIUS) - player_x
                    side = -1.0 if left_space > right_space else 1.0
                if player_x < 285.0:
                    side = 1.0
                elif player_x > 1315.0:
                    side = -1.0
                desired = Vector2(side, -0.12).normalized()
                p["action"] = &"DODGE"
                if best_eta < 0.60 and int(p["charges"]) > 0 and rng.chance(0.28):
                    players[slot] = p
                    _try_build_wall(slot)
                    p = players[slot]
            else:
                desired.x = sin(float(tick) * 0.015 + slot * 1.7) * 0.18
                desired = desired.normalized()
                p["action"] = &"ADVANCE"
            p["cpu_move"] = desired
        var target_velocity: Vector2 = Vector2(p["cpu_move"]) * PLAYER_SPEED * _web_speed_scale(Vector2(p["pos"]), slot) * rng.rangef(0.94, 1.02)
        p["vel"] = Vector2(p["vel"]).move_toward(target_velocity, PLAYER_ACCEL * dt)
        players[slot] = p

func _move_players(dt: float) -> void:
    for i in range(players.size()):
        var p: Dictionary = players[i]
        if not bool(p["alive"]):
            continue
        var pos: Vector2 = Vector2(p["pos"]) + Vector2(p["vel"]) * dt
        pos.x = clampf(pos.x, 220.0 + PLAYER_RADIUS, 1380.0 - PLAYER_RADIUS)
        pos.y = clampf(pos.y, 92.0, stage_height - 80.0)
        for wall_index in range(walls.size()):
            var wall: Dictionary = walls[wall_index]
            var delta := pos - Vector2(wall["pos"])
            var min_dist := PLAYER_RADIUS + WALL_RADIUS
            if delta.length_squared() < min_dist * min_dist:
                var n := delta.normalized() if delta.length_squared() > 0.001 else Vector2.RIGHT
                pos = Vector2(wall["pos"]) + n * min_dist
                var owner := int(wall["owner"])
                var bit := 1 << i
                if owner != i and (int(wall["blocked_mask"]) & bit) == 0:
                    wall["blocked_mask"] = int(wall["blocked_mask"]) | bit
                    wall["durability"] = int(wall["durability"]) - 1
                    mischief[owner] += 1
                    var owner_player: Dictionary = players[owner]
                    owner_player["charges"] = maxi(0, int(owner_player["charges"]) - 1)
                    players[owner] = owner_player
                    p["last_interference_by"] = owner
                    p["interference_time"] = 2.5
                    event_log.emit(tick, &"wall_grief", owner, i, {"durability": wall["durability"]})
                    if int(wall["durability"]) <= 0:
                        wall["expired"] = true
                walls[wall_index] = wall
        p["pos"] = pos
        players[i] = p
    var active_walls: Array[Dictionary] = []
    for wall in walls:
        if not bool(wall.get("expired", false)):
            active_walls.append(wall)
    walls = active_walls
    for _pass in range(1):
        for a in range(players.size()):
            if not bool(players[a]["alive"]):
                continue
            for b in range(a + 1, players.size()):
                if not bool(players[b]["alive"]):
                    continue
                var pa: Dictionary = players[a]
                var pb: Dictionary = players[b]
                var delta := Vector2(pb["pos"]) - Vector2(pa["pos"])
                var min_dist := PLAYER_RADIUS * 1.35
                if delta.length_squared() < min_dist * min_dist:
                    var n := delta.normalized() if delta.length_squared() > 0.001 else Vector2.RIGHT.rotated(a + b)
                    var push := minf(2.5, (min_dist - delta.length()) * 0.4)
                    var pa_shoving := float(pa["shove_time"]) > 0.0
                    var pb_shoving := float(pb["shove_time"]) > 0.0
                    if pa_shoving != pb_shoving:
                        var source_index := a if pa_shoving else b
                        var target_index := b if pa_shoving else a
                        var source: Dictionary = pa if pa_shoving else pb
                        var target: Dictionary = pb if pa_shoving else pa
                        var target_bit := 1 << target_index
                        if (int(source["chain_mask"]) & target_bit) == 0:
                            var owner := int(source["shove_owner"])
                            source["chain_mask"] = int(source["chain_mask"]) | target_bit
                            target["vel"] = Vector2(target["vel"]) + Vector2(source["vel"]) * 0.62
                            target["shove_time"] = 0.32
                            target["shove_owner"] = owner
                            target["chain_mask"] = 1 << source_index
                            target["last_interference_by"] = owner
                            target["interference_time"] = 2.5
                            if owner >= 0:
                                mischief[owner] += 1
                                chain_shoves[owner] += 1
                                event_log.emit(tick, &"player_pinball", owner, target_index, {"via":source_index})
                                _announce("P%d STARTED A PLAYER PINBALL!" % [owner + 1], 75)
                            if pa_shoving:
                                pa = source
                                pb = target
                            else:
                                pb = source
                                pa = target
                    pa["pos"] = Vector2(pa["pos"]) - n * push
                    pb["pos"] = Vector2(pb["pos"]) + n * push
                    players[a] = pa
                    players[b] = pb

func _update_boulders(dt: float) -> void:
    spawn_timer -= dt
    if spawn_timer <= 0.0 and stage_clear_timer < 0.0:
        spawn_timer = float(stages[stage_index]["interval"])
        var count := PLAYER_COUNT
        if stage_index == 4 and (tick / 60) % 16 > 10:
            count = PLAYER_COUNT * 2
        for i in range(count):
            _spawn_boulder(i * 0.11)
    var new_boulders: Array[Dictionary] = []
    for b0 in boulders:
        var b: Dictionary = b0
        b["warning"] = maxf(0.0, float(b["warning"]) - dt)
        if float(b["warning"]) > 0.0:
            new_boulders.append(b)
            continue
        var speed_scale := 1.0
        for zone in web_zones:
            if Vector2(b["pos"]).distance_to(Vector2(zone["pos"])) <= float(zone["radius"]):
                speed_scale = minf(speed_scale, 0.30)
        b["pos"] = Vector2(b["pos"]) + Vector2(b["vel"]) * dt * speed_scale
        var hit_wall := false
        for wi in range(walls.size() - 1, -1, -1):
            var wall: Dictionary = walls[wi]
            if Vector2(b["pos"]).distance_to(Vector2(wall["pos"])) < float(b["radius"]) + WALL_RADIUS:
                event_log.emit(tick, &"wall_broken", int(wall["owner"]), int(b["id"]), {"pos": wall["pos"]})
                event_log.emit(tick, &"boulder_blocked", int(wall["owner"]), int(b["id"]), {"pos": wall["pos"]})
                var wall_owner := int(wall["owner"])
                contributions[wall_owner] += 1
                boulder_blocks[wall_owner] += 1
                var builder: Dictionary = players[wall_owner]
                builder["charges"] = mini(4, int(builder["charges"]) + 1)
                players[wall_owner] = builder
                walls.remove_at(wi)
                hit_wall = true
                impact_ticks = 8
                _announce("WALL BLOCKED A BOULDER!", 75)
                break
        if hit_wall:
            continue
        for slot in range(players.size()):
            var p: Dictionary = players[slot]
            if not bool(p["alive"]) or float(p["invuln"]) > 0.0:
                continue
            if Vector2(b["pos"]).distance_to(Vector2(p["pos"])) < float(b["radius"]) + PLAYER_RADIUS:
                _kill_player(slot, int(b["id"]))
        if Vector2(b["pos"]).y < stage_height + 160.0:
            new_boulders.append(b)
    boulders = new_boulders

func _spawn_boulder(extra_warning: float) -> void:
    var cfg: Dictionary = stages[stage_index]
    var x: float = 800.0 + rng.rangef(-float(cfg["lane_jitter"]), float(cfg["lane_jitter"]))
    x = clampf(x, 270.0, 1330.0)
    boulders.append({
        "id": next_entity_id,
        "pos": Vector2(x, 42.0),
        "vel": Vector2(rng.rangef(-25.0, 25.0), float(cfg["speed"]) * rng.rangef(0.94, 1.08)),
        "radius": rng.rangef(32.0, 46.0),
        "warning": 0.65 + extra_warning
    })
    next_entity_id += 1
    event_log.emit(tick, &"boulder_warning", -1, next_entity_id - 1, {"x": x})

func _try_build_wall(slot: int) -> void:
    var p: Dictionary = players[slot]
    if not bool(p["alive"]) or int(p["charges"]) <= 0:
        return
    var pos := Vector2(p["pos"]) + Vector2(0.0, -62.0)
    pos.x = clampf(pos.x, 260.0, 1340.0)
    for wall in walls:
        if pos.distance_to(Vector2(wall["pos"])) < WALL_RADIUS * 1.8:
            return
    walls.append({"id": next_entity_id, "owner": slot, "pos": pos, "durability": 2, "blocked_mask": 0, "expired": false})
    next_entity_id += 1
    p["charges"] = int(p["charges"]) - 1
    players[slot] = p
    event_log.emit(tick, &"wall_built", slot, next_entity_id - 1, {"pos": pos})

func _consume_oldest_wall(slot: int) -> bool:
    for i in range(walls.size()):
        if int(walls[i]["owner"]) == slot:
            var wall: Dictionary = walls[i]
            walls.remove_at(i)
            event_log.emit(tick, &"wall_consumed", slot, int(wall["id"]), {})
            return true
    return false

func _try_bomb(slot: int) -> void:
    var p: Dictionary = players[slot]
    if float(p["tool_cd"]) > 0.0 or not _consume_oldest_wall(slot):
        return
    var center: Vector2 = Vector2(p["pos"])
    var kept: Array[Dictionary] = []
    var removed := 0
    for b in boulders:
        if Vector2(b["pos"]).distance_to(center) <= 280.0:
            removed += 1
        else:
            kept.append(b)
    boulders = kept
    var pushed := 0
    for target_index in range(players.size()):
        if target_index == slot or not bool(players[target_index]["alive"]):
            continue
        var target_player: Dictionary = players[target_index]
        var distance := Vector2(target_player["pos"]).distance_to(center)
        if distance <= 205.0:
            var away := center.direction_to(Vector2(target_player["pos"]))
            if away.length_squared() < 0.01:
                away = Vector2.RIGHT.rotated(float(target_index))
            target_player["pos"] = Vector2(target_player["pos"]) + away * (72.0 - distance * 0.12)
            target_player["vel"] = Vector2(target_player["vel"]) + away * 560.0
            target_player["shove_time"] = 0.45
            target_player["shove_owner"] = slot
            target_player["chain_mask"] = 1 << slot
            target_player["last_interference_by"] = slot
            target_player["interference_time"] = 2.5
            players[target_index] = target_player
            pushed += 1
    contributions[slot] += removed
    mischief[slot] += pushed
    p = players[slot]
    p["tool_cd"] = 5.0
    players[slot] = p
    impact_ticks = 12
    event_log.emit(tick, &"tool_used", slot, -1, {"tool": "bomb", "removed": removed, "pushed": pushed})

func _try_web(slot: int) -> void:
    var p: Dictionary = players[slot]
    if float(p["tool_cd"]) > 0.0 or not _consume_oldest_wall(slot):
        return
    web_zones.append({"id": next_entity_id, "pos": Vector2(p["pos"]) + Vector2.UP * 140.0, "radius": 230.0, "time": 4.0, "owner": slot})
    next_entity_id += 1
    p = players[slot]
    p["tool_cd"] = 8.0
    players[slot] = p
    event_log.emit(tick, &"tool_used", slot, -1, {"tool": "web"})

func _ghost_gust(slot: int, direction: Vector2) -> void:
    var p: Dictionary = players[slot]
    if bool(p["alive"]) or float(p["ghost_cd"]) > 0.0 or int(p["spirit"]) <= 0:
        return
    var center := Vector2(p["pos"])
    for flag in flags:
        if int(flag["owner"]) == slot:
            center = Vector2(flag["pos"])
            break
    var gust_dir := direction.normalized()
    if gust_dir.length_squared() < 0.01:
        gust_dir = Vector2.RIGHT if (tick / 60) % 2 == 0 else Vector2.LEFT
    var affected := 0
    var pushed := 0
    for index in range(boulders.size()):
        var boulder: Dictionary = boulders[index]
        var distance := Vector2(boulder["pos"]).distance_to(center)
        if distance <= 330.0:
            boulder["vel"] = Vector2(boulder["vel"]) + gust_dir * (340.0 * (1.0 - distance / 430.0))
            boulders[index] = boulder
            affected += 1
    for index in range(players.size()):
        if index == slot or not bool(players[index]["alive"]):
            continue
        var target: Dictionary = players[index]
        if Vector2(target["pos"]).distance_to(center) <= 180.0:
            target["pos"] = Vector2(target["pos"]) + gust_dir * 42.0
            target["vel"] = Vector2(target["vel"]) + gust_dir * 460.0
            target["shove_time"] = 0.40
            target["shove_owner"] = slot
            target["chain_mask"] = 1 << slot
            target["last_interference_by"] = slot
            target["interference_time"] = 2.5
            players[index] = target
            pushed += 1
    p = players[slot]
    p["ghost_cd"] = 2.2
    p["spirit"] = int(p["spirit"]) - 1
    players[slot] = p
    contributions[slot] += affected
    mischief[slot] += pushed
    impact_ticks = 10
    _announce("P%d'S GHOST BLEW %d BOULDERS!" % [slot + 1, affected], 100)
    event_log.emit(tick, &"ghost_gust", slot, -1, {"affected": affected, "pushed": pushed})

func _update_webs(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for z0 in web_zones:
        var z: Dictionary = z0
        z["time"] = float(z["time"]) - dt
        if float(z["time"]) > 0.0:
            kept.append(z)
    web_zones = kept

func _web_speed_scale(pos: Vector2, slot: int) -> float:
    var scale := 1.0
    for zone in web_zones:
        if pos.distance_to(Vector2(zone["pos"])) <= float(zone["radius"]):
            scale = minf(scale, 0.72 if int(zone["owner"]) == slot else 0.48)
    return scale

func _kill_player(slot: int, boulder_id: int) -> void:
    var p: Dictionary = players[slot]
    if not bool(p["alive"]):
        return
    p["alive"] = false
    p["vel"] = Vector2.ZERO
    players[slot] = p
    if int(p["last_interference_by"]) >= 0 and float(p["interference_time"]) > 0.0:
        var saboteur := int(p["last_interference_by"])
        mischief[saboteur] += 2
        event_log.emit(tick, &"interference_knockout", saboteur, slot, {})
    flags.append({"owner": slot, "pos": Vector2(p["pos"]), "progress": 0.0, "revivers": 0})
    var kept: Array[Dictionary] = []
    for wall in walls:
        if int(wall["owner"]) != slot:
            kept.append(wall)
        else:
            event_log.emit(tick, &"wall_broken", slot, boulder_id, {"reason": "owner_dead"})
    walls = kept
    event_log.emit(tick, &"climber_died", boulder_id, slot, {"pos": p["pos"]})
    event_log.emit(tick, &"flag_spawned", slot, slot, {"pos": p["pos"]})
    impact_ticks = 14
    _announce("P%d GOT FLATTENED — GHOST MODE!" % (slot + 1), 120)

func _best_flag_for(slot: int) -> Dictionary:
    var best: Dictionary = {}
    var best_dist := 999999.0
    var p: Dictionary = players[slot]
    for flag in flags:
        var d := Vector2(p["pos"]).distance_to(Vector2(flag["pos"]))
        if d < best_dist:
            best_dist = d
            best = flag
    return best

func _resolve_rescue(p1_command: Dictionary, p2_command: Dictionary, dt: float) -> void:
    for fi in range(flags.size() - 1, -1, -1):
        var flag: Dictionary = flags[fi]
        var revivers := 0
        var reviver_slots: Array[int] = []
        for slot in range(players.size()):
            var p: Dictionary = players[slot]
            if not bool(p["alive"]):
                continue
            var wants := false
            if slot == 0:
                wants = bool(p1_command.get("interact", false))
            elif slot == 1 and party_mode:
                wants = bool(p2_command.get("interact", false))
            else:
                wants = true
            if wants and Vector2(p["pos"]).distance_to(Vector2(flag["pos"])) <= 58.0:
                revivers += 1
                reviver_slots.append(slot)
                p["vel"] = Vector2.ZERO
                p["action"] = &"RESCUE_CHANNEL"
                players[slot] = p
        if revivers > 0:
            flag["progress"] = float(flag["progress"]) + dt * (1.0 + 0.35 * minf(2.0, revivers - 1.0))
            flag["revivers"] = revivers
            if float(flag["progress"]) >= 1.35:
                var owner := int(flag["owner"])
                var restored: Dictionary = players[owner]
                restored["alive"] = true
                restored["pos"] = Vector2(flag["pos"]) + Vector2(0.0, 42.0)
                restored["invuln"] = 0.65
                restored["charges"] = maxi(1, int(restored["charges"]))
                restored["spirit"] = 2
                restored["action"] = &"ADVANCE"
                players[owner] = restored
                for reviver in reviver_slots:
                    contributions[reviver] += 2
                    rescues[reviver] += 1
                    var helper: Dictionary = players[reviver]
                    helper["charges"] = mini(4, int(helper["charges"]) + 1)
                    players[reviver] = helper
                event_log.emit(tick, &"rescue_completed", -1, owner, {"revivers": revivers})
                _announce("P%d IS BACK!" % (owner + 1), 85)
                flags.remove_at(fi)
                continue
        else:
            flag["progress"] = maxf(0.0, float(flag["progress"]) - dt * 0.25)
            flag["revivers"] = 0
        flags[fi] = flag

func _check_stage_state(dt: float) -> void:
    if stage_clear_timer < 0.0:
        for p in players:
            if bool(p["alive"]) and Vector2(p["pos"]).y <= 130.0:
                stage_clear_timer = 1.0
                event_log.emit(tick, &"summit_reached", int(p["slot"]), -1, {"stage": stage_index + 1})
                _announce("P%d REACHED THE SUMMIT!" % (int(p["slot"]) + 1), 120)
                break
    else:
        stage_clear_timer -= dt
        if stage_clear_timer <= 0.0:
            if stage_index >= stages.size() - 1:
                result = &"won"
                event_log.emit(tick, &"match_won", -1, -1, {})
            else:
                stage_index += 1
                _start_stage()
            return
    var alive_count := 0
    for p in players:
        if bool(p["alive"]):
            alive_count += 1
    if alive_count == 0 and wipe_timer < 0.0:
        wipe_timer = 1.8
        event_log.emit(tick, &"team_wiped", -1, -1, {"stage": stage_index + 1})
    if wipe_timer >= 0.0:
        wipe_timer -= dt
        if wipe_timer <= 0.0:
            _start_stage()

func _announce(text: String, duration_ticks: int) -> void:
    callout = text
    callout_ticks = duration_ticks

func camera_target() -> Vector2:
    if players.is_empty():
        return Vector2(800.0, stage_height - 450.0)
    if bool(players[0]["alive"]):
        return Vector2(800.0, clampf(Vector2(players[0]["pos"]).y - 110.0, 450.0, stage_height - 450.0))
    var best_y := stage_height
    for p in players:
        if bool(p["alive"]):
            best_y = minf(best_y, Vector2(p["pos"]).y)
    return Vector2(800.0, clampf(best_y - 110.0, 450.0, stage_height - 450.0))

func summary() -> Dictionary:
    var alive := 0
    for p in players:
        if bool(p["alive"]):
            alive += 1
    return {
        "tick": tick,
        "stage": stage_index + 1,
        "alive": alive,
        "flags": flags.size(),
        "walls": walls.size(),
        "boulders": boulders.size(),
        "start_countdown": start_countdown,
        "party_ready": party_ready,
        "party_mode": party_mode,
        "contributions": contributions.duplicate(),
        "mischief": mischief.duplicate(),
        "rescues": rescues.duplicate(),
        "boulder_blocks": boulder_blocks.duplicate(),
        "chain_shoves": chain_shoves.duplicate(),
        "result": result
    }

func has_invalid_numbers() -> bool:
    for p in players:
        var pos: Vector2 = p["pos"]
        if not is_finite(pos.x) or not is_finite(pos.y):
            return true
    return false
