extends RefCounted
## 게스트 NetWorld 가 호스트 아레나(7840x4760)와 같은 좌표계를 쓰는지.
## 회귀: 옛 ISLAND_RADIUS=402 클램프가 클라이언트를 맵 구석 존 경계에 가뒀다.

const NetWorldScript := preload("res://games/dagul/net/net_world.gd")
const ArenaGeo := preload("res://games/dagul/sim/arena_geometry.gd")
const WorldScript := preload("res://games/dagul/sim/game_world.gd")
const SnapContract := preload("res://games/dagul/net/snap_contract.gd")
const Parser := preload("res://games/dagul/net/net_snap_parser.gd")

func run(t) -> void:
	t.check("게스트 아레나 크기가 시뮬과 같다", NetWorldScript.ARENA_SIZE == ArenaGeo.ARENA_SIZE)
	t.check("게스트 아레나 중심이 시뮬과 같다", NetWorldScript.ARENA_CENTER == ArenaGeo.ARENA_CENTER)
	_prediction_stays_on_full_map(t)
	_snap_hp_and_mag(t)
	_peer_reload_reaches_host(t)
	_peer_fire_follows_aim(t)
	_guest_bullets_keep_own_velocity(t)
	_local_fire_shake_decays(t)
	_new_snap_bullet_emits_gun_fire(t)

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

func _peer_fire_follows_aim(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 1
	nw.push_snap({
		SnapContract.TICK: 4,
		SnapContract.TIME: 0.2,
		SnapContract.RESULT: "playing",
		SnapContract.ZONE_R: 3304.0,
		SnapContract.PLAYERS: [{
			SnapContract.P_SLOT: 1,
			SnapContract.P_NAME: "게스트",
			SnapContract.P_X: 4000.0, SnapContract.P_Y: 2380.0,
			SnapContract.P_AIM_X: 4120.0, SnapContract.P_AIM_Y: 2380.0,
			SnapContract.P_HP: 176.0, SnapContract.P_MAX_HP: 176.0,
			SnapContract.P_ALIVE: true, SnapContract.P_MAG: 17, SnapContract.P_MAG_MAX: 18,
			SnapContract.P_KILLS: 0, SnapContract.P_ACK: 2,
		}],
		SnapContract.BULLETS: [{
			SnapContract.B_ID: 9,
			SnapContract.B_X: 4030.0, SnapContract.B_Y: 2380.0,
			SnapContract.B_VX: 900.0, SnapContract.B_VY: 0.0,
			SnapContract.B_OWNER: 1,
		}],
	})
	nw.present(1.0 / 60.0)
	t.check("게스트 탄이 권위 스냅에 생긴다", nw.projectiles.size() > 0)
	if nw.projectiles.is_empty():
		return
	var mine: Dictionary = nw.projectiles[0]
	t.check("게스트 탄의 주인이 맞다", int(mine.get("owner", -1)) == 1)
	t.check("게스트 탄이 조준 쪽으로 간다", Vector2(mine.get("vel", Vector2.ZERO)).x > 0.0)

func _guest_bullets_keep_own_velocity(t) -> void:
	var prev: Array = [{
		"id": 1, "pos": Vector2(100.0, 100.0), "vel": Vector2(-800.0, 0.0), "owner": 0,
	}]
	var next: Array = [
		{"id": 1, "x": 60.0, "y": 100.0, "vx": -800.0, "vy": 0.0, "owner": 0},
		{"id": 2, "x": 110.0, "y": 104.0, "vx": 900.0, "vy": 0.0, "owner": 1},
	]
	var parsed: Array = Parser.parse_bullets(next, prev, 20.0)
	t.check("탄 두 발이 유지된다", parsed.size() == 2)
	if parsed.size() < 2:
		return
	var fresh: Dictionary = parsed[1]
	t.check("새 탄이 이웃 속도를 훔치지 않는다", Vector2(fresh["vel"]).x > 0.0)
	t.check("새 탄 id 가 유지된다", int(fresh.get("id", -1)) == 2)

func _new_snap_bullet_emits_gun_fire(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	var first := _center_snap(3920.0, 2380.0, 176.0, 18, 18)
	first[SnapContract.BULLETS] = []
	nw.push_snap(first)
	nw.present(1.0 / 60.0)
	var before: int = nw.event_log.events.size()
	var second := first.duplicate(true)
	second[SnapContract.TICK] = 13
	second[SnapContract.BULLETS] = [{
		SnapContract.B_ID: 4,
		SnapContract.B_X: 4000.0, SnapContract.B_Y: 2380.0,
		SnapContract.B_VX: 900.0, SnapContract.B_VY: 0.0,
		SnapContract.B_OWNER: 0,
	}]
	nw.push_snap(second)
	nw.present(1.0 / 60.0)
	var fired := false
	for ev in nw.event_log.events:
		if StringName(ev.get("type", &"")) == &"gun_fire" and int(ev.get("actor_id", -1)) == 0:
			fired = true
	t.check("첫 스냅 탄은 발사 이벤트가 없다", before == 0)
	t.check("새 스냅 탄이 gun_fire 를 남긴다", fired)

func _local_fire_shake_decays(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_fire_shake = 3
	nw.present(1.0 / 60.0)
	t.check("로컬 발사 흔들림이 줄어든다", nw.local_fire_shake == 2)

func _center_snap(x: float, y: float, max_hp: float, mag: int, mag_max: int) -> Dictionary:
	return {
		SnapContract.TICK: 12,
		SnapContract.TIME: 1.0,
		SnapContract.RESULT: "playing",
		SnapContract.ZONE_R: 3304.0,
		SnapContract.ZONE_CX: 3920.0,
		SnapContract.ZONE_CY: 2380.0,
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
