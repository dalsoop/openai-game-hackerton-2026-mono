extends Control

const GunSig = preload("res://scripts/sim/gun_signature.gd")

var world
var mode_id: String = "classic"
var spectate_slot: int = 0
var hud_mode: int = 0
var touch_hints: bool = false
var net_rtt_ms: int = -1
var net_connected: bool = false
var player_colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc"), Color("#ffe066"), Color("#70e7ff")]

const ZODIAC_NAMES := ["쥐", "소", "호랑이", "토끼", "용", "뱀", "말", "양", "원숭이", "닭", "개", "돼지"]
const PANEL_BG := Color(0.012, 0.018, 0.028, 0.86)
const ZONE_PURPLE := Color("#c65cff")

var gun_texture: Texture2D = null
var medkit_texture: Texture2D = null
var ammo_round_texture: Texture2D = null
var ammo_casing_texture: Texture2D = null
var roulette_icons: Dictionary = {}
var _controls_overlay_time: float = 4.0
var _controls_dismissed: bool = false
var _kill_feed: Array[Dictionary] = []
var _last_kill_event_id: int = 0
var _ammo_last_mag: int = -1
var _ammo_last_equipment: String = ""
var _ammo_eject_tick: int = -1000
var _ammo_casings: Array[Dictionary] = []
var _ammo_casing_serial: int = 0
var _ammo_last_tick: int = -1
var _ammo_world_instance_id: int = 0

func _ready() -> void:
    for icon_id in ["atk", "spd", "def", "hp", "rate", "range", "giant", "shield", "berserk", "turtle", "sniper", "double_giant"]:
        var icon_path := "res://assets/hud/roulette/%s.png" % icon_id
        if ResourceLoader.exists(icon_path):
            roulette_icons[icon_id] = load(icon_path)
    if ResourceLoader.exists("res://assets/items/gun.png"):
        gun_texture = load("res://assets/items/gun.png")
    if ResourceLoader.exists("res://assets/items/medkit.png"):
        medkit_texture = load("res://assets/items/medkit.png")
    if ResourceLoader.exists("res://assets/fx/ui/Tex_UI_AmmoRound_4x1.png"):
        ammo_round_texture = load("res://assets/fx/ui/Tex_UI_AmmoRound_4x1.png")
    if ResourceLoader.exists("res://assets/fx/ui/Tex_UI_AmmoCasing.png"):
        ammo_casing_texture = load("res://assets/fx/ui/Tex_UI_AmmoCasing.png")

func _zodiac_name(slot: int) -> String:
    return ZODIAC_NAMES[posmod(slot, 12)]

func reset_match_visuals() -> void:
    _ammo_last_mag = -1
    _ammo_last_equipment = ""
    _ammo_eject_tick = -1000
    _ammo_casings.clear()
    _ammo_casing_serial = 0
    _ammo_last_tick = -1
    _ammo_world_instance_id = 0

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
        _draw_ammo_conveyor(me)
    _draw_critical(me)
    _draw_ultimate_cinematic()
    _draw_crosshair(me)
    _draw_controls_overlay()
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
            row_name = "P%d %s" % [slot + 1, _zodiac_name(slot)]
        _text(Vector2(50.0, row_y), row_name, 15, name_color, 128.0)
        var state := "K %d" % int(hero["kills"]) if alive else "OUT"
        var state_color := Color("#fff36a") if alive else Color("#5a6b5a")
        if bool(hero.get("parked", false)):
            state = "AFK"
            state_color = Color("#ff8d93")
        _text(Vector2(186.0, row_y), state, 15, state_color, 76.0)
        row_y += 26.0

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

