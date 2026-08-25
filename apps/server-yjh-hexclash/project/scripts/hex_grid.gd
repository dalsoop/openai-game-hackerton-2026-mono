class_name HexGrid
extends RefCounted

const HEX_SIZE := 32.0
const SQRT3 := 1.7320508

static func axial_to_pixel(q: int, r: int) -> Vector2:
	var x := HEX_SIZE * (SQRT3 * float(q) + SQRT3 / 2.0 * float(r))
	var y := HEX_SIZE * (1.5 * float(r))
	return Vector2(x, y)

static func pixel_to_axial(px: Vector2) -> Vector2i:
	var q := (SQRT3 / 3.0 * px.x - 1.0 / 3.0 * px.y) / HEX_SIZE
	var r := (2.0 / 3.0 * px.y) / HEX_SIZE
	return axial_round(q, r)

static func axial_round(fq: float, fr: float) -> Vector2i:
	var fs := -fq - fr
	var q := roundi(fq)
	var r := roundi(fr)
	var s := roundi(fs)
	var dq := absf(float(q) - fq)
	var dr := absf(float(r) - fr)
	var ds := absf(float(s) - fs)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	return Vector2i(q, r)

static func neighbors(coord: Vector2i) -> Array[Vector2i]:
	var q := coord.x
	var r := coord.y
	return [
		Vector2i(q + 1, r), Vector2i(q - 1, r),
		Vector2i(q, r + 1), Vector2i(q, r - 1),
		Vector2i(q + 1, r - 1), Vector2i(q - 1, r + 1)
	]

static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq := absi(a.x - b.x)
	var dr := absi(a.y - b.y)
	var ds := absi((-a.x - a.y) - (-b.x - b.y))
	return maxi(dq, maxi(dr, ds))

static func hex_corners(center: Vector2) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in 6:
		var angle := TAU / 6.0 * float(i) - PI / 6.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * HEX_SIZE)
	return pts

static func generate_map(radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		var r1 := maxi(-radius, -q - radius)
		var r2 := mini(radius, -q + radius)
		for r in range(r1, r2 + 1):
			cells.append(Vector2i(q, r))
	return cells
