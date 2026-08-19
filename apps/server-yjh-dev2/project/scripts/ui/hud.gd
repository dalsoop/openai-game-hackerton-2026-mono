extends Control

var world
var spectate_slot: int = 0
var hud_mode: int = 0
var mode_id: String = "classic"
var touch_hints: bool = false
var player_colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc"), Color("#ffe066"), Color("#70e7ff")]

const ZODIAC_NAMES := ["쥐", "소", "호랑이", "토끼", "용", "뱀", "말", "양", "원숭이", "닭", "개", "돼지"]
const MODE_TITLES := {"classic":"클래식", "gun-semi":"단발", "gun-auto":"연발", "item":"아이템", "full":"풀"}
const PANEL_BG := Color(0.012, 0.018, 0.028, 0.86)
const ZONE_PURPLE := Color("#c65cff")

var gun_texture: Texture2D = null
var medkit_texture: Texture2D = null

func _ready() -> void:
    if ResourceLoader.exists("res://assets/items/gun.png"):
        gun_texture = load("res://assets/items/gun.png")
    if ResourceLoader.exists("res://assets/items/medkit.png"):
        medkit_texture = load("res://assets/items/medkit.png")

func _zodiac_name(slot: int) -> String:
    return ZODIAC_NAMES[posmod(slot, 12)]

