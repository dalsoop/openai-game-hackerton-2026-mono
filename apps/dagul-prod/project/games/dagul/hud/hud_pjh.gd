class_name HudPjhDraw
extends RefCounted

const ANIMAL_ATLAS_FRAME := [0, 1, 2, 3, 5, 4, 6, 7, 8, 9, 10, 11]
const LayoutKeysScript := preload("res://core/input/layout_keys.gd")

var h: Control

func _init(hud: Control) -> void:
	h = hud


func reset_match_visuals() -> void:
	h._ammo_last_mag = -1
	h._ammo_last_equipment = ""
	h._ammo_eject_tick = -1000
	h._ammo_casings.clear()
	h._ammo_casing_serial = 0
	h._ammo_last_tick = -1
	h._ammo_world_instance_id = 0
	h._result_hold_at_ms = -1


func draw_zone_overlay() -> void:
	var world = h.world
	var slot := clampi(int(world.local_slot), 0, world.heroes.size() - 1)
	var hero: Dictionary = world.heroes[slot]
	if not bool(hero.get("alive", false)) or bool(hero.get("eliminated", false)):
		return
	var outside := Vector2(hero["pos"]).distance_to(Vector2(world.safe_zone_center)) - float(world.safe_zone_radius)
	if outside <= 0.0:
		return
	var danger := clampf(0.34 + outside / 260.0, 0.34, 1.0)
	var edge_alpha := danger * (0.72 + 0.28 * sin(float(world.tick) * 0.38))
	_draw_zone_vignette(edge_alpha)
	_draw_zone_bolts(edge_alpha)


func _draw_zone_vignette(edge_alpha: float) -> void:
	var edge_color := Color(0.66, 0.15, 0.96, 0.20 * edge_alpha)
	h.draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(0.42, 0.03, 0.68, 0.07 * edge_alpha))
	for inset_index in range(10):
		var inset := float(inset_index) * 8.0
		var gradient_t := 1.0 - float(inset_index) / 10.0
		h.draw_rect(Rect2(inset, inset, 1600.0 - inset * 2.0, 900.0 - inset * 2.0), Color(edge_color, edge_color.a * gradient_t * gradient_t), false, 9.0)


func _draw_zone_bolts(edge_alpha: float) -> void:
	var world = h.world
	var burst_tick := posmod(int(world.tick), 9)
	if burst_tick >= 6:
		return
	var burst_progress := float(burst_tick) / 5.0
	var rise := clampf(float(burst_tick) / 2.0, 0.0, 1.0)
	var envelope := sin(burst_progress * PI) * edge_alpha
	var burst_cycle := int(world.tick / 9)
	for bolt_index in range(6):
		_draw_one_bolt(bolt_index, burst_cycle, rise, envelope)


func _draw_one_bolt(bolt_index: int, burst_cycle: int, rise: float, envelope: float) -> void:
	var seed := bolt_index * 137 + burst_cycle * 293 + int(h.world.local_slot) * 41
	if posmod(seed, 5) == 0:
		return
	var side := posmod(seed, 4)
	var side_ratio := float(posmod(seed * 17, 941)) / 941.0
	var start := _bolt_start(side, side_ratio)
	var inward := _bolt_inward(side)
	if h.zone_lightning_texture != null:
		_draw_bolt_tex(start, inward, side, seed, rise, envelope)
	else:
		_draw_bolt_poly(start, inward, _bolt_tangent(side), seed, envelope)


func _bolt_start(side: int, side_ratio: float) -> Vector2:
	match side:
		0:
			return Vector2(40.0 + side_ratio * 1520.0, 2.0)
		1:
			return Vector2(1598.0, 40.0 + side_ratio * 820.0)
		2:
			return Vector2(40.0 + side_ratio * 1520.0, 898.0)
		_:
			return Vector2(2.0, 40.0 + side_ratio * 820.0)


func _bolt_inward(side: int) -> Vector2:
	match side:
		0:
			return Vector2.DOWN
		1:
			return Vector2.LEFT
		2:
			return Vector2.UP
		_:
			return Vector2.RIGHT


func _bolt_tangent(side: int) -> Vector2:
	return Vector2.RIGHT if side == 0 or side == 2 else Vector2.DOWN


