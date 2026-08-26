extends RefCounted
## 맵은 타일 격자. 픽셀 크기는 파생값이다.

const PlayMapScript := preload("res://games/dagul/sim/play_map.gd")
const ArenaGeo := preload("res://games/dagul/sim/arena_geometry.gd")

func run(t) -> void:
	var m = PlayMapScript.island_2x2()
	t.check("기본 격자는 2x2", m.cols == 2 and m.rows == 2)
	t.check("월드 크기는 격자에서 나온다", m.world_size() == Vector2(7840.0, 4760.0))
	t.check("월드 중심도 격자에서 나온다", m.world_center() == Vector2(3920.0, 2380.0))
	t.check("시뮬 상수와 파생 크기가 같다", m.world_size() == ArenaGeo.ARENA_SIZE)
	t.check("타일 origin 은 4칸", m.tile_origins().size() == 4)
	_wire_roundtrip(t)
	_old_island_is_1x1(t)

func _wire_roundtrip(t) -> void:
	var packed: Dictionary = PlayMapScript.island_2x2().to_wire()
	t.check("와이어에 mapId", packed.has("mapId"))
	t.check("와이어에 mapCols", int(packed["mapCols"]) == 2)
	var restored = PlayMapScript.from_wire(packed)
	t.check("왕복 크기가 같다", restored.world_size() == Vector2(7840.0, 4760.0))

func _old_island_is_1x1(t) -> void:
	var old = PlayMapScript.from_wire({
		"mapId": "island_1x1",
		"mapCols": 1,
		"mapRows": 1,
		"cellW": 804.0,
		"cellH": 804.0,
		"cellScale": 1.0,
		"mapMargin": 0.0,
	})
	t.check("옛 섬은 한 칸", old.world_size() == Vector2(804.0, 804.0))
	var clamped: Vector2 = old.clamp_point(Vector2(3920.0, 2380.0), 20.0)
	t.check("옛 섬 클램프는 작은 칸 안", clamped.x <= 804.0 and clamped.y <= 804.0)