func _text(pos: Vector2, text: String, size: int, color: Color, width: float = -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
    draw_string(GameFont.get_font(), pos + Vector2(1.5, 1.5), text, align, width, size, Color(0.0, 0.0, 0.0, 0.72 * color.a))
    draw_string(GameFont.get_font(), pos, text, align, width, size, color)

func _draw() -> void:
    if world == null or world.heroes.is_empty():
        return
    var summary: Dictionary = world.summary()
    var me: Dictionary = world.heroes[clampi(world.local_slot, 0, world.heroes.size() - 1)]
    if hud_mode == 0:
        _draw_status_panel(summary, me)
        _draw_mode_chip()
        _draw_minimap()
        _draw_zone_timer()
        if world.result == &"playing" and bool(me["alive"]):
            _draw_hotbar(me)
    elif hud_mode == 1:
        _draw_status_panel(summary, me)
        _draw_mode_chip()
        _draw_minimap()
        _draw_zone_timer()
        _draw_scoreboard()
        if world.result == &"playing" and bool(me["alive"]):
            _draw_hotbar(me)
    else:
        draw_rect(Rect2(16.0, 16.0, 112.0, 34.0), Color(0.02, 0.03, 0.05, 0.72))
        _text(Vector2(28.0, 39.0), "F1  HUD", 14, Color("#c8d5e4"))
    _draw_critical(me)
    _draw_ultimate_cinematic()

func _draw_status_panel(summary: Dictionary, me: Dictionary) -> void:
    var panel := Rect2(16.0, 16.0, 240.0, 74.0 + float(world.heroes.size()) * 22.0)
    draw_rect(panel, PANEL_BG)
    draw_rect(panel, Color(0.32, 0.38, 0.48, 0.55), false, 2.0)
    draw_rect(Rect2(panel.position, Vector2(5.0, panel.size.y)), player_colors[clampi(world.local_slot, 0, player_colors.size() - 1)])
    _text(Vector2(34.0, 46.0), "처치 %d" % int(me["kills"]), 24, Color("#ffd166"))
    _text(Vector2(150.0, 46.0), "생존 %d/%d" % [int(summary["alive"]), world.heroes.size()], 20, Color("#6ef3a5"))
    _text(Vector2(34.0, 68.0), "점수 %d" % roundi(float(me["score"])), 13, Color("#aebaca"))
    var row_y := 92.0
    for slot in range(world.heroes.size()):
        var hero: Dictionary = world.heroes[slot]
        var alive := bool(hero["alive"]) and not bool(hero["eliminated"])
        if slot == world.local_slot:
            draw_rect(Rect2(24.0, row_y - 14.0, 224.0, 22.0), Color(1.0, 1.0, 1.0, 0.08))
        var dot_color: Color = player_colors[slot] if alive else Color(0.35, 0.38, 0.42, 0.9)
        draw_circle(Vector2(34.0, row_y - 4.0), 5.0, dot_color)
        var name_color := Color.WHITE if alive else Color("#6b7480")
        var row_name := str(hero.get("display_name", ""))
        if row_name == "":
            row_name = "P%d %s" % [slot + 1, _zodiac_name(slot)]
        _text(Vector2(46.0, row_y), row_name, 13, name_color, 110.0)
        var state := "%d킬" % int(hero["kills"]) if alive else "탈락"
        _text(Vector2(158.0, row_y), state, 12, Color("#ffd166") if alive else Color("#6b7480"), 76.0)
        row_y += 22.0

func _draw_mode_chip() -> void:
    var title := str(MODE_TITLES.get(mode_id, mode_id))
    var chip := Rect2(700.0, 14.0, 200.0, 34.0)
    draw_rect(chip, PANEL_BG)
    draw_rect(chip, Color(ZONE_PURPLE, 0.55), false, 2.0)
    _text(chip.position + Vector2(0.0, 23.0), "모드 · %s" % title, 15, Color("#e8d5ff"), chip.size.x, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_minimap() -> void:
    if world.heroes.is_empty():
        return
    var center := Vector2(1486.0, 110.0)
    var radius := 88.0
    draw_circle(center, radius + 7.0, PANEL_BG)
    draw_circle(center, radius, Color("#17456f"))
    var scale := (radius * 2.0) / maxf(world.ARENA_SIZE.x, world.ARENA_SIZE.y)
    var arena_center := Vector2(world.ARENA_CENTER)
    draw_circle(center, world.ARENA_SIZE.y * 0.47 * scale, Color("#cbb37a"))
    var zone_center: Vector2 = center + (Vector2(world.safe_zone_center) - arena_center) * scale
    var zone_radius: float = maxf(2.0, float(world.safe_zone_radius) * scale)
    draw_circle(zone_center, zone_radius, Color(0.45, 0.12, 0.75, 0.16))
    var zone_ring := Color("#e05cff") if bool(world.safe_zone_shrinking) else ZONE_PURPLE
    draw_arc(zone_center, zone_radius, 0.0, TAU, 48, zone_ring, 2.5)
    if bool(world.safe_zone_shrinking) or absf(float(world.safe_zone_target_radius) - float(world.safe_zone_radius)) > 4.0:
        draw_arc(zone_center, maxf(2.0, float(world.safe_zone_target_radius) * scale), 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.70), 1.5)
    var focus_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
    if spectate_slot != world.local_slot and spectate_slot >= 0 and spectate_slot < world.heroes.size() and bool(world.heroes[spectate_slot]["alive"]):
        focus_slot = spectate_slot
    for hero in world.heroes:
        var slot := int(hero["slot"])
        if slot == focus_slot or not bool(hero["alive"]) or bool(hero["eliminated"]):
            continue
        var offset := (Vector2(hero["pos"]) - arena_center) * scale
        if offset.length() > radius - 6.0:
            offset = offset.normalized() * (radius - 6.0)
        draw_circle(center + offset, 5.2, Color(0.02, 0.03, 0.05, 0.95))
        draw_circle(center + offset, 3.8, player_colors[slot])
    if focus_slot >= 0 and focus_slot < world.heroes.size() and bool(world.heroes[focus_slot]["alive"]):
        var my_offset := (Vector2(world.heroes[focus_slot]["pos"]) - arena_center) * scale
        if my_offset.length() > radius - 7.0:
            my_offset = my_offset.normalized() * (radius - 7.0)
        var me_pos: Vector2 = center + my_offset
        draw_circle(me_pos, 7.2, Color(0.02, 0.03, 0.05, 0.95))
        draw_circle(me_pos, 5.6, Color.WHITE)
        draw_circle(me_pos, 3.6, Color("#7af7ff"))
    draw_arc(center, radius + 7.0, 0.0, TAU, 56, Color("#8aa0b8", 0.62), 2.0)

func _draw_zone_timer() -> void:
    var status_color := ZONE_PURPLE
    var status_text := ""
    if bool(world.safe_zone_shrinking):
        status_text = "안전 구역 축소 중"
        status_color = Color("#e05cff")
    elif bool(world.safe_zone_complete):
        status_text = "최종 안전 구역"
        status_color = Color("#d8b4ff")
    else:
        var phase := int(world.safe_zone_phase)
        if phase < world.SAFE_ZONE_PHASES.size():
            var wait := float(world.SAFE_ZONE_PHASES[phase]["wait"])
            status_text = "축소까지 %d초" % maxi(0, ceili(wait - float(world.safe_zone_phase_time)))
            status_color = Color("#c9a6ff")
    if bool(world.safe_zone_shrinking):
        status_color.a = 0.75 + sin(float(world.tick) * 0.22) * 0.25
    _text(Vector2(1376.0, 226.0), status_text, 16, status_color, 220.0, HORIZONTAL_ALIGNMENT_CENTER)
    var remaining: float = maxf(0.0, float(world.MATCH_TIME_LIMIT) - float(world.match_time))
    var display_total: int = maxi(0, ceili(remaining))
    var urgent: bool = remaining <= 10.0 and world.result == &"playing"
    var clock_color: Color = Color("#ff4f68") if urgent else Color("#dbe5f0")
    _text(Vector2(1376.0, 258.0), "%d:%02d" % [display_total / 60, display_total % 60], 26, clock_color, 220.0, HORIZONTAL_ALIGNMENT_CENTER)
    if urgent:
        draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(clock_color, 0.34 + sin(float(world.tick) * 0.22) * 0.08), false, 9.0)