func _draw_bolt_tex(start: Vector2, inward: Vector2, side: int, seed: int, rise: float, envelope: float) -> void:
	var tex: Texture2D = h.zone_lightning_texture
	var frame := posmod(seed / 7, 8)
	var cell := Vector2(float(tex.get_width()) / 4.0, float(tex.get_height()) / 2.0)
	var src := Rect2(Vector2(float(frame % 4), float(frame / 4)) * cell, cell)
	var scale_random := 1.0 + float(posmod(seed * 31, 501)) / 1000.0
	var visible_ratio := 0.50 + float(posmod(seed * 19, 301)) / 1000.0
	var bolt_size := Vector2(52.0, 90.0) * scale_random
	var visible_length := bolt_size.y * visible_ratio * rise
	var bolt_center := start + inward * (visible_length - bolt_size.y * 0.5)
	var rot: float = [0.0, -PI * 0.5, PI, PI * 0.5][side]
	h.draw_set_transform(bolt_center, rot, Vector2.ONE)
	h.draw_texture_rect_region(tex, Rect2(-bolt_size * 0.5, bolt_size), src, Color(1.0, 1.0, 1.0, envelope))
	h.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _bolt_shape(pattern: int) -> PackedVector2Array:
	match pattern:
		0:
			return PackedVector2Array([Vector2(0, 0), Vector2(-5, 9), Vector2(3, 17), Vector2(-3, 28), Vector2(8, 40)])
		1:
			return PackedVector2Array([Vector2(0, 0), Vector2(7, 7), Vector2(2, 18), Vector2(10, 25), Vector2(-4, 42)])
		2:
			return PackedVector2Array([Vector2(0, 0), Vector2(-8, 11), Vector2(8, 19), Vector2(-7, 29), Vector2(2, 44)])
		3:
			return PackedVector2Array([Vector2(0, 0), Vector2(3, 10), Vector2(-10, 20), Vector2(-2, 31), Vector2(9, 39)])
		_:
			return PackedVector2Array([Vector2(0, 0), Vector2(10, 8), Vector2(-2, 15), Vector2(5, 27), Vector2(-8, 43)])


func _draw_bolt_poly(start: Vector2, inward: Vector2, tangent: Vector2, seed: int, envelope: float) -> void:
	var points := PackedVector2Array()
	for shape_point in _bolt_shape(posmod(seed / 4, 5)):
		points.append(start + tangent * shape_point.x + inward * shape_point.y)
	h.draw_polyline(points, Color(0.52, 0.08, 0.90, 0.58 * envelope), 7.0)
	h.draw_polyline(points, Color(0.94, 0.76, 1.0, 0.96 * envelope), 2.0)
	var spark := points[points.size() - 1]
	h.draw_rect(Rect2(spark - Vector2.ONE * 3.0, Vector2.ONE * 6.0), Color(1.0, 0.90, 1.0, envelope))


func draw_status_blocks(rect: Rect2, ratio: float, segments: int, color: Color, pulse_endpoint: bool, pulse_all: bool, pulse_hz: float) -> void:
	var gap := 3.0
	var block_width := (rect.size.x - gap * float(segments - 1)) / float(segments)
	var filled_units := clampf(ratio, 0.0, 1.0) * float(segments)
	var endpoint := clampi(ceili(filled_units) - 1, 0, segments - 1)
	var pulse := 0.5 + 0.5 * sin(float(h.world.tick) * TAU * pulse_hz / 60.0)
	for index in range(segments):
		_draw_status_block(rect, index, block_width, gap, filled_units, endpoint, pulse, color, pulse_endpoint, pulse_all)


func _draw_status_block(rect: Rect2, index: int, block_width: float, gap: float, filled_units: float, endpoint: int, pulse: float, color: Color, pulse_endpoint: bool, pulse_all: bool) -> void:
	var block := Rect2(rect.position + Vector2(float(index) * (block_width + gap), 0.0), Vector2(block_width, rect.size.y))
	var portion := clampf(filled_units - float(index), 0.0, 1.0)
	h.draw_rect(block, Color(0.025, 0.035, 0.050, 0.94))
	var is_pulsing := pulse_all or (pulse_endpoint and index == endpoint and portion > 0.0)
	var fill_alpha := lerpf(1.0, 0.18, pulse) if is_pulsing else 1.0
	var border_alpha := lerpf(0.58, 1.0, pulse) if is_pulsing else (0.52 if portion > 0.0 else 0.20)
	if portion > 0.0:
		h.draw_rect(Rect2(block.position + Vector2(2.0, 2.0), Vector2(maxf(0.0, (block.size.x - 4.0) * portion), block.size.y - 4.0)), Color(color, fill_alpha))
	h.draw_rect(block, Color(color, border_alpha), false, 2.0)


