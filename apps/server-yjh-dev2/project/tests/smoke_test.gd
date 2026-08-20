extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _equipment_by_id(world, equipment_id: String) -> Dictionary:
    for equipment0 in world.equipment_defs:
        if str(equipment0["id"]) == equipment_id:
            var equipment: Dictionary = Dictionary(equipment0).duplicate(true)
            for values in [world._identity_for_equipment(equipment_id), world._mobility_for_equipment(equipment_id), world._combat_stats_for_equipment(equipment_id)]:
                for key in values:
                    equipment[key] = values[key]
            return equipment
    return {}

func _ability_origin(core_pos: Vector2, equipment_id: String, ultimate: bool) -> Vector2:
    if ultimate:
        match equipment_id:
            "scatter": return core_pos - Vector2(145.0, 0.0)
            "rail": return core_pos - Vector2(300.0, 0.0)
            "mortar": return core_pos - Vector2(500.0, 0.0)
            "leech": return core_pos
            "breaker": return core_pos - Vector2(260.0, 0.0)
            "brawler": return core_pos - Vector2(240.0, 0.0)
            "bomb": return core_pos - Vector2(260.0, 0.0)
            "chain", "shield": return core_pos
            _: return core_pos - Vector2(430.0, 0.0)
    match equipment_id:
        "breaker": return core_pos - Vector2(175.0, 0.0)
        "blade": return core_pos - Vector2(190.0, 0.0)
        "brawler": return core_pos - Vector2(130.0, 0.0)
        "bomb": return core_pos - Vector2(380.0, 0.0)
        "leech": return core_pos - Vector2(190.0, 0.0)
        "spear": return core_pos - Vector2(260.0, 0.0)
        "chain": return core_pos - Vector2(175.0, 0.0)
        "shield": return core_pos - Vector2(110.0, 0.0)
    return core_pos - Vector2(430.0, 0.0)

func _run_ability_core_check(equipment_id: String, ultimate: bool, seed: int) -> bool:
    var ability_world = WorldScript.new(seed)
    ability_world.match_time = 20.0
    for slot in range(1, ability_world.heroes.size()):
        ability_world.heroes[slot]["alive"] = false
    ability_world.heroes[0]["equipment"] = _equipment_by_id(ability_world, equipment_id)
    ability_world.heroes[0]["pos"] = _ability_origin(Vector2(ability_world.cores[1]["pos"]), equipment_id, ultimate)
    ability_world.heroes[0]["aim"] = Vector2.RIGHT
    var hp_before := float(ability_world.cores[1]["hp"])
    if ultimate:
        ability_world.heroes[0]["ultimate_charge"] = ability_world.ULTIMATE_MAX
        ability_world._try_ultimate(0, Vector2.RIGHT)
    else:
        ability_world.heroes[0]["equipment_cd"] = 0.0
        ability_world._try_equipment_attack(0, Vector2.RIGHT)
    for frame in range(150):
        ability_world._update_deployables(1.0 / 60.0)
        ability_world._update_projectiles(1.0 / 60.0)
        ability_world._update_zones(1.0 / 60.0)
    return float(ability_world.cores[1]["hp"]) < hp_before

