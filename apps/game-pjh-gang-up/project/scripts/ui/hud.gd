extends Control

var world
var spectate_slot: int = 0
var hud_mode: int = 0
var player_colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc")]

func _draw() -> void:
    if world == null:
        return
    var summary: Dictionary = world.summary()
    var me: Dictionary = world.heroes[0]
    if hud_mode == 0:
        _draw_minimal_status(summary, me)
    elif hud_mode == 1:
        _draw_full(summary, me)
        _draw_scoreboard()
    else:
        draw_rect(Rect2(16.0, 16.0, 112.0, 34.0), Color(0.02, 0.03, 0.05, 0.72))
        draw_string(ThemeDB.fallback_font, Vector2(28.0, 39.0), "F1  HUD", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#c8d5e4"))
    if hud_mode == 0 and world.result == &"playing" and bool(me["alive"]):
        _draw_combat_dock(me)
    _draw_match_clock()
    _draw_critical(me)
    _draw_ultimate_cinematic()

func _draw_match_clock() -> void:
    var remaining: float = maxf(0.0, float(world.MATCH_TIME_LIMIT) - float(world.match_time))
    var display_total: int = maxi(0, ceili(remaining))
    var minutes: int = display_total / 60
    var seconds: int = display_total % 60
    var urgent: bool = remaining <= 10.0 and world.result == &"playing"
    var clock_color: Color = Color("#ff4f68") if urgent else Color("#dbe5f0")
    var pulse: float = 0.78 + sin(float(world.tick) * 0.22) * 0.16 if urgent else 0.88
    draw_rect(Rect2(690.0, 16.0, 220.0, 58.0), Color(0.012, 0.018, 0.028, pulse))
    draw_rect(Rect2(690.0, 16.0, 220.0, 58.0), Color(clock_color, 0.92 if urgent else 0.36), false, 4.0 if urgent else 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(710.0, 39.0), "HP DECISION", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 12, Color(clock_color, 0.88))
    draw_string(ThemeDB.fallback_font, Vector2(710.0, 67.0), "%d:%02d" % [minutes, seconds], HORIZONTAL_ALIGNMENT_CENTER, 180.0, 27, clock_color)
    if urgent:
        var countdown := maxi(1, ceili(remaining))
        draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(clock_color, 0.34 + sin(float(world.tick) * 0.22) * 0.08), false, 9.0)
        draw_string(ThemeDB.fallback_font, Vector2(610.0, 178.0), "DECISION IN %d" % countdown, HORIZONTAL_ALIGNMENT_CENTER, 380.0, 34, Color(clock_color, 0.92))