func draw_pixel_panel(rect: Rect2, accent: Color, fill: Color) -> void:
	var cut := 12.0
	var points := PackedVector2Array([
		rect.position + Vector2(cut, 0.0), rect.position + Vector2(rect.size.x - cut, 0.0),
		rect.position + Vector2(rect.size.x, cut), rect.position + Vector2(rect.size.x, rect.size.y - cut),
		rect.position + Vector2(rect.size.x - cut, rect.size.y), rect.position + Vector2(cut, rect.size.y),
		rect.position + Vector2(0.0, rect.size.y - cut), rect.position + Vector2(0.0, cut)
	])
	h.draw_colored_polygon(points, fill)
	var outline := points.duplicate()
	outline.append(points[0])
	h.draw_polyline(outline, Color(accent, 0.92), 3.0)
	h.draw_line(rect.position + Vector2(cut + 8.0, 7.0), rect.position + Vector2(rect.size.x - cut - 8.0, 7.0), Color(accent, 0.28), 2.0)
	h.draw_rect(Rect2(rect.position + Vector2(8.0, 18.0), Vector2(4.0, rect.size.y - 36.0)), Color(accent, 0.76))


func draw_winner_god_rays(center: Vector2, accent: Color) -> void:
	var pulse := 0.88 + sin(float(h.world.tick) * 0.055) * 0.12
	var gold := Color("#ffd166")
	var top_y := 140.0
	var bottom_y := center.y + 142.0
	h.draw_colored_polygon(_beam(center, top_y, bottom_y, 42.0, 142.0), Color(accent, 0.045 * pulse))
	h.draw_colored_polygon(_beam(center, top_y, bottom_y, 25.0, 104.0), Color(gold, 0.075 * pulse))
	h.draw_colored_polygon(_beam(center, top_y, bottom_y, 11.0, 62.0), Color("#fff3bd", 0.085 * pulse))
	_draw_ray_ticks(center, top_y, gold, pulse)
	_draw_ray_glow(center, top_y, gold, pulse)


func _beam(center: Vector2, top_y: float, bottom_y: float, top_w: float, bot_w: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(center.x - top_w, top_y), Vector2(center.x + top_w, top_y),
		Vector2(center.x + bot_w, bottom_y), Vector2(center.x - bot_w, bottom_y)
	])


func _draw_ray_ticks(center: Vector2, top_y: float, gold: Color, pulse: float) -> void:
	for step_index in range(6):
		var step_y := top_y + 28.0 + step_index * 53.0
		var spread := 50.0 + step_index * 17.0
		h.draw_line(Vector2(center.x - spread, step_y), Vector2(center.x - spread + 16.0, step_y), Color(gold, 0.22 * pulse), 3.0)
		h.draw_line(Vector2(center.x + spread - 16.0, step_y), Vector2(center.x + spread, step_y), Color(gold, 0.22 * pulse), 3.0)
	h.draw_rect(Rect2(center.x - 45.0, top_y, 90.0, 5.0), Color("#fff3bd", 0.62 * pulse))
	h.draw_rect(Rect2(center.x - 29.0, top_y + 7.0, 58.0, 3.0), Color(gold, 0.34 * pulse))


