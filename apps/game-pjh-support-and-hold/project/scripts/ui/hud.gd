extends Control

var world

func _draw() -> void:
    if world == null:
        return
    var soldier: Dictionary = world.actors[0]
    var supplier: Dictionary = world.actors[3]
    draw_rect(Rect2(18.0, 16.0, 1110.0, 166.0), Color(0.02, 0.025, 0.04, 0.93))
    draw_rect(Rect2(18.0, 16.0, 7.0, 166.0), Color("#59d8ff"))
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 48.0), "SUPPORT AND HOLD  |  PHASE %d / 5" % world.phase, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 80.0), "BASE %d/%d   HIVE %d/%d   DELIVERED %d   LOST %d" % [int(world.base_hp), int(world.base_hp_max), int(world.hive_hp), int(world.hive_hp_max), world.deliveries_completed, world.deliveries_destroyed], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 111.0), "P1 SOLDIER  HP %d  AMMO %d  |  WASD + MOUSE, LMB fire, Q grenade, F ammo, E med, SPACE barrier" % [int(soldier["hp"]), int(soldier["ammo"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 139.0), "P2 SUPPLIER  %s [%d/%d/%d] -> P%d  |  ENTER send, hold / risky, . item, SHIFT target" % [String(supplier["selected_supply"]).to_upper(), int(supplier["stock_ammo"]), int(supplier["stock_med"]), int(supplier["stock_barrier"]), world.party_target + 1], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#59d8ff"))
    draw_string(ThemeDB.fallback_font, Vector2(40.0, 166.0), "MORALE %d  REVIVES %d  LANE COVERS %d  CLUTCH %d  BOTCH %d  |  A rescue can expose the covering lane." % [int(world.team_morale), world.support_revives, world.lane_covers, world.clutch_detonations, world.botched_detonations], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#9de7ff"))
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
        var title := "HIVE DOWN - TEAMWORK WINS!" if world.result == &"victory" else "BASE LOST - CHECK THE SUPPLY CHAIN"
        draw_string(ThemeDB.fallback_font, Vector2(500.0, 407.0), title, HORIZONTAL_ALIGNMENT_CENTER, 600.0, 27, Color("#ffd166"))
        draw_string(ThemeDB.fallback_font, Vector2(500.0, 462.0), "Press R to rebuild the friendship", HORIZONTAL_ALIGNMENT_CENTER, 600.0, 21, Color.WHITE)

func _draw_party_lobby() -> void:
    draw_rect(Rect2(390.0, 270.0, 820.0, 300.0), Color(0.01, 0.02, 0.04, 0.97))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 340.0), "SOLDIER + SUPPLIER REQUIRED", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 34, Color("#59d8ff"))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 405.0), "P1: press SPACE when ready", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 24, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 450.0), "P2: press ENTER when ready", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 24, Color("#59d8ff"))
    draw_string(ThemeDB.fallback_font, Vector2(430.0, 515.0), "Neither role can carry the match alone.", HORIZONTAL_ALIGNMENT_CENTER, 740.0, 20, Color("#c8d5e4"))