func _draw_hotbar(me: Dictionary) -> void:
    var equipment: Dictionary = me["equipment"]
    var bar := Rect2(549.0, 790.0, 502.0, 98.0)
    draw_rect(bar, Color(0.008, 0.012, 0.020, 0.84))
    draw_rect(bar, Color(0.32, 0.38, 0.48, 0.72), false, 2.0)
    var hp_ratio := clampf(float(me["hp"]) / float(me["max_hp"]), 0.0, 1.0)
    draw_rect(Rect2(bar.position + Vector2(8.0, 6.0), Vector2(bar.size.x - 16.0, 8.0)), Color("#252b36"))
    draw_rect(Rect2(bar.position + Vector2(8.0, 6.0), Vector2((bar.size.x - 16.0) * hp_ratio, 8.0)), Color("#6ef3a5") if hp_ratio > 0.34 else Color("#ff5d73"))
    var ultimate_fill := clampf(float(me["ultimate_charge"]) / float(world.ULTIMATE_MAX), 0.0, 1.0)
    draw_rect(Rect2(bar.position + Vector2(8.0, 17.0), Vector2(bar.size.x - 16.0, 5.0)), Color("#302333"))
    draw_rect(Rect2(bar.position + Vector2(8.0, 17.0), Vector2((bar.size.x - 16.0) * ultimate_fill, 5.0)), Color("#ff5d91"))
    var slot_y := 818.0
    _draw_gun_slot(Rect2(563.0, slot_y, 220.0, 60.0), equipment)
    _draw_medkit_slot(Rect2(795.0, slot_y, 130.0, 60.0), me)
    _draw_dash_slot(Rect2(937.0, slot_y, 100.0, 60.0), me, equipment)

func _draw_gun_slot(rect: Rect2, equipment: Dictionary) -> void:
    draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
    draw_rect(rect, Color("#ffd166", 0.65), false, 2.0)
    if gun_texture != null:
        draw_texture_rect(gun_texture, Rect2(rect.position + Vector2(10.0, 17.0), Vector2(52.0, 30.0)), false)
    else:
        draw_line(rect.position + Vector2(12.0, 30.0), rect.position + Vector2(52.0, 30.0), Color("#ffd166"), 8.0)
    _text(rect.position + Vector2(10.0, 15.0), "공격" if touch_hints else "LMB", 11, Color("#ffd166"))
    _text(rect.position + Vector2(70.0, 28.0), str(equipment["name"]), 14, Color.WHITE, rect.size.x - 78.0)
    _text(rect.position + Vector2(70.0, 48.0), str(equipment["character_name"]), 11, Color("#aebaca"), rect.size.x - 78.0)

func _draw_medkit_slot(rect: Rect2, me: Dictionary) -> void:
    var carried := int(me.get("medkits", 0))
    var usable := carried > 0
    draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
    draw_rect(rect, Color("#6ef3a5", 0.85 if usable else 0.25), false, 2.0)
    var tint := Color.WHITE if usable else Color(1.0, 1.0, 1.0, 0.30)
    if medkit_texture != null:
        draw_texture_rect(medkit_texture, Rect2(rect.position + Vector2(10.0, 15.0), Vector2(34.0, 34.0)), false, tint)
    else:
        draw_rect(Rect2(rect.position + Vector2(22.0, 18.0), Vector2(10.0, 28.0)), tint)
        draw_rect(Rect2(rect.position + Vector2(13.0, 27.0), Vector2(28.0, 10.0)), tint)
    _text(rect.position + Vector2(52.0, 40.0), "x%d" % carried, 22, Color("#6ef3a5") if usable else Color("#6b7480"))
    _text(rect.position + Vector2(10.0, 15.0), "약" if touch_hints else "E", 11, Color("#6ef3a5") if usable else Color("#6b7480"))
    _text(rect.position + Vector2(52.0, 55.0), "메드킷", 11, Color("#aebaca"))

