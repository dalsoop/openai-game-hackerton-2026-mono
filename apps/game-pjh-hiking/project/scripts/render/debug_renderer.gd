extends Node2D

var world

func _draw() -> void:
    if world == null:
        return
    draw_rect(Rect2(0.0, 0.0, world.stage_width, world.stage_height), Color("#0b1016"))
    draw_rect(Rect2(200.0, 0.0, 1200.0, world.stage_height), Color("#27313a"))
    draw_rect(Rect2(220.0, world.stage_height - 230.0, 1160.0, 230.0), Color("#213a31"))
    draw_rect(Rect2(620.0, 30.0, 360.0, 150.0), Color("#756b35"))
    draw_string(ThemeDB.fallback_font, Vector2(700.0, 110.0), "SUMMIT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color.WHITE)
    for z in world.web_zones:
        draw_circle(Vector2(z["pos"]), float(z["radius"]), Color(0.2, 0.65, 0.9, 0.14))
        draw_arc(Vector2(z["pos"]), float(z["radius"]), 0.0, TAU, 48, Color(0.3, 0.8, 1.0, 0.8), 3.0)
    for wall in world.walls:
        var wall_color := Color("#8aa0b2") if int(wall["durability"]) >= 2 else Color("#d18b65")
        draw_rect(Rect2(Vector2(wall["pos"]) - Vector2(34.0, 42.0), Vector2(68.0, 84.0)), wall_color)
        draw_string(ThemeDB.fallback_font, Vector2(wall["pos"]) + Vector2(-7.0, 7.0), str(int(wall["owner"]) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#0d1318"))
        if int(wall["durability"]) < 2:
            draw_line(Vector2(wall["pos"]) + Vector2(-18.0, -32.0), Vector2(wall["pos"]) + Vector2(14.0, 30.0), Color("#4a2418"), 5.0)
    for b in world.boulders:
        var pos: Vector2 = b["pos"]
        if float(b["warning"]) > 0.0:
            draw_line(Vector2(pos.x, 0.0), Vector2(pos.x, 250.0), Color(1.0, 0.35, 0.22, 0.85), 6.0)
            draw_circle(Vector2(pos.x, 70.0), float(b["radius"]), Color(1.0, 0.25, 0.16, 0.25))
        else:
            draw_circle(pos, float(b["radius"]), Color("#171b20"))
            draw_arc(pos, float(b["radius"]), 0.0, TAU, 24, Color("#e25c3f"), 4.0)
    for flag in world.flags:
        var pos: Vector2 = flag["pos"]
        var owner := int(flag["owner"])
        var pulse := 30.0 + sin(float(world.tick) * 0.12 + owner) * 5.0
        draw_circle(pos, pulse, Color(0.55, 0.88, 1.0, 0.13))
        draw_arc(pos, pulse, 0.0, TAU, 28, Color(0.55, 0.88, 1.0, 0.72), 3.0)
        draw_line(pos + Vector2(0.0, 24.0), pos + Vector2(0.0, -28.0), Color.WHITE, 4.0)
        draw_colored_polygon(PackedVector2Array([pos + Vector2(0.0, -28.0), pos + Vector2(32.0, -17.0), pos + Vector2(0.0, -5.0)]), Color("#ffd166"))
        if float(flag["progress"]) > 0.0:
            draw_arc(pos, 34.0, -PI * 0.5, -PI * 0.5 + TAU * float(flag["progress"]) / 1.35, 24, Color("#6ef3a5"), 5.0)
        if owner == 0 and float(world.players[0]["ghost_cd"]) <= 0.0:
            draw_string(ThemeDB.fallback_font, pos + Vector2(-74.0, 58.0), "SPACE: GHOST GUST", HORIZONTAL_ALIGNMENT_CENTER, 148.0, 14, Color("#9de7ff"))
        draw_string(ThemeDB.fallback_font, pos + Vector2(-45.0, 78.0), "SPIRIT %d" % int(world.players[owner]["spirit"]), HORIZONTAL_ALIGNMENT_CENTER, 90.0, 12, Color("#ffd166"))
    var colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc")]
    for p in world.players:
        var pos: Vector2 = p["pos"]
        if bool(p["alive"]):
            draw_circle(pos, 22.0, colors[int(p["slot"])])
            draw_arc(pos, 24.0, 0.0, TAU, 24, Color.BLACK, 3.0)
            draw_string(ThemeDB.fallback_font, pos + Vector2(-6.0, 6.0), str(int(p["slot"]) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color.BLACK)
            if float(p["shove_time"]) > 0.0:
                draw_line(pos - Vector2(p["vel"]).normalized() * 48.0, pos, Color("#ff9f1c"), 9.0)
                draw_string(ThemeDB.fallback_font, pos + Vector2(-34.0, -34.0), "PINBALL", HORIZONTAL_ALIGNMENT_CENTER, 68.0, 11, Color("#ffcf70"))
            if int(p["slot"]) > (1 if world.party_mode else 0):
                draw_string(ThemeDB.fallback_font, pos + Vector2(-40.0, -32.0), str(p["action"]), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 13, Color.WHITE)
            elif world.party_mode:
                draw_arc(pos, 28.0, 0.0, TAU, 24, Color.WHITE, 4.0)
            if world._web_speed_scale(pos, int(p["slot"])) < 1.0:
                draw_arc(pos, 32.0, 0.0, TAU, 24, Color("#54d6ff"), 4.0)
    if world.impact_ticks > 0:
        draw_rect(Rect2(200.0, 0.0, 1200.0, world.stage_height), Color(0.65, 0.88, 1.0, float(world.impact_ticks) / 130.0), false, 10.0)
