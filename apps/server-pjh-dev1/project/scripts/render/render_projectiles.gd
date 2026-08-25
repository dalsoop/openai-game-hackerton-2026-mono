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
