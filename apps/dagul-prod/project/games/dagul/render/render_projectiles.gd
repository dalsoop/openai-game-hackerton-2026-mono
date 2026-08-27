class_name RenderProjectiles
extends RefCounted

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer

func draw_deployables() -> void:
	var max_deploy := 4 if r.lite_draw else 999
	var deploy_drawn := 0
	for mine in world.deployables:
		if r.lite_draw and deploy_drawn >= max_deploy:
			break
		deploy_drawn += 1
		var mine_pos: Vector2 = mine["pos"]
		var mine_owner := int(mine["owner"])
		var mine_color: Color = r._slot_color(mine_owner)
		if StringName(mine.get("type", &"mine")) == &"wall":
			_draw_wall(mine, mine_pos, mine_owner, mine_color)
			continue
		_draw_mine(mine, mine_pos, mine_owner, mine_color)

func _draw_wall(mine: Dictionary, mine_pos: Vector2, mine_owner: int, mine_color: Color) -> void:
	var wall_dir := Vector2(mine["direction"]).normalized()
	var wall_normal := Vector2(mine.get("travel_direction", wall_dir.orthogonal())).normalized()
	var wall_a := mine_pos - wall_dir * float(mine["half_length"])
	var wall_b := mine_pos + wall_dir * float(mine["half_length"])
	var life_ratio := clampf(float(mine["lifetime"]) / maxf(0.01, float(mine["max_lifetime"])), 0.0, 1.0)
	var arming := float(mine.get("arm_time", 0.0)) > 0.0
	var pulse := 0.72 + sin(float(world.tick) * 0.18) * 0.12
	r.draw_colored_polygon(PackedVector2Array([
		wall_a - wall_normal * 55.0, wall_b - wall_normal * 55.0,
		wall_b - wall_normal * 12.0, wall_a - wall_normal * 12.0
	]), Color(0.16, 0.69, 0.88, 0.08 if not arming else 0.16))
	r.draw_line(wall_a - wall_normal * 44.0, wall_b - wall_normal * 44.0, Color("#63d8ff", 0.18), 5.0)
	r.draw_line(wall_a, wall_b, Color("#102b3e", 0.82), 27.0)
	r.draw_line(wall_a, wall_b, Color("#8de1ff", pulse), 11.0)
	for wall_segment in range(7):
		var segment_pos := wall_a.lerp(wall_b, float(wall_segment) / 6.0)
		r.draw_line(segment_pos - wall_normal * 17.0, segment_pos + wall_normal * 17.0, Color.WHITE, 3.0)
		r.draw_colored_polygon(PackedVector2Array([segment_pos + wall_normal * 13.0, segment_pos + wall_dir * 7.0, segment_pos - wall_normal * 13.0, segment_pos - wall_dir * 7.0]), Color(mine_color, 0.72))
	var arrow_center := mine_pos + wall_normal * 48.0
	r.draw_colored_polygon(PackedVector2Array([
		arrow_center + wall_normal * 20.0,
		arrow_center - wall_normal * 12.0 + wall_dir * 13.0,
		arrow_center - wall_normal * 5.0,
		arrow_center - wall_normal * 12.0 - wall_dir * 13.0
	]), Color("#dff8ff", 0.55 if arming else 0.95))
	r.draw_rect(Rect2(mine_pos + Vector2(-54.0, -36.0), Vector2(108.0, 20.0)), Color(0.02, 0.06, 0.09, 0.82))
	var wall_text := "P%d LAUNCH" % (mine_owner + 1) if arming else "P%d RAM %.1f" % [mine_owner + 1, float(mine["lifetime"])]
	r.draw_string(GameFont.get_font(), mine_pos + Vector2(-50.0, -21.0), wall_text, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 11, Color("#dff8ff", 1.0 if arming else life_ratio))

func _draw_mine(mine: Dictionary, mine_pos: Vector2, mine_owner: int, mine_color: Color) -> void:
	var armed := float(mine["arm_time"]) <= 0.0
	var triggered := bool(mine["triggered"])
	var trigger_radius := float(mine["trigger_radius"])
	if armed:
		for sensor_arc in range(8):
			var sensor_start := TAU * float(sensor_arc) / 8.0 + 0.08
			r.draw_arc(mine_pos, trigger_radius, sensor_start, sensor_start + 0.48, 8, Color("#ff765f", 0.48 if not triggered else 0.88), 3.0)
	else:
		var arm_ratio := 1.0 - clampf(float(mine["arm_time"]) / maxf(0.01, float(mine["arm_duration"])), 0.0, 1.0)
		r.draw_arc(mine_pos, 31.0, -PI * 0.5, -PI * 0.5 + TAU * arm_ratio, 24, Color("#ffd166"), 5.0)
	if triggered:
		var fuse_ratio := clampf(float(mine["fuse_time"]) / maxf(0.01, float(mine["fuse_duration"])), 0.0, 1.0)
		r.draw_circle(mine_pos, float(mine["blast_radius"]), Color(0.42, 0.03, 0.02, 0.08 + (1.0 - fuse_ratio) * 0.12))
		r.draw_arc(mine_pos, float(mine["blast_radius"]) * lerpf(0.34, 1.0, fuse_ratio), 0.0, TAU, 42, Color("#ff554a"), 5.0)
		r.draw_string(GameFont.get_font(), mine_pos + Vector2(-42.0, -39.0), "MOVE! %.1f" % float(mine["fuse_time"]), HORIZONTAL_ALIGNMENT_CENTER, 84.0, 13, Color.WHITE)
	r.draw_circle(mine_pos, 19.0, Color("#241014"))
	r.draw_colored_polygon(PackedVector2Array([mine_pos + Vector2(0.0, -18.0), mine_pos + Vector2(18.0, 0.0), mine_pos + Vector2(0.0, 18.0), mine_pos + Vector2(-18.0, 0.0)]), Color("#ff554a") if armed else Color("#8ca0b8"))
	r.draw_circle(mine_pos, 7.0 + (sin(float(world.tick) * 0.28) * 2.0 if armed else 0.0), Color.WHITE if triggered else mine_color)
	r.draw_string(GameFont.get_font(), mine_pos + Vector2(-30.0, 34.0), "P%d MINE" % (mine_owner + 1), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color.WHITE)