func _draw_dash_slot(rect: Rect2, me: Dictionary, equipment: Dictionary) -> void:
    var mobility_cd: float = float(me["mobility_cd"])
    var ready := mobility_cd <= 0.0
    draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
    draw_rect(rect, Color("#66e09a", 0.85 if ready else 0.25), false, 2.0)
    var chevron := Color("#66e09a") if ready else Color("#6b7480")
    for index in range(2):
        var cx := rect.position.x + 26.0 + float(index) * 14.0
        var cy := rect.position.y + 30.0
        draw_line(Vector2(cx - 6.0, cy - 10.0), Vector2(cx + 6.0, cy), chevron, 4.0)
        draw_line(Vector2(cx + 6.0, cy), Vector2(cx - 6.0, cy + 10.0), chevron, 4.0)
    _text(rect.position + Vector2(10.0, 15.0), "대시" if touch_hints else "SPACE", 10, chevron)
    if ready:
        _text(rect.position + Vector2(48.0, 40.0), "대시", 15, Color.WHITE)
    else:
        _text(rect.position + Vector2(48.0, 40.0), "%.1f" % mobility_cd, 15, Color("#c5ccd6"))

func _draw_scoreboard() -> void:
    var rows: Array[Dictionary] = world.leaderboard()
    draw_rect(Rect2(940.0, 300.0, 644.0, 66.0 + float(rows.size()) * 31.0), Color(0.02, 0.03, 0.05, 0.91))
    _text(Vector2(960.0, 328.0), "실시간 순위  CHARACTER / EQUIPMENT       SCORE  D/D  ZONE  STATE       ULT", 13, Color("#ffd166"))
    for rank in range(rows.size()):
        var row: Dictionary = rows[rank]
        var slot := int(row["slot"])
        var hero: Dictionary = world.heroes[slot]
        var equipment: Dictionary = hero["equipment"]
        var state := "LIVE"
        if bool(hero["eliminated"]) or not bool(hero["alive"]):
            state = "OUT"
        elif float(hero.get("stun_time", 0.0)) > 0.0:
            state = "STUN"
        elif float(hero.get("root_time", 0.0)) > 0.0:
            state = "ROOT"
        elif float(hero["cc_time"]) > 0.0:
            state = "CC"
        elif int(hero.get("kill_streak", 0)) >= 2:
            state = "LIVE x%d" % int(hero["kill_streak"])
        var y := 360.0 + rank * 31.0
        var row_color: Color = Color("#283242") if slot == world.local_slot else Color(0.08, 0.10, 0.14, 0.72)
        draw_rect(Rect2(952.0, y - 19.0, 620.0, 26.0), row_color)
        draw_circle(Vector2(967.0, y - 6.0), 6.0, player_colors[slot])
        _text(Vector2(980.0, y), "%d  P%d %s / %s" % [rank + 1, slot + 1, equipment["character_name"], equipment["name"]], 13, Color.WHITE)
        _text(Vector2(1280.0, y), "%4d" % roundi(float(row["score"])), 13, Color("#ffd166"))
        _text(Vector2(1340.0, y), "%d/%d" % [int(row["kills"]), int(row["deaths"])], 13, Color("#dbe5f0"))
        _text(Vector2(1395.0, y), "%3d" % roundi(float(world.safe_zone_radius)), 13, Color("#6ef3a5"))
        _text(Vector2(1442.0, y), state, 11, Color("#ff9ca4") if state != "LIVE" else Color("#8be3ff"))
        var ultimate_ready: bool = float(hero["ultimate_charge"]) >= float(world.ULTIMATE_MAX)
        _text(Vector2(1512.0, y), "READY" if ultimate_ready else "%d%%" % roundi(float(hero["ultimate_charge"])), 11, Color("#ff5d91") if ultimate_ready else Color("#c8a5b8"))