func _draw_ray_glow(center: Vector2, top_y: float, gold: Color, pulse: float) -> void:
	h.draw_set_transform(center + Vector2(0.0, 112.0), 0.0, Vector2(1.0, 0.34))
	h.draw_circle(Vector2.ZERO, 132.0, Color(gold, 0.11 * pulse))
	h.draw_arc(Vector2.ZERO, 132.0, 0.0, TAU, 32, Color(gold, 0.42 * pulse), 5.0)
	h.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for dust_index in range(10):
		var dust_x := center.x - 92.0 + float((dust_index * 37) % 184)
		var dust_y := top_y + 38.0 + float((dust_index * 61) % 310)
		var flicker := 0.45 + sin(float(h.world.tick) * 0.09 + float(dust_index)) * 0.25
		var dust_size := 2.0 if dust_index % 3 != 0 else 4.0
		h.draw_rect(Rect2(Vector2(roundf(dust_x / 2.0) * 2.0, roundf(dust_y / 2.0) * 2.0), Vector2(dust_size, dust_size)), Color(gold, flicker * pulse))


func draw_ammo_conveyor(me: Dictionary) -> void:
	_sync_ammo_state(me)
	var mag_now := maxi(0, int(me.get("mag", 0)))
	var mag_max := maxi(1, int(me.get("equipment", {}).get("mag_size", 1)))
	var layout := _ammo_layout()
	_draw_ammo_panel(layout)
	_draw_ammo_casings(layout["panel_left"], layout["row_top"], int(h.world.tick))
	_draw_ammo_header(me, layout, mag_now, mag_max)
	_draw_ammo_rounds(layout, mag_now)


func _sync_ammo_state(me: Dictionary) -> void:
	var equipment: Dictionary = me.get("equipment", {})
	var equipment_id := str(equipment.get("id", equipment.get("name", "")))
	var mag_now := maxi(0, int(me.get("mag", 0)))
	var mag_max := maxi(1, int(equipment.get("mag_size", 1)))
	var tick_now := int(h.world.tick)
	var world_instance_id := int(h.world.get_instance_id())
	if h._ammo_world_instance_id != world_instance_id or (h._ammo_last_tick >= 0 and tick_now < h._ammo_last_tick):
		reset_match_visuals()
		h._ammo_world_instance_id = world_instance_id
	h._ammo_last_tick = tick_now
	_apply_ammo_delta(equipment_id, mag_now, mag_max, tick_now)


func _apply_ammo_delta(equipment_id: String, mag_now: int, mag_max: int, tick_now: int) -> void:
	if equipment_id != h._ammo_last_equipment:
		h._ammo_last_equipment = equipment_id
		h._ammo_last_mag = mag_now
		h._ammo_eject_tick = -1000
		h._ammo_casings.clear()
	elif h._ammo_last_mag >= 0 and mag_now < h._ammo_last_mag:
		h._ammo_eject_tick = tick_now
		_spawn_ammo_casings(h._ammo_last_mag - mag_now, int(ceil(float(mag_max) * 0.5)), tick_now)
	h._ammo_last_mag = mag_now


func _ammo_layout() -> Dictionary:
	var right_edge := h.size.x - 14.0
	var bottom_edge := h.size.y - 10.0
	var header_y := bottom_edge - 134.0
	var panel_width := 196.0
	return {
		"right_edge": right_edge, "bottom_edge": bottom_edge, "header_y": header_y,
		"row_top": header_y + 34.0, "row_gap": 32.0, "panel_width": panel_width,
		"panel_left": right_edge - panel_width, "panel_top": header_y - 8.0,
		"bullet_x": right_edge - panel_width + 12.0,
	}


func _draw_ammo_panel(layout: Dictionary) -> void:
	var notch := 8.0
	var panel_left: float = layout["panel_left"]
	var panel_top: float = layout["panel_top"]
	var right_edge: float = layout["right_edge"]
	var bottom_edge: float = layout["bottom_edge"]
	var shape := PackedVector2Array([
		Vector2(panel_left + notch, panel_top), Vector2(right_edge, panel_top),
		Vector2(right_edge, bottom_edge), Vector2(panel_left + notch, bottom_edge),
		Vector2(panel_left, bottom_edge - notch), Vector2(panel_left, panel_top + notch),
		Vector2(panel_left + notch, panel_top),
	])
	h.draw_colored_polygon(shape, Color(0.008, 0.012, 0.020, 0.64))
	_draw_ammo_panel_marks(layout, shape)


