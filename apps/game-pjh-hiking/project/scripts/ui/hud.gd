extends Control

var world

func _draw() -> void:
    if world == null:
        return
    var summary: Dictionary = world.summary()
    draw_rect(Rect2(16.0, 16.0, 1010.0, 145.0), Color(0.02, 0.03, 0.05, 0.92))
    draw_rect(Rect2(16.0, 16.0, 7.0, 145.0), Color("#6ef3a5"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 49.0), "MOUNT IMPOSSIBLE  |  ONE SUMMIT SAVES EVERYONE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 23, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 82.0), "STAGE %d/5   ALIVE %d/6   WALLS %d   BOULDERS %d" % [summary["stage"], summary["alive"], summary["walls"], summary["boulders"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#d5deeb"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 113.0), "P1 WASD: SPACE wall, Q bomb, E web, G rescue", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#c8d5e4"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 141.0), "P2 ARROWS: ENTER wall, / bomb, . web, SHIFT rescue  |  Dead? Move your ghost and gust with wall key.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#9de7ff"))
    var p1: Dictionary = world.players[0]
    var p2: Dictionary = world.players[1]
    var party_stats := "P1 C%d S%d H%d PIN%d   P2 C%d S%d H%d PIN%d" % [int(p1["charges"]), int(p1["spirit"]), world.contributions[0], world.chain_shoves[0], int(p2["charges"]), int(p2["spirit"]), world.contributions[1], world.chain_shoves[1]]
    draw_rect(Rect2(1040.0, 16.0, 540.0, 50.0), Color(0.02, 0.03, 0.05, 0.92))
    draw_string(ThemeDB.fallback_font, Vector2(1055.0, 49.0), party_stats, HORIZONTAL_ALIGNMENT_CENTER, 510.0, 14, Color("#ffd166"))
    if not world.party_ready:
        _draw_party_lobby()
        return
    if world.callout_ticks > 0:
        var alpha := clampf(float(world.callout_ticks) / 24.0, 0.0, 1.0)
        draw_rect(Rect2(430.0, 180.0, 740.0, 62.0), Color(0.03, 0.05, 0.07, 0.84 * alpha))
        draw_string(ThemeDB.fallback_font, Vector2(450.0, 221.0), world.callout, HORIZONTAL_ALIGNMENT_CENTER, 700.0, 24, Color(0.70, 0.94, 1.0, alpha))
    if world.start_countdown > 0.0:
        draw_circle(Vector2(800.0, 410.0), 82.0, Color(0.02, 0.03, 0.05, 0.88))
        draw_arc(Vector2(800.0, 410.0), 86.0, 0.0, TAU, 64, Color("#ffd166"), 7.0)
        draw_string(ThemeDB.fallback_font, Vector2(720.0, 440.0), str(ceili(world.start_countdown)), HORIZONTAL_ALIGNMENT_CENTER, 160.0, 82, Color.WHITE)
    if world.result == &"won":
        draw_rect(Rect2(470.0, 340.0, 660.0, 170.0), Color(0.02, 0.03, 0.05, 0.95))
        draw_string(ThemeDB.fallback_font, Vector2(500.0, 413.0), "THE PARTY REACHED ALL 5 SUMMITS!", HORIZONTAL_ALIGNMENT_CENTER, 600.0, 30, Color("#ffd166"))
        draw_string(ThemeDB.fallback_font, Vector2(500.0, 462.0), "Press R to blame each other again", HORIZONTAL_ALIGNMENT_CENTER, 600.0, 21, Color.WHITE)

func _draw_party_lobby() -> void:
    draw_rect(Rect2(390.0, 270.0, 820.0, 300.0), Color(0.01, 0.02, 0.04, 0.97))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 340.0), "LOCAL PARTY ONLY", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 38, Color("#6ef3a5"))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 405.0), "P1: press SPACE when ready", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 24, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 450.0), "P2: press ENTER when ready", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 24, Color("#5bc0eb"))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 515.0), "Cooperate, interfere, survive the story.", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 20, Color("#c8d5e4"))