func _draw_match_result() -> void:
    draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(0.005, 0.008, 0.014, 0.72))
    if world.winner_slot < 0:
        draw_rect(Rect2(430.0, 290.0, 740.0, 260.0), Color(0.02, 0.03, 0.05, 0.98))
        draw_string(ThemeDB.fallback_font, Vector2(470.0, 410.0), "DRAW", HORIZONTAL_ALIGNMENT_CENTER, 660.0, 54, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(470.0, 478.0), "NO CORE SURVIVED", HORIZONTAL_ALIGNMENT_CENTER, 660.0, 22, Color("#aebaca"))
        return
    var winner: Dictionary = world.heroes[world.winner_slot]
    var equipment: Dictionary = winner["equipment"]
    var accent: Color = player_colors[world.winner_slot]
    var reason_title := "HP DECISION WINNER" if world.result_reason == &"time_limit" else "LAST CORE STANDING"
    draw_rect(Rect2(330.0, 154.0, 940.0, 592.0), Color(0.012, 0.018, 0.028, 0.98))
    draw_rect(Rect2(330.0, 154.0, 940.0, 592.0), Color(accent, 0.92), false, 6.0)
    draw_rect(Rect2(330.0, 154.0, 940.0, 72.0), Color(accent, 0.17))
    draw_string(ThemeDB.fallback_font, Vector2(375.0, 201.0), reason_title, HORIZONTAL_ALIGNMENT_CENTER, 850.0, 23, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(375.0, 278.0), "P%d  %s  WINS" % [world.winner_slot + 1, equipment["character_name"]], HORIZONTAL_ALIGNMENT_CENTER, 850.0, 48, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(375.0, 318.0), "%s  /  %s  /  %s" % [equipment["role"], equipment["name"], equipment["special_name"]], HORIZONTAL_ALIGNMENT_CENTER, 850.0, 18, Color(accent))
    draw_rect(Rect2(422.0, 346.0, 756.0, 72.0), Color(0.035, 0.048, 0.068, 0.95))
    draw_string(ThemeDB.fallback_font, Vector2(445.0, 379.0), "HP  %d%%" % roundi(world.decision_hp_ratio * 100.0), HORIZONTAL_ALIGNMENT_CENTER, 210.0, 25, Color("#6ef3a5"))
    draw_string(ThemeDB.fallback_font, Vector2(695.0, 379.0), "CORE  %d%%" % roundi(world.decision_core_ratio * 100.0), HORIZONTAL_ALIGNMENT_CENTER, 210.0, 25, Color("#70e7ff"))
    draw_string(ThemeDB.fallback_font, Vector2(945.0, 379.0), "SCORE  %d" % roundi(float(winner["score"])), HORIZONTAL_ALIGNMENT_CENTER, 210.0, 25, Color("#ffd166"))
    var standings: Array[Dictionary] = world.final_standings()
    draw_string(ThemeDB.fallback_font, Vector2(410.0, 455.0), "FINAL STANDINGS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#aebaca"))
    for rank in range(mini(3, standings.size())):
        var row: Dictionary = standings[rank]
        var slot := int(row["slot"])
        var row_equipment: Dictionary = world.heroes[slot]["equipment"]
        var row_y := 490.0 + rank * 52.0
        draw_rect(Rect2(404.0, row_y - 27.0, 792.0, 42.0), Color(player_colors[slot], 0.16 if rank > 0 else 0.28))
        draw_circle(Vector2(430.0, row_y - 6.0), 9.0, player_colors[slot])
        draw_string(ThemeDB.fallback_font, Vector2(452.0, row_y), "%d   P%d  %s / %s" % [rank + 1, slot + 1, row_equipment["character_name"], row_equipment["name"]], HORIZONTAL_ALIGNMENT_LEFT, 380.0, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(845.0, row_y), "HP %3d%%" % roundi(float(row["hp_ratio"]) * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 92.0, 15, Color("#6ef3a5"))
        draw_string(ThemeDB.fallback_font, Vector2(952.0, row_y), "CORE %3d%%" % roundi(float(row["core_ratio"]) * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 112.0, 15, Color("#70e7ff"))
        draw_string(ThemeDB.fallback_font, Vector2(1076.0, row_y), "%5d" % roundi(float(row["score"])), HORIZONTAL_ALIGNMENT_RIGHT, 86.0, 15, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(450.0, 701.0), "PRESS R FOR REMATCH", HORIZONTAL_ALIGNMENT_CENTER, 700.0, 19, Color("#dbe5f0"))

func _draw_ultimate_cinematic() -> void:
    if world.ultimate_focus_time <= 0.0 or world.ultimate_focus_slot < 0 or world.ultimate_focus_slot >= world.heroes.size():
        return
    var actor: Dictionary = world.heroes[world.ultimate_focus_slot]
    var equipment: Dictionary = actor["equipment"]
    var ratio := clampf(world.ultimate_focus_time / maxf(0.01, world.ultimate_focus_max), 0.0, 1.0)
    var fade := sin(ratio * PI)
    draw_rect(Rect2(0.0, 0.0, 1600.0, 54.0), Color(0.01, 0.01, 0.02, fade * 0.72))
    draw_rect(Rect2(0.0, 846.0, 1600.0, 54.0), Color(0.01, 0.01, 0.02, fade * 0.72))
    var banner := Rect2(560.0, 112.0, 480.0, 58.0)
    draw_rect(banner, Color(0.025, 0.030, 0.045, fade * 0.92))
    draw_rect(Rect2(banner.position, Vector2(6.0, banner.size.y)), player_colors[world.ultimate_focus_slot])
    draw_string(ThemeDB.fallback_font, banner.position + Vector2(24.0, 24.0), "P%d  %s" % [world.ultimate_focus_slot + 1, equipment["character_name"]], HORIZONTAL_ALIGNMENT_LEFT, 160.0, 13, Color(Color("#c8d5e4"), fade))
    draw_string(ThemeDB.fallback_font, banner.position + Vector2(24.0, 47.0), str(equipment["ultimate_name"]), HORIZONTAL_ALIGNMENT_LEFT, 430.0, 22, Color(Color("#ff8dac"), fade))

func _draw_minimal_status(summary: Dictionary, me: Dictionary) -> void:
    var equipment: Dictionary = me["equipment"]
    var hp_ratio := clampf(float(me["hp"]) / float(me["max_hp"]), 0.0, 1.0)
    draw_rect(Rect2(16.0, 16.0, 500.0, 76.0), Color(0.012, 0.018, 0.028, 0.88))
    draw_rect(Rect2(16.0, 16.0, 5.0, 76.0), player_colors[0])
    draw_string(ThemeDB.fallback_font, Vector2(34.0, 43.0), "%s  ·  %s" % [equipment["character_name"], equipment["name"]], HORIZONTAL_ALIGNMENT_LEFT, 300.0, 18, Color.WHITE)
    draw_rect(Rect2(34.0, 54.0, 208.0, 9.0), Color("#252b36"))
    draw_rect(Rect2(34.0, 54.0, 208.0 * hp_ratio, 9.0), Color("#6ef3a5") if hp_ratio > 0.34 else Color("#ff5d73"))
    draw_string(ThemeDB.fallback_font, Vector2(250.0, 65.0), "%d / %d" % [roundi(float(me["hp"])), roundi(float(me["max_hp"]))], HORIZONTAL_ALIGNMENT_LEFT, 90.0, 13, Color("#dbe5f0"))
    var streak_text := "  ·  x%d" % int(me.get("kill_streak", 0)) if int(me.get("kill_streak", 0)) > 0 else ""
    draw_string(ThemeDB.fallback_font, Vector2(342.0, 42.0), "SCORE %d%s" % [roundi(float(me["score"])), streak_text], HORIZONTAL_ALIGNMENT_LEFT, 150.0, 13, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(342.0, 66.0), "CORE %d  ·  %d/6" % [roundi(float(world.cores[0]["hp"])), int(summary["alive"])], HORIZONTAL_ALIGNMENT_LEFT, 150.0, 13, Color("#aebaca"))

func _draw_combat_dock(me: Dictionary) -> void:
    var equipment: Dictionary = me["equipment"]
    var skill_cd: float = float(me["equipment_cd"])
    var skill_max: float = maxf(0.01, float(equipment["cooldown"]))
    var skill_charging: bool = bool(me["charging_skill"])
    var skill_charge: float = clampf(float(me["charge_time"]) / 1.15, 0.0, 1.0)
    var mobility_cd: float = float(me["mobility_cd"])
    var mobility_max: float = maxf(0.01, float(equipment["mobility_cooldown"]))
    var ultimate_fill := clampf(float(me["ultimate_charge"]) / float(world.ULTIMATE_MAX), 0.0, 1.0)
    var dock_rect := Rect2(385.0, 796.0, 830.0, 88.0)
    draw_rect(dock_rect, Color(0.008, 0.012, 0.020, 0.84))
    draw_line(Vector2(dock_rect.position.x, dock_rect.position.y), Vector2(dock_rect.end.x, dock_rect.position.y), Color(0.32, 0.38, 0.48, 0.72), 2.0)
    _draw_normal_slot(Rect2(401.0, 808.0, 168.0, 62.0), equipment)
    _draw_ability_slot(Rect2(582.0, 808.0, 178.0, 62.0), "RMB", str(equipment["skill_name"]), skill_cd, skill_max, Color("#62d9ef"), skill_charge if skill_charging else -1.0)
    _draw_ability_slot(Rect2(773.0, 808.0, 142.0, 62.0), "SPACE", str(equipment["mobility_name"]), mobility_cd, mobility_max, Color("#66e09a"), -1.0)
    _draw_ultimate_slot(Rect2(928.0, 808.0, 271.0, 62.0), str(equipment["ultimate_name"]), ultimate_fill)

func _draw_normal_slot(rect: Rect2, equipment: Dictionary) -> void:
    draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 19.0), "LMB", HORIZONTAL_ALIGNMENT_LEFT, 42.0, 12, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(48.0, 19.0), str(equipment["normal_name"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56.0, 12, Color("#dbe5f0"))
    draw_line(rect.position + Vector2(13.0, 44.0), rect.position + Vector2(46.0, 44.0), Color("#ffd166"), 3.0)
    draw_colored_polygon(PackedVector2Array([rect.position + Vector2(46.0, 38.0), rect.position + Vector2(57.0, 44.0), rect.position + Vector2(46.0, 50.0)]), Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(64.0, 49.0), "AIM ASSIST", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 72.0, 11, Color("#aebaca"))

func _draw_ability_slot(rect: Rect2, key_text: String, title: String, cooldown: float, cooldown_max: float, color: Color, charge: float) -> void:
    var ready := cooldown <= 0.0
    var fill := clampf(1.0 - cooldown / maxf(0.01, cooldown_max), 0.0, 1.0)
    if charge >= 0.0:
        fill = charge
    draw_rect(rect, Color(0.042, 0.050, 0.066, 0.96))
    draw_rect(Rect2(rect.position, Vector2(rect.size.x * fill, rect.size.y)), Color(color, 0.16 if ready or charge >= 0.0 else 0.08))
    draw_rect(rect, Color(color, 0.90 if ready or charge >= 0.0 else 0.28), false, 2.0)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(9.0, 18.0), key_text, HORIZONTAL_ALIGNMENT_LEFT, 54.0, 11, color)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(9.0, 48.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 18.0, 13, Color.WHITE if ready or charge >= 0.0 else Color("#7f8998"))
    if charge >= 0.0:
        draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 66.0, 24.0), "%d%%" % roundi(charge * 100.0), HORIZONTAL_ALIGNMENT_RIGHT, 54.0, 17, color)
    elif not ready:
        draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 62.0, 25.0), "%.1f" % cooldown, HORIZONTAL_ALIGNMENT_RIGHT, 50.0, 20, Color("#c5ccd6"))
    else:
        draw_circle(rect.position + Vector2(rect.size.x - 13.0, 13.0), 4.0, color)

