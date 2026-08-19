extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _init() -> void:
    var completed := 0
    var total_seconds := 0.0
    var earliest_elimination := 999.0
    var worst_dogpile_seconds := 0.0
    var equipment_hits := PackedInt32Array()
    equipment_hits.resize(12)
    var winner_counts := PackedInt32Array()
    winner_counts.resize(12)
    var ultimate_uses := 0
    var equipment_index := {"scatter":0, "rail":1, "mortar":2, "leech":3, "breaker":4, "burst":5, "blade":6, "brawler":7, "bomb":8, "spear":9, "chain":10, "shield":11}
    for seed_offset in range(60):
        var world = WorldScript.new(13000 + seed_offset)
        var event_cursor := 0
        var first_elimination := -1.0
        var dogpile_frames := 0
        for frame in range(13000):
            var angle := float(frame) * 0.009
            var aim := Vector2(1960.0, 1190.0)
            var nearest_distance := INF
            for target in range(1, world.heroes.size()):
                if not bool(world.heroes[target]["alive"]) or bool(world.heroes[target]["eliminated"]):
                    continue
                var target_pos: Vector2 = world.heroes[target]["pos"]
                var distance := Vector2(world.heroes[0]["pos"]).distance_to(target_pos)
                if distance < nearest_distance:
                    nearest_distance = distance
                    aim = target_pos
            world.step_tick({"move":Vector2.RIGHT.rotated(angle), "aim":aim, "primary":true, "equipment":true, "ultimate":true}, 1.0 / 60.0)
            while event_cursor < world.event_log.events.size():
                var event: Dictionary = world.event_log.events[event_cursor]
                if StringName(event["type"]) == &"player_eliminated" and first_elimination < 0.0:
                    first_elimination = world.match_time
                event_cursor += 1
            var counts := PackedInt32Array()
            counts.resize(6)
            for cpu_slot in range(1, world.heroes.size()):
                var target := int(world.heroes[cpu_slot]["target"])
                if target >= 0 and target < counts.size():
                    counts[target] += 1
            var concentrated := false
            for count in counts:
                if count >= 3:
                    concentrated = true
            dogpile_frames = dogpile_frames + 1 if concentrated else 0
            worst_dogpile_seconds = maxf(worst_dogpile_seconds, float(dogpile_frames) / 60.0)
            if world.result != &"playing":
                completed += 1
                total_seconds += world.match_time
                break
        if world.result == &"playing":
            push_error("gang-up stalled for seed %d: %s" % [seed_offset, JSON.stringify(world.summary())])
            quit(1)
            return
        if first_elimination < 0.0:
            push_error("gang-up ended without an elimination event")
            quit(1)
            return
        var winner_equipment := str(world.heroes[world.winner_slot]["equipment"]["id"])
        winner_counts[int(equipment_index[winner_equipment])] += 1
        for slot in range(world.heroes.size()):
            var equipment_id := str(world.heroes[slot]["equipment"]["id"])
            equipment_hits[int(equipment_index[equipment_id])] += int(world.heroes[slot]["equipment_hits"])
            ultimate_uses += int(world.heroes[slot]["ultimates"])
        earliest_elimination = minf(earliest_elimination, first_elimination)
    var average_seconds := total_seconds / float(completed)
    print("PLAYABILITY_SAMPLE ", JSON.stringify({"runs":completed, "average_seconds":average_seconds, "earliest_elimination":earliest_elimination, "worst_dogpile_seconds":worst_dogpile_seconds, "equipment_hits":Array(equipment_hits), "winner_counts":Array(winner_counts), "ultimate_uses":ultimate_uses}))
    if earliest_elimination < 3.0:
        push_error("a player was erased before they could react: %.2f" % earliest_elimination)
        quit(1)
        return
    if average_seconds < 20.0 or average_seconds > 210.01:
        push_error("gang-up match length is outside target: %.2f" % average_seconds)
        quit(1)
        return
    if worst_dogpile_seconds > 7.0:
        push_error("three CPUs held one target for %.2f seconds" % worst_dogpile_seconds)
        quit(1)
        return
    var winning_equipment_count := 0
    var most_wins := 0
    for wins in winner_counts:
        if wins > 0:
            winning_equipment_count += 1
        most_wins = maxi(most_wins, wins)
    if winning_equipment_count < 10 or most_wins > 14:
        push_error("starting equipment is deciding too many matches: %s" % str(winner_counts))
        quit(1)
        return
    for hits in equipment_hits:
        if hits <= 0:
            push_error("one starting equipment never landed a hit: %s" % str(equipment_hits))
            quit(1)
            return
    if ultimate_uses < 250:
        push_error("hit-earned ultimates were too rare: %d" % ultimate_uses)
        quit(1)
        return
    print("PLAYABILITY_OK ", JSON.stringify({"runs":completed, "average_seconds":average_seconds, "earliest_elimination":earliest_elimination, "worst_dogpile_seconds":worst_dogpile_seconds, "equipment_hits":Array(equipment_hits), "winner_counts":Array(winner_counts), "ultimate_uses":ultimate_uses}))
    quit(0)
