extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _init() -> void:
    var party_world = WorldScript.new(55000)
    party_world.step_tick({"party_ready":false, "p1":{}, "p2":{}}, 1.0 / 60.0)
    if party_world.tick != 0:
        push_error("operation advanced without soldier and supplier ready")
        quit(1)
        return
    var supplier_start := Vector2(party_world.actors[3]["pos"])
    for ready_frame in range(190):
        party_world.step_tick({"party_ready":true, "p1":{"move":Vector2.ZERO}, "p2":{"move":Vector2.RIGHT, "primary":true, "supply_kind":&"ammo", "target_actor":0}}, 1.0 / 60.0)
    if Vector2(party_world.actors[3]["pos"]).distance_to(supplier_start) < 10.0:
        push_error("second local supplier did not move after ready")
        quit(1)
        return
    var rescue_world = WorldScript.new(55005)
    rescue_world._down_actor(0)
    var cover_command := rescue_world._cpu_soldier_command(1)
    if int(rescue_world.actors[1]["covering_lane"]) != 0 or rescue_world.lane_covers != 1 or Vector2(cover_command["move"]).y >= 0.0:
        push_error("adjacent soldier did not abandon its lane to cover the downed front")
        quit(1)
        return
    var auto_med_request := false
    for request in rescue_world.requests:
        if int(request["actor"]) == 0 and StringName(request["kind"]) == &"med":
            auto_med_request = true
    if not auto_med_request:
        push_error("downed soldier did not create an urgent rescue request")
        quit(1)
        return
    var supplier_request := rescue_world._best_request_for_supplier(3)
    if supplier_request < 0 or StringName(rescue_world.requests[supplier_request]["kind"]) != &"med":
        push_error("supplier AI ignored an urgent downed-soldier medical request")
        quit(1)
        return
    rescue_world._dispatch_supply(3, 0, &"ammo")
    if not rescue_world.packages.is_empty():
        push_error("non-medical supply could target a downed soldier")
        quit(1)
        return
    rescue_world._dispatch_supply(3, 0, &"med")
    if rescue_world.packages.is_empty():
        push_error("medical supply could not target a downed soldier")
        quit(1)
        return
    rescue_world.packages[0]["pos"] = Vector2(rescue_world.actors[0]["pos"])
    rescue_world._update_packages()
    if not bool(rescue_world.actors[0]["alive"]) or rescue_world.support_revives != 1 or int(rescue_world.actors[3]["revives"]) != 1:
        push_error("field medical delivery did not restore the broken lane")
        quit(1)
        return
    var world = WorldScript.new(55001)
    for i in range(120000):
        var actor: Dictionary = world.actors[world.human_slot]
        var aim: Vector2 = Vector2(world.hive_pos)
        var nearest_distance := INF
        for enemy in world.enemies:
            if bool(enemy["alive"]) and int(enemy["lane"]) == int(actor["lane"]):
                var d := Vector2(actor["pos"]).distance_to(Vector2(enemy["pos"]))
                if d < nearest_distance:
                    nearest_distance = d
                    aim = Vector2(enemy["pos"])
        var can_push: bool = bool(world.hive_vulnerable) and int(world._lane_enemy_count(int(actor["lane"]))) <= 2
        var command := {
            "move": Vector2(actor["pos"]).direction_to(Vector2(1050.0 if can_push else 520.0, world.lane_y[int(actor["lane"])])),
            "aim": aim,
            "primary": true,
            "ability": i % 480 == 0,
            "request_ammo": int(actor["ammo"]) < 18,
            "request_med": float(actor["hp"]) < float(actor["hp_max"]) * 0.4,
            "request_barrier": i % 900 == 0,
            "cycle_supply": false,
            "target_actor": -1
        }
        world.step_tick(command, 1.0 / 60.0)
        if world.has_invalid_numbers():
            push_error("invalid number at tick %d" % i)
            quit(1)
            return
        if world.result != &"playing":
            break
    if world.result != &"victory":
        push_error("support match did not reach victory: %s" % JSON.stringify(world.summary()))
        quit(1)
        return
    var chaos_world = WorldScript.new(55002)
    chaos_world._dispatch_supply(3, 0, &"ammo")
    if chaos_world.packages.is_empty():
        push_error("supplier could not dispatch an unsolicited package")
        quit(1)
        return
    chaos_world.packages[0]["pos"] = Vector2(chaos_world.actors[0]["pos"])
    chaos_world._update_packages()
    if int(chaos_world.actors[0]["overcharge"]) <= 0:
        push_error("unsolicited delivery did not create overcharge")
        quit(1)
        return
    var risk_world = WorldScript.new(55003)
    risk_world._dispatch_supply(3, 0, &"ammo", true)
    if risk_world.packages.is_empty() or not bool(risk_world.packages[0]["overcharged"]) or float(risk_world.packages[0]["speed"]) <= 300.0:
        push_error("supplier could not launch a fragile high-reward overcharge")
        quit(1)
        return
    risk_world.packages[0]["pos"] = Vector2(risk_world.actors[0]["pos"]) + Vector2.LEFT * 60.0
    var hp_before := float(risk_world.actors[0]["hp"])
    risk_world._soldier_fire(0, Vector2(risk_world.packages[0]["pos"]))
    for shot_frame in range(30):
        risk_world._update_projectiles()
        if risk_world.manual_detonations > 0:
            break
    risk_world._resolve_damage()
    if risk_world.manual_detonations != 1 or risk_world.friendly_blasts < 1 or risk_world.botched_detonations != 1 or float(risk_world.actors[0]["hp"]) >= hp_before or int(risk_world.actors[3]["jam_ticks"]) <= 0:
        push_error("manual overcharge blast did not pay off with an ally-risk penalty")
        quit(1)
        return
    var clutch_world = WorldScript.new(55004)
    var clutch_center := Vector2(900.0, 450.0)
    for enemy_index in range(3):
        clutch_world._spawn_enemy(1, false)
        clutch_world.enemies[enemy_index]["pos"] = clutch_center + Vector2(enemy_index * 18.0, 0.0)
    var morale_before: float = float(clutch_world.team_morale)
    clutch_world._package_pop({"pos":clutch_center, "supplier":3, "overcharged":false}, true, 0)
    if clutch_world.clutch_detonations != 1 or clutch_world.team_morale <= morale_before or int(clutch_world.actors[0]["hit_combo"]) < 3:
        push_error("well-timed shared detonation did not reward both roles")
        quit(1)
        return
    print("SMOKE_OK ", JSON.stringify(world.summary()))
    quit(0)