func _draw_status_blocks(rect: Rect2, ratio: float, segments: int, color: Color, pulse_endpoint: bool, pulse_all: bool, pulse_hz: float) -> void:
    var gap := 3.0
    var block_width := (rect.size.x - gap * float(segments - 1)) / float(segments)
    var filled_units := clampf(ratio, 0.0, 1.0) * float(segments)
    var endpoint := clampi(ceili(filled_units) - 1, 0, segments - 1)
    var pulse := 0.5 + 0.5 * sin(float(world.tick) * TAU * pulse_hz / 60.0)
    for index in range(segments):
        var block := Rect2(rect.position + Vector2(float(index) * (block_width + gap), 0.0), Vector2(block_width, rect.size.y))
        var portion := clampf(filled_units - float(index), 0.0, 1.0)
        draw_rect(block, Color(0.025, 0.035, 0.050, 0.94))
        var is_pulsing := pulse_all or (pulse_endpoint and index == endpoint and portion > 0.0)
        var fill_alpha := lerpf(1.0, 0.18, pulse) if is_pulsing else 1.0
        var border_alpha := lerpf(0.58, 1.0, pulse) if is_pulsing else (0.52 if portion > 0.0 else 0.20)
        if portion > 0.0:
            var inner := Rect2(block.position + Vector2(2.0, 2.0), Vector2(maxf(0.0, (block.size.x - 4.0) * portion), block.size.y - 4.0))
            draw_rect(inner, Color(color, fill_alpha))
        draw_rect(block, Color(color, border_alpha), false, 2.0)

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
    _draw_status_blocks(Rect2(bar.position + Vector2(8.0, 19.0), Vector2(310.0, 16.0)), hp_ratio, 10, hp_color, hp_now > 0.0, false, 1.2)
    var ult_max := 100.0
    var power_ratio := clampf(float(me.get("ultimate_charge", 0.0)) / maxf(1.0, ult_max), 0.0, 1.0)
    var ult_ready := power_ratio >= 0.999
    var ult_color := Color("#a970ff") if ult_ready else Color("#4f8cff")
    _text(bar.position + Vector2(328.0, 15.0), "ULT READY" if ult_ready else "ULT  %d%%" % roundi(power_ratio * 100.0), 12, ult_color, 164.0, HORIZONTAL_ALIGNMENT_RIGHT)
    _draw_status_blocks(Rect2(bar.position + Vector2(326.0, 19.0), Vector2(168.0, 16.0)), power_ratio, 8, ult_color, false, ult_ready, 0.7)
    _draw_perk_chips_at(me, bar.position + Vector2(8.0, 38.0), bar.size.x - 16.0)

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

func _ammo_frame_rect(frame: int) -> Rect2:
    match clampi(frame, 0, 3):
        0:
            return Rect2(0.0, 256.0, 440.0, 256.0)
        1:
            return Rect2(430.0, 256.0, 470.0, 256.0)
        2:
            return Rect2(920.0, 256.0, 500.0, 256.0)
        _:
            return Rect2(1400.0, 256.0, 500.0, 256.0)

func _draw_ammo_round(pos: Vector2, frame: int, alpha: float = 1.0) -> void:
    var display_rect := Rect2(pos, Vector2(74.0, 34.0))
    if ammo_round_texture != null:
        draw_texture_rect_region(ammo_round_texture, display_rect, _ammo_frame_rect(frame), Color(1.0, 1.0, 1.0, alpha))
        return
    var tint := Color(1.0, 0.73, 0.24, alpha)
    draw_rect(Rect2(pos + Vector2(8.0, 11.0), Vector2(46.0, 12.0)), tint)
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(54.0, 11.0),
        pos + Vector2(70.0, 17.0),
        pos + Vector2(54.0, 23.0),
    ]), tint)

func _spawn_ammo_casings(amount: int, capacity: int, tick_now: int) -> void:
    for shot_index in range(amount):
        _ammo_casing_serial += 1
        var seed := fposmod(float(_ammo_casing_serial * 37), 101.0) / 101.0
        _ammo_casings.append({
            "tick": tick_now + shot_index,
            "seed": seed,
            "spin": 1.5 + fposmod(float(_ammo_casing_serial * 19), 100.0) / 100.0,
            "clockwise": 1.0 if _ammo_casing_serial % 2 == 0 else -1.0,
        })
    while _ammo_casings.size() > capacity:
        _ammo_casings.pop_front()