func _init() -> void:
    var world = WorldScript.new(222)
    for i in range(13000):
        var angle := float(i) * 0.013
        var command := {
            "move":Vector2(cos(angle), sin(angle)),
            "aim":Vector2(1960.0,1190.0),
            "primary":true,
            "equipment":i % 150 == 0,
            "ultimate":true
        }
        world.step_tick(command, 1.0/60.0)
        if world.has_invalid_numbers():
            push_error("invalid number at tick %d" % i)
            quit(1)
            return
        if world.result != &"playing":
            break
    if world.result == &"playing":
        push_error("match did not produce a winner: %s" % JSON.stringify(world.summary()))
        quit(1)
        return
    var decision_world = WorldScript.new(532)
    decision_world.start_countdown = 0.0
    decision_world.match_time = decision_world.MATCH_TIME_LIMIT - 0.01
    for decision_slot in range(decision_world.heroes.size()):
        decision_world.heroes[decision_slot]["hp"] = float(decision_world.heroes[decision_slot]["max_hp"]) * (0.40 + float(decision_slot) * 0.05)
    decision_world.heroes[3]["hp"] = float(decision_world.heroes[3]["max_hp"]) * 0.92
    decision_world.step_tick({}, 0.02)
    if decision_world.result_reason != &"time_limit" or decision_world.winner_slot != 3 or absf(decision_world.match_time - decision_world.MATCH_TIME_LIMIT) > 0.001:
        push_error("210-second HP decision did not choose the highest remaining HP ratio")
        quit(1)
        return
    if absf(decision_world.decision_hp_ratio - 0.92) > 0.001 or decision_world.final_standings().is_empty() or int(decision_world.final_standings()[0]["slot"]) != 3:
        push_error("time-limit result did not preserve its visible decision evidence")
        quit(1)
        return
    var heal_world = WorldScript.new(221)
    if heal_world.health_pickups.size() != 4:
        push_error("fixed health pickup layout was not created")
        quit(1)
        return
    var pickup_pos: Vector2 = heal_world.health_pickups[0]["pos"]
    heal_world.heroes[0]["hp"] = float(heal_world.heroes[0]["max_hp"]) * 0.40
    for slot in range(1, heal_world.heroes.size()):
        heal_world.heroes[slot]["hp"] = float(heal_world.heroes[slot]["max_hp"])
    heal_world.heroes[0]["pos"] = pickup_pos + Vector2(140.0, 0.0)
    var magnet_distance_before := Vector2(heal_world.health_pickups[0]["pos"]).distance_to(Vector2(heal_world.heroes[0]["pos"]))
    heal_world._update_health_pickups(heal_world.FIXED_DT)
    var magnet_distance_after := Vector2(heal_world.health_pickups[0]["pos"]).distance_to(Vector2(heal_world.heroes[0]["pos"]))
    if int(heal_world.health_pickups[0]["magnet_slot"]) != 0 or magnet_distance_after >= magnet_distance_before:
        push_error("health pickup did not magnetize toward a nearby hurt hero")
        quit(1)
        return
    var hp_before_pickup := float(heal_world.heroes[0]["hp"])
    heal_world.heroes[0]["pos"] = pickup_pos
    heal_world._update_health_pickups(heal_world.FIXED_DT)
    if float(heal_world.heroes[0]["hp"]) <= hp_before_pickup or bool(heal_world.health_pickups[0]["active"]):
        push_error("health pickup did not heal and enter respawn")
        quit(1)
        return
    heal_world.heroes[0]["pos"] = Vector2(heal_world.ARENA_MARGIN + 100.0, heal_world.ARENA_MARGIN + 100.0)
    heal_world._update_health_pickups(heal_world.HEALTH_PICKUP_RESPAWN)
    if not bool(heal_world.health_pickups[0]["active"]):
        push_error("health pickup did not respawn at its fixed point")
        quit(1)
        return
    heal_world.heroes[0]["hp"] = float(heal_world.heroes[0]["max_hp"])
    heal_world.heroes[0]["pos"] = Vector2(heal_world.health_pickups[0]["pos"])
    heal_world._update_health_pickups(heal_world.FIXED_DT)
    if bool(heal_world.health_pickups[0]["active"]):
        push_error("full-health hero could not consume the map potion to deny it")
        quit(1)
        return
    var ghost_world = WorldScript.new(223)
    for i in range(180):
        ghost_world.step_tick({"move":Vector2.ZERO, "aim":Vector2(1960.0, 1190.0), "primary":false, "equipment":false, "ultimate":false}, 1.0 / 60.0)
    var equipment_ids: Dictionary = {}
    var normal_signatures: Dictionary = {}
    var skill_names: Dictionary = {}
    var ultimate_names: Dictionary = {}
    var character_names: Dictionary = {}
    for hero in ghost_world.heroes:
        var equipment: Dictionary = hero["equipment"]
        equipment_ids[str(equipment["id"])] = true
        skill_names[str(equipment["skill_name"])] = true
        ultimate_names[str(equipment["ultimate_name"])] = true
        character_names[str(equipment["character_name"])] = true
        var signature := "%s|%.2f|%.2f|%d|%.1f|%s" % [equipment["normal_name"], float(equipment["normal_damage"]), float(equipment["normal_interval"]), int(equipment["normal_projectiles"]), float(equipment["normal_splash"]), str(equipment["normal_leech"])]
        normal_signatures[signature] = true
    if equipment_ids.size() != 6:
        push_error("starting equipment was not distributed uniquely")
        quit(1)
        return
    if normal_signatures.size() != 6:
        push_error("equipment did not provide six distinct normal attacks")
        quit(1)
        return
    var mobility_names: Dictionary = {}
    for hero in ghost_world.heroes:
        mobility_names[str(hero["equipment"]["mobility_name"])] = true
    if mobility_names.size() != 6:
        push_error("equipment did not provide six distinct mobility identities")
        quit(1)
        return
    if skill_names.size() != 6 or ultimate_names.size() != 6:
        push_error("equipment did not provide six readable skill and ultimate identities")
        quit(1)
        return
    if character_names.size() != 6:
        push_error("combatants did not provide six readable character identities")
        quit(1)
        return
    var attack_world = WorldScript.new(225)
    for equipment0 in attack_world.equipment_defs:
        var equipment_id := str(equipment0["id"])
        attack_world.heroes[0]["equipment"] = _equipment_by_id(attack_world, equipment_id)
        attack_world.projectiles.clear()
        attack_world.zones.clear()
        attack_world.heroes[0]["fire_cd"] = 0.0
        attack_world.heroes[0]["normal_step"] = 0
        attack_world.heroes[0]["normal_chain_time"] = 0.0
        attack_world._try_normal_attack(0, Vector2.RIGHT)
        if attack_world._normal_combo_length(0) < 3:
            push_error("career lacked a multi-step normal string: %s" % equipment_id)
            quit(1)
            return
        if equipment_id in ["bomb", "mortar"]:
            if attack_world.projectiles.is_empty() or not bool(attack_world.projectiles[0].get("arc", false)) or not attack_world.zones.is_empty():
                push_error("explosive career did not use a telegraphed arc normal: %s" % equipment_id)
                quit(1)
                return
        elif equipment_id in ["scatter", "rail", "burst"]:
            if attack_world.projectiles.is_empty() or not attack_world.zones.is_empty():
                push_error("gun career did not use a projectile normal: %s" % equipment_id)
                quit(1)
                return
        elif not attack_world.projectiles.is_empty() or attack_world.zones.is_empty():
            push_error("non-gun career still used a projectile normal: %s" % equipment_id)
            quit(1)
            return
    var warning_world = WorldScript.new(226)
    warning_world.match_time = 20.0
    warning_world.covers.clear()
    for slot in range(2, warning_world.heroes.size()):
        warning_world.heroes[slot]["alive"] = false
    warning_world.heroes[0]["equipment"] = _equipment_by_id(warning_world, "mortar")
    warning_world.heroes[0]["pos"] = Vector2(500.0, 500.0)
    warning_world.heroes[0]["fire_cd"] = 0.0
    warning_world.heroes[1]["pos"] = Vector2(770.0, 500.0)
    var warned_hp := float(warning_world.heroes[1]["hp"])
    warning_world._try_normal_attack(0, Vector2.RIGHT)
    if warning_world.projectiles.is_empty() or float(warning_world.projectiles[0].get("max_ttl", 0.0)) < 0.49 or not warning_world.zones.is_empty():
        push_error("BOMBI normal did not show an airborne shell and landing marker")
        quit(1)
        return
    warning_world._update_projectiles(0.30)
    if float(warning_world.heroes[1]["hp"]) < warned_hp:
        push_error("BOMBI normal dealt damage before the visible shell landed")
        quit(1)
        return
    warning_world._update_projectiles(0.21)
    warning_world._update_zones(0.02)
    if float(warning_world.heroes[1]["hp"]) >= warned_hp:
        push_error("BOMBI visible shell failed to damage at its marked landing point")
        quit(1)
        return
    warning_world.zones.clear()
    warning_world.heroes[0]["equipment_cd"] = 0.0
    warning_world._try_equipment_attack(0, Vector2.RIGHT, 1.0)
    if warning_world.zones.is_empty() or float(warning_world.zones[0]["delay"]) < 0.60 or float(warning_world.zones[0].get("warning_duration", 0.0)) < 0.60:
        push_error("SKYFALL still had an unreadable escape window")
        quit(1)
        return
    var danger_pos: Vector2 = warning_world.zones[0]["pos"]
    warning_world.heroes[1]["pos"] = danger_pos + Vector2(15.0, 0.0)
    var escape_dir := warning_world._hazard_escape_vector(1)
    if escape_dir.dot(danger_pos.direction_to(Vector2(warning_world.heroes[1]["pos"]))) < 0.90:
        push_error("CPU did not understand a warned blast zone")
        quit(1)
        return
    warning_world.zones.clear()
    warning_world.heroes[0]["ultimate_charge"] = warning_world.ULTIMATE_MAX
    warning_world._try_ultimate(0, Vector2.RIGHT)
    var shortest_ultimate_warning := INF
    for zone in warning_world.zones:
        shortest_ultimate_warning = minf(shortest_ultimate_warning, float(zone["delay"]))
    if warning_world.zones.size() != 5 or shortest_ultimate_warning < 0.70:
        push_error("NO SAFE PLACE still struck before a first-look dodge was possible")
        quit(1)
        return
    var installer_world = WorldScript.new(524)
    installer_world.match_time = 20.0
    installer_world.covers.clear()
    for slot in range(2, installer_world.heroes.size()):
        installer_world.heroes[slot]["alive"] = false
    installer_world.heroes[0]["equipment"] = _equipment_by_id(installer_world, "bomb")
    installer_world.heroes[0]["pos"] = Vector2(500.0, 500.0)
    installer_world.heroes[1]["pos"] = Vector2(1000.0, 500.0)
    for mine_dir in [Vector2.RIGHT, Vector2.DOWN, Vector2.UP]:
        installer_world.heroes[0]["equipment_cd"] = 0.0
        installer_world._try_equipment_attack(0, mine_dir, 1.0)
    var normal_mines := 0
    for installed in installer_world.deployables:
        if StringName(installed.get("type", &"mine")) == &"mine" and not bool(installed.get("ultimate", false)):
            normal_mines += 1
    if normal_mines != 2:
        push_error("MIMI did not enforce the readable two-mine installation limit")
        quit(1)
        return
    var live_mine: Dictionary = installer_world.deployables[0]
    installer_world.heroes[1]["pos"] = Vector2(live_mine["pos"])
    installer_world._update_deployables(0.80)
    installer_world._update_deployables(0.01)
    if installer_world.deployables.is_empty() or not bool(installer_world.deployables[0]["triggered"]):
        push_error("armed proximity mine did not detect an entering enemy")
        quit(1)
        return
    var mine_target_hp := float(installer_world.heroes[1]["hp"])
    installer_world._update_deployables(0.20)
    installer_world._update_zones(0.20)
    if float(installer_world.heroes[1]["hp"]) < mine_target_hp:
        push_error("proximity mine exploded before its reaction fuse ended")
        quit(1)
        return
    installer_world._update_deployables(0.20)
    installer_world._update_zones(0.02)
    if float(installer_world.heroes[1]["hp"]) >= mine_target_hp:
        push_error("proximity mine did not explode after its visible fuse")
        quit(1)
        return
    var wall_world = WorldScript.new(525)
    wall_world.match_time = 20.0
    wall_world.covers.clear()
    for slot in range(2, wall_world.heroes.size()):
        wall_world.heroes[slot]["alive"] = false
    wall_world.heroes[0]["equipment"] = _equipment_by_id(wall_world, "shield")
    wall_world.heroes[0]["pos"] = Vector2(500.0, 500.0)
    wall_world.heroes[1]["pos"] = Vector2(850.0, 500.0)
    wall_world._try_equipment_attack(0, Vector2.RIGHT, 1.0)
    if wall_world.deployables.size() != 1 or StringName(wall_world.deployables[0].get("type", &"mine")) != &"wall":
        push_error("WARD did not launch a bulldozer wall")
        quit(1)
        return
    var starting_wall_pos: Vector2 = wall_world.deployables[0]["pos"]
    if wall_world._hazard_escape_vector(1).length_squared() < 0.5:
        push_error("CPU did not understand the incoming moving wall lane")
        quit(1)
        return
    var wall_target_hp := float(wall_world.heroes[1]["hp"])
    wall_world._update_deployables(0.17)
    if Vector2(wall_world.deployables[0]["pos"]).distance_to(starting_wall_pos) > 0.1 or float(wall_world.heroes[1]["hp"]) < wall_target_hp:
        push_error("bulldozer wall moved or hit before its launch warning ended")
        quit(1)
        return
    wall_world._update_deployables(0.02)
    wall_world._update_deployables(0.50)
    if wall_world.deployables.is_empty() or Vector2(wall_world.deployables[0]["pos"]).x <= starting_wall_pos.x:
        push_error("bulldozer wall did not travel forward after its warning")
        quit(1)
        return
    if float(wall_world.heroes[1]["hp"]) >= wall_target_hp or Vector2(wall_world.heroes[1]["launch_vel"]).x <= 0.0:
        push_error("moving wall did not sweep and launch a stationary enemy")
        quit(1)
        return
    var hp_after_wall_hit := float(wall_world.heroes[1]["hp"])
    wall_world._update_deployables(0.30)
    if float(wall_world.heroes[1]["hp"]) < hp_after_wall_hit:
        push_error("one moving wall damaged the same enemy more than once")
        quit(1)
        return
    var charge_world = WorldScript.new(227)
    charge_world.heroes[0]["equipment"] = _equipment_by_id(charge_world, "blade")
    charge_world.heroes[0]["attack_lock_time"] = 0.3
    charge_world.heroes[0]["fire_cd"] = 0.3
    charge_world._begin_skill_charge(0, Vector2.RIGHT)
    charge_world._continue_skill_charge(0, 0.72, Vector2.RIGHT)
    if not bool(charge_world.heroes[0]["charging_skill"]) or float(charge_world.heroes[0]["attack_lock_time"]) > 0.0:
        push_error("charged skill did not cancel normal recovery")
        quit(1)
        return
    charge_world._release_skill_charge(0, Vector2.RIGHT)
    if bool(charge_world.heroes[0]["charging_skill"]) or float(charge_world.heroes[0]["equipment_cd"]) <= 0.0 or charge_world.zones.is_empty():
        push_error("charged skill did not release into its career attack")
        quit(1)
        return
    var cancel_world = WorldScript.new(228)
    cancel_world._begin_skill_charge(0, Vector2.RIGHT)
    cancel_world.heroes[0]["ultimate_charge"] = cancel_world.ULTIMATE_MAX
    cancel_world._try_ultimate(0, Vector2.RIGHT)
    if bool(cancel_world.heroes[0]["charging_skill"]) or float(cancel_world.heroes[0]["ultimate_charge"]) >= cancel_world.ULTIMATE_MAX:
        push_error("ultimate did not cancel a charged action")
        quit(1)
        return
    cancel_world._begin_skill_charge(0, Vector2.RIGHT)
    cancel_world._try_mobility(0, Vector2.RIGHT)
    if bool(cancel_world.heroes[0]["charging_skill"]) or float(cancel_world.heroes[0]["mobility_cd"]) <= 0.0:
        push_error("mobility did not cancel a charged action")
        quit(1)
        return
    var gate_world = WorldScript.new(226)
    var score_before_hit := float(gate_world.heroes[0]["score"])
    gate_world._damage_hero(0, 1, 10.0)
    if float(gate_world.heroes[0]["score"]) <= score_before_hit:
        push_error("confirmed hero damage did not update the score")
        quit(1)
        return
    var protected_core_hp := float(gate_world.cores[1]["hp"])
    gate_world._damage_core(0, 1, 50.0)
    if float(gate_world.cores[1]["hp"]) != protected_core_hp:
        push_error("protected core took damage while its owner was active")
        quit(1)
        return
    gate_world.heroes[1]["cc_time"] = 1.0
    gate_world._damage_core(0, 1, 50.0)
    if float(gate_world.cores[1]["hp"]) >= protected_core_hp:
        push_error("CC did not expose the owner's core")
        quit(1)
        return
    var cc_damaged_hp := float(gate_world.cores[1]["hp"])
    gate_world.heroes[1]["cc_time"] = 0.0
    gate_world.heroes[1]["alive"] = false
    gate_world._damage_core(0, 1, 50.0)
    if float(gate_world.cores[1]["hp"]) >= cc_damaged_hp:
        push_error("downed owner did not expose the core")
        quit(1)
        return
    var zone_core_world = WorldScript.new(228)
    zone_core_world.match_time = 20.0
    zone_core_world.heroes[1]["cc_time"] = 1.0
    var zone_core_hp := float(zone_core_world.cores[1]["hp"])
    zone_core_world._add_zone(0, Vector2(zone_core_world.cores[1]["pos"]), 90.0, 0.0, 30.0, &"equipment", 0.0, 0.0, "CORE ZONE", Color.WHITE)
    zone_core_world._update_zones(1.0 / 60.0)
    if float(zone_core_world.cores[1]["hp"]) >= zone_core_hp:
        push_error("zone skill did not damage an exposed core")
        quit(1)
        return
    var ability_ids := ["scatter", "rail", "mortar", "leech", "breaker", "burst", "blade", "brawler", "bomb", "spear", "chain", "shield"]
    if zone_core_world.equipment_defs.size() != 12:
        push_error("expanded roster did not contain twelve distinct weapon careers")
        quit(1)
        return
    for ability_index in range(ability_ids.size()):
        var equipment_id: String = ability_ids[ability_index]
        if equipment_id != "shield" and not _run_ability_core_check(equipment_id, false, 300 + ability_index):
            push_error("equipment skill could not damage an exposed core: %s" % equipment_id)
            quit(1)
            return
        if not _run_ability_core_check(equipment_id, true, 400 + ability_index):
            push_error("ultimate could not damage an exposed core: %s" % equipment_id)
            quit(1)
            return
    var armor_world = WorldScript.new(520)
    armor_world.match_time = 20.0
    armor_world.heroes[0]["equipment"] = _equipment_by_id(armor_world, "shield")
    armor_world.heroes[0]["ultimate_charge"] = armor_world.ULTIMATE_MAX
    armor_world._try_ultimate(0, Vector2.RIGHT)
    if armor_world.ultimate_focus_slot != 0 or armor_world.ultimate_focus_time <= 0.0 or float(armor_world.heroes[0]["super_armor_time"]) < 1.0 or float(armor_world.heroes[0]["super_armor_strength"]) < 0.99:
        push_error("ultimate did not start its camera focus and career armor window")
        quit(1)
        return
    armor_world.heroes[0]["evade_time"] = 0.0
    armor_world.heroes[1]["normal_interval"] = 0.25
    var armored_hp := float(armor_world.heroes[0]["hp"])
    armor_world._damage_hero(1, 0, 8.0, &"normal", 0.0, 160.0, Vector2(armor_world.heroes[1]["pos"]), "", &"hit_spark", true)
    if float(armor_world.heroes[0]["hp"]) >= armored_hp or float(armor_world.heroes[0]["hitstun_time"]) > 0.0 or Vector2(armor_world.heroes[0]["launch_vel"]).length() > 0.01:
        push_error("ultimate armor became invulnerability or failed to resist stagger and launch")
        quit(1)
        return
    armor_world._damage_hero(1, 0, 2.0, &"equipment", 1.2, 0.0, Vector2(armor_world.heroes[1]["pos"]), "", &"chain_arc", false, &"root")
    if float(armor_world.heroes[0]["root_time"]) > 0.0 or float(armor_world.heroes[0]["cc_time"]) > 0.0:
        push_error("ultimate armor did not resist crowd control")
        quit(1)
        return
    var enemy_ultimate_world = WorldScript.new(521)
    enemy_ultimate_world.heroes[1]["ultimate_charge"] = enemy_ultimate_world.ULTIMATE_MAX
    enemy_ultimate_world._try_ultimate(1, Vector2.LEFT)
    if enemy_ultimate_world.ultimate_focus_slot >= 0 or enemy_ultimate_world.ultimate_focus_time > 0.0:
        push_error("enemy ultimate stole the player camera")
        quit(1)
        return
    var control_world = WorldScript.new(522)
    control_world.match_time = 20.0
    control_world.covers.clear()
    for slot in range(2, control_world.heroes.size()):
        control_world.heroes[slot]["alive"] = false
    control_world.heroes[0]["equipment"] = _equipment_by_id(control_world, "chain")
    control_world.heroes[0]["pos"] = Vector2(500.0, 500.0)
    control_world.heroes[1]["pos"] = Vector2(706.0, 500.0)
    control_world._begin_skill_charge(0, Vector2.RIGHT)
    control_world._continue_skill_charge(0, 1.15, Vector2.RIGHT)
    control_world._release_skill_charge(0, Vector2.RIGHT)
    control_world._update_zones(0.20)
    if float(control_world.heroes[1]["root_time"]) < 1.45 or not control_world._core_exposed(1):
        push_error("RIVA charged skill did not root its target and expose the core")
        quit(1)
        return
    control_world.heroes[1]["hitstun_time"] = 0.0
    control_world.heroes[1]["launch_time"] = 0.0
    var rooted_pos: Vector2 = control_world.heroes[1]["pos"]
    control_world._try_mobility(1, Vector2.RIGHT)
    if not Vector2(control_world.heroes[1]["pos"]).is_equal_approx(rooted_pos) or float(control_world.heroes[1]["mobility_cd"]) > 0.0:
        push_error("rooted target escaped with SPACE")
        quit(1)
        return
    control_world.heroes[1]["ultimate_charge"] = control_world.ULTIMATE_MAX
    control_world._try_ultimate(1, Vector2.LEFT)
    if float(control_world.heroes[1]["ultimate_charge"]) >= control_world.ULTIMATE_MAX:
        push_error("root incorrectly blocked the counterplay ultimate")
        quit(1)
        return
    control_world.heroes[1]["super_armor_time"] = 0.0
    control_world.heroes[1]["super_armor_strength"] = 0.0
    control_world.heroes[1]["ultimate_charge"] = control_world.ULTIMATE_MAX
    control_world._damage_hero(0, 1, 2.0, &"ultimate", 0.82, 0.0, Vector2(control_world.heroes[0]["pos"]), "", &"stun_burst", false, &"stun")
    var charge_before_stun_try := float(control_world.heroes[1]["ultimate_charge"])
    control_world._try_ultimate(1, Vector2.LEFT)
    if float(control_world.heroes[1]["stun_time"]) < 0.80 or float(control_world.heroes[1]["ultimate_charge"]) != charge_before_stun_try:
        push_error("stun did not lock all combat inputs")
        quit(1)
        return
    var chain_ultimate_world = WorldScript.new(523)
    chain_ultimate_world.heroes[0]["equipment"] = _equipment_by_id(chain_ultimate_world, "chain")
    chain_ultimate_world.heroes[0]["ultimate_charge"] = chain_ultimate_world.ULTIMATE_MAX
    chain_ultimate_world._try_ultimate(0, Vector2.RIGHT)
    var root_pulses := 0
    var stun_finishers := 0
    for zone in chain_ultimate_world.zones:
        if StringName(zone.get("control_kind", &"slow")) == &"root":
            root_pulses += 1
        elif StringName(zone.get("control_kind", &"slow")) == &"stun" and float(zone.get("knockback", 0.0)) > 200.0:
            stun_finishers += 1
    if root_pulses != 2 or stun_finishers != 1:
        push_error("BLACK CAROUSEL did not contain two pulls and a stun fling")
        quit(1)
        return
    var facing_world = WorldScript.new(229)
    facing_world.covers.clear()
    for slot in range(2, facing_world.heroes.size()):
        facing_world.heroes[slot]["alive"] = false
    facing_world.heroes[0]["equipment"] = _equipment_by_id(facing_world, "blade")
    facing_world.heroes[0]["pos"] = Vector2(500.0, 500.0)
    facing_world.heroes[0]["facing"] = Vector2.RIGHT
    facing_world.heroes[0]["aim"] = Vector2.RIGHT
    facing_world.heroes[0]["fire_cd"] = 0.0
    facing_world.heroes[1]["pos"] = Vector2(525.0, 390.0)
    facing_world._apply_human({"move":Vector2.RIGHT, "aim":Vector2(facing_world.heroes[1]["pos"]), "primary":true, "equipment":false, "equipment_pressed":false, "equipment_released":false, "ultimate":false, "mobility":false})
    var assisted_dir := Vector2(facing_world.heroes[0]["aim"])
    if int(facing_world.heroes[0]["combo_target"]) != 1 or assisted_dir.dot(Vector2(500.0, 500.0).direction_to(Vector2(525.0, 390.0))) < 0.99:
        push_error("normal attack did not follow mouse aim and assist the exposed target")
        quit(1)
        return
    var mobility_world = WorldScript.new(230)
    mobility_world.match_time = 20.0
    mobility_world.heroes[1]["normal_interval"] = 0.22
    mobility_world.heroes[1]["combo_target"] = 0
    var mobility_start: Vector2 = mobility_world.heroes[0]["pos"]
    mobility_world._damage_hero(1, 0, 5.0, &"normal", 0.0, 18.0, Vector2(mobility_world.heroes[1]["pos"]), "", &"hit_spark", false)
    if float(mobility_world.heroes[0]["combo_capture_time"]) <= float(mobility_world.heroes[0]["hitstun_time"]) or Vector2(mobility_world.heroes[0]["launch_vel"]).length() > 0.01:
        push_error("middle normal hit did not hold the combo target without launching it")
        quit(1)
        return
    mobility_world._try_mobility(0, Vector2.RIGHT)
    if not Vector2(mobility_world.heroes[0]["pos"]).is_equal_approx(mobility_start) or float(mobility_world.heroes[0]["mobility_cd"]) > 0.0:
        push_error("emergency dodge was allowed during the exact hit-lock window")
        quit(1)
        return
    mobility_world._update_timers(float(mobility_world.heroes[0]["hitstun_time"]) + 0.01)
    mobility_world._try_mobility(0, Vector2.RIGHT)
    if Vector2(mobility_world.heroes[0]["pos"]).is_equal_approx(mobility_start) or float(mobility_world.heroes[0]["mobility_cd"]) <= 0.0 or float(mobility_world.heroes[0]["combo_capture_time"]) > 0.0 or float(mobility_world.heroes[0]["combo_immunity"]) <= 0.0:
        push_error("emergency dodge did not break the combo during the post-hit escape window")
        quit(1)
        return
    var bomb_world = WorldScript.new(231)
    bomb_world.match_time = 20.0
    bomb_world.covers.clear()
    for slot in range(2, bomb_world.heroes.size()):
        bomb_world.heroes[slot]["alive"] = false
    bomb_world.heroes[0]["equipment"] = _equipment_by_id(bomb_world, "bomb")
    bomb_world.heroes[0]["pos"] = Vector2(500.0, 500.0)
    bomb_world.heroes[0]["facing"] = Vector2.RIGHT
    bomb_world.heroes[0]["aim"] = Vector2.RIGHT
    bomb_world.heroes[0]["fire_cd"] = 0.0
    bomb_world.heroes[1]["pos"] = Vector2(760.0, 500.0)
    var bomb_hp := float(bomb_world.heroes[1]["hp"])
    bomb_world._try_normal_attack(0, Vector2.RIGHT)
    if bomb_world.projectiles.size() != 1 or not bool(bomb_world.projectiles[0].get("arc", false)) or not bomb_world.zones.is_empty():
        push_error("bomb normal did not launch a readable arc projectile")
        quit(1)
        return
    bomb_world._update_projectiles(0.20)
    if float(bomb_world.heroes[1]["hp"]) < bomb_hp or bomb_world.zones.size() > 0:
        push_error("bomb normal exploded before its visible landing")
        quit(1)
        return
    bomb_world._update_projectiles(0.30)
    bomb_world._update_zones(0.02)
    if float(bomb_world.heroes[1]["hp"]) >= bomb_hp:
        push_error("bomb normal did not explode on its telegraphed landing point")
        quit(1)
        return
    var combo_world = WorldScript.new(232)
    combo_world.match_time = 20.0
    var combo_max_hp := float(combo_world.heroes[1]["max_hp"])
    for hit in range(4):
        combo_world.heroes[0]["normal_interval"] = 0.20
        combo_world._damage_hero(0, 1, 50.0, &"normal", 0.0, 22.0, Vector2(combo_world.heroes[0]["pos"]), "COMBO TEST", &"hit_spark", hit == 3)
    if not bool(combo_world.heroes[1]["alive"]) or int(combo_world.heroes[1]["combo_hits"]) != 4 or Vector2(combo_world.heroes[1]["launch_vel"]).length() < 1200.0:
        push_error("one attack string killed from full health or lacked a fast finisher launch")
        quit(1)
        return
    var expected_floor := combo_max_hp * (1.0 - float(combo_world.heroes[1]["equipment"]["combo_cap_ratio"]))
    if float(combo_world.heroes[1]["hp"]) < expected_floor - 0.01:
        push_error("single-combo damage exceeded the career cap")
        quit(1)
        return
    var combo_count := 1
    while bool(combo_world.heroes[1]["alive"]) and combo_count < 5:
        combo_world._update_timers(1.2)
        combo_count += 1
        for hit in range(4):
            combo_world._damage_hero(0, 1, 50.0, &"normal", 0.0, 22.0, Vector2(combo_world.heroes[0]["pos"]), "COMBO TEST", &"hit_spark", hit == 3)
            if not bool(combo_world.heroes[1]["alive"]):
                break
    if bool(combo_world.heroes[1]["alive"]) or combo_count < 4 or combo_count > 5:
        push_error("career did not fall within the four-to-five combo target")
        quit(1)
        return
    var streak_world = WorldScript.new(233)
    streak_world.heroes[0]["hp"] = float(streak_world.heroes[0]["max_hp"]) * 0.45
    streak_world.heroes[0]["equipment_cd"] = 3.0
    streak_world.heroes[0]["mobility_cd"] = 3.0
    streak_world.heroes[0]["ultimate_charge"] = 0.0
    var streak_hp_before := float(streak_world.heroes[0]["hp"])
    streak_world._down_hero(0, 1)
    if int(streak_world.heroes[0]["kill_streak"]) != 1 or float(streak_world.heroes[0]["hp"]) <= streak_hp_before or float(streak_world.heroes[0]["equipment_cd"]) >= 3.0 or float(streak_world.heroes[0]["ultimate_charge"]) <= 0.0:
        push_error("surviving killer did not receive bounded momentum rewards")
        quit(1)
        return
    streak_world.heroes[1]["alive"] = true
    streak_world.heroes[1]["eliminated"] = false
    streak_world.heroes[1]["hp"] = float(streak_world.heroes[1]["max_hp"])
    streak_world._down_hero(0, 1)
    if int(streak_world.heroes[0]["kill_streak"]) != 2 or streak_world.streak_callout_ticks <= 0 or streak_world.streak_callout_shutdown:
        push_error("second surviving kill did not start the visible kill-streak announcement")
        quit(1)
        return
    streak_world.heroes[2]["kill_streak"] = 4
    var shutdown_score := float(streak_world.heroes[0]["score"])
    streak_world._down_hero(0, 2)
    if int(streak_world.heroes[2]["kill_streak"]) != 0 or not streak_world.streak_callout_shutdown or float(streak_world.heroes[0]["score"]) < shutdown_score + 210.0:
        push_error("ending a four-kill streak did not reset it and pay a shutdown bonus")
        quit(1)
        return
    if streak_world._streak_damage_multiplier(0) <= 1.0 or streak_world._streak_damage_multiplier(0) > 1.101 or streak_world._streak_move_multiplier(0) > 1.061:
        push_error("kill-streak combat momentum was missing or exceeded its cap")
        quit(1)
        return
    streak_world._down_hero(3, 0)
    if int(streak_world.heroes[0]["kill_streak"]) != 0:
        push_error("death did not clear the killer's active streak advantage")
        quit(1)
        return
    var bounce_world = WorldScript.new(230)
    bounce_world.heroes[0]["pos"] = Vector2(bounce_world.ARENA_MARGIN + bounce_world.HERO_RADIUS + 1.0, 220.0)
    bounce_world.heroes[0]["launch_vel"] = Vector2(-800.0, 0.0)
    bounce_world.heroes[0]["launch_time"] = 1.0
    bounce_world.heroes[0]["launch_owner"] = 1
    bounce_world.heroes[0]["launch_trail"] = [Vector2(bounce_world.heroes[0]["pos"])]
    var bounce_hp := float(bounce_world.heroes[0]["hp"])
    bounce_world._move_launched_hero(0, 0.1)
    if int(bounce_world.heroes[0]["wall_bounces"]) != 1 or float(bounce_world.heroes[0]["hp"]) >= bounce_hp or Vector2(bounce_world.heroes[0]["launch_vel"]).x <= 0.0:
        push_error("launched hero did not bounce, take wall damage and reflect")
        quit(1)
        return
    bounce_world.heroes[0]["launch_trail"].append(Vector2(bounce_world.heroes[0]["pos"]) + Vector2.RIGHT * 40.0)
    bounce_world.heroes[0]["launch_time"] = 0.0
    bounce_world.heroes[0]["launch_trail_fade"] = 0.34
    bounce_world._update_timers(0.17)
    if bounce_world.heroes[0]["launch_trail"].is_empty() or absf(float(bounce_world.heroes[0]["launch_trail_fade"]) - 0.17) > 0.01:
        push_error("launch trajectory did not enter its timed fade after motion ended")
        quit(1)
        return
    bounce_world._update_timers(0.18)
    if not bounce_world.heroes[0]["launch_trail"].is_empty():
        push_error("launch trajectory did not clear after its fade completed")
        quit(1)
        return
    var respawn_world = WorldScript.new(227)
    respawn_world._down_hero(0, 1)
    if respawn_world.knockouts.is_empty():
        push_error("downed hero did not create a visible knockout trajectory")
        quit(1)
        return
    if bool(respawn_world.heroes[1]["alive"]) or not bool(respawn_world.heroes[1]["eliminated"]):
        push_error("downed hero was not eliminated")
        quit(1)
        return
    respawn_world.knockouts[0]["finished"] = true
    respawn_world.knockouts[0]["vel"] = Vector2.ZERO
    respawn_world.knockouts[0]["time"] = 0.42
    respawn_world._update_knockouts(0.20)
    if respawn_world.knockouts.is_empty() or float(respawn_world.knockouts[0]["time"]) >= 0.42:
        push_error("knockout trajectory did not remain for its final fade")
        quit(1)
        return
    respawn_world._update_knockouts(0.23)
    if not respawn_world.knockouts.is_empty():
        push_error("knockout trajectory remained after its fade completed")
        quit(1)
        return
    respawn_world._update_timers(11.0)
    if bool(respawn_world.heroes[1]["alive"]) or not bool(respawn_world.heroes[1]["eliminated"]):
        push_error("eliminated hero returned after death")
        quit(1)
        return
    var ranking := respawn_world.leaderboard()
    if ranking.size() != 6:
        push_error("scoreboard did not include all combatants")
        quit(1)
        return
    for rank in range(1, ranking.size()):
        if float(ranking[rank - 1]["score"]) < float(ranking[rank]["score"]):
            push_error("scoreboard was not sorted by score")
            quit(1)
            return
    var cover_world = WorldScript.new(224)
    cover_world.heroes[0]["equipment"] = _equipment_by_id(cover_world, "rail")
    cover_world.heroes[0]["fire_cd"] = 0.0
    cover_world.heroes[0]["normal_step"] = 0
    cover_world.heroes[0]["normal_chain_time"] = 0.0
    cover_world.heroes[0]["pos"] = Vector2(850.0, 700.0)
    cover_world.heroes[1]["pos"] = Vector2(1120.0, 700.0)
    var protected_hp := float(cover_world.heroes[1]["hp"])
    cover_world._try_normal_attack(0, Vector2.RIGHT)
    for frame in range(20):
        cover_world._update_projectiles(1.0 / 60.0)
    if float(cover_world.heroes[1]["hp"]) != protected_hp or not cover_world.projectiles.is_empty():
        push_error("cover did not block a projectile")
        quit(1)
        return
    cover_world.heroes[0]["ultimate_charge"] = cover_world.ULTIMATE_MAX
    cover_world._try_ultimate(0, Vector2.RIGHT)
    if int(cover_world.heroes[0]["ultimates"]) != 1 or float(cover_world.heroes[0]["ultimate_charge"]) > 0.0:
        push_error("charged ultimate could not be used")
        quit(1)
        return
    var finish_world = WorldScript.new(531)
    finish_world.heroes[0]["launch_trail"] = [Vector2.ZERO, Vector2.RIGHT * 80.0]
    finish_world.heroes[0]["launch_trail_fade"] = 0.34
    finish_world.impact_ticks = 8
    finish_world._add_effect(&"hit_spark", Vector2(400.0, 400.0), 60.0, 0.50, Color.WHITE)
    finish_world._spawn_projectile(0, Vector2.RIGHT, 1.0, 200.0, 4.0, 1.0, &"normal")
    for finish_slot in range(1, finish_world.heroes.size()):
        finish_world.heroes[finish_slot]["alive"] = false
        finish_world.heroes[finish_slot]["eliminated"] = true
    finish_world._check_end()
    if finish_world.result == &"playing" or not finish_world.projectiles.is_empty():
        push_error("match finish did not clear unresolved combat clutter")
        quit(1)
        return
    var finish_tick: int = int(finish_world.tick)
    var finish_effect_time := float(finish_world.effects[0]["time"])
    var finish_impact_ticks := int(finish_world.impact_ticks)
    finish_world.step_tick({}, 0.17)
    if finish_world.tick != finish_tick + 1 or finish_world.impact_ticks >= finish_impact_ticks or float(finish_world.effects[0]["time"]) >= finish_effect_time or finish_world.heroes[0]["launch_trail"].is_empty():
        push_error("post-match visual effects froze instead of fading")
        quit(1)
        return
    finish_world.step_tick({}, 0.18)
    if not finish_world.heroes[0]["launch_trail"].is_empty():
        push_error("post-match launch trajectory did not finish fading")
        quit(1)
        return
    var house_world = WorldScript.new(541)
    house_world.heroes[1]["cc_time"] = 1.0
    house_world.cores[1]["hp"] = 5.0
    house_world._damage_core(0, 1, 50.0)
    if bool(house_world.cores[1]["alive"]):
        push_error("exposed house could not be destroyed")
        quit(1)
        return
    if not bool(house_world.heroes[1]["alive"]) or bool(house_world.heroes[1]["eliminated"]) or house_world.result != &"playing":
        push_error("destroying a house eliminated its owner")
        quit(1)
        return
    var zone_world = WorldScript.new(542)
    zone_world.start_countdown = 0.0
    if absf(float(zone_world.safe_zone_radius) - float(zone_world.SAFE_ZONE_INITIAL_RADIUS)) > 0.01:
        push_error("safe zone did not start at its initial radius")
        quit(1)
        return
    zone_world.heroes[1]["pos"] = Vector2(40.0, 40.0)
    var zone_hp := float(zone_world.heroes[1]["hp"])
    zone_world._update_safe_zone(0.50)
    if float(zone_world.heroes[1]["hp"]) >= zone_hp:
        push_error("safe-zone exterior did not apply continuous damage")
        quit(1)
        return
    zone_world.heroes[1]["pos"] = Vector2(zone_world.safe_zone_center)
    zone_hp = float(zone_world.heroes[1]["hp"])
    zone_world._update_safe_zone(0.50)
    if absf(float(zone_world.heroes[1]["hp"]) - zone_hp) > 0.001:
        push_error("safe-zone interior kept dealing damage")
        quit(1)
        return
    var radius_before := float(zone_world.safe_zone_radius)
    zone_world._update_safe_zone(12.2)
    if float(zone_world.safe_zone_radius) >= radius_before - 0.5 and not bool(zone_world.safe_zone_shrinking):
        push_error("safe zone did not begin shrinking after its hold phase")
        quit(1)
        return
    var hold_cmd := {
        "move":Vector2.ZERO,
        "aim":Vector2(900, 450),
        "primary":true,
        "equipment":true,
        "equipment_pressed":true,
        "equipment_released":false,
        "ultimate":false,
        "mobility":false,
        "medkit":false
    }
    var dual_world = WorldScript.new(19)
    dual_world.start_countdown = 0.0
    var dual_shots := 0
    for frame in range(90):
        hold_cmd["equipment_pressed"] = frame == 0
        dual_world.step_tick(hold_cmd, 1.0 / 60.0)
    for event in dual_world.event_log.events:
        if event["type"] == &"normal_combo_step" and int(event["actor_id"]) == 0:
            dual_shots += 1
    var left_world = WorldScript.new(19)
    left_world.start_countdown = 0.0
    hold_cmd["equipment"] = false
    hold_cmd["equipment_pressed"] = false
    var left_shots := 0
    for _frame in range(90):
        left_world.step_tick(hold_cmd, 1.0 / 60.0)
    for event in left_world.event_log.events:
        if event["type"] == &"normal_combo_step" and int(event["actor_id"]) == 0:
            left_shots += 1
    if dual_shots > left_shots + 2:
        push_error("holding right+left mouse should not outpace left-click fire rate (dual=%d left=%d)" % [dual_shots, left_shots])
        quit(1)
        return
    print("SMOKE_OK ", JSON.stringify(world.summary()))
    quit(0)