func draw_impact_flashes() -> void:
	if r.impact_atlas == null:
		return
	for flash in r.impact_flashes:
		var row := int(flash.get("row", 1))
		var counts := [2, 3, 4]
		var n: int = int(counts[clampi(row, 0, 2)])
		if float(flash.get("time", 0.0)) < 0.0:
			continue
		var col := clampi(int(float(flash.get("time", 0.0)) / 0.055), 0, n - 1)
		var pos: Vector2 = flash["pos"]
		r.draw_texture_rect_region(r.impact_atlas, Rect2(pos - Vector2(42.0, 42.0), Vector2(84.0, 84.0)), r._impact_src_rect(row, col), Color.WHITE)

func draw_combat_texts() -> void:
	for item in r.combat_texts:
		var fade := 1.0 - clampf(float(item["time"]) / 0.85, 0.0, 1.0)
		var pos: Vector2 = item["pos"]
		var text := str(item.get("text", ""))
		var col: Color = item.get("color", Color.WHITE)
		r.draw_string(GameFont.get_font(), pos + Vector2(-31.0, 1.0), text, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 18, Color(0.0, 0.0, 0.0, 0.75 * fade))
		r.draw_string(GameFont.get_font(), pos + Vector2(-32.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 18, Color(col, fade))

func draw_projectiles_main() -> void:
	for projectile in world.projectiles:
		var source := StringName(projectile["source"])
		var projectile_color: Color = Color.WHITE if source == &"ultimate" else r._projectile_color(projectile)
		var projectile_pos: Vector2 = projectile["pos"]
		var direction := Vector2(projectile["vel"]).normalized()
		var kind := str(projectile.get("kind", "bolt"))
		if bool(projectile.get("arc", false)):
			_draw_arc_projectile(projectile, projectile_pos, direction, projectile_color)
			continue
		if kind in ["shell", "seeker", "bomb"]:
			r._draw_dashed_tracer(projectile_pos, direction, r.BULLET_YELLOW, 4.0)
		if r._draw_projectile_texture(projectile_pos, direction, kind):
			continue
		if kind in ["beam", "shell", "tether", "seeker", "slash", "fist"]:
			_draw_projectile_energy(kind, projectile_pos, direction, projectile_color)
		else:
			_draw_projectile_ordnance(projectile, kind, projectile_pos, direction, projectile_color)

func _draw_arc_projectile(projectile: Dictionary, projectile_pos: Vector2, direction: Vector2, projectile_color: Color) -> void:
	r._draw_motion_trail(projectile.get("trail", []), projectile_color, 5.0)
	var arc_progress := clampf(1.0 - float(projectile["ttl"]) / maxf(0.01, float(projectile["max_ttl"])), 0.0, 1.0)
	var bomb_scale := 0.72 + sin(arc_progress * PI) * 0.95
	var landing: Vector2 = projectile["landing_pos"]
	r.draw_circle(projectile_pos + Vector2(7.0, 9.0), 13.0 * bomb_scale, Color(0.0, 0.0, 0.0, 0.23))
	if not r._draw_projectile_texture(projectile_pos, direction, "bomb", bomb_scale):
		r.draw_circle(projectile_pos, 11.0 * bomb_scale, Color("#2c1115"))
		r.draw_arc(projectile_pos, 13.0 * bomb_scale, 0.0, TAU, 22, Color("#ff6b4a"), 4.0)
	r.draw_circle(landing, float(projectile["splash"]), Color(0.35, 0.04, 0.03, 0.07))
	r.draw_arc(landing, float(projectile["splash"]) * lerpf(1.0, 0.78, arc_progress), 0.0, TAU, 36, Color(1.0, 0.34, 0.22, 0.68), 3.0)

func _draw_projectile_energy(kind: String, projectile_pos: Vector2, direction: Vector2, projectile_color: Color) -> void:
	match kind:
		"beam":
			r.draw_line(projectile_pos - direction * 125.0, projectile_pos + direction * 18.0, Color(projectile_color, 0.28), 18.0)
			r.draw_line(projectile_pos - direction * 145.0, projectile_pos + direction * 22.0, Color.WHITE, 3.5)
			r.draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 18.0, projectile_pos + direction.orthogonal() * 7.0, projectile_pos - direction * 16.0, projectile_pos - direction.orthogonal() * 7.0]), projectile_color)
		"shell":
			r._draw_dashed_tracer(projectile_pos, direction, r.BULLET_YELLOW, 5.0)
			r.draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 15.0, projectile_pos + direction.orthogonal() * 10.0, projectile_pos - direction * 11.0, projectile_pos - direction.orthogonal() * 10.0]), Color("#ff503f"))
			r.draw_line(projectile_pos - direction * 34.0, projectile_pos - direction * 8.0, Color("#ffcf66"), 8.0)
		"tether":
			_draw_tether_segments(projectile_pos, direction, projectile_color)
		"seeker":
			r._draw_dashed_tracer(projectile_pos, direction, r.BULLET_YELLOW, 4.0)
			_draw_seeker_star(projectile_pos, projectile_color)
		"slash":
			var slash_angle := direction.angle()
			r.draw_arc(projectile_pos - direction * 8.0, 31.0, slash_angle - 1.05, slash_angle + 1.05, 18, Color("#b9f3ff"), 10.0)
			r.draw_arc(projectile_pos - direction * 8.0, 25.0, slash_angle - 0.95, slash_angle + 0.95, 16, Color.WHITE, 3.0)
		"fist":
			r.draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 18.0, projectile_pos + direction.orthogonal() * 13.0, projectile_pos - direction * 13.0 + direction.orthogonal() * 9.0, projectile_pos - direction * 13.0 - direction.orthogonal() * 9.0]), Color("#ff9466"))
			r.draw_line(projectile_pos - direction * 38.0, projectile_pos - direction * 8.0, Color("#ffd0ac"), 9.0)

func _draw_tether_segments(projectile_pos: Vector2, direction: Vector2, projectile_color: Color) -> void:
	for segment in range(3):
		var center := projectile_pos - direction * float(segment * 13)
		r.draw_line(center - direction.orthogonal() * 7.0, center + direction.orthogonal() * 7.0, projectile_color, 4.0)

func _draw_seeker_star(projectile_pos: Vector2, projectile_color: Color) -> void:
	var star := PackedVector2Array()
	for point in range(8):
		star.append(projectile_pos + Vector2.RIGHT.rotated(TAU * float(point) / 8.0) * (12.0 if point % 2 == 0 else 5.0))
	r.draw_colored_polygon(star, projectile_color)

