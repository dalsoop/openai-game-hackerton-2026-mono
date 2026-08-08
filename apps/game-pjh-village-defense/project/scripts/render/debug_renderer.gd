extends Node2D

var world

func _draw() -> void:
    if world == null:
        return
    draw_rect(Rect2(Vector2.ZERO, world.world_size), Color("#11171b"))
    _draw_lanes()
    draw_circle(world.center, world.village_radius + 18.0, Color("#253a31"))
    draw_circle(world.center, world.village_radius, Color("#936f3c"))
    draw_arc(world.center, world.village_radius, 0.0, TAU, 64, Color("#e3bd68"), 5.0)
    draw_string(ThemeDB.fallback_font, world.center + Vector2(-43.0, 8.0), "VILLAGE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color.WHITE)
    for zone in world.stasis_zones:
        var life_alpha := clampf(float(zone["life"]) / 150.0, 0.15, 0.75)
        draw_circle(Vector2(zone["pos"]), float(zone["radius"]), Color(0.28, 0.62, 0.95, 0.13 * life_alpha))
        draw_arc(Vector2(zone["pos"]), float(zone["radius"]), 0.0, TAU, 48, Color(0.36, 0.78, 1.0, life_alpha), 3.0)
    for p in world.projectiles:
        draw_circle(Vector2(p["pos"]), float(p["radius"]), Color("#ffd66f"))
    for enemy in world.enemies:
        if not bool(enemy["alive"]):
            continue
        var pos := Vector2(enemy["pos"])
        var radius: float = 30.0 if bool(enemy["boss"]) else float(world.enemy_radius)
        var color := Color("#7e2f9c") if bool(enemy["boss"]) else (Color("#d47a32") if bool(enemy.get("siege", false)) else Color("#a84242"))
        draw_circle(pos, radius, color)
        if int(enemy["stasis"]) > 0:
            draw_arc(pos, radius + 5.0, 0.0, TAU, 24, Color("#63d7ff"), 3.0)
        if int(enemy["panic_time"]) > 0:
            draw_arc(pos, radius + 8.0, 0.0, TAU, 24, Color("#ffb347"), 4.0)
        if int(enemy["enrage_time"]) > 0:
            draw_arc(pos, radius + 13.0, float(world.tick) * 0.08, float(world.tick) * 0.08 + PI * 1.45, 24, Color("#ff4141"), 5.0)
        var ratio := clampf(float(enemy["hp"]) / maxf(1.0, float(enemy["hp_max"])), 0.0, 1.0)
        draw_rect(Rect2(pos + Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0, 5.0)), Color("#34191a"))
        draw_rect(Rect2(pos + Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0 * ratio, 5.0)), Color("#f17a69"))
    for hero in world.heroes:
        var pos := Vector2(hero["pos"])
        if not bool(hero["alive"]):
            draw_circle(pos, 16.0, Color(0.25, 0.25, 0.25, 0.65))
            draw_line(pos + Vector2(-9.0, -9.0), pos + Vector2(9.0, 9.0), Color.WHITE, 3.0)
            draw_line(pos + Vector2(9.0, -9.0), pos + Vector2(-9.0, 9.0), Color.WHITE, 3.0)
            continue
        var slot := int(hero["slot"])
        var color := Color("#65d7ff") if slot == 0 else (Color("#ff72d2") if slot == 1 else Color.from_hsv(float(slot) / 7.0, 0.65, 0.95))
        draw_circle(pos, world.hero_radius + float(hero["level"]) * 2.0, color)
        var human_controlled: bool = slot == 0 or (bool(world.party_mode) and slot == 1)
        draw_arc(pos, world.hero_radius + (8.0 if human_controlled else 5.0), 0.0, TAU, 24, Color.WHITE, 4.0 if human_controlled else 2.0)
        draw_line(pos, pos.direction_to(Vector2(hero["aim"])) * 28.0 + pos, Color.WHITE, 2.0)
        if int(hero["recoil"]) > 0:
            draw_arc(pos, world.hero_radius + 14.0, -0.7, 0.7, 12, Color("#fff0a8"), 5.0)
        if int(hero["stasis_struggle"]) > 0:
            var struggle_ratio := clampf(float(hero["stasis_struggle"]) / 36.0, 0.0, 1.0)
            draw_arc(pos, world.hero_radius + 17.0, -PI * 0.5, -PI * 0.5 + TAU * struggle_ratio, 24, Color("#ff72d2"), 5.0)
        elif int(hero["stasis_immunity"]) > 0:
            draw_arc(pos, world.hero_radius + 17.0, 0.0, TAU, 24, Color("#7df9ff"), 4.0)
        draw_string(ThemeDB.fallback_font, pos + Vector2(-8.0, 6.0), str(slot + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#101417"))
        draw_string(ThemeDB.fallback_font, pos + Vector2(-38.0, -31.0), String(hero["role"]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 76.0, 10, Color.WHITE)
        var hp_ratio := clampf(float(hero["hp"]) / maxf(1.0, float(hero["hp_max"])), 0.0, 1.0)
        draw_rect(Rect2(pos + Vector2(-22.0, 27.0), Vector2(44.0, 5.0)), Color("#172026"))
        draw_rect(Rect2(pos + Vector2(-22.0, 27.0), Vector2(44.0 * hp_ratio, 5.0)), Color("#72df8b"))
        if int(hero["combo"]) >= 3:
            draw_string(ThemeDB.fallback_font, pos + Vector2(-30.0, 48.0), "x%d" % int(hero["combo"]), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 14, Color("#ffd166"))
    if world.impact_ticks > 0:
        var bell_radius := 110.0 + float(18 - world.impact_ticks) * 18.0
        draw_arc(world.center, bell_radius, 0.0, TAU, 64, Color(1.0, 0.78, 0.28, float(world.impact_ticks) / 20.0), 10.0)

func _draw_lanes() -> void:
    var center: Vector2 = Vector2(world.center)
    for i in range(4):
        var endpoint: Vector2 = world.lane_spawns[i]
        draw_line(endpoint, center, Color("#3d4850"), 125.0)
        draw_line(endpoint, center, Color("#66737c"), 4.0)
        var hold: Vector2 = Vector2(world._lane_hold_point(i, 260.0))
        draw_circle(hold, 14.0, Color(0.9, 0.9, 0.9, 0.18))
        draw_string(ThemeDB.fallback_font, hold + Vector2(-8.0, 6.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#becbd3"))
        var gate: Vector2 = world._gate_pos(i)
        var outward := center.direction_to(endpoint)
        var tangent := outward.rotated(PI * 0.5)
        var gate_ratio := clampf(float(world.gate_hp[i]) / float(world.GATE_HP_MAX), 0.0, 1.0)
        var gate_color := Color("#77d38b") if gate_ratio > 0.35 else (Color("#ffb347") if gate_ratio > 0.0 else Color("#e44f4f"))
        draw_line(gate - tangent * 50.0, gate + tangent * 50.0, gate_color, 14.0)
        draw_line(gate - tangent * 50.0, gate - tangent * 50.0 + outward * 80.0 * gate_ratio, Color("#dff6df"), 4.0)
        if gate_ratio <= 0.0:
            draw_line(gate - Vector2(18.0, 18.0), gate + Vector2(18.0, 18.0), Color.WHITE, 5.0)
            draw_line(gate + Vector2(-18.0, 18.0), gate + Vector2(18.0, -18.0), Color.WHITE, 5.0)
