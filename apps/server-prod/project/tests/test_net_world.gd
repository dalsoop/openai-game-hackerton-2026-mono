extends RefCounted
## 게스트 NetWorld 가 호스트 아레나(7840x4760)와 같은 좌표계를 쓰는지.
## 회귀: 옛 ISLAND_RADIUS=402 클램프가 클라이언트를 맵 구석 존 경계에 가뒀다.

const NetWorldScript := preload("res://games/dagul/net/net_world.gd")
const ArenaGeo := preload("res://games/dagul/sim/arena_geometry.gd")
const WorldScript := preload("res://games/dagul/sim/game_world.gd")
const SnapContract := preload("res://games/dagul/net/snap_contract.gd")

func run(t) -> void:
	var nw_defaults = NetWorldScript.new()
	t.check("게스트 아레나 크기가 시뮬과 같다", nw_defaults.ARENA_SIZE == ArenaGeo.ARENA_SIZE)
	t.check("게스트 아레나 중심이 시뮬과 같다", nw_defaults.ARENA_CENTER == ArenaGeo.ARENA_CENTER)
	_prediction_stays_on_full_map(t)
	_snap_hp_and_mag(t)
	_peer_reload_reaches_host(t)
	_host_map_overrides_old_island(t)

func _prediction_stays_on_full_map(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.push_snap(_center_snap(3920.0, 2380.0, 176.0, 7, 18))
	nw.present(1.0 / 60.0)
	t.check("스냅이 게스트 히어로를 만든다", nw.heroes.size() == 1)
	if nw.heroes.is_empty():
		return
	nw.predict_local(Vector2.ZERO, false, Vector2(4020.0, 2380.0), 1.0 / 60.0)
	var pos := Vector2(nw.heroes[0]["pos"])
	t.check("예측이 옛 섬으로 순간이동하지 않는다", pos.distance_to(Vector2(3920.0, 2380.0)) < 8.0)
	nw.predict_local(Vector2.RIGHT, false, Vector2(4100.0, 2380.0), 1.0 / 60.0)
	var moved := Vector2(nw.heroes[0]["pos"])
	t.check("게스트가 맵 중앙에서 이동한다", moved.x > pos.x + 2.0)
	t.check("이동 후에도 풀맵 안이다", moved.x > 3000.0)

func _snap_hp_and_mag(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.push_snap(_center_snap(3920.0, 2380.0, 176.0, 7, 18))
	t.check("탄창 스냅 히어로가 있다", nw.heroes.size() == 1)
	if nw.heroes.is_empty():
		return
	var me: Dictionary = nw.heroes[0]
	t.check("스냅 maxHp 가 HUD 분모가 된다", is_equal_approx(float(me["max_hp"]), 176.0))
	t.check("스냅 mag 가 HUD 탄창이 된다", int(me["mag"]) == 7)
	t.check("스냅 magMax 가 장비 탄창이다", int(me["equipment"].get("mag_size", 0)) == 18)

func _peer_reload_reaches_host(t) -> void:
	var world = WorldScript.new(2222)
	world.reset()
	world.local_slot = 0
	world.human_slots[1] = true
	var h: Dictionary = world.heroes[1]
	h["mag"] = 0
	world.heroes[1] = h
	var pos: Vector2 = h["pos"]
	world.peer_commands[1] = {
		"mx": 0.0, "my": 0.0,
		"aimX": pos.x + 10.0, "aimY": pos.y,
		"reload": true,
	}
	world.mov.apply_peer_humans()
	t.check("호스트가 게스트 리로드를 적용한다", float(world.heroes[1]["reload_left"]) > 0.0)

func _host_map_overrides_old_island(t) -> void:
	var PlayMapScript := preload("res://games/dagul/sim/play_map.gd")
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.play_map = PlayMapScript.from_wire({
		"mapId": "island_1x1",
		"mapCols": 1, "mapRows": 1,
		"cellW": 804.0, "cellH": 804.0,
		"cellScale": 1.0, "mapMargin": 0.0,
	})
	t.check("덮기 전 게스트는 옛 섬", is_equal_approx(nw.ARENA_SIZE.x, 804.0))
	nw.push_snap(_center_snap(3920.0, 2380.0, 176.0, 7, 18))
	t.check("호스트 격자가 게스트 옛 섬을 덮는다", is_equal_approx(nw.ARENA_SIZE.x, 7840.0))
	t.check("호스트 격자 높이도 덮인다", is_equal_approx(nw.ARENA_SIZE.y, 4760.0))
	t.check("호스트 중심이 게스트 중심이 된다", nw.ARENA_CENTER == Vector2(3920.0, 2380.0))
	nw.predict_local(Vector2.RIGHT, false, Vector2(4100.0, 2380.0), 1.0 / 60.0)
	var pos := Vector2(nw.heroes[0]["pos"])
	t.check("덮은 뒤에도 풀맵에서 움직인다", pos.x > 3900.0)

func _center_snap(x: float, y: float, max_hp: float, mag: int, mag_max: int) -> Dictionary:
	return {
		SnapContract.TICK: 12,
		SnapContract.TIME: 1.0,
		SnapContract.RESULT: "playing",
		SnapContract.ZONE_R: 3304.0,
		SnapContract.ZONE_CX: 3920.0,
		SnapContract.ZONE_CY: 2380.0,
		"mapId": "island_2x2",
		"mapCols": 2,
		"mapRows": 2,
		"cellW": 2800.0,
		"cellH": 1700.0,
		"cellScale": 1.4,
		"mapMargin": 104.0,
		SnapContract.PLAYERS: [{
			SnapContract.P_SLOT: 0,
			SnapContract.P_NAME: "게스트",
			SnapContract.P_X: x, SnapContract.P_Y: y,
			SnapContract.P_AIM_X: x + 100.0, SnapContract.P_AIM_Y: y,
			SnapContract.P_HP: 204.0,
			SnapContract.P_MAX_HP: max_hp,
			SnapContract.P_ALIVE: true,
			SnapContract.P_WEAPON: "GLOCK 18",
			SnapContract.P_MAG: mag,
			SnapContract.P_MAG_MAX: mag_max,
			SnapContract.P_KILLS: 0,
			SnapContract.P_ACK: 0,
		}],
	}