func _draw_ammo_panel_marks(layout: Dictionary, shape: PackedVector2Array) -> void:
	var panel_left: float = layout["panel_left"]
	var panel_top: float = layout["panel_top"]
	var right_edge: float = layout["right_edge"]
	var bottom_edge: float = layout["bottom_edge"]
	for band_y in range(int(panel_top) + 16, int(bottom_edge), 16):
		h.draw_line(Vector2(panel_left + 5.0, float(band_y)), Vector2(right_edge - 4.0, float(band_y)), Color(0.22, 0.25, 0.30, 0.10), 1.0)
	h.draw_polyline(shape, Color("#ffd166", 0.68), 2.0)
	h.draw_line(Vector2(panel_left + 12.0, panel_top + 27.0), Vector2(right_edge - 10.0, panel_top + 27.0), Color("#ffd166", 0.28), 1.0)
	for marker_y in range(int(layout["row_top"]) + 15, int(bottom_edge) - 8, int(layout["row_gap"])):
		h.draw_line(Vector2(panel_left + 3.0, float(marker_y)), Vector2(panel_left + 8.0, float(marker_y)), Color("#ffd166", 0.42), 2.0)


func _spawn_ammo_casings(amount: int, capacity: int, tick_now: int) -> void:
	for shot_index in range(amount):
		h._ammo_casing_serial += 1
		var seed := fposmod(float(h._ammo_casing_serial * 37), 101.0) / 101.0
		h._ammo_casings.append({
			"tick": tick_now + shot_index,
			"seed": seed,
			"spin": 1.5 + fposmod(float(h._ammo_casing_serial * 19), 100.0) / 100.0,
			"clockwise": 1.0 if h._ammo_casing_serial % 2 == 0 else -1.0,
		})
	while h._ammo_casings.size() > capacity:
		h._ammo_casings.pop_front()


func _draw_ammo_casings(panel_left: float, row_top: float, tick_now: int) -> void:
	var alive_casings: Array[Dictionary] = []
	for casing in h._ammo_casings:
		var age := maxf(0.0, float(tick_now - int(casing["tick"])) / 60.0)
		if age > 1.0:
			continue
		alive_casings.append(casing)
		_draw_hud_casing(casing, panel_left, row_top, age)
	h._ammo_casings = alive_casings


func _draw_hud_casing(casing: Dictionary, panel_left: float, row_top: float, age: float) -> void:
	var seed := float(casing["seed"])
	var start := Vector2(panel_left + 88.0 + seed * 20.0, row_top + 7.0 + seed * 5.0)
	var velocity := Vector2(245.0 + seed * 70.0, -104.0 - seed * 20.0)
	var pos := start + velocity * age + Vector2(0.0, 400.0 * age * age)
	var rotation := float(casing["clockwise"]) * TAU * float(casing["spin"]) * age + seed * TAU
	h.draw_set_transform(pos, rotation, Vector2.ONE)
	if h.ammo_casing_texture != null:
		h.draw_texture_rect_region(h.ammo_casing_texture, Rect2(-15.0, -10.0, 30.0, 20.0), Rect2(240.0, 280.0, 800.0, 680.0))
	else:
		h.draw_rect(Rect2(-9.0, -3.0, 18.0, 6.0), Color(0.95, 0.64, 0.18, 1.0))
	h.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ammo_header(me: Dictionary, layout: Dictionary, mag_now: int, mag_max: int) -> void:
	var reload_left := float(me.get("reload_left", 0.0))
	var reloading := reload_left > 0.04
	var counter_color := Color("#ffd166") if reloading else (Color("#ff5d73") if mag_now <= 0 else Color.WHITE)
	var ammo_label := HudStrings.t("hud_ammo") % [mag_now, mag_max]
	if reloading:
		ammo_label = HudStrings.t("hud_reload_time") % reload_left
	elif mag_now <= 0:
		ammo_label = HudStrings.t("hud_empty") % mag_max
	var key := HudStrings.t("hud_reload_name") if h.touch_hints else LayoutKeysScript.seat_label(KEY_R)
	h._text(Vector2(layout["panel_left"] + 10.0, layout["header_y"] + 18.0), key, 14, counter_color, 36.0)
	h._text(Vector2(layout["panel_left"] + 44.0, layout["header_y"] + 18.0), ammo_label, 18, counter_color, layout["panel_width"] - 54.0, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_ammo_rounds(layout: Dictionary, mag_now: int) -> void:
	var tick_now := int(h.world.tick)
	var eject_progress := clampf(float(tick_now - h._ammo_eject_tick) / 9.0, 0.0, 1.0)
	var ejecting := eject_progress < 1.0
	var shift_offset: float = layout["row_gap"] * (1.0 - eject_progress) if ejecting else 0.0
	var visible_rounds := mini(mag_now, 3)
	for index in range(visible_rounds):
		var round_pos := Vector2(layout["bullet_x"], layout["row_top"] + float(index) * layout["row_gap"] + shift_offset)
		var slot_alpha := 1.0
		if round_pos.y + 30.0 > layout["bottom_edge"]:
			slot_alpha = clampf((layout["bottom_edge"] - round_pos.y) / 30.0, 0.0, 1.0)
		_draw_ammo_round(round_pos, 0, slot_alpha)
	if ejecting:
		_draw_eject_round(layout, eject_progress)


func _draw_eject_round(layout: Dictionary, eject_progress: float) -> void:
	var eased := 1.0 - pow(1.0 - eject_progress, 3.0)
	var eject_pos := Vector2(layout["bullet_x"] + eased * 150.0, layout["row_top"] - sin(eject_progress * PI) * 5.0)
	_draw_ammo_round(eject_pos, mini(3, int(eject_progress * 4.0)), 1.0 - clampf((eject_progress - 0.68) / 0.32, 0.0, 1.0))


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
	if h.ammo_round_texture != null:
		h.draw_texture_rect_region(h.ammo_round_texture, display_rect, _ammo_frame_rect(frame), Color(1.0, 1.0, 1.0, alpha))
		return
	var tint := Color(1.0, 0.73, 0.24, alpha)
	h.draw_rect(Rect2(pos + Vector2(8.0, 11.0), Vector2(46.0, 12.0)), tint)
	h.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(54.0, 11.0), pos + Vector2(70.0, 17.0), pos + Vector2(54.0, 23.0),
	]), tint)