func _draw_projectile_ordnance(projectile: Dictionary, kind: String, projectile_pos: Vector2, direction: Vector2, projectile_color: Color) -> void:
	match kind:
		"bomb":
			r._draw_dashed_tracer(projectile_pos, direction, r.BULLET_YELLOW, 4.0)
			r.draw_circle(projectile_pos, 13.0, Color("#2c1115"))
			r.draw_arc(projectile_pos, 14.0, 0.0, TAU, 22, Color("#ff554a"), 5.0)
			r.draw_line(projectile_pos - direction.orthogonal() * 12.0, projectile_pos - direction.orthogonal() * 23.0 - direction * 7.0, Color("#ffe36a"), 4.0)
		"spear":
			r.draw_line(projectile_pos - direction * 66.0, projectile_pos + direction * 24.0, Color("#d0a447"), 7.0)
			r.draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 36.0, projectile_pos + direction * 17.0 + direction.orthogonal() * 10.0, projectile_pos + direction * 17.0 - direction.orthogonal() * 10.0]), Color("#fff1a8"))
		"chain":
			r.draw_arc(projectile_pos, 14.0, -direction.angle() - PI * 0.6, -direction.angle() + PI * 0.7, 14, Color("#e2c8ff"), 6.0)
		"shield":
			var shield_side := direction.orthogonal()
			r.draw_colored_polygon(PackedVector2Array([projectile_pos - shield_side * 18.0 - direction * 8.0, projectile_pos + shield_side * 18.0 - direction * 8.0, projectile_pos + shield_side * 14.0 + direction * 17.0, projectile_pos + direction * 26.0, projectile_pos - shield_side * 14.0 + direction * 17.0]), Color("#8de1ff"))
		"tracer":
			_draw_tracer_fallback(projectile, projectile_pos, direction)
		"pellet", "burst", "bolt":
			r._draw_lhj_bullet(projectile_pos, direction, kind, 2.5 if bool(projectile.get("heavy", false)) else 1.0)
		_:
			_draw_ordnance_default(kind, projectile_pos, direction)

func _draw_ordnance_default(kind: String, projectile_pos: Vector2, direction: Vector2) -> void:
	if r.bullet_atlas != null and kind not in ["beam", "slash", "fist", "spear", "chain", "shield", "tether", "bomb"]:
		r._draw_dashed_tracer(projectile_pos, direction, r.BULLET_YELLOW, 3.0)
		r._draw_lhj_bullet(projectile_pos, direction, kind)
	else:
		r._draw_dashed_tracer(projectile_pos, direction, r.BULLET_YELLOW, 5.0)
		r.draw_circle(projectile_pos + direction * 6.0, 7.0, Color(r.BULLET_YELLOW, 0.35))
		r.draw_circle(projectile_pos + direction * 6.0, 4.5, r.BULLET_YELLOW)
		r.draw_circle(projectile_pos + direction * 8.0, 2.2, Color.WHITE)

func _draw_tracer_fallback(projectile: Dictionary, projectile_pos: Vector2, direction: Vector2) -> void:
	var origin: Vector2 = projectile_pos
	var trail: Array = projectile.get("trail", [])
	if trail.size() > 0:
		origin = trail[0]
	var tracer_end := projectile_pos + direction * 28.0
	if r.tracer_fx_atlas != null:
		var tracer_length := clampf(origin.distance_to(tracer_end), 96.0, 240.0)
		var tracer_center := origin.lerp(tracer_end, 0.5)
		var tracer_frame := posmod(int(world.tick / 2), 4)
		r.draw_set_transform(tracer_center, direction.angle(), Vector2.ONE)
		r.draw_texture_rect_region(r.tracer_fx_atlas, Rect2(Vector2(-tracer_length * 0.5, -28.0), Vector2(tracer_length, 56.0)),r._horizontal_fx_src_rect(r.tracer_fx_atlas, 4, tracer_frame))
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		r.draw_line(origin, tracer_end, Color(1.0, 1.0, 1.0, 0.22), 10.0)
		r.draw_line(origin, tracer_end, Color(1.0, 0.95, 0.75, 0.95), 3.0)

func draw_zones_main() -> void:
	var max_zones := 4 if r.lite_draw else 999
	var zone_drawn := 0
	for zone in world.zones:
		if r.lite_draw and zone_drawn >= max_zones:
			break
		zone_drawn += 1
		var zone_color: Color = zone.get("color",r._slot_color(int(zone["owner"])))
		var delay := float(zone.get("delay", 0.0))
		var warning_duration := maxf(0.01, float(zone.get("warning_duration", delay)))
		var warning_ratio := clampf(delay / warning_duration, 0.0, 1.0)
		var impact_progress := 1.0 - warning_ratio
		var warning_alpha := 0.08 + impact_progress * 0.18 + 0.04 * sin(float(world.tick) * 0.32)
		var zone_pos: Vector2 = zone["pos"]
		var zone_radius := float(zone["radius"])
		var zone_kind := StringName(zone.get("effect_kind", &"explosion"))
		if delay <= 0.06:
			continue
		r.draw_circle(zone_pos, zone_radius, Color("#15090b", warning_alpha * 1.35) if zone_kind == &"explosion" else Color(zone_color, warning_alpha * 0.72))
		r.draw_arc(zone_pos, zone_radius, 0.0, TAU, 42, Color(zone_color, 0.78), 4.0)
		_draw_zone_kind(zone_kind, zone_pos, zone_radius, zone_color)
		if delay > 0.0:
			_draw_zone_timer(zone, zone_pos, zone_radius, zone_color, delay, warning_ratio, impact_progress)

