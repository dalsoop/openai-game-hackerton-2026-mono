extends Node2D

var world
var colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc")]

func _projectile_color(projectile: Dictionary) -> Color:
    match str(projectile.get("kind", "bolt")):
        "pellet": return Color("#ffae57")
        "beam": return Color("#70e7ff")
        "shell": return Color("#ff665a")
        "tether": return Color("#db6cff")
        "hammer": return Color("#ffe066")
        "seeker": return Color("#ff5ca8")
        "burst": return Color("#8bffde")
        "slash": return Color("#b9f3ff")
        "fist": return Color("#ff9466")
        "bomb": return Color("#ff554a")
        "spear": return Color("#ffe27a")
        "chain": return Color("#b78cff")
        "shield": return Color("#8de1ff")
        _: return colors[int(projectile["owner"])]

func _draw_character_shape(pos: Vector2, equipment_id: String, color: Color) -> void:
    var points := PackedVector2Array()
    match equipment_id:
        "rail":
            points = PackedVector2Array([pos + Vector2(0.0, -24.0), pos + Vector2(21.0, 18.0), pos + Vector2(-21.0, 18.0)])
        "mortar":
            for index in range(6):
                points.append(pos + Vector2.RIGHT.rotated(TAU * float(index) / 6.0) * 22.0)
        "breaker":
            points = PackedVector2Array([pos + Vector2(0.0, -25.0), pos + Vector2(25.0, 0.0), pos + Vector2(0.0, 25.0), pos + Vector2(-25.0, 0.0)])
        "burst":
            for index in range(10):
                var radius := 24.0 if index % 2 == 0 else 12.0
                points.append(pos + Vector2.UP.rotated(TAU * float(index) / 10.0) * radius)
        "leech":
            draw_circle(pos, 22.0, Color(color, 0.35))
            draw_arc(pos, 22.0, 0.0, TAU, 28, color, 7.0)
            draw_circle(pos, 8.0, color)
            return
        "blade":
            points = PackedVector2Array([pos + Vector2(0.0, -25.0), pos + Vector2(19.0, -5.0), pos + Vector2(15.0, 22.0), pos + Vector2(-15.0, 22.0), pos + Vector2(-19.0, -5.0)])
        "brawler":
            points = PackedVector2Array([pos + Vector2(-20.0, -18.0), pos + Vector2(20.0, -18.0), pos + Vector2(25.0, 8.0), pos + Vector2(0.0, 25.0), pos + Vector2(-25.0, 8.0)])
        "bomb":
            for index in range(8):
                points.append(pos + Vector2.RIGHT.rotated(TAU * float(index) / 8.0) * (23.0 if index % 2 == 0 else 18.0))
        "spear":
            points = PackedVector2Array([pos + Vector2(0.0, -26.0), pos + Vector2(18.0, 17.0), pos + Vector2(0.0, 23.0), pos + Vector2(-18.0, 17.0)])
        "chain":
            for index in range(6):
                points.append(pos + Vector2.RIGHT.rotated(TAU * float(index) / 6.0) * 22.0)
        "shield":
            points = PackedVector2Array([pos + Vector2(-22.0, -20.0), pos + Vector2(22.0, -20.0), pos + Vector2(19.0, 15.0), pos + Vector2(0.0, 27.0), pos + Vector2(-19.0, 15.0)])
        _:
            points = PackedVector2Array([pos + Vector2(-21.0, -21.0), pos + Vector2(21.0, -21.0), pos + Vector2(21.0, 21.0), pos + Vector2(-21.0, 21.0)])
    draw_colored_polygon(points, color)
    draw_polyline(points, Color(Color.BLACK, color.a), 3.0)
    draw_line(points[points.size() - 1], points[0], Color(Color.BLACK, color.a), 3.0)

func _draw_weapon(pos: Vector2, equipment_id: String, color: Color, aim: Vector2, opacity: float = 1.0) -> void:
    var dir := aim.normalized() if aim.length_squared() > 0.1 else Vector2.RIGHT
    var side := dir.orthogonal()
    match equipment_id:
        "scatter":
            draw_line(pos + dir * 8.0, pos + dir * 43.0 + side * 5.0, Color(Color("#ffae57"), opacity), 7.0)
            draw_line(pos + dir * 8.0, pos + dir * 43.0 - side * 5.0, Color(Color("#ffcf8a"), opacity), 5.0)
        "rail":
            draw_line(pos - dir * 8.0, pos + dir * 55.0, Color(Color("#70e7ff"), opacity), 7.0)
            draw_line(pos + dir * 8.0, pos + dir * 58.0, Color(Color.WHITE, opacity), 2.0)
        "mortar":
            draw_rect(Rect2(pos - side * 15.0 - dir * 8.0, Vector2(27.0, 17.0)), Color(Color("#70362f"), opacity))
            draw_circle(pos + dir * 21.0, 9.0, Color(Color("#ff665a"), opacity))
        "leech":
            for link in range(4):
                var link_pos := pos + dir * (18.0 + link * 9.0)
                draw_arc(link_pos, 5.0, 0.0, TAU, 10, Color(Color("#db6cff"), opacity), 2.0)
            draw_line(pos + dir * 48.0, pos + dir * 56.0 - side * 8.0, Color(Color("#f1b5ff"), opacity), 4.0)
        "breaker":
            draw_line(pos - dir * 5.0, pos + dir * 44.0, Color(Color("#8a623d"), opacity), 7.0)
            draw_line(pos + dir * 38.0 - side * 16.0, pos + dir * 38.0 + side * 16.0, Color(Color("#ffe066"), opacity), 15.0)
        "burst":
            draw_line(pos + side * 8.0, pos + side * 8.0 + dir * 35.0, Color(Color("#ff5ca8"), opacity), 6.0)
            draw_line(pos - side * 8.0, pos - side * 8.0 + dir * 35.0, Color(Color("#8bffde"), opacity), 6.0)
        "blade":
            draw_line(pos - dir * 5.0, pos + dir * 53.0, Color(Color("#d9fbff"), opacity), 6.0)
            draw_line(pos + dir * 5.0 - side * 13.0, pos + dir * 5.0 + side * 13.0, Color(Color("#6ca7bd"), opacity), 5.0)
            draw_line(pos + dir * 17.0, pos + dir * 53.0, Color(Color.WHITE, opacity), 2.0)
        "brawler":
            draw_colored_polygon(PackedVector2Array([pos + dir * 20.0 + side * 8.0, pos + dir * 37.0 + side * 12.0, pos + dir * 42.0 + side * 3.0, pos + dir * 25.0]), Color(Color("#ff9466"), opacity))
            draw_colored_polygon(PackedVector2Array([pos + dir * 18.0 - side * 9.0, pos + dir * 34.0 - side * 15.0, pos + dir * 41.0 - side * 6.0, pos + dir * 24.0]), Color(Color("#ffcf9f"), opacity))
        "bomb":
            draw_circle(pos + dir * 31.0, 15.0, Color(Color("#32191d"), opacity))
            draw_arc(pos + dir * 31.0, 15.0, 0.0, TAU, 20, Color(Color("#ff554a"), opacity), 4.0)
            draw_line(pos + dir * 31.0 - side * 15.0, pos + dir * 38.0 - side * 24.0, Color(Color("#ffdb61"), opacity), 3.0)
        "spear":
            draw_line(pos - dir * 18.0, pos + dir * 65.0, Color(Color("#d0a447"), opacity), 6.0)
            draw_colored_polygon(PackedVector2Array([pos + dir * 73.0, pos + dir * 55.0 + side * 9.0, pos + dir * 55.0 - side * 9.0]), Color(Color("#fff1a8"), opacity))
        "chain":
            var chain_points := PackedVector2Array([pos, pos + dir * 18.0 + side * 8.0, pos + dir * 36.0 - side * 9.0, pos + dir * 55.0 + side * 5.0])
            draw_polyline(chain_points, Color(Color("#b78cff"), opacity), 5.0)
            draw_arc(pos + dir * 59.0, 10.0, -PI * 0.5, PI * 0.9, 12, Color(Color("#e2c8ff"), opacity), 5.0)
        "shield":
            var center := pos + dir * 30.0
            draw_colored_polygon(PackedVector2Array([center - side * 22.0 - dir * 12.0, center + side * 22.0 - dir * 12.0, center + side * 18.0 + dir * 18.0, center + dir * 28.0, center - side * 18.0 + dir * 18.0]), Color(Color("#5d91a8"), opacity))
            draw_polyline(PackedVector2Array([center - side * 22.0 - dir * 12.0, center + side * 22.0 - dir * 12.0, center + side * 18.0 + dir * 18.0, center + dir * 28.0, center - side * 18.0 + dir * 18.0, center - side * 22.0 - dir * 12.0]), Color(Color("#bcefff"), opacity), 4.0)

