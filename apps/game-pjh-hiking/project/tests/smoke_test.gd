extends SceneTree

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _init() -> void:
    var party_world = WorldScript.new(122)
    party_world.step_tick({"party_ready":false, "p1":{}, "p2":{}}, 1.0 / 60.0)
    if party_world.tick != 0:
        push_error("climb advanced without two ready players")
        quit(1)
        return
    var p2_start := Vector2(party_world.players[1]["pos"])
    for ready_frame in range(190):
        party_world.step_tick({"party_ready":true, "p1":{"move":Vector2.ZERO}, "p2":{"move":Vector2.UP}}, 1.0 / 60.0)
    if Vector2(party_world.players[1]["pos"]).distance_to(p2_start) < 10.0:
        push_error("second local climber did not move after ready")
        quit(1)
        return
    var world = WorldScript.new(123)
    for i in range(3600):
        var move := Vector2.UP
        var command := {
            "move": move,
            "build": i % 240 == 0,
            "bomb": i % 600 == 0,
            "web": false,
            "interact": true
        }
        world.step_tick(command, 1.0 / 60.0)
        if world.has_invalid_numbers():
            push_error("invalid number at tick %d" % i)
            quit(1)
            return
    if world.stage_index < 2:
        push_error("climb did not advance through enough stages")
        quit(1)
        return
    var wall_world = WorldScript.new(456)
    for i in range(180):
        wall_world.step_tick({"move":Vector2.ZERO}, 1.0 / 60.0)
    wall_world._try_build_wall(0)
    var wall_pos: Vector2 = wall_world.walls[0]["pos"]
    wall_world.boulders.append({"id":9998, "pos":wall_pos, "vel":Vector2.DOWN * 200.0, "radius":36.0, "warning":0.0})
    wall_world.step_tick({"move":Vector2.ZERO}, 1.0 / 60.0)
    if not wall_world.walls.is_empty() or not wall_world.boulders.is_empty() or not bool(wall_world.players[0]["alive"]) or wall_world.contributions[0] < 1 or int(wall_world.players[0]["charges"]) < 4:
        push_error("wall did not sacrifice itself to stop a boulder")
        quit(1)
        return
    var ghost_world = WorldScript.new(321)
    for i in range(180):
        ghost_world.step_tick({"move":Vector2.ZERO}, 1.0 / 60.0)
    ghost_world._kill_player(0, -1)
    var ghost_pos := Vector2(ghost_world.flags[0]["pos"])
    ghost_world.boulders.append({"id":9999, "pos":ghost_pos + Vector2(20.0, -40.0), "vel":Vector2.DOWN * 200.0, "radius":36.0, "warning":0.0})
    ghost_world.step_tick({"move":Vector2.RIGHT, "build":true, "bomb":false, "web":false, "interact":false}, 1.0 / 60.0)
    if float(Vector2(ghost_world.boulders[0]["vel"]).x) <= 0.0 or float(ghost_world.players[0]["ghost_cd"]) <= 0.0 or int(ghost_world.players[0]["spirit"]) != 1:
        push_error("ghost gust did not affect the match after failure")
        quit(1)
        return
    var web_world = WorldScript.new(654)
    web_world.web_zones.append({"id":9000, "pos":Vector2(web_world.players[0]["pos"]), "radius":230.0, "time":4.0, "owner":0})
    if web_world._web_speed_scale(Vector2(web_world.players[0]["pos"]), 0) >= 1.0 or web_world._web_speed_scale(Vector2(web_world.players[0]["pos"]), 1) >= 0.7:
        push_error("web did not trade boulder control for shared movement risk")
        quit(1)
        return
    var pinball_world = WorldScript.new(655)
    pinball_world.players[0]["pos"] = Vector2(700.0, 900.0)
    pinball_world.players[1]["pos"] = Vector2(728.0, 900.0)
    pinball_world.players[0]["vel"] = Vector2.RIGHT * 500.0
    pinball_world.players[0]["shove_time"] = 0.4
    pinball_world.players[0]["shove_owner"] = 0
    pinball_world._move_players(1.0 / 60.0)
    if pinball_world.chain_shoves[0] != 1 or float(pinball_world.players[1]["shove_time"]) <= 0.0:
        push_error("a sabotage shove did not propagate into player pinball")
        quit(1)
        return
    print("SMOKE_OK ", JSON.stringify(world.summary()))
    quit(0)
