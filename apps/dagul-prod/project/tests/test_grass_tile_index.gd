extends RefCounted
## 잔디 타일 인덱스는 (tile_x, tile_y) 결정론 — 컬링 시작 오프셋과 무관.

const RenderEnvScript := preload("res://games/dagul/render/render_environment.gd")

func run(t) -> void:
	var env = RenderEnvScript.new(Node2D.new())
	var cell := 192.0
	var tile_x_a := RenderEnvScript.tile_coord(384.0, cell)
	var tile_x_b := RenderEnvScript.tile_coord(575.9, cell)
	var tile_y_a := RenderEnvScript.tile_coord(768.0, cell)
	var tile_y_b := RenderEnvScript.tile_coord(959.1, cell)
	t.check("cull start offsets map to same tile_x", tile_x_a == tile_x_b)
	t.check("cull start offsets map to same tile_y", tile_y_a == tile_y_b)
	t.check("same tile coords same grass index", env._grass_tile_index(tile_x_a, tile_y_a, 8) == env._grass_tile_index(tile_x_b, tile_y_b, 8))
	t.check("same tile coords same flower index", env._grass_tile_index(tile_x_a, tile_y_a, 16) == env._grass_tile_index(tile_x_b, tile_y_b, 16))
	t.check("tile_coord is floori", RenderEnvScript.tile_coord(400.0, cell) == 2)
	t.check("cell start and interior same tile", RenderEnvScript.tile_coord(0.0, cell) == RenderEnvScript.tile_coord(191.9, cell))
	t.check("explicit (2,3) stable", env._grass_tile_index(2, 3, 8) == env._grass_tile_index(2, 3, 8))
	var vis_a := Rect2(400.0, 400.0, 800.0, 450.0)
	var vis_b := Rect2(410.0, 410.0, 800.0, 450.0)
	var vis_c := Rect2(600.0, 400.0, 800.0, 450.0)
	var tiles_a := RenderEnvScript.vis_tile_rect(vis_a, cell)
	var tiles_b := RenderEnvScript.vis_tile_rect(vis_b, cell)
	var tiles_c := RenderEnvScript.vis_tile_rect(vis_c, cell)
	t.check("camera move inside tile keeps rect", tiles_a == tiles_b)
	t.check("crossing tile changes rect", tiles_a != tiles_c)
