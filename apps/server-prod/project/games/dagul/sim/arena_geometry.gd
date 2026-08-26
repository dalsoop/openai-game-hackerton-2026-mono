class_name ArenaGeometry
extends RefCounted

const SOURCE_ARENA_SIZE := Vector2(2800.0, 1700.0)
const ARENA_TILE_SCALE := 1.4
const ARENA_SIZE := Vector2(7840.0, 4760.0)
const ARENA_CENTER := Vector2(3920.0, 2380.0)
const ARENA_MARGIN := 104.0
const SPAWN_HERO_RADIUS_X := 3360.0
const SPAWN_HERO_RADIUS_Y := 1940.0
const SPAWN_CORE_RADIUS_X := 3600.0
const SPAWN_CORE_RADIUS_Y := 2120.0
const HERO_RADIUS := 20.0

var w

func _init(world) -> void:
	w = world

func resolve_cover_motion(old_pos: Vector2, motion: Vector2) -> Vector2:
	var resolved := old_pos
	var x_candidate := resolved + Vector2(motion.x, 0.0)
	if not point_in_cover(x_candidate, HERO_RADIUS):
		resolved.x = x_candidate.x
	var y_candidate := resolved + Vector2(0.0, motion.y)
	if not point_in_cover(y_candidate, HERO_RADIUS):
		resolved.y = y_candidate.y
	return resolved

func _tile_origins() -> Array:
	var origins: Array = []
	for tile_x in range(2):
		for tile_y in range(2):
			origins.append(Vector2(float(tile_x) * SOURCE_ARENA_SIZE.x, float(tile_y) * SOURCE_ARENA_SIZE.y) * ARENA_TILE_SCALE)
	return origins

func tiled_points(source_points: Array) -> Array:
	var points: Array = []
	for origin in _tile_origins():
		for source in source_points:
			points.append(origin + Vector2(source) * ARENA_TILE_SCALE)
	return points

func build_tiled_covers() -> Array[Dictionary]:
	var source_rects: Array[Rect2] = [
		Rect2(1330.0, 590.0, 140.0, 520.0),
		Rect2(930.0, 810.0, 300.0, 70.0),
		Rect2(1570.0, 810.0, 300.0, 70.0),
		Rect2(590.0, 350.0, 230.0, 82.0),
		Rect2(1980.0, 350.0, 230.0, 82.0),
		Rect2(590.0, 1268.0, 230.0, 82.0),
		Rect2(1980.0, 1268.0, 230.0, 82.0),
		Rect2(340.0, 715.0, 82.0, 270.0),
		Rect2(2378.0, 715.0, 82.0, 270.0),
		Rect2(1030.0, 260.0, 120.0, 120.0),
		Rect2(1650.0, 1320.0, 120.0, 120.0)
	]
	var result: Array[Dictionary] = []
	for origin in _tile_origins():
		for source_rect in source_rects:
			result.append({"rect":Rect2(origin + source_rect.position * ARENA_TILE_SCALE, source_rect.size * ARENA_TILE_SCALE)})
	return result

func clamp_arena_point(point: Vector2, radius: float) -> Vector2:
	return Vector2(
		clampf(point.x, ARENA_MARGIN + radius, ARENA_SIZE.x - ARENA_MARGIN - radius),
		clampf(point.y, ARENA_MARGIN + radius, ARENA_SIZE.y - ARENA_MARGIN - radius)
	)

func nudge_out_of_cover(point: Vector2, radius: float) -> Vector2:
	if not point_in_cover(point, radius):
		return point
	var nudged: Vector2 = point
	for step_index in range(24):
		nudged = nudged.move_toward(ARENA_CENTER, 28.0)
		nudged = clamp_arena_point(nudged, radius)
		if not point_in_cover(nudged, radius):
			return nudged
	return clamp_arena_point(ARENA_CENTER, radius)

func cover_radius(cover: Dictionary) -> float:
	var rect: Rect2 = cover["rect"]
	return minf(rect.size.x, rect.size.y) * 0.5

func point_in_cover(point: Vector2, padding: float = 0.0) -> bool:
	for cover in w.covers:
		var rect: Rect2 = cover["rect"]
		if point.distance_to(rect.get_center()) <= cover_radius(cover) + padding:
			return true
	return false

func line_blocked(from: Vector2, to: Vector2) -> bool:
	for cover in w.covers:
		var c: Vector2 = Rect2(cover["rect"]).get_center()
		var r := cover_radius(cover) + 3.0
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(c, from, to)
		if closest.distance_to(c) <= r:
			return true
	return false
