extends Node2D

var world: HexWorld = null
var hover_cell := Vector2i(-999, -999)
var local_player := 0
var camera_offset := Vector2.ZERO

func _draw() -> void:
	if world == null:
		return
	var vp := get_viewport_rect().size
	draw_rect(Rect2(-vp, vp * 3.0), Color(0.06, 0.07, 0.09))
	var center := vp * 0.5 + camera_offset
	_draw_grid(center)
	_draw_hover(center)

func _draw_grid(center: Vector2) -> void:
	for coord in world.cells:
		var cell: Dictionary = world.cells[coord]
		var px := HexGrid.axial_to_pixel(coord.x, coord.y) + center
		var corners := HexGrid.hex_corners(px)
		var owner := int(cell["owner"])
		var pulse := float(cell["pulse"])
		var base_color: Color
		if owner >= 0 and owner < HexWorld.PLAYER_COUNT:
			base_color = Color(world.players[owner]["color"])
			if bool(cell["fortified"]):
				base_color = base_color.lightened(0.18)
		else:
			base_color = Color(0.13, 0.12, 0.11, 1.0)
		if pulse > 0.0:
			base_color = base_color.lightened(pulse * 0.35)
		draw_colored_polygon(corners, base_color)
		var border_color := Color(0.2, 0.2, 0.2, 0.6) if owner < 0 else Color(0.05, 0.05, 0.05, 0.7)
		draw_polyline(corners, border_color, 1.0, true)
		if bool(cell.get("fortified", false)) and owner >= 0:
			_draw_fortify_mark(px)

func _draw_fortify_mark(center: Vector2) -> void:
	var s := HexGrid.HEX_SIZE * 0.18
	var pts := PackedVector2Array([
		center + Vector2(0, -s), center + Vector2(s, 0),
		center + Vector2(0, s), center + Vector2(-s, 0)
	])
	draw_colored_polygon(pts, Color(1, 1, 1, 0.35))

func _draw_hover(center: Vector2) -> void:
	if hover_cell == Vector2i(-999, -999):
		return
	if not world.cells.has(hover_cell):
		return
	var px := HexGrid.axial_to_pixel(hover_cell.x, hover_cell.y) + center
	var corners := HexGrid.hex_corners(px)
	var can := _can_claim(hover_cell)
	var color := Color(1, 1, 1, 0.7) if can else Color(1, 0.3, 0.3, 0.35)
	draw_polyline(corners, color, 2.5, true)
	if can:
		var cost := _claim_cost(hover_cell)
		var font := ThemeDB.fallback_font
		draw_string(font, px + Vector2(-12, 5), "-%d" % int(cost), HORIZONTAL_ALIGNMENT_CENTER, 24, 11, Color(1, 1, 1, 0.8))

func _can_claim(coord: Vector2i) -> bool:
	if not world.cells.has(coord):
		return false
	var cell: Dictionary = world.cells[coord]
	var owner := int(cell["owner"])
	if owner == local_player:
		return not bool(cell["fortified"]) and float(world.players[local_player]["energy"]) >= HexWorld.FORTIFY_COST
	var adjacent := false
	for n in HexGrid.neighbors(coord):
		if world.cells.has(n) and int(world.cells[n]["owner"]) == local_player:
			adjacent = true
			break
	if not adjacent:
		return false
	return float(world.players[local_player]["energy"]) >= _claim_cost(coord)

func _claim_cost(coord: Vector2i) -> float:
	var cell: Dictionary = world.cells[coord]
	var owner := int(cell["owner"])
	if owner == local_player:
		return HexWorld.FORTIFY_COST
	var cost := HexWorld.CLAIM_COST_EMPTY if owner == -1 else HexWorld.CLAIM_COST_ENEMY
	if bool(cell["fortified"]) and owner != -1:
		cost += HexWorld.FORTIFY_DEFENSE_BONUS
	return cost

func screen_to_hex(screen_pos: Vector2) -> Vector2i:
	var center := get_viewport_rect().size * 0.5 + camera_offset
	return HexGrid.pixel_to_axial(screen_pos - center)
