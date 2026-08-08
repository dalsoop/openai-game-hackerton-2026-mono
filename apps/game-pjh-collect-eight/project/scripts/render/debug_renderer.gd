extends Node2D

var world
var colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc")]

func _draw() -> void:
    if world == null:
        return
    draw_rect(Rect2(0.0,0.0,1600.0,900.0), Color("#12151b"))
    draw_rect(Rect2(0.0,160.0,1600.0,170.0), Color("#2b3038"))
    draw_rect(Rect2(0.0,365.0,1600.0,170.0), Color("#343a43"))
    draw_rect(Rect2(0.0,570.0,1600.0,170.0), Color("#2b3038"))
    for x in range(0, 1601, 100):
        draw_line(Vector2(x, 0), Vector2(x, 900), Color(1.0, 1.0, 1.0, 0.025), 1.0)
    for y in range(0, 901, 100):
        draw_line(Vector2(0, y), Vector2(1600, y), Color(1.0, 1.0, 1.0, 0.025), 1.0)
    for rect in world.obstacles:
        draw_rect(rect, Color("#525c68"))
        draw_rect(rect.grow(-6.0), Color("#1d232a"))
    draw_circle(Vector2(800.0,450.0), 74.0, Color("#3a3424"))
    draw_arc(Vector2(800.0,450.0), 74.0, 0.0, TAU, 48, Color("#ffd166"), 5.0)
    draw_string(ThemeDB.fallback_font, Vector2(762.0,456.0), "MINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color.WHITE)
    for bank in world.banks:
        var slot := int(bank["slot"])
        var pos: Vector2 = bank["pos"]
        draw_circle(pos, float(bank["radius"]), Color(colors[slot],0.22))
        draw_arc(pos, float(bank["radius"]), 0.0, TAU, 36, colors[slot], 5.0)
        draw_string(ThemeDB.fallback_font, pos+Vector2(-20.0,6.0), "B%d" % (slot+1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color.WHITE)
    if world.mineral["state"] != &"respawn":
        var mpos: Vector2 = world.mineral["pos"]
        var mineral_color := Color("#fff4a3") if world.golden_heist else Color("#ffd166")
        draw_colored_polygon(PackedVector2Array([mpos+Vector2(0,-18),mpos+Vector2(18,0),mpos+Vector2(0,18),mpos+Vector2(-18,0)]), mineral_color)
        draw_arc(mpos, 23.0 + (4.0 if world.golden_heist else 0.0), 0.0, TAU, 24, Color.WHITE, 3.0)
        if world.golden_heist:
            draw_arc(mpos, 34.0, float(world.tick) * 0.04, float(world.tick) * 0.04 + PI * 1.35, 30, Color("#ff9f1c"), 5.0)
    for r in world.runners:
        var slot := int(r["slot"])
        var pos: Vector2 = r["pos"]
        if int(world.mineral["owner"]) == slot:
            var bank_pos: Vector2 = world.banks[slot]["pos"]
            draw_dashed_line(pos, bank_pos, Color(colors[slot], 0.28), 4.0, 14.0)
            draw_arc(pos, 31.0, 0.0, TAU, 28, Color("#ffd166"), 6.0)
            draw_colored_polygon(PackedVector2Array([pos + Vector2(-14.0, -34.0), pos + Vector2(0.0, -52.0), pos + Vector2(14.0, -34.0)]), Color("#ffd166"))
            if int(world.mineral.get("steal_chain", 0)) > 0:
                draw_string(ThemeDB.fallback_font, pos + Vector2(-42.0, -58.0), "HOT x%d" % int(world.mineral["steal_chain"]), HORIZONTAL_ALIGNMENT_CENTER, 84.0, 14, Color("#ff7b00"))
            if float(world.mineral["secure_time"]) > 0.0:
                var shield_ratio: float = float(world.mineral["secure_time"]) / float(world.PICKUP_GRACE)
                draw_arc(pos, 38.0, -PI * 0.5, -PI * 0.5 + TAU * shield_ratio, 32, Color("#7df9ff"), 5.0)
            if float(r["deposit_progress"]) > 0.0:
                var deposit_required := 0.25 if world.golden_heist else 0.45
                var deposit_ratio: float = clampf(float(r["deposit_progress"]) / deposit_required, 0.0, 1.0)
                draw_arc(pos, 46.0, -PI * 0.5, -PI * 0.5 + TAU * deposit_ratio, 32, Color.WHITE, 7.0)
        draw_circle(pos, 20.0, colors[slot])
        draw_arc(pos, 22.0, 0.0, TAU, 24, Color.BLACK, 3.0)
        draw_string(ThemeDB.fallback_font, pos+Vector2(-7.0,6.0), str(slot+1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color.BLACK)
        if float(r["dash_time"]) > 0.0:
            draw_line(pos-Vector2(r["dash_dir"])*64.0, pos, Color(colors[slot],0.28), 18.0)
            draw_line(pos-Vector2(r["dash_dir"])*42.0, pos, Color.WHITE, 5.0)
        elif float(r["dash_cd"]) > 0.0:
            var ready_ratio: float = 1.0 - clampf(float(r["dash_cd"]) / 4.2, 0.0, 1.0)
            draw_arc(pos, 28.0, -PI * 0.5, -PI * 0.5 + TAU * ready_ratio, 24, Color(colors[slot], 0.75), 3.0)
        if float(r["revenge_time"]) > 0.0:
            draw_arc(pos, 34.0, 0.0, TAU, 28, Color("#ff4d6d"), 4.0)
        if float(r["foul_lock"]) > 0.0 or float(r["winded"]) > 0.0:
            draw_string(ThemeDB.fallback_font, pos + Vector2(-34.0, -35.0), "FOUL" if float(r["foul_lock"]) > 0.0 else "WIND", HORIZONTAL_ALIGNMENT_CENTER, 68.0, 12, Color("#ff5d5d"))
        if slot > (1 if world.party_mode else 0):
            draw_string(ThemeDB.fallback_font, pos+Vector2(-48,-32), str(r["action"]), HORIZONTAL_ALIGNMENT_CENTER, 96.0, 12, Color.WHITE)
        elif world.party_mode:
            draw_arc(pos, 27.0, 0.0, TAU, 24, Color.WHITE, 4.0)
    if world.impact_ticks > 0:
        draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(1.0, 0.88, 0.45, float(world.impact_ticks) / 110.0), false, 10.0)
