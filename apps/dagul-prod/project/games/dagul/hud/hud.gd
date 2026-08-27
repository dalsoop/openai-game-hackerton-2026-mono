extends Control

const GunSig = preload("res://games/dagul/sim/gun_signature.gd")
const HudPjhScript = preload("res://games/dagul/hud/hud_pjh.gd")
const TextCacheScript = preload("res://games/dagul/render/text_cache.gd")

var world
var mode_id: String = "full"
var spectate_slot: int = 0
var hud_mode: int = 0
var touch_hints: bool = false
var net_rtt_ms: int = -1
var net_connected: bool = false
var player_colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc"), Color("#ffe066"), Color("#70e7ff")]

const _HudStr := preload("res://core/contract/hud_strings.gd")
const PANEL_BG := Color(0.012, 0.018, 0.028, 0.86)
const ZONE_PURPLE := Color("#c65cff")

var gun_texture: Texture2D = null
var medkit_texture: Texture2D = null
var item_textures: Dictionary = {}
var ammo_round_texture: Texture2D = null
var ammo_casing_texture: Texture2D = null
var zone_lightning_texture: Texture2D = null
var animal_texture: Texture2D = null
var roulette_icons: Dictionary = {}
var _kill_feed: Array[Dictionary] = []
var _last_kill_event_id: int = 0
var _ammo_last_mag: int = -1
var _ammo_last_equipment: String = ""
var _ammo_eject_tick: int = -1000
var _ammo_casings: Array[Dictionary] = []
var _ammo_casing_serial: int = 0
var _ammo_last_tick: int = -1
var _ammo_world_instance_id: int = 0
var _pjh
var _result_hold_at_ms: int = -1

func _ready() -> void:
    for icon_id in ["atk", "spd", "def", "hp", "rate", "range", "giant", "shield", "berserk", "turtle", "sniper", "double_giant"]:
        var icon_path := "res://games/dagul/assets/hud/roulette/%s.png" % icon_id
        if ResourceLoader.exists(icon_path):
            roulette_icons[icon_id] = load(icon_path)
    if ResourceLoader.exists("res://games/dagul/assets/items/gun.png"):
        gun_texture = load("res://games/dagul/assets/items/gun.png")
    if ResourceLoader.exists("res://games/dagul/assets/items/medkit.png"):
        medkit_texture = load("res://games/dagul/assets/items/medkit.png")
        # 버프 칩(draw_buff_glyph)도 십자 폴리곤 폴백 대신 실제 아이콘을 쓴다.
        roulette_icons["medkit"] = medkit_texture
    for kind in ["medkit", "spring", "slide", "pull", "pocket", "decoy"]:
        var item_path := "res://games/dagul/assets/items/%s.png" % kind
        if ResourceLoader.exists(item_path):
            item_textures[kind] = load(item_path)
    if ResourceLoader.exists("res://games/dagul/assets/fx/ui/Tex_UI_AmmoRound_4x1.png"):
        ammo_round_texture = load("res://games/dagul/assets/fx/ui/Tex_UI_AmmoRound_4x1.png")
    if ResourceLoader.exists("res://games/dagul/assets/fx/ui/Tex_UI_AmmoCasing.png"):
        ammo_casing_texture = load("res://games/dagul/assets/fx/ui/Tex_UI_AmmoCasing.png")
    if ResourceLoader.exists("res://games/dagul/assets/fx/zone/Tex_FX_ZoneLightning_4x2.png"):
        zone_lightning_texture = load("res://games/dagul/assets/fx/zone/Tex_FX_ZoneLightning_4x2.png")
    if ResourceLoader.exists("res://games/dagul/assets/lhj/Tex_Animal_4x3.png"):
        animal_texture = load("res://games/dagul/assets/lhj/Tex_Animal_4x3.png")
    _pjh = HudPjhScript.new(self)


func reset_match_visuals() -> void:
    if _pjh != null:
        _pjh.reset_match_visuals()
    # 2회차: 이벤트 id 가 1부터 다시 시작한다 — 커서를 안 지우면 새 킬이 전부 걸러진다.
    _kill_feed.clear()
    _last_kill_event_id = 0

func _zodiac_name(slot: int) -> String:
    return HudStrings.zodiac(slot)

func _text(pos: Vector2, text: String, size: int, color: Color, width: float = -1.0, align := HORIZONTAL_ALIGNMENT_LEFT, bold: bool = false) -> void:
    var font := GameFont.get_bold_font() if bold else GameFont.get_font()
    TextCacheScript.draw(self, pos + Vector2(1.5, 1.5), text, font, size, Color(0.0, 0.0, 0.0, 0.72 * color.a), width, align)
    TextCacheScript.draw(self, pos, text, font, size, color, width, align)