func _draw_ultimate_slot(rect: Rect2, title: String, fill: float) -> void:
    var color := Color("#ff5d91")
    var ready := fill >= 1.0
    draw_rect(rect, Color(0.050, 0.038, 0.055, 0.96))
    draw_rect(Rect2(rect.position, Vector2(rect.size.x * fill, rect.size.y)), Color(color, 0.22))
    draw_rect(rect, Color(color, 0.96 if ready else 0.42), false, 3.0 if ready else 2.0)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 20.0), "Q", HORIZONTAL_ALIGNMENT_CENTER, 22.0, 14, color)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(40.0, 20.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 106.0, 13, Color.WHITE)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 68.0, 22.0), "READY" if ready else "%d%%" % roundi(fill * 100.0), HORIZONTAL_ALIGNMENT_RIGHT, 56.0, 15, color if ready else Color("#d4b4c0"))
    draw_rect(Rect2(rect.position + Vector2(10.0, 43.0), Vector2(rect.size.x - 20.0, 7.0)), Color("#302333"))
    draw_rect(Rect2(rect.position + Vector2(10.0, 43.0), Vector2((rect.size.x - 20.0) * fill, 7.0)), color)

func _draw_compact(summary: Dictionary, me: Dictionary) -> void:
    var equipment: Dictionary = me["equipment"]
    var hp_ratio := clampf(float(me["hp"]) / float(me["max_hp"]), 0.0, 1.0)
    draw_rect(Rect2(16.0, 16.0, 610.0, 88.0), Color(0.02, 0.03, 0.05, 0.86))
    draw_rect(Rect2(16.0, 16.0, 6.0, 88.0), Color("#e55934"))
    draw_string(ThemeDB.fallback_font, Vector2(36.0, 45.0), "P1 %s / %s  -  %s" % [equipment["character_name"], equipment["role"], equipment["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color.WHITE)
    draw_rect(Rect2(36.0, 57.0, 270.0, 8.0), Color("#252b36"))
    draw_rect(Rect2(36.0, 57.0, 270.0 * hp_ratio, 8.0), Color("#6ef3a5"))
    draw_string(ThemeDB.fallback_font, Vector2(319.0, 67.0), "HP %d/%d" % [roundi(float(me["hp"])), roundi(float(me["max_hp"]))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#dbe5f0"))
    draw_string(ThemeDB.fallback_font, Vector2(36.0, 91.0), "SCORE %d   CORE %d   ALIVE %d/6   F1 상세/숨김" % [roundi(float(me["score"])), roundi(float(world.cores[0]["hp"])), summary["alive"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#ffd166"))

func _draw_action_bar(me: Dictionary) -> void:
    var equipment: Dictionary = me["equipment"]
    var skill_cd: float = float(me["equipment_cd"])
    var skill_max: float = maxf(0.01, float(equipment["cooldown"]))
    var skill_charging: bool = bool(me["charging_skill"])
    var skill_charge: float = clampf(float(me["charge_time"]) / 1.15, 0.0, 1.0)
    var skill_ready: bool = skill_cd <= 0.0 and not skill_charging
    var skill_state := "CHARGING %d%%" % roundi(skill_charge * 100.0) if skill_charging else ("READY" if skill_ready else "%.1fs" % skill_cd)
    if str(equipment["id"]) == "bomb":
        var mine_count := 0
        for installed in world.deployables:
            if int(installed["owner"]) == 0 and StringName(installed.get("type", &"mine")) == &"mine" and not bool(installed.get("ultimate", false)):
                mine_count += 1
        skill_state += "  MINE %d/2" % mine_count
    elif str(equipment["id"]) == "shield":
        var wall_active := false
        for installed in world.deployables:
            if int(installed["owner"]) == 0 and StringName(installed.get("type", &"mine")) == &"wall":
                wall_active = true
        skill_state += "  WALL MOVING" if wall_active else "  WALL READY"
    var skill_fill := skill_charge if skill_charging else clampf(1.0 - skill_cd / skill_max, 0.0, 1.0)
    var mobility_cd: float = float(me["mobility_cd"])
    var mobility_max: float = maxf(0.01, float(equipment["mobility_cooldown"]))
    var mobility_ready: bool = mobility_cd <= 0.0
    var ultimate_fill := clampf(float(me["ultimate_charge"]) / world.ULTIMATE_MAX, 0.0, 1.0)
    var base_x := 282.0
    var card_y := 780.0
    var card_size := Vector2(250.0, 102.0)
    var gap := 12.0
    draw_rect(Rect2(base_x - 12.0, card_y - 10.0, card_size.x * 4.0 + gap * 3.0 + 24.0, card_size.y + 20.0), Color(0.01, 0.015, 0.025, 0.74))
    _draw_action_card(Rect2(base_x, card_y, card_size.x, card_size.y), "LMB", equipment["normal_name"], "AIM ASSIST", 1.0, Color("#ffd166"), true)
    _draw_action_card(Rect2(base_x + (card_size.x + gap), card_y, card_size.x, card_size.y), "RMB", equipment["skill_name"], skill_state, skill_fill, Color("#70e7ff"), skill_ready or skill_charging)
    _draw_action_card(Rect2(base_x + (card_size.x + gap) * 2.0, card_y, card_size.x, card_size.y), "SPACE", equipment["mobility_name"], "READY" if mobility_ready else "%.1fs" % mobility_cd, clampf(1.0 - mobility_cd / mobility_max, 0.0, 1.0), Color("#6ef3a5"), mobility_ready)
    _draw_action_card(Rect2(base_x + (card_size.x + gap) * 3.0, card_y, card_size.x, card_size.y), "Q", equipment["ultimate_name"], "READY - CANCEL OK" if ultimate_fill >= 1.0 else "%d%%" % roundi(ultimate_fill * 100.0), ultimate_fill, Color("#ff5d91"), ultimate_fill >= 1.0)

func _draw_action_card(rect: Rect2, key_text: String, title: String, state: String, fill: float, color: Color, ready: bool) -> void:
    var pulse := 0.72 + sin(float(world.tick) * 0.18) * 0.16 if ready else 0.32
    draw_rect(rect, Color(0.045, 0.055, 0.075, 0.94))
    draw_rect(rect, Color(color, pulse), false, 3.0 if ready else 1.0)
    draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 8.0), Vector2(rect.size.x, 8.0)), Color("#252b36"))
    draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 8.0), Vector2(rect.size.x * clampf(fill, 0.0, 1.0), 8.0)), color)
    draw_rect(Rect2(rect.position + Vector2(10.0, 10.0), Vector2(58.0, 25.0)), Color(color, 0.25))
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 29.0), key_text, HORIZONTAL_ALIGNMENT_CENTER, 58.0, 14, Color.WHITE)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(77.0, 29.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 87.0, 14, Color.WHITE)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(12.0, 68.0), state, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24.0, 18 if ready else 16, color if ready else Color("#c8d5e4"))

