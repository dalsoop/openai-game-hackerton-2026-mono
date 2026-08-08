extends Control

var world

func _draw() -> void:
    if world == null:
        return
    var p1: Dictionary = world.heroes[0]
    var p2: Dictionary = world.heroes[1]
    draw_rect(Rect2(18.0, 16.0, 1040.0, 166.0), Color(0.02, 0.025, 0.04, 0.93))
    draw_rect(Rect2(18.0, 16.0, 7.0, 166.0), Color("#ff6b6b"))
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 48.0), "VILLAGE LAST STAND  |  WAVE %d / 12" % world.wave_index, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 80.0), "VILLAGE %d/%d   ENEMIES %d   BELL %d   SYNERGY %d   REVIVES %d" % [int(world.village_hp), int(world.village_hp_max), _alive_enemies(), world.bell_tokens, world.role_synergies, world.combat_revives], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 111.0), "P1 %s HP%d K%d A%d COMBO%d DEBT%d | LMB fire, Q skill, E stasis, SPACE bell" % [String(p1["role"]).to_upper(), int(p1["hp"]), int(p1["kills"]), int(p1["assists"]), int(p1["combo"]), int(p1["chaos_debt"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 139.0), "P2 %s HP%d K%d A%d COMBO%d DEBT%d | ENTER fire, SHIFT skill, . stasis, / bell" % [String(p2["role"]).to_upper(), int(p2["hp"]), int(p2["kills"]), int(p2["assists"]), int(p2["combo"]), int(p2["chaos_debt"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#5bc0eb"))
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 166.0), "GATES N%d E%d S%d W%d  FALLS %d REOPENS %d | Engineer skills repair the nearest gate." % [int(world.gate_hp[0]), int(world.gate_hp[1]), int(world.gate_hp[2]), int(world.gate_hp[3]), world.gate_collapses, world.gate_repairs], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#9de7ff"))
    if not world.party_ready:
        _draw_party_lobby()
        return
    if world.start_countdown_ticks > 0:
        var seconds := float(world.start_countdown_ticks) / 60.0
        draw_circle(Vector2(800.0, 410.0), 82.0, Color(0.02, 0.03, 0.05, 0.90))
        draw_string(ThemeDB.fallback_font, Vector2(720.0, 440.0), str(ceili(seconds)), HORIZONTAL_ALIGNMENT_CENTER, 160.0, 82, Color.WHITE)
    if world.recent_message != "":
        draw_rect(Rect2(400.0, 790.0, 800.0, 58.0), Color(0.02, 0.03, 0.04, 0.93))
        draw_string(ThemeDB.fallback_font, Vector2(425.0, 828.0), world.recent_message, HORIZONTAL_ALIGNMENT_CENTER, 750.0, 21, Color("#ffe499"))
    if world.result != &"playing":
        draw_rect(Rect2(470.0, 330.0, 660.0, 180.0), Color(0.01, 0.02, 0.04, 0.97))
        var title := "VILLAGE SAVED!" if world.result == &"victory" else "THE VILLAGE FELL - BUT THE LAST GASP WAS GLORIOUS"
        draw_string(ThemeDB.fallback_font, Vector2(500.0, 407.0), title, HORIZONTAL_ALIGNMENT_CENTER, 600.0, 27, Color("#ffd166"))
        draw_string(ThemeDB.fallback_font, Vector2(500.0, 462.0), "Press R to run it back", HORIZONTAL_ALIGNMENT_CENTER, 600.0, 21, Color.WHITE)

func _alive_enemies() -> int:
    var count := 0
    for enemy in world.enemies:
        if bool(enemy["alive"]):
            count += 1
    return count

func _draw_party_lobby() -> void:
    draw_rect(Rect2(390.0, 270.0, 820.0, 300.0), Color(0.01, 0.02, 0.04, 0.97))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 340.0), "TWO HEROES REQUIRED", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 38, Color("#ff6b6b"))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 405.0), "P1: press SPACE when ready", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 24, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 450.0), "P2: press ENTER when ready", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 24, Color("#5bc0eb"))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 515.0), "No solo defense. The village needs an argument.", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 20, Color("#c8d5e4"))