func _draw_zone_kind(zone_kind: StringName, zone_pos: Vector2, zone_radius: float, zone_color: Color) -> void:
	if zone_kind == &"rail_strike":
		r.draw_line(zone_pos - Vector2(zone_radius * 1.6, 0.0), zone_pos + Vector2(zone_radius * 1.6, 0.0), Color(zone_color, 0.75), 5.0)
		r.draw_line(zone_pos - Vector2(0.0, zone_radius * 1.6), zone_pos + Vector2(0.0, zone_radius * 1.6), Color.WHITE, 2.0)
	elif zone_kind == &"drain":
		for ring in range(3):
			r.draw_arc(zone_pos, zone_radius * (0.35 + ring * 0.23), float(world.tick) * 0.05 + ring, float(world.tick) * 0.05 + ring + PI * 1.35, 24, Color(zone_color, 0.72), 4.0)
	elif zone_kind == &"shockwave":
		for spoke in range(8):
			var radial := Vector2.RIGHT.rotated(TAU * float(spoke) / 8.0)
			r.draw_line(zone_pos + radial * zone_radius * 0.45, zone_pos + radial * zone_radius, Color(zone_color, 0.75), 4.0)
	elif zone_kind == &"slashwave":
		for slash in range(3):
			var slash_angle := float(world.tick) * 0.08 + slash * PI / 3.0
			r.draw_arc(zone_pos, zone_radius * (0.55 + slash * 0.16), slash_angle, slash_angle + PI * 0.85, 18, Color(zone_color, 0.82), 6.0)
	elif zone_kind == &"fist_burst":
		for fist_ray in range(6):
			var fist_dir := Vector2.RIGHT.rotated(TAU * float(fist_ray) / 6.0)
			r.draw_line(zone_pos + fist_dir * 18.0, zone_pos + fist_dir * zone_radius, Color(zone_color, 0.82), 10.0)
	elif zone_kind == &"chain_vortex":
		for ring in range(3):
			r.draw_arc(zone_pos, zone_radius * (0.42 + ring * 0.22), float(world.tick) * -0.08 + ring, float(world.tick) * -0.08 + ring + PI * 1.55, 28, Color(zone_color, 0.86), 7.0)
	elif zone_kind == &"shield_bash":
		r.draw_arc(zone_pos, zone_radius * 0.82, -PI * 0.75, PI * 0.75, 28, Color(zone_color, 0.92), 15.0)
		r.draw_line(zone_pos - Vector2(0.0, zone_radius * 0.8), zone_pos + Vector2(0.0, zone_radius * 0.8), Color.WHITE, 4.0)

func _draw_zone_timer(zone: Dictionary, zone_pos: Vector2, zone_radius: float, zone_color: Color, delay: float, warning_ratio: float, impact_progress: float) -> void:
	var timer_radius := float(zone["radius"]) * lerpf(0.28, 1.0, warning_ratio)
	r.draw_arc(zone_pos, timer_radius, 0.0, TAU, 36, Color.WHITE, 3.0 + impact_progress * 2.0)
	for warning_tick in range(8):
		var tick_dir := Vector2.RIGHT.rotated(TAU * float(warning_tick) / 8.0)
		r.draw_line(zone_pos + tick_dir * (zone_radius + 5.0), zone_pos + tick_dir * (zone_radius + 13.0), Color(zone_color, 0.82), 3.0)
	var warning_label := str(zone.get("label", ""))
	if not warning_label.is_empty() and zone_radius >= 90.0:
		r.draw_rect(Rect2(zone_pos + Vector2(-72.0, -13.0), Vector2(144.0, 25.0)), Color(0.04, 0.02, 0.03, 0.76))
		r.draw_string(GameFont.get_font(), zone_pos + Vector2(-68.0, 6.0), "%s  %.1f" % [warning_label, delay], HORIZONTAL_ALIGNMENT_CENTER, 136.0, 13, Color.WHITE)

func draw_effects_main() -> void:
	var max_effects := 8 if r.lite_draw else 999
	var drawn := 0
	for effect in world.effects:
		var effect_kind := StringName(effect["kind"])
		if effect_kind == &"zone_impact":
			continue
		if r.lite_draw and drawn >= max_effects:
			break
		drawn += 1
		var effect_color: Color = effect["color"]
		var ratio := clampf(float(effect["time"]) / float(effect["max_time"]), 0.0, 1.0)
		var effect_pos: Vector2 = effect["pos"]
		var effect_radius := float(effect["radius"])
		var direction := Vector2(effect["direction"]).normalized()
		var progress := 1.0 - ratio
		var mobility_texture = _mobility_texture(effect, effect_kind, effect_label(effect))
		if mobility_texture != null:
			_draw_mobility_effect(effect, effect_color, ratio, progress, effect_pos, effect_radius, effect_kind, direction, mobility_texture)
			continue
		_draw_effect_kind(effect, effect_color, ratio, progress, effect_pos, effect_radius, effect_kind, direction)
		var label := str(effect["label"])
		if label != "" and effect_kind in [&"heal_pickup", &"respawn"]:
			r.draw_string(GameFont.get_font(), effect_pos + Vector2(-100.0, -effect_radius - 10.0), label, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 16, Color(effect_color, ratio))

func effect_label(effect: Dictionary) -> String:
	return str(effect.get("label", ""))

func _mobility_texture(effect: Dictionary, effect_kind: StringName, effect_label_str: String):
	var mobility_texture = r._mobility_fx_texture(effect_kind, effect_label_str)
	if effect_label_str == "SIGHTLINE STEP" and effect_kind == &"beam_step" and r.rooster_beam_step_atlas != null:
		mobility_texture = r.rooster_beam_step_atlas
	return mobility_texture

func _draw_mobility_effect(effect: Dictionary, effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, effect_kind: StringName, direction: Vector2, mobility_texture) -> void:
	var effect_label_str := effect_label(effect)
	var mobility_frame := clampi(int(progress * 4.0), 0, 3)
	var mobility_alpha := clampf(ratio * 1.20 + 0.18, 0.18, 1.0)
	var directional := effect_kind in [&"speed_streak", &"beam_step", &"slash_dash", &"spear_line", &"chain_arc", &"blast_hop"]
	var mobility_size := Vector2(effect_radius * 1.25, clampf(effect_radius * 0.62, 72.0, 168.0)) if directional else Vector2.ONE * effect_radius * 2.15
	if effect_label_str in ["IRON MARCH", "BRACE STEP"]:
		mobility_size *= 1.35
	var start_pos: Vector2 = effect.get("start_pos", effect_pos)
	if r.dash_departure_atlas != null and bool(effect.get("draw_departure", true)):
		var departure_size := Vector2.ONE * clampf(effect_radius * 0.55, 84.0, 138.0)
		r.draw_set_transform(start_pos, 0.0, Vector2.ONE)
		r.draw_texture_rect_region(r.dash_departure_atlas, Rect2(-departure_size * 0.5, departure_size),r._horizontal_fx_src_rect(r.dash_departure_atlas, 4, mobility_frame), Color(effect_color, mobility_alpha))
		r.draw_texture_rect_region(r.dash_departure_atlas, Rect2(-departure_size * 0.5, departure_size),r._horizontal_fx_src_rect(r.dash_departure_atlas, 4, mobility_frame), Color(effect_color, mobility_alpha * 0.65))
	effect_pos = _followed_hero_pos(int(effect.get("follow_slot", -1)), effect_pos)
	if effect_label_str == "SIGHTLINE STEP":
		effect_pos += direction * 58.0
	var mobility_angle := direction.angle() + (PI if effect_label_str == "SHADOW SHEATH" else 0.0)
	r.draw_set_transform(effect_pos, mobility_angle, Vector2.ONE)
	r.draw_texture_rect_region(mobility_texture, Rect2(-mobility_size * 0.5, mobility_size),r._horizontal_fx_src_rect(mobility_texture, 4, mobility_frame), Color(1.0, 1.0, 1.0, mobility_alpha))
	r.draw_texture_rect_region(mobility_texture, Rect2(-mobility_size * 0.5, mobility_size),r._horizontal_fx_src_rect(mobility_texture, 4, mobility_frame), Color(1.0, 1.0, 1.0, mobility_alpha * 0.65))
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _followed_hero_pos(follow_slot: int, fallback: Vector2) -> Vector2:
	if follow_slot < 0:
		return fallback
	if world.has_method("hero_at_slot"):
		var followed: Dictionary = world.hero_at_slot(follow_slot)
		if not followed.is_empty():
			return Vector2(followed.get("pos", fallback))
		return fallback
	for hero in world.heroes:
		if int(hero.get("slot", -1)) != follow_slot:
			continue
		return Vector2(hero.get("pos", fallback))
	return fallback