func _draw() -> void:
    if world == null or world.heroes.is_empty():
        return
    _pjh.draw_zone_overlay()
    var summary: Dictionary = world.summary()
    var me: Dictionary = world.heroes[clampi(world.local_slot, 0, world.heroes.size() - 1)]
    if hud_mode == 0:
        _draw_status_panel(summary, me)
        _draw_wanted_banner()
        _draw_minimap()
        _draw_zone_timer()
        if world.result == &"playing" and bool(me["alive"]):
            _draw_hotbar(me)
        _draw_life_status(me)
        _draw_roulette_overlay(me)
    elif hud_mode == 1:
        _draw_status_panel(summary, me)
        _draw_wanted_banner()
        _draw_minimap()
        _draw_zone_timer()
        _draw_scoreboard()
        if world.result == &"playing" and bool(me["alive"]):
            _draw_hotbar(me)
        _draw_life_status(me)
        _draw_roulette_overlay(me)
    else:
        draw_rect(Rect2(16.0, 16.0, 112.0, 34.0), Color(0.02, 0.03, 0.05, 0.72))
        _text(Vector2(28.0, 39.0), "F1  HUD", 14, Color("#c8d5e4"))
    if hud_mode != 2 and world.result == &"playing" and bool(me["alive"]):
        _pjh.draw_ammo_conveyor(me)
    _draw_critical(me)
    _draw_ultimate_cinematic()
    _update_kill_feed()
    _draw_kill_feed()

func _draw_led_panel(rect: Rect2, accent: Color) -> void:
    var top := Color(0.03, 0.05, 0.07, 0.38)
    var bot := Color(0.03, 0.05, 0.07, 0.10)
    var steps := 10
    var slice := rect.size.y / float(steps)
    for i in range(steps):
        var fade := top.lerp(bot, float(i) / float(steps - 1))
        draw_rect(Rect2(rect.position.x, rect.position.y + slice * float(i), rect.size.x, slice + 0.5), fade)
    draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), Color(accent, 0.35), 1.0)
    draw_line(rect.position + Vector2(0.0, rect.size.y), rect.position + rect.size, Color(accent, 0.12), 1.0)

func _draw_status_panel(summary: Dictionary, me: Dictionary) -> void:
    var rows_n := float(world.heroes.size())
    var panel := Rect2(14.0, 12.0, 268.0, 92.0 + rows_n * 26.0)
    _draw_led_panel(panel, Color("#39ff6a"))
    _text(Vector2(28.0, 42.0), "KILLS  %d" % int(me["kills"]), 28, Color("#7dff8a"))
    _text(Vector2(28.0, 70.0), "ALIVE  %d / %d" % [int(summary["alive"]), world.heroes.size()], 22, Color("#d4ff6a"))
    _text(Vector2(170.0, 42.0), "%d" % roundi(float(me["score"])), 22, Color("#fff36a"))
    if net_rtt_ms > 0:
        _text(Vector2(170.0, 70.0), "%dms" % net_rtt_ms, 14, Color("#70e7ff"))
    var row_y := 100.0
    for slot in range(world.heroes.size()):
        var hero: Dictionary = world.heroes[slot]
        var alive := bool(hero["alive"]) and not bool(hero["eliminated"])
        var row := Rect2(24.0, row_y - 18.0, 248.0, 24.0)
        if slot == world.local_slot:
            draw_rect(row, Color(0.25, 1.0, 0.4, 0.16))
        var dot_color: Color = player_colors[slot] if alive else Color(0.25, 0.3, 0.28, 0.9)
        draw_circle(Vector2(38.0, row_y - 6.0), 6.0, dot_color)
        var name_color := Color("#e8ffe8") if alive else Color("#4d6050")
        var row_name := str(hero.get("display_name", ""))
        if row_name == "":
            row_name = "P%d %s" % [slot + 1, _zodiac_name(int(hero.get("animal", slot)))]
        _text(Vector2(50.0, row_y), row_name, 15, name_color, 128.0)
        var state := "K %d" % int(hero["kills"]) if alive else "OUT"
        var state_color := Color("#fff36a") if alive else Color("#5a6b5a")
        if bool(hero.get("parked", false)):
            state = "AFK"
            state_color = Color("#ff8d93")
        _text(Vector2(186.0, row_y), state, 15, state_color, 76.0)
        row_y += 26.0