func _draw_full(summary: Dictionary, me: Dictionary) -> void:
    var equipment: Dictionary = me["equipment"]
    var equipment_state := "CHARGE %d%%" % roundi(float(me["charge_time"]) / 1.15 * 100.0) if bool(me["charging_skill"]) else ("READY" if float(me["equipment_cd"]) <= 0.0 else "%.1fs" % float(me["equipment_cd"]))
    var mobility_state := "READY" if float(me["mobility_cd"]) <= 0.0 else "%.1fs" % float(me["mobility_cd"])
    var ultimate_ratio := clampf(float(me["ultimate_charge"]) / world.ULTIMATE_MAX, 0.0, 1.0)
    draw_rect(Rect2(16.0, 16.0, 850.0, 300.0), Color(0.02, 0.03, 0.05, 0.91))
    draw_rect(Rect2(16.0, 16.0, 7.0, 300.0), Color("#e55934"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 47.0), "P1 %s / %s  -  %s" % [equipment["character_name"], equipment["role"], equipment["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 21, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 77.0), "생존 %d/6  HP %d/%d  SPD %d  WT %.2f  |  %s: %s" % [summary["alive"], roundi(float(me["hp"])), roundi(float(me["max_hp"])), roundi(float(equipment["move_speed"])), float(equipment["weight"]), equipment["special_name"], equipment["special_desc"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 108.0), "LMB %s  |  AIM ASSIST  |  RANGE %dm" % [equipment["normal_name"], roundi(world._normal_reach(0))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#dbe5f0"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 137.0), "RMB HOLD/RELEASE %s [%s] - %s" % [equipment["skill_name"], equipment_state, equipment["skill_desc"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#70e7ff"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 166.0), "SPACE %s [%s] - %s" % [equipment["mobility_name"], mobility_state, equipment["mobility_desc"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#6ef3a5"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 195.0), "Q %s - %s" % [equipment["ultimate_name"], equipment["ultimate_desc"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#ff8dac"))
    draw_rect(Rect2(38.0, 211.0, 790.0, 17.0), Color("#252b36"))
    draw_rect(Rect2(38.0, 211.0, 790.0 * ultimate_ratio, 17.0), Color("#ff5d73"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 226.0), "ULT %d / 100%s" % [roundi(float(me["ultimate_charge"])), "  READY" if ultimate_ratio >= 1.0 else ""], HORIZONTAL_ALIGNMENT_CENTER, 790.0, 12, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 258.0), "코어: 다운/CC 때만 노출  |  비행 중 벽 충돌 최대 3회 추가 피해  |  사망 시 10초", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#d8b4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(38.0, 287.0), "WASD 이동  LMB 일반  RMB 스킬  SPACE 이동기  Q 필살기  R 새 판  F1 HUD 전환", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#c8d5e4"))

func _draw_scoreboard() -> void:
    var rows: Array[Dictionary] = world.leaderboard()
    draw_rect(Rect2(940.0, 16.0, 644.0, 270.0), Color(0.02, 0.03, 0.05, 0.91))
    draw_string(ThemeDB.fallback_font, Vector2(960.0, 44.0), "실시간 순위  CHARACTER / EQUIPMENT       SCORE  D/D  CORE  STATE       ULT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#ffd166"))
    for rank in range(rows.size()):
        var row: Dictionary = rows[rank]
        var slot := int(row["slot"])
        var hero: Dictionary = world.heroes[slot]
        var equipment: Dictionary = hero["equipment"]
        var state := "LIVE"
        if bool(hero["eliminated"]):
            state = "OUT"
        elif not bool(hero["alive"]):
            state = "DOWN %.1f" % float(hero["respawn"])
        elif float(hero.get("stun_time", 0.0)) > 0.0:
            state = "STUN"
        elif float(hero.get("root_time", 0.0)) > 0.0:
            state = "ROOT"
        elif float(hero["cc_time"]) > 0.0:
            state = "CC"
        elif int(hero.get("kill_streak", 0)) >= 2:
            state = "LIVE x%d" % int(hero["kill_streak"])
        var y := 76.0 + rank * 31.0
        var row_color: Color = Color("#283242") if slot == 0 else Color(0.08, 0.10, 0.14, 0.72)
        draw_rect(Rect2(952.0, y - 19.0, 620.0, 26.0), row_color)
        draw_circle(Vector2(967.0, y - 6.0), 6.0, player_colors[slot])
        draw_string(ThemeDB.fallback_font, Vector2(980.0, y), "%d  P%d %s / %s" % [rank + 1, slot + 1, equipment["character_name"], equipment["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(1280.0, y), "%4d" % roundi(float(row["score"])), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#ffd166"))
        draw_string(ThemeDB.fallback_font, Vector2(1340.0, y), "%d/%d" % [int(row["kills"]), int(row["deaths"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#dbe5f0"))
        draw_string(ThemeDB.fallback_font, Vector2(1395.0, y), "%3d" % roundi(float(world.cores[slot]["hp"])), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#6ef3a5"))
        draw_string(ThemeDB.fallback_font, Vector2(1442.0, y), state, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#ff9ca4") if state != "LIVE" else Color("#8be3ff"))
        var ultimate_ready: bool = float(hero["ultimate_charge"]) >= float(world.ULTIMATE_MAX)
        draw_string(ThemeDB.fallback_font, Vector2(1512.0, y), "READY" if ultimate_ready else "%d%%" % roundi(float(hero["ultimate_charge"])), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#ff5d91") if ultimate_ready else Color("#c8a5b8"))
    draw_string(ThemeDB.fallback_font, Vector2(958.0, 274.0), "점수 = 피해 + 다운 120 + 연속 처치/처단 보너스 + 탈락 300 + 승리 500", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#aab8c8"))

func _draw_critical(me: Dictionary) -> void:
    if bool(me["alive"]) and float(me.get("stun_time", 0.0)) > 0.0:
        draw_rect(Rect2(550.0, 660.0, 500.0, 48.0), Color(0.10, 0.06, 0.0, 0.90))
        draw_string(ThemeDB.fallback_font, Vector2(570.0, 692.0), "STUNNED  |  INPUT LOCKED", HORIZONTAL_ALIGNMENT_CENTER, 460.0, 20, Color("#ffe27a"))
    elif bool(me["alive"]) and float(me.get("root_time", 0.0)) > 0.0:
        draw_rect(Rect2(510.0, 660.0, 580.0, 48.0), Color(0.07, 0.025, 0.12, 0.90))
        draw_string(ThemeDB.fallback_font, Vector2(530.0, 691.0), "ROOTED  |  MOVE/SPACE LOCKED - ATTACK/Q AVAILABLE", HORIZONTAL_ALIGNMENT_CENTER, 540.0, 17, Color("#d8b4ff"))
    if world.last_down_ticks > 0 and world.last_down_slot >= 0:
        var down_alpha := clampf(float(world.last_down_ticks) / 18.0, 0.0, 1.0)
        var down_hero: Dictionary = world.heroes[world.last_down_slot]
        draw_rect(Rect2(360.0, 190.0, 880.0, 88.0), Color(0.18, 0.0, 0.025, 0.90 * down_alpha))
        draw_rect(Rect2(360.0, 190.0, 880.0, 88.0), Color("#ff3349", down_alpha), false, 8.0)
        draw_string(ThemeDB.fallback_font, Vector2(390.0, 247.0), "P%d %s님이 쓰러졌습니다." % [world.last_down_slot + 1, down_hero["equipment"]["character_name"]], HORIZONTAL_ALIGNMENT_CENTER, 820.0, 38, Color.WHITE)
    if world.callout_ticks > 0 and world.result == &"playing":
        var alpha := clampf(float(world.callout_ticks) / 24.0, 0.0, 1.0)
        draw_rect(Rect2(560.0, 108.0, 480.0, 38.0), Color(0.025, 0.025, 0.04, 0.82 * alpha))
        draw_string(ThemeDB.fallback_font, Vector2(580.0, 133.0), world.callout, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 15, Color(1.0, 0.74, 0.42, alpha))
    if world.streak_callout_ticks > 0 and world.result == &"playing":
        var streak_alpha := clampf(float(world.streak_callout_ticks) / 18.0, 0.0, 1.0)
        var streak_color := Color("#ff4f68") if world.streak_callout_shutdown else Color("#ffd166")
        draw_rect(Rect2(430.0, 290.0, 740.0, 76.0), Color(0.025, 0.018, 0.025, 0.92 * streak_alpha))
        draw_rect(Rect2(430.0, 290.0, 740.0, 76.0), Color(streak_color, streak_alpha), false, 5.0)
        draw_string(ThemeDB.fallback_font, Vector2(455.0, 320.0), world.streak_callout, HORIZONTAL_ALIGNMENT_CENTER, 690.0, 25, Color(streak_color, streak_alpha))
        draw_string(ThemeDB.fallback_font, Vector2(455.0, 348.0), world.streak_subtitle, HORIZONTAL_ALIGNMENT_CENTER, 690.0, 15, Color(Color.WHITE, streak_alpha))
    if world.start_countdown > 0.0:
        var count_text := str(ceili(world.start_countdown))
        draw_circle(Vector2(800.0, 450.0), 82.0, Color(0.02, 0.03, 0.05, 0.88))
        draw_arc(Vector2(800.0, 450.0), 86.0, 0.0, TAU, 64, Color("#ff5d73"), 7.0)
        draw_string(ThemeDB.fallback_font, Vector2(720.0, 480.0), count_text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 82, Color.WHITE)
    elif not bool(me["alive"]) and world.result == &"playing":
        var target_slot := spectate_slot if spectate_slot > 0 and spectate_slot < world.heroes.size() else 0
        var target: Dictionary = world.heroes[target_slot]
        var target_equipment: Dictionary = target["equipment"]
        draw_rect(Rect2(455.0, 786.0, 690.0, 90.0), Color(0.04, 0.02, 0.06, 0.88))
        draw_string(ThemeDB.fallback_font, Vector2(475.0, 816.0), "관전 P%d %s / %s" % [target_slot + 1, target_equipment["character_name"], target_equipment["name"]], HORIZONTAL_ALIGNMENT_CENTER, 650.0, 20, Color("#d8b4ff"))
        var status := "탈락 - 관전 중" if bool(me["eliminated"]) else "부활까지 %.1f초" % float(me["respawn"])
        draw_string(ThemeDB.fallback_font, Vector2(475.0, 843.0), status, HORIZONTAL_ALIGNMENT_CENTER, 650.0, 16, Color("#ff8d93"))
        draw_string(ThemeDB.fallback_font, Vector2(475.0, 867.0), "A/D 또는 TAB: 관전 대상 변경  |  SPACE: 1위 자동 추적", HORIZONTAL_ALIGNMENT_CENTER, 650.0, 14, Color.WHITE)
    if world.result != &"playing":
        _draw_match_result()