func draw_countdown() -> void:
	var world = h.world
	var center := Vector2(800.0, 450.0)
	var count_value := clampi(ceili(world.start_countdown), 1, 3)
	var countdown_fraction := fposmod(world.start_countdown, 1.0)
	var countdown_beat := 0.0 if countdown_fraction < 0.001 else 1.0 - countdown_fraction
	var countdown_punch := lerpf(1.22, 1.0, clampf(countdown_beat / 0.22, 0.0, 1.0))
	var accent := _countdown_accent(count_value)
	h.draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(0.01, 0.015, 0.025, 0.12))
	draw_pixel_panel(Rect2(center - Vector2(104.0, 104.0), Vector2(208.0, 208.0)), accent, Color(0.025, 0.035, 0.055, 0.94))
	h.draw_arc(center, 90.0, -PI * 0.5, -PI * 0.5 + TAU * countdown_fraction, 32, accent, 6.0)
	_draw_countdown_ticks(center, accent)
	h._text(Vector2(696.0, 314.0), HudStrings.t("countdown_ready"), 16, Color("#d9e7f2"), 208.0, HORIZONTAL_ALIGNMENT_CENTER)
	h.draw_set_transform(center, 0.0, Vector2.ONE * countdown_punch)
	h._text(Vector2(-80.0, 31.0), str(count_value), 82, Color.WHITE, 160.0, HORIZONTAL_ALIGNMENT_CENTER)
	h.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_countdown_steps(count_value, accent)

func _countdown_accent(count_value: int) -> Color:
	match count_value:
		1:
			return Color("#ff5d49")
		2:
			return Color("#ff9f43")
		_:
			return Color("#ffd166")


func _draw_countdown_ticks(center: Vector2, accent: Color) -> void:
	for tick_index in range(8):
		var tick_angle := TAU * float(tick_index) / 8.0
		var tick_from := center + Vector2.from_angle(tick_angle) * 112.0
		var tick_len := 124.0 if tick_index % 2 == 0 else 119.0
		var tick_to := center + Vector2.from_angle(tick_angle) * tick_len
		h.draw_line(tick_from, tick_to, Color(accent, 0.88), 4.0)