# 미니맵 — 맵은 7840x4760 사각 풀맵이다. 옛 원형 섬 그리기는 지형을 조그만 원으로
# 그려 플레이어 점이 바다 위에 뜨고, 원형 클램프가 모서리 위치를 왜곡했다.
const MINIMAP_CENTER := Vector2(1486.0, 158.0)
const MINIMAP_HALF_MAX := 88.0

# 과거 스타일: 바다 원판이 겉을 감싸고 그 안의 원형 필드에 전부 들어간다.
const MINIMAP_FIELD_R := 76.0

func _minimap_scale() -> float:
    return (MINIMAP_FIELD_R * 2.0 * 0.96) / Vector2(world.ARENA_SIZE).length()

func _minimap_offset(pos: Vector2, scale: float, half: Vector2, margin: float) -> Vector2:
    var offset := (pos - Vector2(world.ARENA_CENTER)) * scale
    offset.x = clampf(offset.x, -half.x + margin, half.x - margin)
    offset.y = clampf(offset.y, -half.y + margin, half.y - margin)
    return offset

func _draw_minimap() -> void:
    if world.heroes.is_empty():
        return
    var scale := _minimap_scale()
    var half := Vector2(world.ARENA_SIZE) * scale * 0.5
    draw_circle(MINIMAP_CENTER, MINIMAP_HALF_MAX + 7.0, PANEL_BG)
    # 바다가 겉을 감싸고, 원형 필드는 존 밖(보라) 위에 존 안(잔디)을 덮는다.
    draw_circle(MINIMAP_CENTER, MINIMAP_HALF_MAX, Color("#17456f"))
    draw_circle(MINIMAP_CENTER, MINIMAP_FIELD_R, Color("#6d55a0"))
    _draw_minimap_zone(scale)
    _draw_minimap_dots(scale, half)
    draw_arc(MINIMAP_CENTER, MINIMAP_HALF_MAX + 7.0, 0.0, TAU, 56, Color("#8aa0b8", 0.62), 2.0)

# 존 원은 원판보다 클 수 있다 — 원판에서 잘라 그린다 (채움은 원 클램프 폴리곤,
# 링은 원판 안에 온전히 든 호 구간만). 존 안을 잔디색으로 덮어 "밖=보라" 를 만든다.
func _draw_minimap_zone(scale: float) -> void:
    var zone_center: Vector2 = MINIMAP_CENTER + (Vector2(world.safe_zone_center) - Vector2(world.ARENA_CENTER)) * scale
    var zone_radius: float = maxf(2.0, float(world.safe_zone_radius) * scale)
    var fill := PackedVector2Array()
    for i in range(48):
        var p := zone_center + Vector2.RIGHT.rotated(TAU * float(i) / 48.0) * zone_radius
        fill.append(_clamp_to_disc(p))
    draw_colored_polygon(fill, Color("#6b8452"))
    var zone_ring := Color("#e05cff") if bool(world.safe_zone_shrinking) else ZONE_PURPLE
    _draw_clipped_ring(zone_center, zone_radius, zone_ring, 2.5)
    if bool(world.safe_zone_shrinking) or absf(float(world.safe_zone_target_radius) - float(world.safe_zone_radius)) > 4.0:
        _draw_clipped_ring(zone_center, maxf(2.0, float(world.safe_zone_target_radius) * scale), Color(1.0, 1.0, 1.0, 0.70), 1.5)

func _clamp_to_disc(p: Vector2) -> Vector2:
    var offset := p - MINIMAP_CENTER
    if offset.length() <= MINIMAP_FIELD_R:
        return p
    return MINIMAP_CENTER + offset.normalized() * MINIMAP_FIELD_R

func _draw_clipped_ring(center: Vector2, radius: float, color: Color, width: float) -> void:
    var prev := center + Vector2.RIGHT * radius
    for i in range(1, 49):
        var next := center + Vector2.RIGHT.rotated(TAU * float(i) / 48.0) * radius
        var inside := prev.distance_to(MINIMAP_CENTER) <= MINIMAP_FIELD_R + 1.0 \
            and next.distance_to(MINIMAP_CENTER) <= MINIMAP_FIELD_R + 1.0
        if inside:
            draw_line(prev, next, color, width, true)
        prev = next

func _minimap_focus_slot() -> int:
    var focus_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
    if spectate_slot != world.local_slot and spectate_slot >= 0 and spectate_slot < world.heroes.size() and bool(world.heroes[spectate_slot]["alive"]):
        focus_slot = spectate_slot
    return focus_slot

