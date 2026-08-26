extends RefCounted
## 스냅샷 키는 SnapContract 한곳. 패킹/언팩이 PLAYER_KEYS 를 그대로 쓴다.

const SnapContract := preload("res://games/dagul/net/snap_contract.gd")

func run(t) -> void:
	_pack_emits_every_player_key(t)
	_player_roundtrip(t)
	_header_keys(t)

func _pack_emits_every_player_key(t) -> void:
	var packed := SnapContract.pack_player(_sample_hero(), false, 7)
	t.check("플레이어 키 개수가 계약과 같다", packed.size() == SnapContract.PLAYER_KEYS.size())
	for key in SnapContract.PLAYER_KEYS:
		t.check("pack 에 %s" % key, packed.has(key))

func _player_roundtrip(t) -> void:
	var packed := SnapContract.pack_player(_sample_hero(), true, 4)
	var hero := SnapContract.unpack_player(packed, {}, 2, 20.0)
	t.check("hp 왕복", is_equal_approx(float(hero["hp"]), 204.0))
	t.check("max_hp 왕복", is_equal_approx(float(hero["max_hp"]), 176.0))
	t.check("mag 왕복", int(hero["mag"]) == 7)
	t.check("magMax → equipment.mag_size", int(hero["equipment"].get("mag_size", 0)) == 18)
	t.check("ult 왕복", is_equal_approx(float(hero["ultimate_charge"]), 55.0))
	t.check("animal 왕복", int(hero["animal"]) == 2)
	t.check("emote 왕복", int(hero["emote"]) == 2)
	t.check("emoteTime 왕복", is_equal_approx(float(hero["emote_time"]), 1.5))
	t.check("cpu 왕복", bool(hero["cpu"]) == true)
	t.check("ack 는 와이어에만 있다", int(packed[SnapContract.P_ACK]) == 4)

func _header_keys(t) -> void:
	var world := _header_world()
	var header := SnapContract.pack_header(world)
	t.check("header tick", int(header[SnapContract.TICK]) == 12)
	t.check("header zoneR", is_equal_approx(float(header[SnapContract.ZONE_R]), 3304.0))
	t.check("header zoneCX", is_equal_approx(float(header[SnapContract.ZONE_CX]), 3920.0))
	t.check("header wantedSlot", int(header[SnapContract.WANTED_SLOT]) == 3)
	t.check("header mapId", str(header["mapId"]) == "island_2x2")
	t.check("header mapCols", int(header["mapCols"]) == 2)
	t.check("header mapRows", int(header["mapRows"]) == 2)
	t.check("header cellW", is_equal_approx(float(header["cellW"]), 2800.0))
	t.check("header cellH", is_equal_approx(float(header["cellH"]), 1700.0))

func _sample_hero() -> Dictionary:
	return {
		"slot": 2,
		"pos": Vector2(3920.0, 2380.0),
		"aim": Vector2.RIGHT,
		"hp": 204.0,
		"max_hp": 176.0,
		"alive": true,
		"display_name": "게스트",
		"equipment": {"name": "GLOCK 18", "character_name": "게스트", "mag_size": 18},
		"mag": 7,
		"reload_left": 0.0,
		"ultimate_charge": 55.0,
		"animal": 2,
		"medkits": 1,
		"kills": 1,
		"emote": 2,
		"emote_time": 1.5,
		"parked": false,
	}

func _header_world() -> RefCounted:
	var w := HeaderWorld.new()
	w.tick = 12
	w.match_time = 1.0
	w.result = &"playing"
	w.winner_slot = -1
	w.safe_zone_radius = 3304.0
	w.safe_zone_shrinking = false
	w.safe_zone_center = Vector2(3920.0, 2380.0)
	w.safe_zone_phase = 0
	w.start_countdown = 0.0
	w.wanted_slot = 3
	w.mode = "full"
	w.play_map = preload("res://games/dagul/sim/play_map.gd").island_2x2()
	return w

class HeaderWorld extends RefCounted:
	var tick: int = 0
	var match_time: float = 0.0
	var result: StringName = &"playing"
	var winner_slot: int = -1
	var safe_zone_radius: float = 0.0
	var safe_zone_shrinking: bool = false
	var safe_zone_center: Vector2 = Vector2.ZERO
	var safe_zone_phase: int = 0
	var start_countdown: float = 0.0
	var wanted_slot: int = -1
	var mode: String = "classic"
	var play_map = null