func _draw_motion_trail(trail: Array, color: Color, width: float, opacity: float = 1.0) -> void:
    if trail.size() < 2 or opacity <= 0.001:
        return
    var last_index := trail.size() - 1
    for segment_index in range(1, trail.size()):
        var age_ratio := float(segment_index) / float(last_index)
        var fade := pow(age_ratio, 1.65) * opacity
        var segment_width := width * lerpf(0.22, 1.0, age_ratio)
        var from: Vector2 = trail[segment_index - 1]
        var to: Vector2 = trail[segment_index]
        draw_line(from, to, Color(color, fade * 0.16), segment_width * 1.75, true)
        draw_line(from, to, Color(color, fade * 0.76), segment_width, true)

func _draw() -> void:
    if world == null:
        return
    draw_rect(Rect2(Vector2.ZERO, world.ARENA_SIZE), Color("#0b0e13"))
    var arena_rect := Rect2(Vector2(world.ARENA_MARGIN, world.ARENA_MARGIN), world.ARENA_SIZE - Vector2.ONE * world.ARENA_MARGIN * 2.0)
    draw_rect(arena_rect, Color("#202632"))
    draw_rect(arena_rect, Color("#606a78"), false, 5.0)
    for x in range(100, int(world.ARENA_SIZE.x), 100):
        draw_line(Vector2(x, world.ARENA_MARGIN), Vector2(x, world.ARENA_SIZE.y - world.ARENA_MARGIN), Color(0.30, 0.34, 0.41, 0.10), 1.0)
    for y in range(100, int(world.ARENA_SIZE.y), 100):
        draw_line(Vector2(world.ARENA_MARGIN, y), Vector2(world.ARENA_SIZE.x - world.ARENA_MARGIN, y), Color(0.30, 0.34, 0.41, 0.10), 1.0)
    _draw_safe_zone()
    for cover in world.covers:
        var rect: Rect2 = cover["rect"]
        draw_rect(rect, Color("#333c4b"))
        draw_rect(rect.grow(-7.0), Color("#151b25"))
        draw_rect(rect, Color("#8792a3"), false, 4.0)
    for pickup in world.health_pickups:
        var pickup_pos: Vector2 = pickup["pos"]
        var active := bool(pickup["active"])
        var pulse := 1.0 + sin(float(world.tick) * 0.10 + float(pickup["id"])) * 0.10
        if active:
            var magnet_slot := int(pickup.get("magnet_slot", -1))
            if magnet_slot >= 0 and magnet_slot < world.heroes.size():
                var magnet_dir := pickup_pos.direction_to(Vector2(world.heroes[magnet_slot]["pos"]))
                for trail_index in range(3):
                    var side := magnet_dir.orthogonal() * (float(trail_index) - 1.0) * 7.0
                    draw_line(pickup_pos - magnet_dir * (20.0 + float(trail_index) * 9.0) + side, pickup_pos - magnet_dir * (48.0 + float(trail_index) * 12.0) + side, Color("#6ef3a5", 0.72), 4.0)
                draw_arc(pickup_pos, 25.0, magnet_dir.angle() - 1.1, magnet_dir.angle() + 1.1, 18, Color("#d9ffe8"), 5.0)
            else:
                draw_circle(pickup_pos, 23.0 * pulse, Color(0.18, 0.95, 0.52, 0.16))
                draw_arc(pickup_pos, 28.0, 0.0, TAU, 28, Color("#6ef3a5"), 4.0)
            draw_rect(Rect2(pickup_pos + Vector2(-5.0, -18.0), Vector2(10.0, 36.0)), Color("#d9ffe8"))
            draw_rect(Rect2(pickup_pos + Vector2(-18.0, -5.0), Vector2(36.0, 10.0)), Color("#d9ffe8"))
        else:
            draw_circle(pickup_pos, 27.0, Color(0.02, 0.04, 0.04, 0.68))
            draw_arc(pickup_pos, 28.0, 0.0, TAU, 28, Color("#52605b"), 3.0)
            draw_string(ThemeDB.fallback_font, pickup_pos + Vector2(-32.0, 6.0), "%d" % ceili(float(pickup["respawn"])), HORIZONTAL_ALIGNMENT_CENTER, 64.0, 18, Color("#8b9993"))
    for core in world.cores:
        var slot := int(core["slot"])
        var pos: Vector2 = core["pos"]
        var color: Color = Color(colors[slot])
        draw_circle(pos, 22.0, Color(color, 0.10))
        draw_arc(pos, 22.0, 0.0, TAU, 24, Color(color, 0.28), 2.0)
        draw_string(ThemeDB.fallback_font, pos + Vector2(-18.0, 5.0), "P%d" % (slot + 1), HORIZONTAL_ALIGNMENT_CENTER, 36.0, 11, Color(color, 0.55))
    for mine in world.deployables:
        var mine_pos: Vector2 = mine["pos"]
        var mine_owner := int(mine["owner"])
        var mine_color: Color = colors[mine_owner]
        if StringName(mine.get("type", &"mine")) == &"wall":
            var wall_dir := Vector2(mine["direction"]).normalized()
            var wall_normal := Vector2(mine.get("travel_direction", wall_dir.orthogonal())).normalized()
            var wall_a := mine_pos - wall_dir * float(mine["half_length"])
            var wall_b := mine_pos + wall_dir * float(mine["half_length"])
            var life_ratio := clampf(float(mine["lifetime"]) / maxf(0.01, float(mine["max_lifetime"])), 0.0, 1.0)
            var arming := float(mine.get("arm_time", 0.0)) > 0.0
            var pulse := 0.72 + sin(float(world.tick) * 0.18) * 0.12
            draw_colored_polygon(PackedVector2Array([
                wall_a - wall_normal * 55.0,
                wall_b - wall_normal * 55.0,
                wall_b - wall_normal * 12.0,
                wall_a - wall_normal * 12.0
            ]), Color(0.16, 0.69, 0.88, 0.08 if not arming else 0.16))
            draw_line(wall_a - wall_normal * 44.0, wall_b - wall_normal * 44.0, Color("#63d8ff", 0.18), 5.0)
            draw_line(wall_a, wall_b, Color("#102b3e", 0.82), 27.0)
            draw_line(wall_a, wall_b, Color("#8de1ff", pulse), 11.0)
            for wall_segment in range(7):
                var segment_pos := wall_a.lerp(wall_b, float(wall_segment) / 6.0)
                draw_line(segment_pos - wall_normal * 17.0, segment_pos + wall_normal * 17.0, Color.WHITE, 3.0)
                draw_colored_polygon(PackedVector2Array([segment_pos + wall_normal * 13.0, segment_pos + wall_dir * 7.0, segment_pos - wall_normal * 13.0, segment_pos - wall_dir * 7.0]), Color(mine_color, 0.72))
            var arrow_center := mine_pos + wall_normal * 48.0
            draw_colored_polygon(PackedVector2Array([
                arrow_center + wall_normal * 20.0,
                arrow_center - wall_normal * 12.0 + wall_dir * 13.0,
                arrow_center - wall_normal * 5.0,
                arrow_center - wall_normal * 12.0 - wall_dir * 13.0
            ]), Color("#dff8ff", 0.55 if arming else 0.95))
            draw_rect(Rect2(mine_pos + Vector2(-54.0, -36.0), Vector2(108.0, 20.0)), Color(0.02, 0.06, 0.09, 0.82))
            var wall_text := "P%d LAUNCH" % (mine_owner + 1) if arming else "P%d RAM %.1f" % [mine_owner + 1, float(mine["lifetime"])]
            draw_string(ThemeDB.fallback_font, mine_pos + Vector2(-50.0, -21.0), wall_text, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 11, Color("#dff8ff", 1.0 if arming else life_ratio))
            continue
        var armed := float(mine["arm_time"]) <= 0.0
        var triggered := bool(mine["triggered"])
        var trigger_radius := float(mine["trigger_radius"])
        if armed:
            for sensor_arc in range(8):
                var sensor_start := TAU * float(sensor_arc) / 8.0 + 0.08
                draw_arc(mine_pos, trigger_radius, sensor_start, sensor_start + 0.48, 8, Color("#ff765f", 0.48 if not triggered else 0.88), 3.0)
        else:
            var arm_ratio := 1.0 - clampf(float(mine["arm_time"]) / maxf(0.01, float(mine["arm_duration"])), 0.0, 1.0)
            draw_arc(mine_pos, 31.0, -PI * 0.5, -PI * 0.5 + TAU * arm_ratio, 24, Color("#ffd166"), 5.0)
        if triggered:
            var fuse_ratio := clampf(float(mine["fuse_time"]) / maxf(0.01, float(mine["fuse_duration"])), 0.0, 1.0)
            draw_circle(mine_pos, float(mine["blast_radius"]), Color(0.42, 0.03, 0.02, 0.08 + (1.0 - fuse_ratio) * 0.12))
            draw_arc(mine_pos, float(mine["blast_radius"]) * lerpf(0.34, 1.0, fuse_ratio), 0.0, TAU, 42, Color("#ff554a"), 5.0)
            draw_string(ThemeDB.fallback_font, mine_pos + Vector2(-42.0, -39.0), "MOVE! %.1f" % float(mine["fuse_time"]), HORIZONTAL_ALIGNMENT_CENTER, 84.0, 13, Color.WHITE)
        draw_circle(mine_pos, 19.0, Color("#241014"))
        draw_colored_polygon(PackedVector2Array([mine_pos + Vector2(0.0, -18.0), mine_pos + Vector2(18.0, 0.0), mine_pos + Vector2(0.0, 18.0), mine_pos + Vector2(-18.0, 0.0)]), Color("#ff554a") if armed else Color("#8ca0b8"))
        draw_circle(mine_pos, 7.0 + (sin(float(world.tick) * 0.28) * 2.0 if armed else 0.0), Color.WHITE if triggered else mine_color)
        draw_string(ThemeDB.fallback_font, mine_pos + Vector2(-30.0, 34.0), "P%d MINE" % (mine_owner + 1), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color.WHITE)
    for projectile in world.projectiles:
        var source := StringName(projectile["source"])
        var projectile_color: Color = Color.WHITE if source == &"ultimate" else _projectile_color(projectile)
        var projectile_pos: Vector2 = projectile["pos"]
        var direction := Vector2(projectile["vel"]).normalized()
        var kind := str(projectile.get("kind", "bolt"))
        _draw_motion_trail(projectile.get("trail", []), projectile_color, 3.0 if source == &"normal" else 5.0)
        if bool(projectile.get("arc", false)):
            var arc_progress := clampf(1.0 - float(projectile["ttl"]) / maxf(0.01, float(projectile["max_ttl"])), 0.0, 1.0)
            var bomb_scale := 0.72 + sin(arc_progress * PI) * 0.95
            var landing: Vector2 = projectile["landing_pos"]
            draw_circle(projectile_pos + Vector2(7.0, 9.0), 13.0 * bomb_scale, Color(0.0, 0.0, 0.0, 0.23))
            draw_circle(projectile_pos, 11.0 * bomb_scale, Color("#2c1115"))
            draw_arc(projectile_pos, 13.0 * bomb_scale, 0.0, TAU, 22, Color("#ff6b4a"), 4.0)
            draw_circle(landing, float(projectile["splash"]), Color(0.35, 0.04, 0.03, 0.07))
            draw_arc(landing, float(projectile["splash"]) * lerpf(1.0, 0.78, arc_progress), 0.0, TAU, 36, Color(1.0, 0.34, 0.22, 0.68), 3.0)
            continue
        match kind:
            "beam":
                draw_line(projectile_pos - direction * 125.0, projectile_pos + direction * 18.0, Color(projectile_color, 0.28), 18.0)
                draw_line(projectile_pos - direction * 145.0, projectile_pos + direction * 22.0, Color.WHITE, 3.5)
                draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 18.0, projectile_pos + direction.orthogonal() * 7.0, projectile_pos - direction * 16.0, projectile_pos - direction.orthogonal() * 7.0]), projectile_color)
            "shell":
                draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 15.0, projectile_pos + direction.orthogonal() * 10.0, projectile_pos - direction * 11.0, projectile_pos - direction.orthogonal() * 10.0]), Color("#ff503f"))
                draw_line(projectile_pos - direction * 34.0, projectile_pos - direction * 8.0, Color("#ffcf66"), 8.0)
            "tether":
                for segment in range(3):
                    var center := projectile_pos - direction * float(segment * 13)
                    draw_line(center - direction.orthogonal() * 7.0, center + direction.orthogonal() * 7.0, projectile_color, 4.0)
            "seeker":
                var star := PackedVector2Array()
                for point in range(8):
                    star.append(projectile_pos + Vector2.RIGHT.rotated(TAU * float(point) / 8.0) * (12.0 if point % 2 == 0 else 5.0))
                draw_colored_polygon(star, projectile_color)
            "slash":
                var slash_angle := direction.angle()
                draw_arc(projectile_pos - direction * 8.0, 31.0, slash_angle - 1.05, slash_angle + 1.05, 18, Color("#b9f3ff"), 10.0)
                draw_arc(projectile_pos - direction * 8.0, 25.0, slash_angle - 0.95, slash_angle + 0.95, 16, Color.WHITE, 3.0)
            "fist":
                draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 18.0, projectile_pos + direction.orthogonal() * 13.0, projectile_pos - direction * 13.0 + direction.orthogonal() * 9.0, projectile_pos - direction * 13.0 - direction.orthogonal() * 9.0]), Color("#ff9466"))
                draw_line(projectile_pos - direction * 38.0, projectile_pos - direction * 8.0, Color("#ffd0ac"), 9.0)
            "bomb":
                draw_circle(projectile_pos, 13.0, Color("#2c1115"))
                draw_arc(projectile_pos, 14.0, 0.0, TAU, 22, Color("#ff554a"), 5.0)
                draw_line(projectile_pos - direction.orthogonal() * 12.0, projectile_pos - direction.orthogonal() * 23.0 - direction * 7.0, Color("#ffe36a"), 4.0)
            "spear":
                draw_line(projectile_pos - direction * 66.0, projectile_pos + direction * 24.0, Color("#d0a447"), 7.0)
                draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 36.0, projectile_pos + direction * 17.0 + direction.orthogonal() * 10.0, projectile_pos + direction * 17.0 - direction.orthogonal() * 10.0]), Color("#fff1a8"))
            "chain":
                draw_arc(projectile_pos, 14.0, -direction.angle() - PI * 0.6, -direction.angle() + PI * 0.7, 14, Color("#e2c8ff"), 6.0)
            "shield":
                var shield_side := direction.orthogonal()
                draw_colored_polygon(PackedVector2Array([projectile_pos - shield_side * 18.0 - direction * 8.0, projectile_pos + shield_side * 18.0 - direction * 8.0, projectile_pos + shield_side * 14.0 + direction * 17.0, projectile_pos + direction * 26.0, projectile_pos - shield_side * 14.0 + direction * 17.0]), Color("#8de1ff"))
            _:
                draw_line(projectile_pos - direction * 34.0, projectile_pos + direction * 9.0, projectile_color, 5.0)
                draw_line(projectile_pos - direction * 10.0, projectile_pos + direction * 8.0, Color.WHITE, 2.0)
    for zone in world.zones:
        var zone_color: Color = zone.get("color", colors[int(zone["owner"])])
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
        draw_circle(zone_pos, zone_radius, Color("#15090b", warning_alpha * 1.35) if zone_kind == &"explosion" else Color(zone_color, warning_alpha * 0.72))
        draw_arc(zone_pos, zone_radius, 0.0, TAU, 42, Color(zone_color, 0.78), 4.0)
        if zone_kind == &"rail_strike":
            draw_line(zone_pos - Vector2(zone_radius * 1.6, 0.0), zone_pos + Vector2(zone_radius * 1.6, 0.0), Color(zone_color, 0.75), 5.0)
            draw_line(zone_pos - Vector2(0.0, zone_radius * 1.6), zone_pos + Vector2(0.0, zone_radius * 1.6), Color.WHITE, 2.0)
        elif zone_kind == &"drain":
            for ring in range(3):
                draw_arc(zone_pos, zone_radius * (0.35 + ring * 0.23), float(world.tick) * 0.05 + ring, float(world.tick) * 0.05 + ring + PI * 1.35, 24, Color(zone_color, 0.72), 4.0)
        elif zone_kind == &"shockwave":
            for spoke in range(8):
                var radial := Vector2.RIGHT.rotated(TAU * float(spoke) / 8.0)
                draw_line(zone_pos + radial * zone_radius * 0.45, zone_pos + radial * zone_radius, Color(zone_color, 0.75), 4.0)
        elif zone_kind == &"slashwave":
            for slash in range(3):
                var slash_angle := float(world.tick) * 0.08 + slash * PI / 3.0
                draw_arc(zone_pos, zone_radius * (0.55 + slash * 0.16), slash_angle, slash_angle + PI * 0.85, 18, Color(zone_color, 0.82), 6.0)
        elif zone_kind == &"fist_burst":
            for fist_ray in range(6):
                var fist_dir := Vector2.RIGHT.rotated(TAU * float(fist_ray) / 6.0)
                draw_line(zone_pos + fist_dir * 18.0, zone_pos + fist_dir * zone_radius, Color(zone_color, 0.82), 10.0)
        elif zone_kind == &"chain_vortex":
            for ring in range(3):
                draw_arc(zone_pos, zone_radius * (0.42 + ring * 0.22), float(world.tick) * -0.08 + ring, float(world.tick) * -0.08 + ring + PI * 1.55, 28, Color(zone_color, 0.86), 7.0)
        elif zone_kind == &"shield_bash":
            draw_arc(zone_pos, zone_radius * 0.82, -PI * 0.75, PI * 0.75, 28, Color(zone_color, 0.92), 15.0)
            draw_line(zone_pos - Vector2(0.0, zone_radius * 0.8), zone_pos + Vector2(0.0, zone_radius * 0.8), Color.WHITE, 4.0)
        if delay > 0.0:
            var timer_radius := float(zone["radius"]) * lerpf(0.28, 1.0, warning_ratio)
            draw_arc(zone_pos, timer_radius, 0.0, TAU, 36, Color.WHITE, 3.0 + impact_progress * 2.0)
            for warning_tick in range(8):
                var tick_dir := Vector2.RIGHT.rotated(TAU * float(warning_tick) / 8.0)
                draw_line(zone_pos + tick_dir * (zone_radius + 5.0), zone_pos + tick_dir * (zone_radius + 13.0), Color(zone_color, 0.82), 3.0)
            var warning_label := str(zone.get("label", ""))
            if not warning_label.is_empty() and zone_radius >= 90.0:
                draw_rect(Rect2(zone_pos + Vector2(-72.0, -13.0), Vector2(144.0, 25.0)), Color(0.04, 0.02, 0.03, 0.76))
                draw_string(ThemeDB.fallback_font, zone_pos + Vector2(-68.0, 6.0), "%s  %.1f" % [warning_label, delay], HORIZONTAL_ALIGNMENT_CENTER, 136.0, 13, Color.WHITE)
    for effect in world.effects:
        var effect_color: Color = effect["color"]
        var ratio := clampf(float(effect["time"]) / float(effect["max_time"]), 0.0, 1.0)
        var effect_pos: Vector2 = effect["pos"]
        var effect_radius := float(effect["radius"])
        var effect_kind := StringName(effect["kind"])
        var direction := Vector2(effect["direction"]).normalized()
        var progress := 1.0 - ratio
        match effect_kind:
            &"line", &"beam_hit", &"beam_step":
                var line_start := effect_pos - direction * effect_radius * (0.75 if effect_kind == &"beam_hit" else 1.0)
                var line_end := effect_pos + direction * effect_radius * (0.65 if effect_kind == &"beam_hit" else 0.05)
                draw_line(line_start, line_end, Color(effect_color, ratio * 0.34), 26.0 * ratio + 5.0)
                draw_line(line_start, line_end, Color.WHITE, 4.0 * ratio + 1.5)
            &"explosion":
                var blast_radius := effect_radius * lerpf(0.18, 1.28, progress)
                draw_circle(effect_pos, blast_radius * 0.72, Color("#3a0808", ratio * 0.72))
                draw_circle(effect_pos, blast_radius * 0.48, Color(effect_color, ratio * 0.86))
                draw_arc(effect_pos, blast_radius, 0.0, TAU, 52, Color.WHITE, ratio, 9.0 * ratio + 2.0)
            &"drain":
                for arc_index in range(4):
                    var arc_radius := effect_radius * (0.28 + float(arc_index) * 0.18) * (0.65 + progress * 0.35)
                    var arc_start := progress * TAU * (1.0 if arc_index % 2 == 0 else -1.0) + arc_index
                    draw_arc(effect_pos, arc_radius, arc_start, arc_start + PI * 1.25, 22, Color(effect_color, ratio), 5.0)
            &"shockwave":
                var shock_radius := effect_radius * lerpf(0.25, 1.18, progress)
                draw_arc(effect_pos, shock_radius, 0.0, TAU, 32, Color(effect_color, ratio), 10.0 * ratio + 2.0)
                for spoke in range(10):
                    var radial := Vector2.RIGHT.rotated(TAU * float(spoke) / 10.0)
                    draw_line(effect_pos + radial * shock_radius * 0.48, effect_pos + radial * shock_radius, Color(Color.WHITE, ratio * 0.85), 3.0)
            &"wall_impact", &"hit_spark":
                for spark in range(9):
                    var spark_dir := (-direction).rotated((float(spark) - 4.0) * 0.16)
                    draw_line(effect_pos, effect_pos + spark_dir * effect_radius * (0.45 + float(spark % 3) * 0.22), Color(effect_color, ratio), 5.0 if effect_kind == &"wall_impact" else 3.0)
            &"speed_streak":
                for streak in range(5):
                    var side := direction.orthogonal() * (float(streak) - 2.0) * 9.0
                    draw_line(effect_pos + side, effect_pos + side + direction * effect_radius, Color(effect_color, ratio * 0.8), 4.0)
            &"slashwave", &"slash_dash":
                var slash_angle := direction.angle()
                var slash_radius := effect_radius * lerpf(0.72, 1.04, progress)
                draw_arc(effect_pos, slash_radius, slash_angle - 1.05, slash_angle + 1.05, 20, Color(effect_color, ratio), 8.0)
                draw_arc(effect_pos, slash_radius - 9.0, slash_angle - 0.86, slash_angle + 0.86, 16, Color(Color.WHITE, ratio * 0.72), 2.0)
            &"fist_burst":
                draw_line(effect_pos - direction * effect_radius * 0.38, effect_pos + direction * effect_radius * 0.52, Color(effect_color, ratio * 0.42), 18.0)
                draw_line(effect_pos - direction * 8.0, effect_pos + direction * effect_radius * 0.64, Color.WHITE, ratio, 6.0)
                draw_line(effect_pos - direction * 2.0, effect_pos + direction.rotated(0.26) * effect_radius * 0.48, Color(effect_color, ratio * 0.74), 5.0)
            &"hammer_slam":
                var hammer_side := direction.orthogonal()
                draw_line(effect_pos - direction * effect_radius * 0.56, effect_pos + direction * effect_radius * 0.16, Color(effect_color, ratio * 0.72), 20.0)
                draw_line(effect_pos - hammer_side * effect_radius * 0.42, effect_pos + hammer_side * effect_radius * 0.42, Color.WHITE, ratio, 7.0)
                draw_line(effect_pos, effect_pos + direction.rotated(0.55) * effect_radius * 0.56, Color(effect_color, ratio), 5.0)
                draw_line(effect_pos, effect_pos + direction.rotated(-0.55) * effect_radius * 0.56, Color(effect_color, ratio), 5.0)
            &"spear_line":
                draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius * 0.18, Color(effect_color, ratio * 0.34), 22.0)
                draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius * 0.22, Color.WHITE, ratio, 4.0)
                draw_colored_polygon(PackedVector2Array([effect_pos + direction * effect_radius * 0.28, effect_pos + direction * effect_radius * 0.08 + direction.orthogonal() * 14.0, effect_pos + direction * effect_radius * 0.08 - direction.orthogonal() * 14.0]), Color(effect_color, ratio))
            &"chain_arc":
                for link in range(9):
                    var link_angle := progress * PI * 1.4 + float(link) * 0.19
                    var link_pos := effect_pos - direction * effect_radius * (float(link) / 9.0) + direction.orthogonal() * sin(link_angle) * 24.0
                    draw_arc(link_pos, 7.0, 0.0, TAU, 10, Color(effect_color, ratio), 3.0)
            &"fuse":
                draw_line(effect_pos, effect_pos + Vector2.UP.rotated(progress * 2.0) * effect_radius * 0.7, Color("#ffe36a", ratio), 5.0)
                for spark in range(6):
                    var spark_dir := Vector2.RIGHT.rotated(TAU * float(spark) / 6.0 + progress * 4.0)
                    draw_line(effect_pos, effect_pos + spark_dir * effect_radius * 0.45, Color(effect_color, ratio), 4.0)
            &"shield_bash":
                var shield_angle := direction.angle()
                draw_arc(effect_pos, effect_radius * lerpf(0.55, 1.15, progress), shield_angle - 1.15, shield_angle + 1.15, 30, Color(effect_color, ratio), 18.0)
                draw_line(effect_pos - direction.orthogonal() * effect_radius * 0.7, effect_pos + direction.orthogonal() * effect_radius * 0.7, Color.WHITE, ratio, 5.0)
            &"combo_finisher":
                for ray in range(5):
                    var ray_dir := (-direction).rotated((float(ray) - 2.0) * 0.13)
                    draw_line(effect_pos - direction * 10.0, effect_pos + ray_dir * effect_radius * (0.62 + float(ray) * 0.08), Color("#fff2b2", ratio * 0.82), 7.0 - absf(float(ray) - 2.0))
                draw_line(effect_pos - direction.orthogonal() * 34.0, effect_pos + direction.orthogonal() * 34.0, Color.WHITE, ratio, 6.0)
            &"charge_release":
                draw_arc(effect_pos, effect_radius * (0.75 + progress * 0.18), direction.angle() - 0.65, direction.angle() + 0.65, 20, Color(effect_color, ratio), 5.0)
                draw_line(effect_pos - direction * effect_radius * 0.45, effect_pos + direction * effect_radius * 0.28, Color.WHITE, ratio * 0.8, 3.0)
            &"victory":
                for victory_ring in range(3):
                    var ring_radius := effect_radius * (0.26 + float(victory_ring) * 0.19 + progress * 0.32)
                    draw_arc(effect_pos, ring_radius, progress * TAU + victory_ring, progress * TAU + victory_ring + PI * 1.45, 42, Color(effect_color, ratio * (0.86 - victory_ring * 0.18)), 7.0 - victory_ring)
                for victory_ray in range(10):
                    var ray_dir := Vector2.UP.rotated(TAU * float(victory_ray) / 10.0)
                    var ray_start := effect_pos + ray_dir * effect_radius * 0.38
                    draw_line(ray_start, ray_start + ray_dir * effect_radius * (0.22 + progress * 0.26), Color(Color.WHITE, ratio * 0.72), 5.0)
            &"combo_break", &"afterimage":
                draw_arc(effect_pos, effect_radius * lerpf(0.45, 1.20, progress), 0.0, TAU, 34, Color(effect_color, ratio), 8.0)
                draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius, Color(effect_color, ratio * 0.72), 5.0)
            &"death_burst":
                var death_radius := effect_radius * lerpf(0.16, 1.10, progress)
                draw_circle(effect_pos, death_radius * 0.52, Color("#48030b", ratio * 0.82))
                draw_arc(effect_pos, death_radius, 0.0, TAU, 54, Color("#ff3349", ratio), 16.0)
                draw_line(effect_pos - Vector2.ONE * death_radius * 0.72, effect_pos + Vector2.ONE * death_radius * 0.72, Color.WHITE, ratio, 12.0)
                draw_line(effect_pos + Vector2(-1.0, 1.0) * death_radius * 0.72, effect_pos + Vector2(1.0, -1.0) * death_radius * 0.72, Color.WHITE, ratio, 12.0)
            &"guard":
                draw_arc(effect_pos, effect_radius, -PI * 0.8, PI * 0.8, 28, Color(effect_color, ratio), 9.0)
                draw_arc(effect_pos, effect_radius - 12.0, -PI * 0.8, PI * 0.8, 28, Color(Color.WHITE, ratio * 0.8), 3.0)
            &"heal_pickup":
                var heal_lift := progress * effect_radius * 0.55
                draw_line(effect_pos + Vector2(-12.0, -heal_lift), effect_pos + Vector2(12.0, -heal_lift), Color(effect_color, ratio), 7.0)
                draw_line(effect_pos + Vector2(0.0, -12.0 - heal_lift), effect_pos + Vector2(0.0, 12.0 - heal_lift), Color(effect_color, ratio), 7.0)
            &"heal_ready":
                draw_arc(effect_pos, effect_radius * lerpf(0.52, 0.92, progress), -PI * 0.35, PI * 0.35, 18, Color(effect_color, ratio), 5.0)
                draw_arc(effect_pos, effect_radius * lerpf(0.52, 0.92, progress), PI * 0.65, PI * 1.35, 18, Color(effect_color, ratio), 5.0)
            &"respawn":
                for beam in range(3):
                    var beam_x := (float(beam) - 1.0) * 16.0
                    draw_line(effect_pos + Vector2(beam_x, effect_radius * 0.48), effect_pos + Vector2(beam_x, -effect_radius * (0.35 + progress * 0.48)), Color(effect_color, ratio * (0.55 + float(beam) * 0.18)), 5.0)
            &"mine_place":
                draw_arc(effect_pos, effect_radius * lerpf(1.0, 0.35, progress), 0.0, TAU, 28, Color(effect_color, ratio), 7.0)
                for bolt in range(4):
                    var bolt_dir := Vector2.RIGHT.rotated(TAU * float(bolt) / 4.0)
                    draw_line(effect_pos + bolt_dir * 12.0, effect_pos + bolt_dir * effect_radius, Color.WHITE, ratio, 3.0)
            &"mine_fizzle":
                for smoke in range(5):
                    var smoke_dir := Vector2.UP.rotated((float(smoke) - 2.0) * 0.28)
                    draw_circle(effect_pos + smoke_dir * effect_radius * progress, 7.0 + smoke * 1.5, Color(effect_color, ratio * 0.32))
            _:
                var flash_radius := maxf(5.0, effect_radius * lerpf(0.12, 0.28, progress))
                draw_circle(effect_pos, flash_radius, Color(effect_color, ratio * 0.46))
                draw_line(effect_pos - Vector2(flash_radius * 1.8, 0.0), effect_pos + Vector2(flash_radius * 1.8, 0.0), Color(Color.WHITE, ratio * 0.7), 2.0)
        if str(effect["label"]) != "" and effect_kind in [&"heal_pickup", &"respawn"]:
            draw_string(ThemeDB.fallback_font, effect_pos + Vector2(-100.0, -effect_radius - 10.0), str(effect["label"]), HORIZONTAL_ALIGNMENT_CENTER, 200.0, 16, Color(effect_color, ratio))
    for knockout in world.knockouts:
        var knockout_slot := int(knockout["slot"])
        var knockout_fade := clampf(float(knockout["time"]) / 0.42, 0.0, 1.0)
        _draw_motion_trail(knockout.get("trail", []), colors[knockout_slot], 9.0, knockout_fade)
        var knockout_pos: Vector2 = knockout["pos"]
        var knockout_color := Color(colors[knockout_slot], 0.72 * knockout_fade)
        var knockout_direction := Vector2(knockout["vel"]).normalized()
        if knockout_direction.length_squared() < 0.1:
            knockout_direction = Vector2.RIGHT
        _draw_character_shape(knockout_pos, str(knockout["equipment"]), knockout_color)
        _draw_weapon(knockout_pos, str(knockout["equipment"]), knockout_color, knockout_direction, knockout_fade)
    for hero in world.heroes:
        var slot := int(hero["slot"])
        if not bool(hero["alive"]):
            continue
        var pos: Vector2 = hero["pos"]
        var launch_trail_opacity := clampf(float(hero.get("launch_trail_fade", 0.0)) / 0.34, 0.0, 1.0)
        _draw_motion_trail(hero.get("launch_trail", []), colors[slot], 6.5, launch_trail_opacity)
        if float(hero.get("launch_time", 0.0)) > 0.0 and Vector2(hero.get("launch_vel", Vector2.ZERO)).length_squared() > 1.0:
            var launch_dir := Vector2(hero["launch_vel"]).normalized()
            draw_line(pos - launch_dir * 94.0, pos - launch_dir * 18.0, Color(colors[slot], 0.28), 9.0)
            _draw_character_shape(pos - launch_dir * 30.0, str(hero["equipment"]["id"]), Color(colors[slot], 0.11))
        if slot == world.wanted_slot:
            draw_colored_polygon(PackedVector2Array([pos + Vector2(-18.0, -42.0), pos + Vector2(-15.0, -58.0), pos + Vector2(-5.0, -49.0), pos + Vector2(0.0, -64.0), pos + Vector2(5.0, -49.0), pos + Vector2(15.0, -58.0), pos + Vector2(18.0, -42.0)]), Color("#ffd166"))
        if float(hero["cc_time"]) > 0.0:
            draw_arc(pos, 31.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(hero["cc_time"]) / 1.5, 0.15, 1.0), 24, Color("#63d8ff"), 5.0)
        if float(hero.get("root_time", 0.0)) > 0.0:
            var root_spin := float(world.tick) * 0.018
            for link_index in range(4):
                var link_dir := Vector2.RIGHT.rotated(root_spin + TAU * float(link_index) / 4.0)
                var link_center := pos + link_dir * 38.0
                draw_arc(link_center, 7.0, 0.0, TAU, 12, Color("#b78cff"), 3.0)
                draw_line(pos + link_dir * 29.0, pos + link_dir * 34.0, Color("#e2c9ff"), 3.0)
        if float(hero.get("stun_time", 0.0)) > 0.0:
            var stun_spin := float(world.tick) * 0.095
            for star_index in range(3):
                var star_pos := pos + Vector2(28.0, 10.0).rotated(stun_spin + TAU * float(star_index) / 3.0) + Vector2(0.0, -34.0)
                draw_colored_polygon(PackedVector2Array([star_pos + Vector2(0.0, -7.0), star_pos + Vector2(6.0, 0.0), star_pos + Vector2(0.0, 7.0), star_pos + Vector2(-6.0, 0.0)]), Color("#ffe27a"))
        if float(hero.get("guard_time", 0.0)) > 0.0:
            draw_arc(pos, 36.0, -PI * 0.82, PI * 0.82, 28, Color("#ffe066"), 7.0)
        if float(hero.get("super_armor_time", 0.0)) > 0.0:
            var armor_pulse := 40.0 + sin(float(world.tick) * 0.34 + slot) * 2.0
            draw_arc(pos, armor_pulse, 0.0, TAU, 32, Color(Color("#ff8dac"), 0.82), 4.0)
            for armor_mark in range(4):
                var mark_dir := Vector2.RIGHT.rotated(TAU * float(armor_mark) / 4.0 + float(world.tick) * 0.025)
                draw_line(pos + mark_dir * 35.0, pos + mark_dir * 45.0, Color(Color("#fff1f6"), 0.88), 3.0)
        if bool(hero.get("charging_skill", false)):
            var charge_ratio := clampf(float(hero.get("charge_time", 0.0)) / 1.15, 0.0, 1.0)
            draw_arc(pos, 43.0, -PI * 0.5, -PI * 0.5 + TAU * charge_ratio, 36, Color("#dff8ff"), 6.0)
        if world.result != &"playing" and slot == world.winner_slot:
            var winner_pulse := 54.0 + sin(float(world.tick) * 0.11) * 4.0
            draw_circle(pos, winner_pulse + 18.0, Color(1.0, 0.78, 0.24, 0.07))
            draw_arc(pos, winner_pulse, 0.0, TAU, 48, Color("#ffd166"), 6.0)
            draw_arc(pos, winner_pulse + 11.0, float(world.tick) * 0.025, float(world.tick) * 0.025 + PI * 1.45, 38, Color(Color.WHITE, 0.72), 3.0)
            var crown_y := -72.0 + sin(float(world.tick) * 0.08) * 2.0
            draw_colored_polygon(PackedVector2Array([pos + Vector2(-22.0, crown_y + 17.0), pos + Vector2(-20.0, crown_y), pos + Vector2(-7.0, crown_y + 10.0), pos + Vector2(0.0, crown_y - 6.0), pos + Vector2(7.0, crown_y + 10.0), pos + Vector2(20.0, crown_y), pos + Vector2(22.0, crown_y + 17.0)]), Color("#ffd166"))
        _draw_character_shape(pos, str(hero["equipment"]["id"]), colors[slot])
        _draw_weapon(pos, str(hero["equipment"]["id"]), colors[slot], Vector2(hero["aim"]))
        draw_line(pos, pos + Vector2(hero["aim"]) * 34.0, Color.BLACK, 4.0)
        var hp_ratio := maxf(0.0, float(hero["hp"]) / float(hero["max_hp"]))
        draw_rect(Rect2(pos + Vector2(-24.0, -31.0), Vector2(48.0, 5.0)), Color("#2a2d33"))
        draw_rect(Rect2(pos + Vector2(-24.0, -31.0), Vector2(48.0 * hp_ratio, 5.0)), Color("#6ef3a5"))
        if int(hero.get("kill_streak", 0)) >= 2:
            draw_string(ThemeDB.fallback_font, pos + Vector2(-34.0, -47.0), "x%d STREAK" % int(hero["kill_streak"]), HORIZONTAL_ALIGNMENT_CENTER, 68.0, 11, Color("#ffd166"))
        if slot > 0:
            var ultimate_ratio := clampf(float(hero["ultimate_charge"]) / world.ULTIMATE_MAX, 0.0, 1.0)
            var ultimate_ready := ultimate_ratio >= 1.0
            draw_rect(Rect2(pos + Vector2(-24.0, -23.0), Vector2(48.0, 4.0)), Color("#302333"))
            draw_rect(Rect2(pos + Vector2(-24.0, -23.0), Vector2(48.0 * ultimate_ratio, 4.0)), Color("#ff5d91"))
            if ultimate_ready:
                var ultimate_pulse := 37.0 + sin(float(world.tick) * 0.20 + slot) * 2.5
                draw_arc(pos, ultimate_pulse, 0.0, TAU, 32, Color(Color("#ff5d91"), 0.72), 3.0)
                draw_rect(Rect2(pos + Vector2(28.0, -34.0), Vector2(36.0, 17.0)), Color("#ff5d91"))
                draw_string(ThemeDB.fallback_font, pos + Vector2(30.0, -21.0), "ULT", HORIZONTAL_ALIGNMENT_CENTER, 32.0, 10, Color.WHITE)
        draw_string(ThemeDB.fallback_font, pos + Vector2(-8.0, 7.0), str(slot + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color.BLACK)
        draw_string(ThemeDB.fallback_font, pos + Vector2(-88.0, 50.0), "P%d  %s · %s" % [slot + 1, hero["equipment"]["character_name"], hero["equipment"]["name"]], HORIZONTAL_ALIGNMENT_CENTER, 176.0, 12, Color.WHITE)

func _draw_safe_zone() -> void:
    var center: Vector2 = world.safe_zone_center
    var radius: float = maxf(8.0, float(world.safe_zone_radius))
    var target_radius: float = maxf(8.0, float(world.safe_zone_target_radius))
    var outer := maxf(world.ARENA_SIZE.x, world.ARENA_SIZE.y)
    var mid := (radius + outer) * 0.5
    var width := maxf(12.0, outer - radius)
    draw_arc(center, mid, 0.0, TAU, 96, Color(0.62, 0.05, 0.12, 0.34), width)
    draw_circle(center, radius, Color(0.18, 0.92, 0.58, 0.045))
    var ring := Color("#ff4f68") if bool(world.safe_zone_shrinking) else Color("#70e7ff")
    var pulse := 6.0 + (2.0 if bool(world.safe_zone_shrinking) else 0.0) + sin(float(world.tick) * 0.12) * 1.2
    draw_arc(center, radius, 0.0, TAU, 96, ring, pulse)
    if bool(world.safe_zone_shrinking) or absf(target_radius - radius) > 4.0:
        draw_arc(center, target_radius, 0.0, TAU, 72, Color("#ffd166", 0.62), 3.0)
    var label := "SHRINKING" if bool(world.safe_zone_shrinking) else "SAFE ZONE"
    draw_string(ThemeDB.fallback_font, center + Vector2(-90.0, -radius - 18.0), "%s  %d" % [label, roundi(radius)], HORIZONTAL_ALIGNMENT_CENTER, 180.0, 14, Color(ring, 0.92))