func _draw_minimap_dots(scale: float, half: Vector2) -> void:
    var focus_slot := _minimap_focus_slot()
    for hero in world.heroes:
        var slot := int(hero["slot"])
        if slot == focus_slot or not bool(hero["alive"]) or bool(hero["eliminated"]):
            continue
        var dot: Vector2 = MINIMAP_CENTER + _minimap_offset(Vector2(hero["pos"]), scale, half, 6.0)
        draw_circle(dot, 5.2, Color(0.02, 0.03, 0.05, 0.95))
        draw_circle(dot, 3.8, player_colors[slot])
    if focus_slot < 0 or focus_slot >= world.heroes.size() or not bool(world.heroes[focus_slot]["alive"]):
        return
    var me_pos: Vector2 = MINIMAP_CENTER + _minimap_offset(Vector2(world.heroes[focus_slot]["pos"]), scale, half, 7.0)
    draw_circle(me_pos, 7.2, Color(0.02, 0.03, 0.05, 0.95))
    draw_circle(me_pos, 5.6, Color.WHITE)
    draw_circle(me_pos, 3.6, Color("#7af7ff"))

func _draw_zone_timer() -> void:
    var status_color := ZONE_PURPLE
    var status_text := ""
    if bool(world.safe_zone_shrinking):
        status_text = HudStrings.t("zone_shrinking")
        status_color = Color("#e05cff")
    elif bool(world.safe_zone_complete):
        status_text = HudStrings.t("zone_final")
        status_color = Color("#d8b4ff")
    else:
        var phase := int(world.safe_zone_phase)
        if phase < world.SAFE_ZONE_PHASES.size():
            var wait := float(world.SAFE_ZONE_PHASES[phase]["wait"])
            status_text = HudStrings.t("zone_countdown") % maxi(0, ceili(wait - float(world.safe_zone_phase_time)))
            status_color = Color("#c9a6ff")
    if bool(world.safe_zone_shrinking):
        status_color.a = 0.75 + sin(float(world.tick) * 0.22) * 0.25
    _text(Vector2(1376.0, 274.0), status_text, 16, status_color, 220.0, HORIZONTAL_ALIGNMENT_CENTER)
    var remaining: float = maxf(0.0, float(world.MATCH_TIME_LIMIT) - float(world.match_time))
    var display_total: int = maxi(0, ceili(remaining))
    var urgent: bool = remaining <= 10.0 and world.result == &"playing"
    var clock_color: Color = Color("#ff4f68") if urgent else Color("#dbe5f0")
    _text(Vector2(1376.0, 306.0), "%d:%02d" % [display_total / 60, display_total % 60], 26, clock_color, 220.0, HORIZONTAL_ALIGNMENT_CENTER)
    if urgent:
        draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(clock_color, 0.34 + sin(float(world.tick) * 0.22) * 0.08), false, 9.0)

func _draw_hotbar(me: Dictionary) -> void:
    var bar := Rect2(549.0, 802.0, 502.0, 86.0)
    draw_rect(bar, Color(0.008, 0.012, 0.020, 0.78))
    draw_rect(bar, Color(0.32, 0.38, 0.48, 0.55), false, 1.5)
    var hp_now := float(me["hp"])
    var hp_max := float(me["max_hp"])
    var hp_ratio := clampf(hp_now / maxf(1.0, hp_max), 0.0, 1.0)
    var hp_color := Color("#3fe37a")
    if hp_ratio <= 0.30:
        hp_color = Color("#ff5d73")
    elif hp_ratio <= 0.60:
        hp_color = Color("#ffb347")
    _text(bar.position + Vector2(10.0, 15.0), "HP  %d / %d" % [roundi(hp_now), roundi(hp_max)], 13, hp_color, 304.0)
    _pjh.draw_status_blocks(Rect2(bar.position + Vector2(8.0, 19.0), Vector2(310.0, 16.0)), hp_ratio, 10, hp_color, hp_now > 0.0, false, 1.2)
    var ult_max := 100.0
    var power_ratio := clampf(float(me.get("ultimate_charge", 0.0)) / maxf(1.0, ult_max), 0.0, 1.0)
    var ult_ready := power_ratio >= 0.999
    var ult_color := Color("#a970ff") if ult_ready else Color("#4f8cff")
    _text(bar.position + Vector2(328.0, 15.0), "ULT READY" if ult_ready else "ULT  %d%%" % roundi(power_ratio * 100.0), 12, ult_color, 164.0, HORIZONTAL_ALIGNMENT_RIGHT)
    _pjh.draw_status_blocks(Rect2(bar.position + Vector2(326.0, 19.0), Vector2(168.0, 16.0)), power_ratio, 8, ult_color, false, ult_ready, 0.7)
    _draw_perk_chips_at(me, bar.position + Vector2(8.0, 38.0), bar.size.x - 16.0)
    _draw_medkit_slot(Rect2(bar.position.x - 100.0, bar.position.y + 8.0, 92.0, 70.0), me)