func _draw_countdown_steps(count_value: int, accent: Color) -> void:
	var steps := 3
	var shown := mini(count_value, steps)
	for step_index in range(steps):
		var step_rect := Rect2(724.0 + step_index * 32.0, 574.0, 24.0, 6.0)
		var step_active := step_index >= steps - shown
		h.draw_rect(step_rect, accent if step_active else Color(0.25, 0.3, 0.36, 0.55))


func animal_src_rect(animal: int) -> Rect2:
	if h.animal_texture == null:
		return Rect2()
	var frame := int(ANIMAL_ATLAS_FRAME[posmod(animal, 12)])
	var cell := Vector2(float(h.animal_texture.get_width()) / 4.0, float(h.animal_texture.get_height()) / 3.0)
	return Rect2(Vector2(frame % 4, int(frame / 4)) * cell, cell)


func draw_match_result() -> void:
	var world = h.world
	h.draw_rect(Rect2(0.0, 0.0, 1600.0, 900.0), Color(0.005, 0.008, 0.014, 0.58))
	if world.winner_slot < 0:
		draw_pixel_panel(Rect2(470.0, 302.0, 660.0, 240.0), Color("#8b96a8"), Color(0.018, 0.026, 0.040, 0.97))
		h._text(Vector2(510.0, 390.0), HudStrings.t("match_draw"), 48, Color.WHITE, 580.0, HORIZONTAL_ALIGNMENT_CENTER)
		h._text(Vector2(510.0, 446.0), HudStrings.t("match_no_survivors"), 20, Color("#aebaca"), 580.0, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_result_footer()
		return
	_draw_winner_card()
	_draw_result_footer()


func _draw_winner_card() -> void:
	var world = h.world
	var winner: Dictionary = world.heroes[world.winner_slot]
	var equipment: Dictionary = winner["equipment"]
	var accent: Color = h.player_colors[world.winner_slot]
	var panel := Rect2(300.0, 124.0, 1000.0, 650.0)
	draw_pixel_panel(panel, accent, Color(0.010, 0.017, 0.027, 0.97))
	h.draw_rect(Rect2(panel.position + Vector2(14.0, 14.0), Vector2(310.0, panel.size.y - 28.0)), Color(accent, 0.10))
	draw_winner_god_rays(Vector2(465.0, 330.0), accent)
	h.draw_rect(Rect2(panel.position + Vector2(325.0, 14.0), Vector2(3.0, panel.size.y - 28.0)), Color(accent, 0.48))
	_draw_winner_copy(winner, equipment, accent)
	_draw_winner_standings(accent)


func _draw_winner_copy(winner: Dictionary, equipment: Dictionary, accent: Color) -> void:
	var world = h.world
	h._text(Vector2(650.0, 174.0), HudStrings.t("match_winner"), 18, Color("#ffd166"), 600.0, HORIZONTAL_ALIGNMENT_CENTER)
	h._text(Vector2(650.0, 232.0), "P%d  %s" % [world.winner_slot + 1, equipment["character_name"]], 43, Color.WHITE, 600.0, HORIZONTAL_ALIGNMENT_CENTER)
	h._text(Vector2(650.0, 270.0), "%s  ·  %s" % [equipment["name"], HudStrings.special(str(equipment.get("id", "")))], 17, Color(accent), 600.0, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_winner_animal(winner, accent)
	h._text(Vector2(350.0, 482.0), "P%d" % (world.winner_slot + 1), 17, Color(accent), 230.0, HORIZONTAL_ALIGNMENT_CENTER)
	h._text(Vector2(350.0, 516.0), str(equipment["role"]), 19, Color.WHITE, 230.0, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_winner_stat_chips(winner, accent)


func _draw_winner_animal(winner: Dictionary, accent: Color) -> void:
	if h.animal_texture == null:
		return
	var animal := int(winner.get("animal", h.world.winner_slot))
	var pulse := 1.0 + sin(float(h.world.tick) * 0.08) * 0.025
	h.draw_circle(Vector2(465.0, 330.0), 108.0, Color(accent, 0.10))
	h.draw_arc(Vector2(465.0, 330.0), 112.0, -0.25, TAU - 0.25, 40, Color(accent, 0.72), 4.0)
	h.draw_set_transform(Vector2(465.0, 330.0), 0.0, Vector2.ONE * pulse)
	h.draw_texture_rect_region(h.animal_texture, Rect2(-92.0, -92.0, 184.0, 184.0), animal_src_rect(animal))
	h.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_winner_stat_chips(winner: Dictionary, accent: Color) -> void:
	var world = h.world
	for stat in range(3):
		var chip := Rect2(650.0 + stat * 198.0, 302.0, 178.0, 64.0)
		h.draw_rect(chip, Color(0.035, 0.050, 0.072, 0.94))
		h.draw_rect(chip, Color(accent, 0.34), false, 2.0)
	h._text(Vector2(662.0, 340.0), HudStrings.t("stat_hp_pct") % roundi(world.decision_hp_ratio * 100.0), 20, Color("#6ef3a5"), 154.0, HORIZONTAL_ALIGNMENT_CENTER)
	h._text(Vector2(860.0, 340.0), HudStrings.t("stat_zone") % roundi(float(world.safe_zone_radius)), 20, Color("#c65cff"), 154.0, HORIZONTAL_ALIGNMENT_CENTER)
	h._text(Vector2(1058.0, 340.0), HudStrings.t("stat_score") % roundi(float(winner["score"])), 20, Color("#ffd166"), 154.0, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_winner_standings(_accent: Color) -> void:
	var world = h.world
	var standings: Array[Dictionary] = world.final_standings()
	h._text(Vector2(650.0, 410.0), HudStrings.t("match_standings"), 14, Color("#aebaca"))
	for rank in range(mini(3, standings.size())):
		_draw_standing_row(standings[rank], rank)


func _draw_result_footer() -> void:
	if bool(h.world.get("is_net")):
		_draw_return_banner()
		return
	if not h.touch_hints:
		h._text(Vector2(650.0, 724.0), HudStrings.t("result_rematch"), 16, Color("#dbe5f0"), 600.0, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_return_banner() -> void:
	if h._result_hold_at_ms < 0:
		h._result_hold_at_ms = Time.get_ticks_msec()
	var hold := 10.0
	var elapsed := float(Time.get_ticks_msec() - h._result_hold_at_ms) / 1000.0
	var left := maxi(0, ceili(hold - elapsed))
	var ratio := clampf(elapsed / hold, 0.0, 1.0)
	var bar := Rect2(0.0, 788.0, 1600.0, 112.0)
	h.draw_rect(bar, Color(0.04, 0.07, 0.11, 0.96))
	h.draw_rect(Rect2(bar.position, Vector2(1600.0, 6.0)), Color("#ffd166", 0.35))
	h.draw_rect(Rect2(bar.position, Vector2(1600.0 * ratio, 6.0)), Color("#ffd166"))
	var label := HudStrings.t("result_returning") if left <= 0 else HudStrings.t("result_countdown") % left
	h._text(Vector2(0.0, 858.0), label, 28, Color.WHITE, 1600.0, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_standing_row(row: Dictionary, rank: int) -> void:
	var slot := int(row["slot"])
	var row_equipment: Dictionary = h.world.heroes[slot]["equipment"]
	var card := Rect2(650.0, 430.0 + rank * 66.0, 600.0, 52.0)
	h.draw_rect(card, Color(h.player_colors[slot], 0.24 if rank == 0 else 0.11))
	h.draw_rect(Rect2(card.position, Vector2(6.0, card.size.y)), h.player_colors[slot])
	h._text(card.position + Vector2(20.0, 32.0), "%d" % (rank + 1), 21, Color("#ffd166") if rank == 0 else Color.WHITE, 34.0, HORIZONTAL_ALIGNMENT_CENTER)
	h._text(card.position + Vector2(66.0, 31.0), "P%d  %s / %s" % [slot + 1, row_equipment["character_name"], row_equipment["name"]], 15, Color.WHITE, 310.0)
	h._text(card.position + Vector2(390.0, 31.0), HudStrings.t("stat_hp_pct") % roundi(float(row["hp_ratio"]) * 100.0), 14, Color("#6ef3a5"), 88.0)
	h._text(card.position + Vector2(490.0, 31.0), "%d" % roundi(float(row["score"])), 15, Color("#ffd166"), 92.0, HORIZONTAL_ALIGNMENT_RIGHT)
