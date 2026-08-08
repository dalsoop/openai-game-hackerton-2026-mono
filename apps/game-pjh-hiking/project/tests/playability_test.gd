extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _init() -> void:
    var start_world = WorldScript.new(777)
    var human_start: Vector2 = start_world.players[0]["pos"]
    var cpu_start: Vector2 = start_world.players[1]["pos"]
    for frame in range(179):
        start_world.step_tick({"move":Vector2.UP}, 1.0 / 60.0)
    if Vector2(start_world.players[0]["pos"]) != human_start or Vector2(start_world.players[1]["pos"]) != cpu_start:
        push_error("a racer moved before the shared start signal")
        quit(1)
        return
    start_world.step_tick({"move":Vector2.UP}, 1.0 / 60.0)
    if Vector2(start_world.players[0]["pos"]).y >= human_start.y or Vector2(start_world.players[1]["pos"]).y >= cpu_start.y:
        push_error("human and CPU did not launch together on GO")
        quit(1)
        return

    var first_wave_cpu_deaths := 0
    var first_wave_survivors := 0
    var completed_runs := 0
    var completion_frames := 0
    var seeds := 12
    for seed_offset in range(seeds):
        var world = WorldScript.new(7000 + seed_offset)
        var counted_events := 0
        var stage_one_cpu_deaths := {}
        for frame in range(2400):
            world.step_tick({"move":Vector2.UP, "build":false, "bomb":false, "web":false, "interact":true}, 1.0 / 60.0)
            while counted_events < world.event_log.events.size():
                var event: Dictionary = world.event_log.events[counted_events]
                if StringName(event["type"]) == &"climber_died" and int(event["target_id"]) > 0:
                    stage_one_cpu_deaths[int(event["target_id"])] = true
                counted_events += 1
            if world.stage_index > 0:
                break
        first_wave_cpu_deaths += stage_one_cpu_deaths.size()
        first_wave_survivors += 5 - stage_one_cpu_deaths.size()

    for seed_offset in range(6):
        var world = WorldScript.new(9000 + seed_offset)
        for frame in range(10800):
            world.step_tick({"move":Vector2.UP, "build":frame % 300 == 0, "bomb":frame % 720 == 0, "web":false, "interact":true}, 1.0 / 60.0)
            if world.result == &"won":
                completed_runs += 1
                completion_frames += frame + 1
                break
            if world.has_invalid_numbers():
                push_error("invalid number in seed %d" % seed_offset)
                quit(1)
                return

    var survival_ratio := float(first_wave_survivors) / float(seeds * 5)
    if survival_ratio < 0.68:
        push_error("CPU first-obstacle survival too low: %.3f (%d deaths)" % [survival_ratio, first_wave_cpu_deaths])
        quit(1)
        return
    if completed_runs < 5:
        push_error("too few full matches completed: %d / 6" % completed_runs)
        quit(1)
        return
    var average_completion_seconds := float(completion_frames) / float(completed_runs * 60)
    if average_completion_seconds < 75.0:
        push_error("hike still resolves before rescue tension can build: %.2f seconds" % average_completion_seconds)
        quit(1)
        return
    print("PLAYABILITY_OK ", JSON.stringify({"first_wave_survival":survival_ratio, "cpu_deaths":first_wave_cpu_deaths, "completed_runs":completed_runs, "average_completion_seconds":average_completion_seconds}))
    quit(0)