func _draw_ammo_slot(rect: Rect2, me: Dictionary, equipment: Dictionary) -> void:
    var mag_now: int = int(me.get("mag", 0))
    var mag_max: int = int(equipment.get("mag_size", 0))
    if mag_max <= 0:
        mag_max = 1
    var reloading: bool = float(me.get("reload_left", 0.0)) > 0.0
    var just_reloaded: bool = float(me.get("reload_flash", 0.0)) > 0.0
    var fill: float = 0.0
    if reloading:
        var reload_dur: float = maxf(0.20, float(equipment.get("reload_time", 1.2)))
        fill = 1.0 - clampf(float(me.get("reload_left", 0.0)) / reload_dur, 0.0, 1.0)
    else:
        fill = clampf(float(mag_now) / float(mag_max), 0.0, 1.0)
    var rim: Color = Color("#ff5d73", 0.85)
    if reloading:
        rim = Color("#ffd166", 0.90)
    elif just_reloaded:
        rim = Color("#6ef3a5", 0.90)
    elif mag_now > 0:
        rim = Color("#7af7ff", 0.80)
    draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
    draw_rect(rect, rim, false, 2.0)
    draw_rect(Rect2(rect.position + Vector2(10.0, 44.0), Vector2(rect.size.x - 20.0, 8.0)), Color("#1b2430"))
    draw_rect(Rect2(rect.position + Vector2(10.0, 44.0), Vector2((rect.size.x - 20.0) * fill, 8.0)), rim)
    var label: String = "AMMO  %d / %d" % [mag_now, mag_max]
    if reloading:
        label = "RELOAD  %d / %d" % [mag_now, mag_max]
    elif mag_now <= 0:
        label = "EMPTY  0 / %d" % mag_max
    _text(rect.position + Vector2(12.0, 28.0), label, 22, Color.WHITE, rect.size.x - 24.0)

func _draw_gun_slot(rect: Rect2, equipment: Dictionary) -> void:
    draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
    draw_rect(rect, Color("#ffd166", 0.65), false, 2.0)
    if gun_texture != null:
        draw_texture_rect(gun_texture, Rect2(rect.position + Vector2(10.0, 17.0), Vector2(52.0, 30.0)), false)
    else:
        draw_line(rect.position + Vector2(12.0, 30.0), rect.position + Vector2(52.0, 30.0), Color("#ffd166"), 8.0)
    _text(rect.position + Vector2(10.0, 15.0), HudStrings.t("touch_fire") if touch_hints else "LMB", 11, Color("#ffd166"))
    _text(rect.position + Vector2(70.0, 28.0), str(equipment["name"]), 14, Color.WHITE, rect.size.x - 78.0)
    _text(rect.position + Vector2(70.0, 48.0), str(equipment["character_name"]), 11, Color("#aebaca"), rect.size.x - 78.0)

func _draw_medkit_slot(rect: Rect2, me: Dictionary) -> void:
    if str(world.mode) == "item":
        var kind := str(me.get("held_item", ""))
        var label := HudBuffs.held_item_label(kind)
        var usable := label != "EMPTY"
        var accent: Color = HudBuffs.held_item_color(kind)
        _draw_medkit_frame(rect, accent, usable)
        var icon_tex: Texture2D = null
        if item_textures.has(kind):
            icon_tex = item_textures[kind]
        elif kind == "medkit":
            icon_tex = medkit_texture
        if icon_tex != null:
            draw_texture_rect(
                icon_tex,
                Rect2(rect.position + Vector2(8.0, 16.0), Vector2(40.0, 40.0)),
                false,
                Color.WHITE if usable else Color(1.0, 1.0, 1.0, 0.28),
            )
        elif kind == "medkit":
            _draw_medkit_icon(rect, Color.WHITE if usable else Color(1.0, 1.0, 1.0, 0.28))
        else:
            draw_circle(rect.position + Vector2(28.0, 38.0), 13.0, Color(accent, 0.85 if usable else 0.28))
        _text(rect.position + Vector2(52.0, 42.0), label, 14, accent if usable else Color("#6b7480"), 36.0)
        _text(rect.position + Vector2(6.0, 12.0), "E", 11, accent if usable else Color("#6b7480"))
        return
    var carried := int(me.get("medkits", 0))
    var usable := carried > 0
    var tint := Color.WHITE if usable else Color(1.0, 1.0, 1.0, 0.28)
    _draw_medkit_frame(rect, Color("#6ef3a5"), usable)
    _draw_medkit_icon(rect, tint)
    var count_color := Color("#6ef3a5") if usable else Color("#6b7480")
    _text(rect.position + Vector2(52.0, 38.0), "x%d" % carried, 20, count_color)
    _text(rect.position + Vector2(6.0, 12.0), HudStrings.t("touch_medkit") if touch_hints else "E", 11, count_color)

