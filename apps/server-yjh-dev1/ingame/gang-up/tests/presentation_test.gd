extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene_resource = load("res://scenes/main.tscn")
    var game = scene_resource.instantiate()
    root.add_child(game)
    await process_frame
    game.world._down_hero(1, 0)
    game._update_spectator()
    if game.spectate_slot <= 0 or not bool(game.world.heroes[game.spectate_slot]["alive"]):
        push_error("downed player did not acquire a living spectator target")
        quit(1)
        return
    var first_target: int = int(game.spectate_slot)
    game._cycle_spectator(1)
    if game.spectate_slot == first_target or not bool(game.world.heroes[game.spectate_slot]["alive"]):
        push_error("spectator target cycling did not select another living player")
        quit(1)
        return
    var camera_target: Vector2 = game._camera_target()
    if camera_target.distance_to(Vector2(game.world.heroes[game.spectate_slot]["pos"])) > 260.0:
        push_error("spectator camera did not follow the selected combatant")
        quit(1)
        return
    game.hud.hud_mode = 0
    game.hud.queue_redraw()
    if game.world.leaderboard().size() != 6:
        push_error("full statistics did not include six players")
        quit(1)
        return
    game._restart()
    game.world.start_countdown = 0.0
    game.world.match_time = game.world.MATCH_TIME_LIMIT - 0.01
    for decision_slot in range(game.world.heroes.size()):
        game.world.heroes[decision_slot]["hp"] = float(game.world.heroes[decision_slot]["max_hp"]) * (0.35 + float(decision_slot) * 0.04)
    game.world.heroes[4]["hp"] = float(game.world.heroes[4]["max_hp"]) * 0.94
    game.world.step_tick({}, 0.02)
    await process_frame
    if game.world.winner_slot != 4 or game.world.result_reason != &"time_limit":
        push_error("210-second presentation did not resolve the expected HP winner")
        quit(1)
        return
    var winner_target: Vector2 = game._camera_target()
    if winner_target.distance_to(Vector2(game.world.heroes[4]["pos"])) > 260.0 or absf(game._camera_zoom_target() - 1.16) > 0.001:
        push_error("result camera did not focus and tighten on the winner")
        quit(1)
        return
    var result_winner: int = game.world.winner_slot
    var result_zoom: float = game._camera_zoom_target()
    game.queue_free()
    await process_frame
    print("PRESENTATION_OK ", JSON.stringify({"spectate_slot":first_target, "camera_target":camera_target, "hud_modes":3, "leaderboard_rows":6, "result_winner":result_winner, "result_zoom":result_zoom}))
    quit(0)