func effect_family(effect_kind: StringName) -> StringName:
	if effect_kind in [&"line", &"beam_hit", &"beam_step", &"local_tracer", &"explosion", &"drain", &"shockwave", &"cast"]:
		return &"beam"
	if effect_kind in [&"wall_impact", &"hit_spark", &"impact", &"speed_streak", &"slashwave", &"slash_dash", &"fist_burst", &"hammer_slam", &"spear_line", &"chain_arc", &"chain_bind", &"blast_hop"]:
		return &"impact"
	if effect_kind in [&"fuse", &"shield_bash", &"combo_finisher", &"charge_release", &"victory", &"combo_break", &"afterimage", &"death_burst", &"guard", &"charge_break", &"stun_burst", &"snake_pop", &"sheep_pop", &"monkey_pop", &"rooster_burst"]:
		return &"burst"
	return &"pickup"

func _draw_effect_kind(effect: Dictionary, effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, effect_kind: StringName, direction: Vector2) -> void:
	match effect_family(effect_kind):
		&"beam":
			_draw_beam_family(effect_color, ratio, progress, effect_pos, effect_radius, effect_kind, direction)
		&"impact":
			_draw_impact_family(effect_color, ratio, progress, effect_pos, effect_radius, effect_kind, direction)
		&"burst":
			_draw_burst_family(effect_color, ratio, progress, effect_pos, effect_radius, effect_kind, direction)
		_:
			_draw_pickup_family(effect_color, ratio, progress, effect_pos, effect_radius, effect_kind, direction)

func _draw_beam_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, effect_kind: StringName, direction: Vector2) -> void:
	match effect_kind:
		&"line", &"beam_hit", &"beam_step", &"local_tracer":
			var line_start := effect_pos - direction * effect_radius * (0.75 if effect_kind == &"beam_hit" else 1.0)
			var line_end := effect_pos + direction * effect_radius * (0.65 if effect_kind == &"beam_hit" else 0.05)
			r.draw_line(line_start, line_end, Color(effect_color, ratio * 0.34), 26.0 * ratio + 5.0)
			r.draw_line(line_start, line_end, Color.WHITE, 4.0 * ratio + 1.5)
		&"cast":
			_draw_cast_beam(effect_color, ratio, effect_pos, effect_radius, direction)
		&"explosion":
			_draw_explosion_family(effect_color, ratio, progress, effect_pos, effect_radius)
		&"drain":
			_draw_drain_family(effect_color, ratio, progress, effect_pos, effect_radius)
		&"shockwave":
			_draw_shockwave_family(effect_color, ratio, progress, effect_pos, effect_radius)

func _draw_explosion_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	if r.explosion_fx_atlas != null:
		var explosion_frame := clampi(int(progress * 6.0), 0, 5)
		var explosion_size := Vector2.ONE * effect_radius * 2.35
		r.draw_texture_rect_region(r.explosion_fx_atlas, Rect2(effect_pos - explosion_size * 0.5, explosion_size),r._horizontal_fx_src_rect(r.explosion_fx_atlas, 6, explosion_frame))
	else:
		var blast_radius := effect_radius * lerpf(0.18, 1.28, progress)
		r.draw_circle(effect_pos, blast_radius * 0.72, Color("#3a0808", ratio * 0.72))
		r.draw_circle(effect_pos, blast_radius * 0.48, Color(effect_color, ratio * 0.86))
		r.draw_arc(effect_pos, blast_radius, 0.0, TAU, 52, Color.WHITE, ratio, 9.0 * ratio + 2.0)

func _draw_drain_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	for arc_index in range(4):
		var arc_radius := effect_radius * (0.28 + float(arc_index) * 0.18) * (0.65 + progress * 0.35)
		var arc_start := progress * TAU * (1.0 if arc_index % 2 == 0 else -1.0) + arc_index
		r.draw_arc(effect_pos, arc_radius, arc_start, arc_start + PI * 1.25, 22, Color(effect_color, ratio), 5.0)

func _draw_shockwave_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	var shock_radius := effect_radius * lerpf(0.25, 1.18, progress)
	r.draw_arc(effect_pos, shock_radius, 0.0, TAU, 32, Color(effect_color, ratio), 10.0 * ratio + 2.0)
	for spoke in range(10):
		var radial := Vector2.RIGHT.rotated(TAU * float(spoke) / 10.0)
		r.draw_line(effect_pos + radial * shock_radius * 0.48, effect_pos + radial * shock_radius, Color(Color.WHITE, ratio * 0.85), 3.0)