func _draw_medkit_frame(rect: Rect2, accent: Color, usable: bool) -> void:
    draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
    draw_rect(rect, Color(accent, 0.90 if usable else 0.22), false, 2.0)

func _draw_medkit_icon(rect: Rect2, tint: Color) -> void:
    var icon := Rect2(rect.position + Vector2(8.0, 16.0), Vector2(40.0, 40.0))
    if medkit_texture != null:
        draw_texture_rect(medkit_texture, icon, false, tint)
        return
    draw_rect(Rect2(icon.position + Vector2(15.0, 4.0), Vector2(10.0, 32.0)), tint)
    draw_rect(Rect2(icon.position + Vector2(4.0, 15.0), Vector2(32.0, 10.0)), tint)

func _draw_dash_slot(rect: Rect2, me: Dictionary, _equipment: Dictionary) -> void:
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
    _text(rect.position + Vector2(10.0, 15.0), HudStrings.t("touch_dash") if touch_hints else "SHIFT", 10, chevron)
    if ready:
        _text(rect.position + Vector2(48.0, 40.0), HudStrings.t("touch_dash"), 15, Color.WHITE)
    else:
        _text(rect.position + Vector2(48.0, 40.0), "%.1f" % mobility_cd, 15, Color("#c5ccd6"))

func _draw_scoreboard() -> void:
    var rows: Array[Dictionary] = world.leaderboard()
    draw_rect(Rect2(940.0, 300.0, 644.0, 66.0 + float(rows.size()) * 31.0), Color(0.02, 0.03, 0.05, 0.91))
    _text(Vector2(960.0, 328.0), "LIVE RANK  CHARACTER / GUN            SCORE  D/D  ZONE  STATE", 13, Color("#ffd166"))
    for rank in range(rows.size()):
        var row: Dictionary = rows[rank]
        var slot := int(row["slot"])
        var hero: Dictionary = world.heroes[slot]
        var equipment: Dictionary = hero["equipment"]
        var state := "LIVE"
        if bool(hero["eliminated"]):
            state = "OUT"
        elif not bool(hero["alive"]):
            state = "WAIT"
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