func _draw_match_result() -> void:
    draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(0.005, 0.008, 0.014, 0.72))
    if world.winner_slot < 0:
        draw_rect(Rect2(430.0, 290.0, 740.0, 260.0), Color(0.02, 0.03, 0.05, 0.98))
        _text(Vector2(470.0, 410.0), "DRAW", 54, Color.WHITE, 660.0, HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(470.0, 478.0), "NO SURVIVORS", 22, Color("#aebaca"), 660.0, HORIZONTAL_ALIGNMENT_CENTER)
        return
    var winner: Dictionary = world.heroes[world.winner_slot]
    var equipment: Dictionary = winner["equipment"]
    var accent: Color = player_colors[world.winner_slot]
    var reason_title := "HP DECISION WINNER" if world.result_reason == &"time_limit" else "LAST ONE STANDING"
    draw_rect(Rect2(330.0, 154.0, 940.0, 592.0), Color(0.012, 0.018, 0.028, 0.98))
    draw_rect(Rect2(330.0, 154.0, 940.0, 592.0), Color(accent, 0.92), false, 6.0)
    draw_rect(Rect2(330.0, 154.0, 940.0, 72.0), Color(accent, 0.17))
    _text(Vector2(375.0, 201.0), reason_title, 23, Color("#ffd166"), 850.0, HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(375.0, 278.0), "P%d  %s  WINS" % [world.winner_slot + 1, equipment["character_name"]], 48, Color.WHITE, 850.0, HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(375.0, 318.0), "%s  /  %s  /  %s" % [equipment["role"], equipment["name"], equipment["special_name"]], 18, accent, 850.0, HORIZONTAL_ALIGNMENT_CENTER)
    draw_rect(Rect2(422.0, 346.0, 756.0, 72.0), Color(0.035, 0.048, 0.068, 0.95))
    _text(Vector2(445.0, 379.0), "HP  %d%%" % roundi(world.decision_hp_ratio * 100.0), 25, Color("#6ef3a5"), 210.0, HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(695.0, 379.0), "ZONE  %d" % roundi(float(world.safe_zone_radius)), 25, Color("#c65cff"), 210.0, HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(945.0, 379.0), "SCORE  %d" % roundi(float(winner["score"])), 25, Color("#ffd166"), 210.0, HORIZONTAL_ALIGNMENT_CENTER)
    var standings: Array[Dictionary] = world.final_standings()
    _text(Vector2(410.0, 455.0), "FINAL STANDINGS", 16, Color("#aebaca"))
    for rank in range(mini(3, standings.size())):
        var row: Dictionary = standings[rank]
        var slot := int(row["slot"])
        var row_equipment: Dictionary = world.heroes[slot]["equipment"]
        var row_y := 490.0 + rank * 52.0
        draw_rect(Rect2(404.0, row_y - 27.0, 792.0, 42.0), Color(player_colors[slot], 0.16 if rank > 0 else 0.28))
        draw_circle(Vector2(430.0, row_y - 6.0), 9.0, player_colors[slot])
        _text(Vector2(452.0, row_y), "%d   P%d  %s / %s" % [rank + 1, slot + 1, row_equipment["character_name"], row_equipment["name"]], 16, Color.WHITE, 380.0)
        _text(Vector2(845.0, row_y), "HP %3d%%" % roundi(float(row["hp_ratio"]) * 100.0), 15, Color("#6ef3a5"), 92.0)
        _text(Vector2(952.0, row_y), "LIVE" if bool(row.get("hero_alive", false)) else "OUT", 15, Color("#70e7ff") if bool(row.get("hero_alive", false)) else Color("#ff8d93"), 112.0)
        _text(Vector2(1076.0, row_y), "%5d" % roundi(float(row["score"])), 15, Color("#ffd166"), 86.0, HORIZONTAL_ALIGNMENT_RIGHT)
    if bool(world.get("is_net")):
        _text(Vector2(450.0, 701.0), "나가기 버튼으로 대기실로" if touch_hints else "ESC  대기실로", 19, Color("#dbe5f0"), 700.0, HORIZONTAL_ALIGNMENT_CENTER)
    else:
        if not touch_hints:
            _text(Vector2(450.0, 701.0), "PRESS R FOR REMATCH", 19, Color("#dbe5f0"), 700.0, HORIZONTAL_ALIGNMENT_CENTER)

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
    _text(banner.position + Vector2(24.0, 24.0), "P%d  %s" % [world.ultimate_focus_slot + 1, equipment["character_name"]], 13, Color(Color("#c8d5e4"), fade), 160.0)
    _text(banner.position + Vector2(24.0, 47.0), str(equipment["ultimate_name"]), 22, Color(Color("#ff8dac"), fade), 430.0)

