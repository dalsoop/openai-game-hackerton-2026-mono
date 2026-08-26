extends RefCounted
## 아레나 기하 순수 로직 — 경계 클램프·타일링·커버 판별·선 차단.

const ArenaGeometryScript := preload("res://games/dagul/sim/arena_geometry.gd")

func _world_with(covers: Array) -> Dictionary:
	return {"covers": covers}

func run(t) -> void:
	var geo = ArenaGeometryScript.new(null)

	var clamped: Vector2 = geo.clamp_arena_point(Vector2(-500.0, 99999.0), 20.0)
	t.check("clamp x lower bound", is_equal_approx(clamped.x, 104.0 + 20.0))
	t.check("clamp y upper bound", is_equal_approx(clamped.y, 4760.0 - 104.0 - 20.0))
	var center: Vector2 = geo.clamp_arena_point(Vector2(3920.0, 2380.0), 20.0)
	t.check("center passes through", center == Vector2(3920.0, 2380.0))

	var tiled: Array = geo.tiled_points([Vector2(100.0, 50.0)])
	t.check("tiled_points 4 tiles", tiled.size() == 4)
	# 루프 순서: tile_x 외부, tile_y 내부 — [1]은 (0,1) 타일
	var expected_tile1 := Vector2(100.0, 50.0) * 1.4 + Vector2(0.0, 1700.0) * 1.4
	t.check("tiled_points tile offset", tiled[1] == expected_tile1)

	# 커버: 중심 (500,500) 반경 50 — 원형 커버 딕셔너리
	var covers := [{"rect": Rect2(450.0, 450.0, 100.0, 100.0)}]
	var geo_cover = ArenaGeometryScript.new(_world_with(covers))
	t.check("point inside cover", geo_cover.point_in_cover(Vector2(500.0, 500.0)) == true)
	t.check("point outside cover", geo_cover.point_in_cover(Vector2(800.0, 800.0)) == false)
	t.check("padding expands cover", geo_cover.point_in_cover(Vector2(570.0, 500.0), 40.0) == true)

	t.check("line through cover blocked", geo_cover.line_blocked(Vector2(300.0, 500.0), Vector2(700.0, 500.0)) == true)
	t.check("line far from cover clear", geo_cover.line_blocked(Vector2(300.0, 900.0), Vector2(700.0, 900.0)) == false)

	# 커버 침투 이동: 후보가 커버 원(반경+패딩) 안에 떨어지면 그 축은 차단된다
	var blocked = ArenaGeometryScript.new(_world_with([{"rect": Rect2(590.0, 490.0, 20.0, 20.0)}]))
	var resolved: Vector2 = blocked.resolve_cover_motion(Vector2(600.0, 600.0), Vector2(0.0, -120.0))
	t.check("cover blocks y motion", is_equal_approx(resolved.y, 600.0))