func _draw_impact_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, effect_kind: StringName, direction: Vector2) -> void:
	match effect_kind:
		&"wall_impact", &"hit_spark", &"impact":
			_draw_hit_spark(effect_color, ratio, progress, effect_pos, effect_radius, effect_kind, direction)
		&"speed_streak":
			_draw_speed_streak(effect_color, ratio, effect_pos, effect_radius, direction)
		&"slashwave", &"slash_dash":
			var slash_angle := direction.angle()
			var slash_radius := effect_radius * lerpf(0.72, 1.04, progress)
			r.draw_arc(effect_pos, slash_radius, slash_angle - 1.05, slash_angle + 1.05, 20, Color(effect_color, ratio), 8.0)
			r.draw_arc(effect_pos, slash_radius - 9.0, slash_angle - 0.86, slash_angle + 0.86, 16, Color(Color.WHITE, ratio * 0.72), 2.0)
		&"fist_burst":
			r.draw_line(effect_pos - direction * effect_radius * 0.38, effect_pos + direction * effect_radius * 0.52, Color(effect_color, ratio * 0.42), 18.0)
			r.draw_line(effect_pos - direction * 8.0, effect_pos + direction * effect_radius * 0.64, Color.WHITE, ratio, 6.0)
			r.draw_line(effect_pos - direction * 2.0, effect_pos + direction.rotated(0.26) * effect_radius * 0.48, Color(effect_color, ratio * 0.74), 5.0)
		&"hammer_slam":
			var hammer_side := direction.orthogonal()
			r.draw_line(effect_pos - direction * effect_radius * 0.56, effect_pos + direction * effect_radius * 0.16, Color(effect_color, ratio * 0.72), 20.0)
			r.draw_line(effect_pos - hammer_side * effect_radius * 0.42, effect_pos + hammer_side * effect_radius * 0.42, Color.WHITE, ratio, 7.0)
			r.draw_line(effect_pos, effect_pos + direction.rotated(0.55) * effect_radius * 0.56, Color(effect_color, ratio), 5.0)
			r.draw_line(effect_pos, effect_pos + direction.rotated(-0.55) * effect_radius * 0.56, Color(effect_color, ratio), 5.0)
		&"spear_line":
			r.draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius * 0.18, Color(effect_color, ratio * 0.34), 22.0)
			r.draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius * 0.22, Color.WHITE, ratio, 4.0)
			r.draw_colored_polygon(PackedVector2Array([effect_pos + direction * effect_radius * 0.28, effect_pos + direction * effect_radius * 0.08 + direction.orthogonal() * 14.0, effect_pos + direction * effect_radius * 0.08 - direction.orthogonal() * 14.0]), Color(effect_color, ratio))
		&"chain_arc":
			_draw_chain_arc(effect_color, ratio, progress, effect_pos, effect_radius, direction)
		&"chain_bind":
			_draw_chain_bind(effect_color, ratio, progress, effect_pos, effect_radius)
		&"blast_hop":
			_draw_blast_hop(effect_color, ratio, progress, effect_pos, effect_radius, direction)

