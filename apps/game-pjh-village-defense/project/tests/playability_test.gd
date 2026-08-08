extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _active_command(world, frame: int) -> Dictionary:
    var aim: Vector2 = world.center
    var nearest_distance := INF
    for enemy in world.enemies:
        if bool(enemy["alive"]):
            var distance := Vector2(world.heroes[0]["pos"]).distance_to(Vector2(enemy["pos"]))
            if distance < nearest_distance:
                nearest_distance = distance
                aim = Vector2(enemy["pos"])
    return {
        "move":Vector2(world.heroes[0]["pos"]).direction_to(world.center.lerp(aim, 0.45)),
        "aim":aim,
        "primary":true,
        "skill":frame % 360 == 0,
        "stasis":frame % 900 == 0,
        "panic":world.village_hp < 450.0 and frame % 720 == 0,
        "upgrade":frame % 120 == 0
    }

func _party_actor_command(world, actor_index: int, frame: int) -> Dictionary:
    var hero: Dictionary = world.heroes[actor_index]
    var aim: Vector2 = world.center
    var nearest_distance := INF
    for enemy in world.enemies:
        if bool(enemy["alive"]):
            var distance := Vector2(hero["pos"]).distance_to(Vector2(enemy["pos"]))
            if distance < nearest_distance:
                nearest_distance = distance
                aim = Vector2(enemy["pos"])
    return {
        "move":Vector2(hero["pos"]).direction_to(world.center.lerp(aim, 0.50)),
        "aim":aim,
        "primary":true,
        "skill":frame % (330 + actor_index * 30) == 0,
        "stasis":frame % (840 + actor_index * 90) == 0,
        "panic":false,
        "upgrade":frame % 120 == 0
    }

func _run(seed: int, active: bool) -> Dictionary:
    var world = WorldScript.new(seed)
    for frame in range(18000):
        var command := _active_command(world, frame) if active else {"move":Vector2.ZERO, "aim":world.center, "primary":false, "skill":false, "stasis":false, "panic":false, "upgrade":false}
        world.step_tick(command, 1.0 / 60.0)
        if world.result != &"playing":
            break
    return world.summary()

func _init() -> void:
    var active_wins := 0
    var idle_wins := 0
    var active_hp_total := 0.0
    var idle_hp_total := 0.0
    for seed_offset in range(3):
        var active_result := _run(14000 + seed_offset, true)
        var idle_result := _run(15000 + seed_offset, false)
        if active_result["result"] == "victory":
            active_wins += 1
            active_hp_total += float(active_result["village_hp"])
        if idle_result["result"] == "victory":
            idle_wins += 1
            idle_hp_total += float(idle_result["village_hp"])
    if active_wins < 2:
        push_error("active player could not reliably save the village: %d / 3" % active_wins)
        quit(1)
        return
    if idle_wins > 1:
        push_error("CPUs still auto-win without the player: %d / 3 active_hp=%.2f idle_hp=%.2f" % [idle_wins, active_hp_total / float(maxi(1, active_wins)), idle_hp_total / float(maxi(1, idle_wins))])
        quit(1)
        return
    var average_active_hp := active_hp_total / float(active_wins)
    if average_active_hp > 900.0:
        push_error("active victories have no pressure: %.2f HP" % average_active_hp)
        quit(1)
        return
    var party_world = WorldScript.new(14500)
    for frame in range(18000):
        party_world.step_tick({"party_ready":true, "p1":_party_actor_command(party_world, 0, frame), "p2":_party_actor_command(party_world, 1, frame)}, 1.0 / 60.0)
        if party_world.result != &"playing":
            break
    if party_world.result != &"victory":
        push_error("two-player party could not finish the defense")
        quit(1)
        return
    if party_world.gate_collapses < 1 or party_world.gate_repairs < 1:
        push_error("party defense never produced a gate collapse/reopen story: falls=%d reopens=%d" % [party_world.gate_collapses, party_world.gate_repairs])
        quit(1)
        return
    var total_party_kills := 0
    var highest_party_kills := 0
    for kills in party_world.summary()["hero_kills"]:
        total_party_kills += int(kills)
        highest_party_kills = maxi(highest_party_kills, int(kills))
    var highest_kill_share := float(highest_party_kills) / float(maxi(1, total_party_kills))
    if highest_kill_share > 0.48:
        push_error("last-hit competition collapsed into one carry: %.3f %s" % [highest_kill_share, JSON.stringify(party_world.summary()["hero_kills"])])
        quit(1)
        return
    print("PLAYABILITY_OK ", JSON.stringify({"active_wins":active_wins, "idle_wins":idle_wins, "average_active_hp":average_active_hp, "party_highest_kill_share":highest_kill_share, "party_kills":party_world.summary()["hero_kills"], "gate_collapses":party_world.gate_collapses, "gate_repairs":party_world.gate_repairs}))
    quit(0)
