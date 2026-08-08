extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _init() -> void:
    var party_world = WorldScript.new(332)
    for bank in party_world.banks:
        if Vector2(bank["pos"]).x >= WorldScript.MINE_POS.x or Vector2(bank["pos"]).distance_to(WorldScript.MINE_POS) < 1100.0:
            push_error("original long-form carrier chase topology was lost")
            quit(1)
            return
    if party_world.obstacles.size() < 2:
        push_error("carrier chase has no route-defining choke points")
        quit(1)
        return
    var climax_world = WorldScript.new(331)
    climax_world.runners[0]["score"] = 6
    climax_world.golden_heist = true
    climax_world._deposit(0)
    if int(climax_world.runners[0]["score"]) != 7 or climax_world.seven_alarm_slot != 0 or climax_world.result != &"playing":
        push_error("golden scoring skipped the original seven-mineral climax")
        quit(1)
        return
    party_world.step_tick({"party_ready":false, "p1":{}, "p2":{}}, 1.0 / 60.0)
    if party_world.tick != 0:
        push_error("match advanced without two ready players")
        quit(1)
        return
    var p2_start := Vector2(party_world.runners[1]["pos"])
    for ready_frame in range(190):
        party_world.step_tick({"party_ready":true, "p1":{"move":Vector2.ZERO}, "p2":{"move":Vector2.RIGHT}}, 1.0 / 60.0)
    if Vector2(party_world.runners[1]["pos"]).distance_to(p2_start) < 10.0:
        push_error("second local player did not enter the heist")
        quit(1)
        return
    var balance_world = WorldScript.new(334)
    balance_world.start_countdown = 0.0
    balance_world.party_ready = true
    balance_world._try_dash(0, Vector2.RIGHT)
    for timer_step in range(20):
        balance_world._update_timers(1.0 / 60.0)
    if int(balance_world.runners[0]["whiffs"]) < 1 or float(balance_world.runners[0]["winded"]) <= 0.0:
        push_error("missed dash did not create a recovery penalty")
        quit(1)
        return
    balance_world.mineral["state"] = &"carried"
    balance_world.mineral["owner"] = 2
    balance_world.mineral["secure_time"] = 0.0
    for foul_hit in range(4):
        balance_world.runners[0]["pos"] = Vector2(700.0, 450.0)
        balance_world.runners[1]["pos"] = Vector2(728.0, 450.0)
        balance_world.runners[0]["dash_cd"] = 0.0
        balance_world._try_dash(0, Vector2.RIGHT)
        balance_world._resolve_dash_hits()
    if int(balance_world.runners[0]["fouls"]) < 3 or float(balance_world.runners[0]["foul_lock"]) <= 0.0:
        push_error("repeat bullying did not trigger the foul lock")
        quit(1)
        return
    var robbery_world = WorldScript.new(335)
    robbery_world.mineral["state"] = &"carried"
    robbery_world.mineral["owner"] = 1
    robbery_world.mineral["secure_time"] = 0.0
    robbery_world.runners[0]["pos"] = Vector2(700.0, 450.0)
    robbery_world.runners[1]["pos"] = Vector2(728.0, 450.0)
    robbery_world._try_dash(0, Vector2.RIGHT)
    robbery_world._resolve_dash_hits()
    if int(robbery_world.runners[0]["robberies"]) != 1 or float(robbery_world.runners[0]["hype_time"]) <= 0.0 or float(robbery_world.runners[1]["revenge_time"]) <= 0.0:
        push_error("robbery did not reward the thief and arm the victim's comeback")
        quit(1)
        return
    robbery_world._drop_mineral(0, Vector2(760.0, 450.0), 1)
    robbery_world._drop_mineral(1, Vector2(780.0, 450.0), 0)
    robbery_world.round_time = 21.0
    robbery_world.mineral["state"] = &"carried"
    robbery_world.mineral["owner"] = 0
    robbery_world._deposit(0)
    if int(robbery_world.runners[0]["score"]) != 2 or int(robbery_world.runners[0]["hot_banks"]) != 1:
        push_error("a late three-steal hot coin did not create a high-risk double bank")
        quit(1)
        return
    var world = WorldScript.new(333)
    for i in range(10800):
        var human_pos := Vector2(world.runners[0]["pos"])
        var target := Vector2(world.banks[0]["pos"]) if int(world.mineral["owner"]) == 0 else Vector2(world.mineral["pos"])
        var move := human_pos.direction_to(target)
        var command := {"move":move, "dash":i%240==0, "interact":true}
        world.step_tick(command, 1.0/60.0)
        if world.has_invalid_numbers():
            push_error("invalid number at tick %d" % i)
            quit(1)
            return
        for runner in world.runners:
            var pos := Vector2(runner["pos"])
            if pos.x < 32.0 or pos.x > 1568.0 or pos.y < 32.0 or pos.y > 868.0:
                push_error("runner escaped arena at tick %d: %s" % [i, pos])
                quit(1)
                return
        if world.result != &"playing":
            break
    var total_score := 0
    var scoring_players := 0
    for runner in world.runners:
        total_score += int(runner["score"])
        if int(runner["score"]) > 0:
            scoring_players += 1
    if world.winner_slot < 0 or total_score < WorldScript.WIN_SCORE or scoring_players < 1:
        push_error("match did not produce a playable race: %s" % JSON.stringify(world.summary()))
        quit(1)
        return
    print("SMOKE_OK ", JSON.stringify(world.summary()))
    quit(0)
