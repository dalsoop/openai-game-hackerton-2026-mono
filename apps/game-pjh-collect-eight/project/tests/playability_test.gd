extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _init() -> void:
    var completed := 0
    var total_seconds := 0.0
    var worst_stall := 0.0
    var lowest_participation := 6
    for seed_offset in range(12):
        var world = WorldScript.new(12000 + seed_offset)
        var event_cursor := 0
        var last_deposit_time := 0.0
        var deposited_by := {}
        for frame in range(15000):
            var human_move := Vector2.RIGHT.rotated(float(frame) * 0.011)
            world.step_tick({"move":human_move, "dash":frame % 300 == 0, "interact":true}, 1.0 / 60.0)
            while event_cursor < world.event_log.events.size():
                var event: Dictionary = world.event_log.events[event_cursor]
                if StringName(event["type"]) == &"coin_deposited":
                    worst_stall = maxf(worst_stall, world.round_time - last_deposit_time)
                    last_deposit_time = world.round_time
                    deposited_by[int(event["actor_id"])] = true
                event_cursor += 1
            if world.result != &"playing":
                completed += 1
                total_seconds += world.round_time
                worst_stall = maxf(worst_stall, world.round_time - last_deposit_time)
                lowest_participation = mini(lowest_participation, deposited_by.size())
                break
        if world.result == &"playing":
            push_error("collect-eight stalled for seed %d: %s deposits=%d last=%.2f" % [seed_offset, JSON.stringify(world.summary()), deposited_by.size(), last_deposit_time])
            quit(1)
            return
        if world.round_time < 18.0:
            push_error("collect-eight ended before the heist developed: %.2f" % world.round_time)
            quit(1)
            return
        if deposited_by.size() < 1:
            push_error("too few players could score for seed %d: %d" % [seed_offset, deposited_by.size()])
            quit(1)
            return
    var average_seconds := total_seconds / float(completed)
    if worst_stall > 30.0:
        push_error("collect-eight had a %.2f second no-score stall" % worst_stall)
        quit(1)
        return
    if average_seconds > 160.0:
        push_error("collect-eight average match is too long: %.2f" % average_seconds)
        quit(1)
        return
    print("PLAYABILITY_OK ", JSON.stringify({"runs":completed, "average_seconds":average_seconds, "worst_stall":worst_stall, "lowest_participation":lowest_participation}))
    quit(0)