func _draw_match_result() -> void:
    _pjh.draw_match_result()

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
        _text(Vector2(530.0, 691.0), "ROOTED  |  MOVE/SHIFT/SPACE LOCKED - FIRE AVAILABLE", 17, Color("#d8b4ff"), 540.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.last_down_ticks > 0 and world.last_down_slot >= 0:
        var down_alpha := clampf(float(world.last_down_ticks) / 18.0, 0.0, 1.0)
        var down_hero: Dictionary = world.heroes[world.last_down_slot]
        draw_rect(Rect2(520.0, 52.0, 560.0, 36.0), Color(0.12, 0.01, 0.03, 0.42 * down_alpha))
        _text(Vector2(530.0, 76.0), HudStrings.t("downed_by") % [world.last_down_slot + 1, down_hero["equipment"]["character_name"]], 18, Color(1.0, 1.0, 1.0, down_alpha * 0.9), 540.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.callout_ticks > 0 and world.result == &"playing":
        var alpha := clampf(float(world.callout_ticks) / 24.0, 0.0, 1.0)
        draw_rect(Rect2(560.0, 52.0, 480.0, 28.0), Color(0.04, 0.04, 0.06, 0.32 * alpha))
        _text(Vector2(580.0, 72.0), world.callout, 13, Color(1.0, 0.74, 0.42, alpha), 440.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.streak_callout_ticks > 0 and world.result == &"playing":
        var streak_alpha := clampf(float(world.streak_callout_ticks) / 18.0, 0.0, 1.0)
        var streak_color := Color("#ff4f68") if world.streak_callout_shutdown else Color("#ffd166")
        draw_rect(Rect2(520.0, 52.0, 560.0, 40.0), Color(0.04, 0.02, 0.03, 0.36 * streak_alpha))
        _text(Vector2(530.0, 78.0), world.streak_callout, 16, Color(streak_color, streak_alpha * 0.9), 540.0, HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(530.0, 106.0), world.streak_subtitle, 15, Color(Color.WHITE, streak_alpha), 540.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.start_countdown > 0.0:
        _pjh.draw_countdown()
    elif not bool(me["alive"]) and world.result == &"playing":
        var target_slot := spectate_slot if spectate_slot >= 0 and spectate_slot < world.heroes.size() and spectate_slot != world.local_slot else clampi(world.local_slot, 0, world.heroes.size() - 1)
        var target: Dictionary = world.heroes[target_slot]
        var target_equipment: Dictionary = target["equipment"]
        draw_rect(Rect2(455.0, 786.0, 690.0, 90.0), Color(0.04, 0.02, 0.06, 0.88))
        _text(Vector2(475.0, 816.0), HudStrings.t("spectate_info") % [target_slot + 1, target_equipment["character_name"], target_equipment["name"]], 20, Color("#d8b4ff"), 650.0, HORIZONTAL_ALIGNMENT_CENTER)
        var death_label := HudStrings.t("spectate_eliminated") if bool(me.get("eliminated", false)) else HudStrings.t("spectate_respawning")
        var death_color := Color("#ff8d93") if bool(me.get("eliminated", false)) else Color("#70e7ff")
        _text(Vector2(475.0, 843.0), death_label, 16, death_color, 650.0, HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(475.0, 867.0), HudStrings.t("spectate_controls"), 14, Color.WHITE, 650.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.result != &"playing":
        _draw_match_result()

func _draw_wanted_banner() -> void:
    var slot := int(world.wanted_slot)
    if slot < 0 or slot >= world.heroes.size():
        return
    if bool(world.heroes[slot]["eliminated"]):
        return
    var hero: Dictionary = world.heroes[slot]
    var name := str(hero.get("display_name", ""))
    if name == "":
        name = "P%d" % (slot + 1)
    var banner := Rect2(560.0, 14.0, 480.0, 34.0)
    draw_rect(banner, Color(0.28, 0.04, 0.06, 0.36))
    draw_rect(banner, Color("#ff3349", 0.85), false, 2.0)
    _text(banner.position + Vector2(12.0, 23.0), "WANTED P%d  %s" % [slot + 1, name], 16, Color("#ffd166"), banner.size.x - 20.0)

func _draw_life_status(me: Dictionary) -> void:
    # revives_used 는 스냅에 안 실린다. deaths 가 죽음마다 같은 지점에서 함께
    # 증가하므로(match-life.ts resolveDeath) 잔여 부활은 deaths 로 계산한다.
    var left := maxi(0, 3 - int(me.get("deaths", 0)))
    if bool(me.get("eliminated", false)):
        _text(Vector2(560.0, 782.0), "OUT", 18, Color("#ff5d73"))
        return
    _text(Vector2(560.0, 782.0), "%d LEFT" % left, 16, Color("#ffd166"))
    if bool(me.get("downed", false)):
        _text(Vector2(680.0, 782.0), "DOWN %.1f   FINISH %d/48" % [float(me.get("down_left", 0.0)), int(round(float(me.get("down_taken", 0.0))))], 16, Color("#ff8d93"))
    elif not bool(me["alive"]) and float(me.get("respawn_left", 0.0)) > 0.0:
        _text(Vector2(680.0, 782.0), "RESPAWN %.1f" % float(me["respawn_left"]), 16, Color("#70e7ff"))
func _draw_perk_chips_at(me: Dictionary, origin: Vector2, width: float) -> void:
    if not bool(me.get("alive", false)):
        return
    var icons: Array = HudBuffs.collect_buff_icons(me, str(world.mode))
    if icons.is_empty():
        return
    var step := 44.0
    var count := mini(icons.size(), int(width / step))
    for i in range(count):
        _draw_buff_icon(Rect2(origin.x + float(i) * step, origin.y, 40.0, 46.0), icons[i])

func _draw_buff_icon(rect: Rect2, icon: Dictionary) -> void:
    var accent: Color = icon.get("color", Color("#b84dff"))
    var kind := str(icon.get("kind", "until"))
    draw_rect(rect, Color(0.02, 0.03, 0.05, 0.88))
    draw_rect(rect, Color(accent, 0.92 if kind != "until" else 0.70), false, 2.0)
    var c: Vector2 = rect.get_center() + Vector2(0.0, -4.0)
    HudBuffs.draw_buff_glyph(self, c, str(icon.get("id", "")), accent, roulette_icons)
    var label := str(icon.get("label", ""))
    _text(rect.position + Vector2(2.0, 48.0), label, 9, Color(accent, 0.95), rect.size.x - 4.0, HORIZONTAL_ALIGNMENT_CENTER)
    var extra := str(icon.get("text", ""))
    if extra != "":
        _text(rect.position + Vector2(2.0, 14.0), extra, 10, Color.WHITE, rect.size.x - 4.0, HORIZONTAL_ALIGNMENT_CENTER)
    var left := float(icon.get("time", 0.0))
    if left > 0.04:
        _text(rect.position + Vector2(2.0, 36.0), "%.0f" % left, 11, Color.WHITE, rect.size.x - 4.0, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_roulette_overlay(me: Dictionary) -> void:
    var phase := str(me.get("roulette_phase", ""))
    if phase != "land":
        return
    var won := str(me.get("roulette_label", ""))
    if won == "":
        return
    var spin_id := str(me.get("roulette_spin_id", ""))
    var desc := str(me.get("roulette_desc", ""))
    if desc == "":
        desc = HudBuffs.roulette_effect_line(spin_id, won)
    var rank := str(me.get("roulette_rank", "kill"))
    var accent: Color = HudBuffs.roulette_rank_color(rank)
    var left := maxf(0.0, float(me.get("roulette_time", 0.0)))
    var fade := 1.0
    if left < 0.35:
        fade = left / 0.35
    var pulse := 0.82 + 0.18 * absf(sin(float(world.tick) * 0.22))
    var cx := 800.0
    var top := 168.0
    var icon_tex: Texture2D = roulette_icons.get(spin_id) as Texture2D
    if icon_tex != null:
        var isz := Vector2(96.0, 96.0)
        draw_texture_rect(icon_tex, Rect2(Vector2(cx - 48.0, top), isz), false)
    else:
        draw_circle(Vector2(cx, top + 48.0), 40.0, Color(accent, 0.55 * fade))
    _text(Vector2(400.0, top + 132.0), won, 40, Color(1.0, 0.96, 0.82, fade * pulse), 800.0, HORIZONTAL_ALIGNMENT_CENTER)
    _text(Vector2(360.0, top + 168.0), desc, 18, Color(accent, fade * 0.95), 880.0, HORIZONTAL_ALIGNMENT_CENTER)
func _update_kill_feed() -> void:
    if world == null or world.event_log == null:
        return
    var now := int(world.tick)
    for ev in world.event_log.events:
        var eid := int(ev.get("id", 0))
        if eid <= _last_kill_event_id:
            continue
        _last_kill_event_id = eid
        var t = ev.get("type", &"")
        if t != &"hero_downed" and t != &"player_eliminated":
            continue
        var killer_slot := int(ev.get("actor_id", -1))
        var victim_slot := int(ev.get("target_id", -1))
        var killer_name := str(world.heroes[killer_slot].get("display_name", "CPU")) if killer_slot >= 0 and killer_slot < world.heroes.size() else ""
        var victim_name := str(world.heroes[victim_slot].get("display_name", "?")) if victim_slot >= 0 and victim_slot < world.heroes.size() else "?"
        var label := "%s → %s" % [killer_name, victim_name] if killer_name != "" else HudStrings.t("eliminated_label") % victim_name
        if t == &"player_eliminated":
            label += HudStrings.t("eliminated_suffix")
        _kill_feed.append({"text": label, "time": now})
    while _kill_feed.size() > 5:
        _kill_feed.pop_front()
    var cutoff := now - 180
    while not _kill_feed.is_empty() and int(_kill_feed[0]["time"]) < cutoff:
        _kill_feed.pop_front()

func _draw_kill_feed() -> void:
    var x := size.x - 220.0
    var y := 332.0
    for i in _kill_feed.size():
        var entry: Dictionary = _kill_feed[i]
        var age := int(world.tick) - int(entry["time"])
        var alpha := clampf(1.0 - float(age) / 180.0, 0.0, 1.0)
        draw_rect(Rect2(x - 4, y + i * 22 - 14, 210, 20), Color(0.0, 0.0, 0.0, 0.5 * alpha))
        _text(Vector2(x, y + i * 22), str(entry["text"]), 13, Color(1.0, 1.0, 1.0, alpha))
