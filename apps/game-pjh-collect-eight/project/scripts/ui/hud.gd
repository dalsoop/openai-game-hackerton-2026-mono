extends Control

var world

func _draw() -> void:
    if world == null:
        return
    draw_rect(Rect2(16.0, 16.0, 900.0, 142.0), Color(0.02, 0.03, 0.05, 0.92))
    draw_rect(Rect2(16.0, 16.0, 7.0, 142.0), Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 49.0), "COLLECT 8 MINERALS  |  BEST OF 5 HEISTS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 23, Color.WHITE)
    var score_text := ""
    for runner in world.runners:
        var slot := int(runner["slot"])
        var marker := "*" if int(world.mineral["owner"]) == slot else ""
        var human_tag := " P1" if slot == 0 else (" P2" if slot == 1 else " CPU")
        score_text += "%s:%d%s   " % [human_tag, int(runner["score"]), marker]
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 82.0), score_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 113.0), "P1 WASD / SPACE DASH / E GRAB     P2 ARROWS / ENTER DASH / SHIFT GRAB", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#c8d5e4"))
    var p1: Dictionary = world.runners[0]
    var p2: Dictionary = world.runners[1]
    var state_text := "P1 DASH %.1f  FOUL %d     P2 DASH %.1f  FOUL %d     HOT COIN x%d" % [float(p1["dash_cd"]), int(p1["foul_strikes"]), float(p2["dash_cd"]), int(p2["foul_strikes"]), int(world.mineral.get("steal_chain", 0))]
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 141.0), state_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#7df9ff"))
    if world.golden_heist:
        draw_rect(Rect2(1190.0, 22.0, 380.0, 54.0), Color(0.35, 0.20, 0.02, 0.92))
        draw_string(ThemeDB.fallback_font, Vector2(1210.0, 58.0), "GOLDEN HEIST: NEXT BANK WINS", HORIZONTAL_ALIGNMENT_CENTER, 340.0, 19, Color("#fff4a3"))
    if not world.party_ready:
        _draw_party_lobby()
        return
    if world.callout_ticks > 0 and world.result == &"playing":
        var alpha := clampf(float(world.callout_ticks) / 24.0, 0.0, 1.0)
        draw_rect(Rect2(420.0, 178.0, 760.0, 64.0), Color(0.04, 0.05, 0.08, 0.82 * alpha))
        draw_string(ThemeDB.fallback_font, Vector2(445.0, 221.0), world.callout, HORIZONTAL_ALIGNMENT_CENTER, 710.0, 25, Color(1.0, 0.82, 0.34, alpha))
    if world.start_countdown > 0.0:
        _draw_countdown(world.start_countdown)
    if world.seven_alarm_slot >= 0 and world.result == &"playing":
        draw_rect(Rect2(560.0, 256.0, 480.0, 50.0), Color(0.50, 0.06, 0.05, 0.90))
        draw_string(ThemeDB.fallback_font, Vector2(580.0, 290.0), "MATCH POINT: STOP P%d!" % (world.seven_alarm_slot + 1), HORIZONTAL_ALIGNMENT_CENTER, 440.0, 20, Color.WHITE)
    if world.result != &"playing":
        draw_rect(Rect2(460.0, 330.0, 680.0, 190.0), Color(0.02, 0.03, 0.05, 0.95))
        draw_string(ThemeDB.fallback_font, Vector2(490.0, 404.0), "P%d WINS THE HEIST!" % (world.winner_slot + 1), HORIZONTAL_ALIGNMENT_CENTER, 620.0, 34, Color("#ffd166"))
        draw_string(ThemeDB.fallback_font, Vector2(490.0, 460.0), "Press R for a salty rematch", HORIZONTAL_ALIGNMENT_CENTER, 620.0, 22, Color.WHITE)

func _draw_party_lobby() -> void:
    draw_rect(Rect2(390.0, 270.0, 820.0, 300.0), Color(0.01, 0.02, 0.04, 0.97))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 340.0), "LOCAL PARTY ONLY", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 38, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 405.0), "P1: press SPACE when ready", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 24, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 450.0), "P2: press ENTER when ready", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 24, Color("#5bc0eb"))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 515.0), "No friend, no heist.", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 20, Color("#c8d5e4"))

func _draw_countdown(seconds: float) -> void:
    draw_circle(Vector2(800.0, 410.0), 82.0, Color(0.02, 0.03, 0.05, 0.88))
    draw_arc(Vector2(800.0, 410.0), 86.0, 0.0, TAU, 64, Color("#ffd166"), 7.0)
    draw_string(ThemeDB.fallback_font, Vector2(720.0, 440.0), str(ceili(seconds)), HORIZONTAL_ALIGNMENT_CENTER, 160.0, 82, Color.WHITE)
