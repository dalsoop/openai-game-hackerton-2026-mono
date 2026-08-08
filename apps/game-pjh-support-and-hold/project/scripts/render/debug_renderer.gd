extends Node2D

var world

func _draw() -> void:
    if world == null:
        return
    draw_rect(Rect2(Vector2.ZERO, world.world_size), Color("#10161b"))
    for lane in range(3):
        var y := float(world.lane_y[lane])
        draw_rect(Rect2(72.0, y - 70.0, 1460.0, 140.0), Color("#28343b"))
        draw_line(Vector2(72.0, y), Vector2(1532.0, y), Color("#62727b"), 3.0)
        draw_string(ThemeDB.fallback_font, Vector2(215.0, y - 48.0), "LANE %d" % (lane + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#9cb0ba"))
    draw_circle(world.base_pos, 72.0, Color("#376d77"))
    draw_arc(world.base_pos, 72.0, 0.0, TAU, 48, Color("#8ad8e5"), 5.0)
    draw_string(ThemeDB.fallback_font, world.base_pos + Vector2(-34.0, 6.0), "BASE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 19, Color.WHITE)
    draw_circle(world.hive_pos, 76.0, Color("#5f274b"))
    draw_arc(world.hive_pos, 76.0, 0.0, TAU, 48, Color("#e35d9f") if world.hive_vulnerable else Color("#6f5964"), 5.0)
    draw_string(ThemeDB.fallback_font, world.hive_pos + Vector2(-31.0, 6.0), "HIVE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 19, Color.WHITE)
    for barrier in world.barriers:
        var pos := Vector2(barrier["pos"])
        draw_rect(Rect2(pos + Vector2(-14.0, -54.0), Vector2(28.0, 108.0)), Color(0.32, 0.75, 0.95, 0.45))
        draw_line(pos + Vector2(0.0, -54.0), pos + Vector2(0.0, 54.0), Color("#7de5ff"), 4.0)
    for package in world.packages:
        if not bool(package["alive"]):
            continue
        var pos := Vector2(package["pos"])
        var kind := StringName(package["kind"])
        var color := Color("#f2d46b") if kind == &"ammo" else (Color("#7fe399") if kind == &"med" else Color("#73c9ff"))
        if bool(package.get("overcharged", false)):
            color = Color("#ff784f")
        draw_line(pos - Vector2(34.0, 0.0), pos, Color(color, 0.28), 12.0)
        draw_rect(Rect2(pos - Vector2(11.0, 11.0), Vector2(22.0, 22.0)), color)
        draw_string(ThemeDB.fallback_font, pos + Vector2(-6.0, 5.0), String(kind).substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#172027"))
        draw_line(pos, Vector2(world.actors[int(package["target"])]["pos"]), Color(color, 0.25), 1.0)
        if bool(package.get("overcharged", false)):
            draw_arc(pos, 18.0 + sin(float(world.tick) * 0.35) * 3.0, 0.0, TAU, 24, Color.WHITE, 3.0)
    for p in world.projectiles:
        draw_circle(Vector2(p["pos"]), float(p["radius"]), Color("#ffe57a"))
    for enemy in world.enemies:
        if not bool(enemy["alive"]):
            continue
        var pos := Vector2(enemy["pos"])
        var radius: float = 21.0 if bool(enemy["elite"]) else float(world.enemy_radius)
        draw_circle(pos, radius, Color("#b74343") if not bool(enemy["elite"]) else Color("#a14db5"))
        var hp_ratio := clampf(float(enemy["hp"]) / maxf(1.0, float(enemy["hp_max"])), 0.0, 1.0)
        draw_rect(Rect2(pos + Vector2(-radius, -radius - 9.0), Vector2(radius * 2.0, 4.0)), Color("#32191c"))
        draw_rect(Rect2(pos + Vector2(-radius, -radius - 9.0), Vector2(radius * 2.0 * hp_ratio, 4.0)), Color("#ff7166"))
    for actor in world.actors:
        var pos := Vector2(actor["pos"])
        var slot := int(actor["slot"])
        var role := StringName(actor["role"])
        var controlled: bool = slot == int(world.human_slot) or (world.party_mode and slot == 3)
        var color := Color("#5ed3ff") if role == &"soldier" else Color("#77df9b")
        if not bool(actor["alive"]):
            color = Color("#555b60")
        if role == &"soldier":
            draw_circle(pos, world.actor_radius, color)
        else:
            draw_rect(Rect2(pos - Vector2(world.actor_radius, world.actor_radius), Vector2(world.actor_radius * 2.0, world.actor_radius * 2.0)), color)
        draw_arc(pos, world.actor_radius + (7.0 if controlled else 3.0), 0.0, TAU, 28, Color("#ffffff") if controlled else Color("#b8c5ca"), 3.0 if controlled else 1.5)
        draw_string(ThemeDB.fallback_font, pos + Vector2(-7.0, 6.0), str(slot + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#10161b"))
        if float(actor["shield"]) > 0.0:
            draw_arc(pos, world.actor_radius + 10.0, -PI * 0.8, PI * 0.8, 20, Color("#6edcff"), 3.0)
        if int(actor["overcharge"]) > 0:
            var pulse: float = float(world.actor_radius) + 14.0 + sin(float(world.tick) * 0.28) * 4.0
            draw_arc(pos, pulse, 0.0, TAU, 28, Color("#ffd166"), 5.0)
        if int(actor["recoil"]) > 0:
            draw_arc(pos, world.actor_radius + 15.0, -0.6, 0.6, 12, Color("#fff2a8"), 5.0)
        if role == &"supplier" and int(actor["jam_ticks"]) > 0:
            draw_string(ThemeDB.fallback_font, pos + Vector2(-38.0, -34.0), "OVERHEAT", HORIZONTAL_ALIGNMENT_CENTER, 76.0, 12, Color("#ff655f"))
    if world.impact_ticks > 0:
        draw_rect(Rect2(5.0, 5.0, 1590.0, 890.0), Color(1.0, 0.72, 0.28, float(world.impact_ticks) / 20.0), false, 10.0)