func _draw_ammo_casings(panel_left: float, row_top: float, tick_now: int) -> void:
    var alive_casings: Array[Dictionary] = []
    for casing in _ammo_casings:
        var age := maxf(0.0, float(tick_now - int(casing["tick"])) / 60.0)
        if age > 1.0:
            continue
        alive_casings.append(casing)
        var seed := float(casing["seed"])
        var start := Vector2(panel_left + 88.0 + seed * 20.0, row_top + 7.0 + seed * 5.0)
        var velocity := Vector2(245.0 + seed * 70.0, -104.0 - seed * 20.0)
        var pos := start + velocity * age + Vector2(0.0, 400.0 * age * age)
        var rotation := float(casing["clockwise"]) * TAU * float(casing["spin"]) * age + seed * TAU
        draw_set_transform(pos, rotation, Vector2.ONE)
        if ammo_casing_texture != null:
            draw_texture_rect_region(ammo_casing_texture, Rect2(-15.0, -10.0, 30.0, 20.0), Rect2(240.0, 280.0, 800.0, 680.0))
        else:
            draw_rect(Rect2(-9.0, -3.0, 18.0, 6.0), Color(0.95, 0.64, 0.18, 1.0))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _ammo_casings = alive_casings

func _draw_ammo_conveyor(me: Dictionary) -> void:
    var equipment: Dictionary = me.get("equipment", {})
    var equipment_id := str(equipment.get("id", equipment.get("name", "")))
    var mag_now := maxi(0, int(me.get("mag", 0)))
    var mag_max := maxi(1, int(equipment.get("mag_size", 1)))
    var tick_now := int(world.tick)
    var world_instance_id := int(world.get_instance_id())
    if _ammo_world_instance_id != world_instance_id or (_ammo_last_tick >= 0 and tick_now < _ammo_last_tick):
        reset_match_visuals()
        _ammo_world_instance_id = world_instance_id
    _ammo_last_tick = tick_now
    if equipment_id != _ammo_last_equipment:
        _ammo_last_equipment = equipment_id
        _ammo_last_mag = mag_now
        _ammo_eject_tick = -1000
        _ammo_casings.clear()
    elif _ammo_last_mag >= 0 and mag_now < _ammo_last_mag:
        var fired_rounds := _ammo_last_mag - mag_now
        _ammo_eject_tick = tick_now
        _spawn_ammo_casings(fired_rounds, int(ceil(float(mag_max) * 0.5)), tick_now)
    _ammo_last_mag = mag_now

    var right_edge := size.x - 14.0
    var bottom_edge := size.y - 10.0
    var header_y := bottom_edge - 134.0
    var row_top := header_y + 34.0
    var row_gap := 32.0
    var panel_width := 196.0
    var panel_left := right_edge - panel_width
    var panel_top := header_y - 8.0
    var notch := 8.0
    var bullet_x := panel_left + 12.0
    var panel_shape := PackedVector2Array([
        Vector2(panel_left + notch, panel_top),
        Vector2(right_edge, panel_top),
        Vector2(right_edge, bottom_edge),
        Vector2(panel_left + notch, bottom_edge),
        Vector2(panel_left, bottom_edge - notch),
        Vector2(panel_left, panel_top + notch),
        Vector2(panel_left + notch, panel_top),
    ])
    draw_colored_polygon(panel_shape, Color(0.008, 0.012, 0.020, 0.64))
    for band_y in range(int(panel_top) + 16, int(bottom_edge), 16):
        draw_line(Vector2(panel_left + 5.0, float(band_y)), Vector2(right_edge - 4.0, float(band_y)), Color(0.22, 0.25, 0.30, 0.10), 1.0)
    draw_polyline(panel_shape, Color("#ffd166", 0.68), 2.0)
    draw_line(Vector2(panel_left + 12.0, panel_top + 27.0), Vector2(right_edge - 10.0, panel_top + 27.0), Color("#ffd166", 0.28), 1.0)
    for marker_y in range(int(row_top) + 15, int(bottom_edge) - 8, int(row_gap)):
        draw_line(Vector2(panel_left + 3.0, float(marker_y)), Vector2(panel_left + 8.0, float(marker_y)), Color("#ffd166", 0.42), 2.0)
    _draw_ammo_casings(panel_left, row_top, tick_now)

    var reloading := float(me.get("reload_left", 0.0)) > 0.0
    var counter_color := Color("#ffd166") if reloading else (Color("#ff5d73") if mag_now <= 0 else Color.WHITE)
    var prefix := "RELOAD  " if reloading else ("EMPTY  " if mag_now <= 0 else "")
    _text(Vector2(panel_left + 10.0, header_y + 18.0), "%s%d / %d" % [prefix, mag_now, mag_max], 21, counter_color, panel_width - 20.0, HORIZONTAL_ALIGNMENT_RIGHT)

    var eject_progress := clampf(float(tick_now - _ammo_eject_tick) / 9.0, 0.0, 1.0)
    var ejecting := eject_progress < 1.0
    var shift_offset := row_gap * (1.0 - eject_progress) if ejecting else 0.0
    var visible_rounds := mini(mag_now, 3)
    for index in range(visible_rounds):
        var round_pos := Vector2(bullet_x, row_top + float(index) * row_gap + shift_offset)
        var slot_alpha := 1.0
        if round_pos.y + 30.0 > bottom_edge:
            slot_alpha = clampf((bottom_edge - round_pos.y) / 30.0, 0.0, 1.0)
        _draw_ammo_round(round_pos, 0, slot_alpha)

    if ejecting:
        var eased := 1.0 - pow(1.0 - eject_progress, 3.0)
        var eject_pos := Vector2(bullet_x + eased * 150.0, row_top - sin(eject_progress * PI) * 5.0)
        var eject_frame := mini(3, int(eject_progress * 4.0))
        var eject_alpha := 1.0 - clampf((eject_progress - 0.68) / 0.32, 0.0, 1.0)
        _draw_ammo_round(eject_pos, eject_frame, eject_alpha)

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
    if str(world.mode) == "item":
        var kind := str(me.get("held_item", ""))
        var label := HudBuffs.held_item_label(kind)
        var usable := label != "EMPTY"
        var accent: Color = HudBuffs.held_item_color(kind)
        draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
        draw_rect(rect, Color(accent, 0.85 if usable else 0.25), false, 2.0)
        if kind == "medkit" and medkit_texture != null:
            draw_texture_rect(medkit_texture, Rect2(rect.position + Vector2(10.0, 15.0), Vector2(34.0, 34.0)), false)
        else:
            draw_circle(rect.position + Vector2(27.0, 34.0), 12.0, Color(accent, 0.85 if usable else 0.28))
        _text(rect.position + Vector2(52.0, 40.0), label, 16, accent if usable else Color("#6b7480"))
        _text(rect.position + Vector2(10.0, 15.0), "E", 11, accent if usable else Color("#6b7480"))
        return
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
    _text(rect.position + Vector2(10.0, 15.0), "대시" if touch_hints else "SHIFT", 10, chevron)
    if ready:
        _text(rect.position + Vector2(48.0, 40.0), "대시", 15, Color.WHITE)
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
        _text(Vector2(450.0, 701.0), "대기실로 버튼을 누르세요" if touch_hints else "대기실로 버튼 또는 ESC", 19, Color("#dbe5f0"), 700.0, HORIZONTAL_ALIGNMENT_CENTER)
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
        _text(Vector2(530.0, 691.0), "ROOTED  |  MOVE/SHIFT/SPACE LOCKED - FIRE AVAILABLE", 17, Color("#d8b4ff"), 540.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.last_down_ticks > 0 and world.last_down_slot >= 0:
        var down_alpha := clampf(float(world.last_down_ticks) / 18.0, 0.0, 1.0)
        var down_hero: Dictionary = world.heroes[world.last_down_slot]
        draw_rect(Rect2(520.0, 52.0, 560.0, 36.0), Color(0.12, 0.01, 0.03, 0.42 * down_alpha))
        _text(Vector2(530.0, 76.0), "P%d %s님이 쓰러졌습니다." % [world.last_down_slot + 1, down_hero["equipment"]["character_name"]], 18, Color(1.0, 1.0, 1.0, down_alpha * 0.9), 540.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.callout_ticks > 0 and world.result == &"playing":
        var alpha := clampf(float(world.callout_ticks) / 24.0, 0.0, 1.0)
        draw_rect(Rect2(560.0, 52.0, 480.0, 28.0), Color(0.04, 0.04, 0.06, 0.32 * alpha))
        _text(Vector2(580.0, 72.0), world.callout, 13, Color(1.0, 0.74, 0.42, alpha), 440.0, HORIZONTAL_ALIGNMENT_CENTER)
    if world.streak_callout_ticks > 0 and world.result == &"playing":
        var streak_alpha := clampf(float(world.streak_callout_ticks) / 18.0, 0.0, 1.0)
        var streak_color := Color("#ff4f68") if world.streak_callout_shutdown else Color("#ffd166")
        draw_rect(Rect2(520.0, 52.0, 560.0, 40.0), Color(0.04, 0.02, 0.03, 0.36 * streak_alpha))
        _text(Vector2(530.0, 78.0), world.streak_callout, 16, Color(streak_color, streak_alpha * 0.9), 540.0, HORIZONTAL_ALIGNMENT_CENTER)
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
    var left := maxi(0, 3 - int(me.get("revives_used", 0)))
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
func _draw_crosshair(me: Dictionary) -> void:
    if me.is_empty():
        return
    var spray_i := float(me.get("spray_index", 0.0))
    var c: Vector2 = get_local_mouse_position()
    var climb := spray_i * 3.2
    var gap := 8.0 + climb * 0.10
    var arm := 11.0
    var ink := Color(0.12, 0.07, 0.04, 0.92)
    var fill := Color(1.0, 0.96, 0.86, 0.96)
    var accent := Color(1.0, 0.55, 0.22, 0.95)
    for thick in [3.4, 1.6]:
        var col := ink if thick > 2.0 else fill
        draw_circle(c, 2.6 if thick > 2.0 else 1.7, col if thick > 2.0 else accent)
        draw_line(c + Vector2(0, -gap - arm), c + Vector2(0, -gap), col, thick)
        draw_line(c + Vector2(0, gap), c + Vector2(0, gap + arm), col, thick)
        draw_line(c + Vector2(-gap - arm, 0), c + Vector2(-gap, 0), col, thick)
        draw_line(c + Vector2(gap, 0), c + Vector2(gap + arm, 0), col, thick)
    draw_arc(c, 5.0 + climb * 0.04, 0.0, TAU, 28, Color(accent, 0.45), 1.4)

func _draw_controls_overlay() -> void:
    if _controls_dismissed or _controls_overlay_time <= 0.0:
        return
    _controls_overlay_time -= 1.0 / 60.0
    if Input.is_anything_pressed():
        _controls_dismissed = true
        return
    var alpha := clampf(_controls_overlay_time / 1.0, 0.0, 1.0) if _controls_overlay_time < 1.0 else 0.85
    var bg := Color(0.0, 0.0, 0.0, alpha * 0.7)
    var tx := Color(1.0, 1.0, 1.0, alpha)
    var cx := size.x * 0.5
    var cy := size.y * 0.5
    draw_rect(Rect2(cx - 160, cy - 90, 320, 180), bg)
    var lines := ["WASD  이동", "마우스  조준", "좌클릭  공격", "우클릭(홀드)  장비 스킬", "Shift  대시"]
    for i in lines.size():
        _text(Vector2(cx - 130, cy - 60 + i * 28), lines[i], 16, tx)

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
        var label := "%s → %s" % [killer_name, victim_name] if killer_name != "" else "%s 탈락" % victim_name
        if t == &"player_eliminated":
            label += " 제거"
        _kill_feed.append({"text": label, "time": now})
    while _kill_feed.size() > 5:
        _kill_feed.pop_front()
    var cutoff := now - 180
    while not _kill_feed.is_empty() and int(_kill_feed[0]["time"]) < cutoff:
        _kill_feed.pop_front()

func _draw_kill_feed() -> void:
    var x := size.x - 220.0
    var y := 60.0
    for i in _kill_feed.size():
        var entry: Dictionary = _kill_feed[i]
        var age := int(world.tick) - int(entry["time"])
        var alpha := clampf(1.0 - float(age) / 180.0, 0.0, 1.0)
        draw_rect(Rect2(x - 4, y + i * 22 - 14, 210, 20), Color(0.0, 0.0, 0.0, 0.5 * alpha))
        _text(Vector2(x, y + i * 22), str(entry["text"]), 13, Color(1.0, 1.0, 1.0, alpha))