func _draw_speed_streak(effect_color: Color, ratio: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	for streak in range(5):
		var side := direction.orthogonal() * (float(streak) - 2.0) * 9.0
		r.draw_line(effect_pos + side, effect_pos + side + direction * effect_radius, Color(effect_color, ratio * 0.8), 4.0)

func _draw_cast_beam(effect_color: Color, ratio: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	var line_start := effect_pos - direction * effect_radius * 0.12
	var line_end := effect_pos + direction * effect_radius
	r.draw_line(line_start, line_end, Color(effect_color, ratio * 0.34), 26.0 * ratio + 5.0)
	r.draw_line(line_start, line_end, Color.WHITE, 4.0 * ratio + 1.5)
	for fan in range(3):
		var fan_dir := direction.rotated((float(fan) - 1.0) * 0.18)
		r.draw_line(effect_pos, effect_pos + fan_dir * effect_radius * 0.72, Color(effect_color, ratio * 0.7), 4.0)

func _draw_blast_hop(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	_draw_speed_streak(effect_color, ratio, effect_pos, effect_radius, direction)
	var hop_radius := effect_radius * lerpf(0.22, 0.72, progress)
	r.draw_arc(effect_pos, hop_radius, 0.0, TAU, 24, Color(effect_color, ratio), 5.0)
	r.draw_line(effect_pos, effect_pos + direction * effect_radius * 0.85, Color(Color.WHITE, ratio * 0.8), 3.0)

func _draw_hit_spark(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, effect_kind: StringName, direction: Vector2) -> void:
	if effect_kind in [&"hit_spark", &"impact"] and r.hit_spark_fx_atlas != null:
		var hit_frame := clampi(int(progress * 4.0), 0, 3)
		var hit_size := Vector2.ONE * effect_radius * 2.1
		r.draw_set_transform(effect_pos, direction.angle(), Vector2.ONE)
		r.draw_texture_rect_region(r.hit_spark_fx_atlas, Rect2(-hit_size * 0.5, hit_size),r._horizontal_fx_src_rect(r.hit_spark_fx_atlas, 4, hit_frame))
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		for spark in range(9):
			var spark_dir := (-direction).rotated((float(spark) - 4.0) * 0.16)
			r.draw_line(effect_pos, effect_pos + spark_dir * effect_radius * (0.45 + float(spark % 3) * 0.22), Color(effect_color, ratio), 5.0 if effect_kind == &"wall_impact" else 3.0)

func _draw_chain_arc(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	for link in range(9):
		var link_angle := progress * PI * 1.4 + float(link) * 0.19
		var link_pos := effect_pos - direction * effect_radius * (float(link) / 9.0) + direction.orthogonal() * sin(link_angle) * 24.0
		r.draw_arc(link_pos, 7.0, 0.0, TAU, 10, Color(effect_color, ratio), 3.0)

func _draw_burst_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, effect_kind: StringName, direction: Vector2) -> void:
	match effect_kind:
		&"fuse":
			_draw_fuse_family(effect_color, ratio, progress, effect_pos, effect_radius)
		&"shield_bash":
			var shield_angle := direction.angle()
			r.draw_arc(effect_pos, effect_radius * lerpf(0.55, 1.15, progress), shield_angle - 1.15, shield_angle + 1.15, 30, Color(effect_color, ratio), 18.0)
			r.draw_line(effect_pos - direction.orthogonal() * effect_radius * 0.7, effect_pos + direction.orthogonal() * effect_radius * 0.7, Color.WHITE, ratio, 5.0)
		&"combo_finisher":
			_draw_combo_finisher(effect_color, ratio, effect_pos, effect_radius, direction)
		&"charge_release":
			r.draw_arc(effect_pos, effect_radius * (0.75 + progress * 0.18), direction.angle() - 0.65, direction.angle() + 0.65, 20, Color(effect_color, ratio), 5.0)
			r.draw_line(effect_pos - direction * effect_radius * 0.45, effect_pos + direction * effect_radius * 0.28, Color.WHITE, ratio * 0.8, 3.0)
		&"victory":
			_draw_victory_family(effect_color, ratio, progress, effect_pos, effect_radius)
		&"combo_break", &"afterimage":
			r.draw_arc(effect_pos, effect_radius * lerpf(0.45, 1.20, progress), 0.0, TAU, 34, Color(effect_color, ratio), 8.0)
			r.draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius, Color(effect_color, ratio * 0.72), 5.0)
		&"death_burst":
			_draw_death_burst(effect_color, ratio, progress, effect_pos, effect_radius)
		&"guard":
			r.draw_arc(effect_pos, effect_radius, -PI * 0.8, PI * 0.8, 28, Color(effect_color, ratio), 9.0)
			r.draw_arc(effect_pos, effect_radius - 12.0, -PI * 0.8, PI * 0.8, 28, Color(Color.WHITE, ratio * 0.8), 3.0)
		&"charge_break":
			_draw_charge_break(effect_color, ratio, progress, effect_pos, effect_radius)
		&"stun_burst":
			_draw_stun_burst(effect_color, ratio, progress, effect_pos, effect_radius)
		&"snake_pop":
			_draw_snake_pop(effect_color, ratio, progress, effect_pos, effect_radius, direction)
		&"sheep_pop":
			_draw_sheep_pop(effect_color, ratio, progress, effect_pos, effect_radius, direction)
		&"monkey_pop":
			_draw_monkey_pop(effect_color, ratio, progress, effect_pos, effect_radius, direction)
		&"rooster_burst":
			_draw_rooster_burst(effect_color, ratio, progress, effect_pos, effect_radius, direction)

func _draw_fuse_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	r.draw_line(effect_pos, effect_pos + Vector2.UP.rotated(progress * 2.0) * effect_radius * 0.7, Color("#ffe36a", ratio), 5.0)
	for spark in range(6):
		var spark_dir := Vector2.RIGHT.rotated(TAU * float(spark) / 6.0 + progress * 4.0)
		r.draw_line(effect_pos, effect_pos + spark_dir * effect_radius * 0.45, Color(effect_color, ratio), 4.0)

func _draw_combo_finisher(effect_color: Color, ratio: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	for ray in range(5):
		var ray_dir := (-direction).rotated((float(ray) - 2.0) * 0.13)
		r.draw_line(effect_pos - direction * 10.0, effect_pos + ray_dir * effect_radius * (0.62 + float(ray) * 0.08), Color("#fff2b2", ratio * 0.82), 7.0 - absf(float(ray) - 2.0))
	r.draw_line(effect_pos - direction.orthogonal() * 34.0, effect_pos + direction.orthogonal() * 34.0, Color.WHITE, ratio, 6.0)

func _draw_victory_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	for victory_ring in range(3):
		var ring_radius := effect_radius * (0.26 + float(victory_ring) * 0.19 + progress * 0.32)
		r.draw_arc(effect_pos, ring_radius, progress * TAU + victory_ring, progress * TAU + victory_ring + PI * 1.45, 42, Color(effect_color, ratio * (0.86 - victory_ring * 0.18)), 7.0 - victory_ring)
	for victory_ray in range(10):
		var ray_dir := Vector2.UP.rotated(TAU * float(victory_ray) / 10.0)
		var ray_start := effect_pos + ray_dir * effect_radius * 0.38
		r.draw_line(ray_start, ray_start + ray_dir * effect_radius * (0.22 + progress * 0.26), Color(Color.WHITE, ratio * 0.72), 5.0)

func _draw_death_burst(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	if r.death_burst_atlas != null:
		var death_frame := clampi(int(progress * 6.0), 0, 5)
		var death_size := effect_radius * lerpf(0.72, 2.05, progress)
		var death_rect := Rect2(effect_pos - Vector2.ONE * death_size * 0.5, Vector2.ONE * death_size)
		r.draw_texture_rect_region(r.death_burst_atlas, death_rect,r._horizontal_fx_src_rect(r.death_burst_atlas, 6, death_frame), Color(1.0, 1.0, 1.0, ratio))
	else:
		var death_radius := effect_radius * lerpf(0.16, 1.10, progress)
		r.draw_circle(effect_pos, death_radius * 0.52, Color("#48030b", ratio * 0.82))
		r.draw_arc(effect_pos, death_radius, 0.0, TAU, 54, Color("#ff3349", ratio), 16.0)
		r.draw_line(effect_pos - Vector2.ONE * death_radius * 0.72, effect_pos + Vector2.ONE * death_radius * 0.72, Color.WHITE, ratio, 12.0)
		r.draw_line(effect_pos + Vector2(-1.0, 1.0) * death_radius * 0.72, effect_pos + Vector2(1.0, -1.0) * death_radius * 0.72, Color.WHITE, ratio, 12.0)

func _draw_pickup_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, effect_kind: StringName, _direction: Vector2) -> void:
	match effect_kind:
		&"heal_pickup":
			var heal_lift := progress * effect_radius * 0.55
			r.draw_line(effect_pos + Vector2(-12.0, -heal_lift), effect_pos + Vector2(12.0, -heal_lift), Color(effect_color, ratio), 7.0)
			r.draw_line(effect_pos + Vector2(0.0, -12.0 - heal_lift), effect_pos + Vector2(0.0, 12.0 - heal_lift), Color(effect_color, ratio), 7.0)
		&"heal_ready":
			r.draw_arc(effect_pos, effect_radius * lerpf(0.52, 0.92, progress), -PI * 0.35, PI * 0.35, 18, Color(effect_color, ratio), 5.0)
			r.draw_arc(effect_pos, effect_radius * lerpf(0.52, 0.92, progress), PI * 0.65, PI * 1.35, 18, Color(effect_color, ratio), 5.0)
		&"respawn":
			_draw_respawn_family(effect_color, ratio, progress, effect_pos, effect_radius)
		&"mine_place":
			_draw_mine_place(effect_color, ratio, progress, effect_pos, effect_radius)
		&"mine_fizzle":
			_draw_mine_fizzle(effect_color, ratio, progress, effect_pos, effect_radius)
		_:
			var flash_radius := maxf(5.0, effect_radius * lerpf(0.12, 0.28, progress))
			r.draw_circle(effect_pos, flash_radius, Color(effect_color, ratio * 0.46))
			r.draw_line(effect_pos - Vector2(flash_radius * 1.8, 0.0), effect_pos + Vector2(flash_radius * 1.8, 0.0), Color(Color.WHITE, ratio * 0.7), 2.0)

func _draw_respawn_family(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	for beam in range(3):
		var beam_x := (float(beam) - 1.0) * 16.0
		r.draw_line(effect_pos + Vector2(beam_x, effect_radius * 0.48), effect_pos + Vector2(beam_x, -effect_radius * (0.35 + progress * 0.48)), Color(effect_color, ratio * (0.55 + float(beam) * 0.18)), 5.0)

func _draw_mine_place(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	r.draw_arc(effect_pos, effect_radius * lerpf(1.0, 0.35, progress), 0.0, TAU, 28, Color(effect_color, ratio), 7.0)
	for bolt in range(4):
		var bolt_dir := Vector2.RIGHT.rotated(TAU * float(bolt) / 4.0)
		r.draw_line(effect_pos + bolt_dir * 12.0, effect_pos + bolt_dir * effect_radius, Color.WHITE, ratio, 3.0)

func _draw_mine_fizzle(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	for smoke in range(5):
		var smoke_dir := Vector2.UP.rotated((float(smoke) - 2.0) * 0.28)
		r.draw_circle(effect_pos + smoke_dir * effect_radius * progress, 7.0 + smoke * 1.5, Color(effect_color, ratio * 0.32))

func _try_ultimate_pop(animal: int, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> bool:
	var frame := clampi(int(progress * 4.0), 0, 3)
	var size := Vector2.ONE * effect_radius * 2.35
	var alpha := clampf(ratio * 1.25, 0.0, 1.0)
	return r.draw_ultimate_frame(animal, effect_pos, size, frame, 1, direction.angle(), alpha)

func _draw_chain_bind(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	var bind_r := effect_radius * lerpf(0.55, 0.95, progress)
	r.draw_arc(effect_pos, bind_r, progress * 1.2, progress * 1.2 + PI * 1.55, 22, Color(effect_color, ratio), 6.0)
	r.draw_arc(effect_pos, bind_r * 0.72, -progress * 1.4, -progress * 1.4 + PI * 1.4, 18, Color(Color.WHITE, ratio * 0.8), 3.0)
	for link in range(6):
		var link_dir := Vector2.RIGHT.rotated(TAU * float(link) / 6.0 + progress)
		r.draw_arc(effect_pos + link_dir * bind_r, 6.0, 0.0, TAU, 10, Color(effect_color, ratio), 3.0)

func _draw_charge_break(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	var break_r := effect_radius * lerpf(0.35, 1.08, progress)
	for shard in range(8):
		var shard_dir := Vector2.RIGHT.rotated(TAU * float(shard) / 8.0 + progress * 0.4)
		var start_ang := TAU * float(shard) / 8.0 + 0.28
		r.draw_arc(effect_pos, break_r, start_ang, start_ang + 0.42, 8, Color(effect_color, ratio), 5.0)
		r.draw_line(effect_pos + shard_dir * break_r * 0.55, effect_pos + shard_dir * break_r, Color(Color.WHITE, ratio * 0.85), 3.0)

func _draw_stun_burst(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float) -> void:
	var stun_r := effect_radius * lerpf(0.28, 1.05, progress)
	r.draw_arc(effect_pos, stun_r, 0.0, TAU, 28, Color(effect_color, ratio), 6.0)
	r.draw_circle(effect_pos, 6.0 * ratio, Color(Color.WHITE, ratio * 0.7))
	for star in range(5):
		var star_dir := Vector2.UP.rotated(TAU * float(star) / 5.0 + progress * 1.2)
		var star_pos := effect_pos + star_dir * stun_r * 0.62
		r.draw_line(star_pos - star_dir * 7.0, star_pos + star_dir * 7.0, Color(effect_color, ratio), 3.0)
		r.draw_line(star_pos - star_dir.orthogonal() * 7.0, star_pos + star_dir.orthogonal() * 7.0, Color(Color.WHITE, ratio), 2.0)

func _draw_snake_pop(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	if _try_ultimate_pop(5, ratio, progress, effect_pos, effect_radius, direction):
		return
	var shed_r := effect_radius * lerpf(0.22, 1.05, progress)
	for ring in range(3):
		var ring_r := shed_r * (0.42 + float(ring) * 0.22)
		var start := progress * 2.2 + float(ring)
		r.draw_arc(effect_pos, ring_r, start, start + PI * 1.35, 16, Color(effect_color, ratio * (0.9 - float(ring) * 0.18)), 4.0)
	r.draw_arc(effect_pos, shed_r * 0.35, 0.0, TAU, 16, Color(Color.WHITE, ratio * 0.6), 2.0)

func _draw_sheep_pop(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	if _try_ultimate_pop(7, ratio, progress, effect_pos, effect_radius, direction):
		return
	var puff_r := effect_radius * lerpf(0.18, 0.95, progress)
	r.draw_circle(effect_pos, puff_r * 0.28, Color(effect_color, ratio * 0.45))
	for puff in range(7):
		var puff_dir := Vector2.RIGHT.rotated(TAU * float(puff) / 7.0 + progress * 0.6)
		r.draw_circle(effect_pos + puff_dir * puff_r * 0.62, 8.0 + float(puff % 3) * 2.0, Color(effect_color, ratio * 0.55))
	r.draw_arc(effect_pos, puff_r, 0.0, TAU, 22, Color(Color.WHITE, ratio * 0.7), 3.0)

func _draw_monkey_pop(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	if _try_ultimate_pop(8, ratio, progress, effect_pos, effect_radius, direction):
		return
	var pop_r := effect_radius * lerpf(0.20, 1.00, progress)
	r.draw_arc(effect_pos, pop_r, 0.0, TAU, 24, Color(effect_color, ratio), 5.0)
	for hop in range(6):
		var hop_dir := Vector2.RIGHT.rotated(TAU * float(hop) / 6.0 + progress * 2.0)
		var hop_pos := effect_pos + hop_dir * pop_r * (0.45 + 0.2 * sin(progress * TAU + float(hop)))
		r.draw_circle(hop_pos, 4.5, Color(Color.WHITE, ratio * 0.85))
	r.draw_circle(effect_pos, 5.0, Color(effect_color, ratio * 0.7))

func _draw_rooster_burst(effect_color: Color, ratio: float, progress: float, effect_pos: Vector2, effect_radius: float, direction: Vector2) -> void:
	if _try_ultimate_pop(9, ratio, progress, effect_pos, effect_radius, direction):
		return
	var burst_r := effect_radius * lerpf(0.25, 1.10, progress)
	r.draw_arc(effect_pos, burst_r, 0.0, TAU, 28, Color(effect_color, ratio), 6.0)
	for ray in range(8):
		var ray_dir := Vector2.UP.rotated(TAU * float(ray) / 8.0)
		r.draw_line(effect_pos + ray_dir * burst_r * 0.28, effect_pos + ray_dir * burst_r, Color(effect_color, ratio * 0.85), 3.0)
	r.draw_circle(effect_pos, 6.0 * (1.0 - progress * 0.4), Color(Color.WHITE, ratio))
