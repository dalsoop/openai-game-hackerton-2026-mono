extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _init() -> void:
    var gate_world = WorldScript.new(44006)
    gate_world.gate_hp[1] = 8.0
    gate_world._damage_gate(1, 12.0, 999)
    if gate_world.gate_hp[1] > 0.0 or gate_world.gate_collapses != 1:
        push_error("lane gate could not collapse")
        quit(1)
        return
    gate_world.heroes[4]["pos"] = gate_world._gate_pos(1)
    gate_world._hero_skill(4, gate_world._gate_pos(1))
    if gate_world.gate_hp[1] < WorldScript.GATE_HP_MAX * 0.35 or gate_world.gate_repairs != 1:
        push_error("engineer could not reopen a collapsed gate")
        quit(1)
        return
    var rescue_world = WorldScript.new(44005)
    rescue_world._down_hero(0)
    rescue_world.heroes[3]["pos"] = Vector2(rescue_world.heroes[0]["pos"])
    rescue_world._hero_skill(3, Vector2(rescue_world.heroes[0]["pos"]))
    if not bool(rescue_world.heroes[0]["alive"]) or rescue_world.combat_revives != 1 or int(rescue_world.heroes[3]["rescues"]) != 1:
        push_error("priest role could not restore a downed front line")
        quit(1)
        return
    var party_world = WorldScript.new(44000)
    party_world.step_tick({"party_ready":false, "p1":{}, "p2":{}}, 1.0 / 60.0)
    if party_world.tick != 0:
        push_error("defense advanced without two ready heroes")
        quit(1)
        return
    var p2_start := Vector2(party_world.heroes[1]["pos"])
    for ready_frame in range(190):
        party_world.step_tick({"party_ready":true, "p1":{"move":Vector2.ZERO}, "p2":{"move":Vector2.RIGHT, "aim":Vector2(1200.0, 450.0), "primary":true}}, 1.0 / 60.0)
    if Vector2(party_world.heroes[1]["pos"]).distance_to(p2_start) < 10.0:
        push_error("second local hero did not move after ready")
        quit(1)
        return
    var balance_world = WorldScript.new(44002)
    balance_world.party_mode = true
    balance_world.heroes[0]["coins"] = 10
    balance_world.heroes[1]["pos"] = Vector2(balance_world.heroes[0]["pos"])
    for enemy_slot in range(6):
        balance_world._spawn_enemy(enemy_slot % 4, false)
        balance_world.enemies[balance_world.enemies.size() - 1]["pos"] = Vector2(balance_world.heroes[0]["pos"]) + Vector2.RIGHT.rotated(float(enemy_slot)) * 80.0
    var cast_center := Vector2(balance_world.heroes[0]["pos"])
    balance_world._hero_stasis(0, cast_center)
    if int(balance_world.heroes[0]["chaos_debt"]) < 1 or int(balance_world.heroes[0]["coins"]) >= 10 or int(balance_world.heroes[0]["stasis_cd"]) != 540:
        push_error("stasis did not balance enemy control with ally debt and coin cost")
        quit(1)
        return
    var debt_before_breakout := int(balance_world.heroes[0]["chaos_debt"])
    for struggle_frame in range(36):
        balance_world._apply_hero_command(1, {"move":Vector2.RIGHT})
    if balance_world.stasis_breakouts != 1 or int(balance_world.heroes[1]["stasis_immunity"]) <= 0 or int(balance_world.heroes[0]["chaos_debt"]) <= debt_before_breakout:
        push_error("the trapped player could not reverse an ally stasis grief")
        quit(1)
        return
    balance_world._request_damage(0, 0, 1.0, &"skill")
    balance_world._resolve_damage()
    balance_world._request_damage(1, 0, 1.0, &"skill")
    balance_world._resolve_damage()
    if balance_world.role_synergies < 1:
        push_error("different human roles did not create a combo bonus")
        quit(1)
        return
    balance_world.bell_tokens = 1
    balance_world.panic_cd = 0
    balance_world._ring_panic_bell(0)
    if balance_world.bell_tokens != 0:
        push_error("panic bell did not consume its shared team token")
        quit(1)
        return
    var world = WorldScript.new(44001)
    for i in range(90000):
        var aim: Vector2 = Vector2(world.center)
        var nearest_distance := INF
        for enemy in world.enemies:
            if bool(enemy["alive"]):
                var d := Vector2(world.heroes[0]["pos"]).distance_to(Vector2(enemy["pos"]))
                if d < nearest_distance:
                    nearest_distance = d
                    aim = Vector2(enemy["pos"])
        var move := Vector2(world.heroes[0]["pos"]).direction_to(world.center.lerp(aim, 0.45))
        var command := {
            "move": move,
            "aim": aim,
            "primary": true,
            "skill": i % 360 == 0,
            "stasis": i % 900 == 0,
            "panic": i == 600,
            "upgrade": i % 120 == 0
        }
        world.step_tick(command, 1.0 / 60.0)
        if world.has_invalid_numbers():
            push_error("invalid number at tick %d" % i)
            quit(1)
            return
        if world.result != &"playing":
            break
    var panic_events := 0
    for event in world.log.events:
        if StringName(event["type"]) == &"panic_bell":
            panic_events += 1
    if world.result != &"victory" or panic_events == 0:
        push_error("victory or panic-bell party mechanic missing: %s panic=%d" % [JSON.stringify(world.summary()), panic_events])
        quit(1)
        return
    print("SMOKE_OK ", JSON.stringify(world.summary()))
    quit(0)