func _draw_critical(me: Dictionary) -> void:
    if bool(me["alive"]) and float(me.get("stun_time", 0.0)) > 0.0:
        draw_rect(Rect2(550.0, 660.0, 500.0, 48.0), Color(0.10, 0.06, 0.0, 0.90))
        _text(Vector2(570.0, 692.0), "STUNNED  |  INPUT LOCKED", 20, Color("#ffe27a"), 460.0, HORIZONTAL_ALIGNMENT_CENTER)
    elif bool(me["alive"]) and float(me.get("root_time", 0.0)) > 0.0:
        draw_rect(Rect2(510.0, 660.0, 580.0, 48.0), Color(0.07, 0.025, 0.12, 0.90))
        _text(Vector2(530.0, 691.0), "ROOTED  |  MOVE/SPACE LOCKED - ATTACK/Q AVAILABLE", 17, Color("#d8b4ff"), 540.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.last_down_ticks > 0 and world.last_down_slot >= 0:
        var down_alpha := clampf(float(world.last_down_ticks) / 18.0, 0.0, 1.0)
        var down_hero: Dictionary = world.heroes[world.last_down_slot]
        draw_rect(Rect2(360.0, 190.0, 880.0, 88.0), Color(0.18, 0.0, 0.025, 0.90 * down_alpha))
        draw_rect(Rect2(360.0, 190.0, 880.0, 88.0), Color("#ff3349", down_alpha), false, 8.0)
        _text(Vector2(390.0, 247.0), "P%d %s님이 쓰러졌습니다." % [world.last_down_slot + 1, down_hero["equipment"]["character_name"]], 38, Color(1.0, 1.0, 1.0, down_alpha), 820.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.callout_ticks > 0 and world.result == &"playing":
        var alpha := clampf(float(world.callout_ticks) / 24.0, 0.0, 1.0)
        draw_rect(Rect2(560.0, 108.0, 480.0, 38.0), Color(0.025, 0.025, 0.04, 0.82 * alpha))
        _text(Vector2(580.0, 133.0), world.callout, 15, Color(1.0, 0.74, 0.42, alpha), 440.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.streak_callout_ticks > 0 and world.result == &"playing":
        var streak_alpha := clampf(float(world.streak_callout_ticks) / 18.0, 0.0, 1.0)
        var streak_color := Color("#ff4f68") if world.streak_callout_shutdown else Color("#ffd166")
        draw_rect(Rect2(430.0, 290.0, 740.0, 76.0), Color(0.025, 0.018, 0.025, 0.92 * streak_alpha))
        draw_rect(Rect2(430.0, 290.0, 740.0, 76.0), Color(streak_color, streak_alpha), false, 5.0)
        _text(Vector2(455.0, 320.0), world.streak_callout, 25, Color(streak_color, streak_alpha), 690.0, HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(455.0, 348.0), world.streak_subtitle, 15, Color(Color.WHITE, streak_alpha), 690.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.start_countdown > 0.0:
        var count_text := str(ceili(world.start_countdown))
        draw_circle(Vector2(800.0, 450.0), 82.0, Color(0.02, 0.03, 0.05, 0.88))
        draw_arc(Vector2(800.0, 450.0), 86.0, 0.0, TAU, 64, Color("#ff5d73"), 7.0)
        _text(Vector2(720.0, 480.0), count_text, 82, Color.WHITE, 160.0, HORIZONTAL_ALIGNMENT_CENTER)
    elif not bool(me["alive"]) and world.result == &"playing":
        var target_slot := spectate_slot if spectate_slot >= 0 and spectate_slot < world.heroes.size() and spectate_slot != world.local_slot else clampi(world.local_slot, 0, world.heroes.size() - 1)
        var target: Dictionary = world.heroes[target_slot]
        var target_equipment: Dictionary = target["equipment"]
        draw_rect(Rect2(455.0, 786.0, 690.0, 90.0), Color(0.04, 0.02, 0.06, 0.88))
        _text(Vector2(475.0, 816.0), "관전 P%d %s / %s" % [target_slot + 1, target_equipment["character_name"], target_equipment["name"]], 20, Color("#d8b4ff"), 650.0, HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(475.0, 843.0), "탈락 - 관전 중", 16, Color("#ff8d93"), 650.0, HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(475.0, 867.0), "A/D 또는 TAB: 관전 대상 변경  |  SPACE: 1위 자동 추적", 14, Color.WHITE, 650.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.result != &"playing":
        _draw_match_result()
