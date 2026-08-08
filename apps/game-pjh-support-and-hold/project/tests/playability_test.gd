extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _active_command(world, frame: int) -> Dictionary:
    var actor: Dictionary = world.actors[world.human_slot]
    var aim: Vector2 = Vector2(world.hive_pos)
    var nearest_distance := INF
    for enemy in world.enemies:
        if bool(enemy["alive"]) and int(enemy["lane"]) == int(actor["lane"]):
            var distance := Vector2(actor["pos"]).distance_to(Vector2(enemy["pos"]))
            if distance < nearest_distance:
                nearest_distance = distance
                aim = Vector2(enemy["pos"])
    var can_push: bool = bool(world.hive_vulnerable) and int(world._lane_enemy_count(int(actor["lane"]))) <= 2
    return {
        "move":Vector2(actor["pos"]).direction_to(Vector2(1050.0 if can_push else 520.0, world.lane_y[int(actor["lane"])])),
        "aim":aim,
        "primary":true,
        "ability":frame % 480 == 0,
        "request_ammo":int(actor["ammo"]) < 18,
        "request_med":float(actor["hp"]) < float(actor["hp_max"]) * 0.4,
        "request_barrier":frame % 900 == 0,
        "cycle_supply":false,
        "target_actor":-1
    }

func _run(seed: int, active: bool) -> Dictionary:
    var world = WorldScript.new(seed)
    for frame in range(12000):
        var command := _active_command(world, frame) if active else {"move":Vector2.ZERO, "aim":world.hive_pos, "primary":false, "ability":false, "request_ammo":false, "request_med":false, "request_barrier":false, "cycle_supply":false, "target_actor":-1}
        world.step_tick(command, 1.0 / 60.0)
        if world.result != &"playing":
            break
    return world.summary()

func _init() -> void:
    var active_wins := 0
    var idle_wins := 0
    var active_hp_total := 0.0
    var active_destroyed := 0
    var active_revives := 0
    var active_lane_covers := 0
    var active_summaries: Array[Dictionary] = []
    for seed_offset in range(3):
        var active_result := _run(16000 + seed_offset, true)
        active_summaries.append(active_result)
        var idle_result := _run(17000 + seed_offset, false)
        if active_result["result"] == "victory":
            active_wins += 1
            active_hp_total += float(active_result["base_hp"])
            active_destroyed += int(active_result["deliveries_destroyed"])
            active_revives += int(active_result["support_revives"])
            active_lane_covers += int(active_result["lane_covers"])
        if idle_result["result"] == "victory":
            idle_wins += 1
    if active_wins < 2:
        push_error("active player could not reliably complete support operation: %d / 3" % active_wins)
        quit(1)
        return
    if idle_wins > 1:
        push_error("support CPUs still auto-win without the player: %d / 3" % idle_wins)
        quit(1)
        return
    if active_revives < 1 or active_lane_covers < 1:
        push_error("support cascade did not produce rescue and lane-cover events: revives=%d covers=%d" % [active_revives, active_lane_covers])
        quit(1)
        return
    var average_active_hp := active_hp_total / float(active_wins)
    if average_active_hp > 1275.0:
        push_error("active support victories have no pressure: %.2f HP runs=%s" % [average_active_hp, JSON.stringify(active_summaries)])
        quit(1)
        return
    print("PLAYABILITY_OK ", JSON.stringify({"active_wins":active_wins, "idle_wins":idle_wins, "average_active_hp":average_active_hp, "destroyed_deliveries":active_destroyed, "support_revives":active_revives, "lane_covers":active_lane_covers}))
    quit(0)
