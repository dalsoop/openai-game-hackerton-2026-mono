extends RefCounted
## 플레이 공간은 타일 격자로만 정의한다. 월드 크기·중심은 여기서 계산한다.
## 이후 Godot TileMap 이 같은 cols/rows/cell 을 소유하면 된다.

const ID_ISLAND := "island_2x2"
const DEFAULT_CELL := Vector2(2800.0, 1700.0)
const DEFAULT_SCALE := 1.4
const DEFAULT_COLS := 2
const DEFAULT_ROWS := 2
const DEFAULT_MARGIN := 104.0

const WIRE_ID := "mapId"
const WIRE_COLS := "mapCols"
const WIRE_ROWS := "mapRows"
const WIRE_CELL_W := "cellW"
const WIRE_CELL_H := "cellH"
const WIRE_SCALE := "cellScale"
const WIRE_MARGIN := "mapMargin"

var id: String = ID_ISLAND
var cols: int = DEFAULT_COLS
var rows: int = DEFAULT_ROWS
var cell: Vector2 = DEFAULT_CELL
var cell_scale: float = DEFAULT_SCALE
var margin: float = DEFAULT_MARGIN

static func island_2x2():
	return load("res://games/dagul/sim/play_map.gd").new()

func world_size() -> Vector2:
	return Vector2(float(cols) * cell.x, float(rows) * cell.y) * cell_scale

func world_center() -> Vector2:
	return world_size() * 0.5

func tile_origins() -> Array:
	var origins: Array = []
	var scaled: Vector2 = cell * cell_scale
	for tile_x in range(cols):
		for tile_y in range(rows):
			origins.append(Vector2(float(tile_x) * scaled.x, float(tile_y) * scaled.y))
	return origins

func clamp_point(point: Vector2, radius: float) -> Vector2:
	var size := world_size()
	return Vector2(
		clampf(point.x, margin + radius, size.x - margin - radius),
		clampf(point.y, margin + radius, size.y - margin - radius)
	)

func to_wire() -> Dictionary:
	return {
		WIRE_ID: id,
		WIRE_COLS: cols,
		WIRE_ROWS: rows,
		WIRE_CELL_W: cell.x,
		WIRE_CELL_H: cell.y,
		WIRE_SCALE: cell_scale,
		WIRE_MARGIN: margin,
	}

static func from_wire(d: Dictionary):
	var script = load("res://games/dagul/sim/play_map.gd")
	var m = script.new()
	if d.is_empty():
		return m
	if d.has(WIRE_ID):
		m.id = str(d[WIRE_ID])
	if d.has(WIRE_COLS):
		m.cols = maxi(1, int(d[WIRE_COLS]))
	if d.has(WIRE_ROWS):
		m.rows = maxi(1, int(d[WIRE_ROWS]))
	var cell_w := float(d.get(WIRE_CELL_W, m.cell.x))
	var cell_h := float(d.get(WIRE_CELL_H, m.cell.y))
	m.cell = Vector2(cell_w, cell_h)
	if d.has(WIRE_SCALE):
		m.cell_scale = float(d[WIRE_SCALE])
	if d.has(WIRE_MARGIN):
		m.margin = float(d[WIRE_MARGIN])
	return m

static func has_wire(d: Dictionary) -> bool:
	return d.has(WIRE_ID) or d.has(WIRE_COLS) or d.has(WIRE_ROWS)
