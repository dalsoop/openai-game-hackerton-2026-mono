extends RefCounted
## 게스트 NetWorld 가 호스트 아레나(7840x4760)와 같은 좌표계를 쓰는지.
## 회귀: 옛 ISLAND_RADIUS=402 클램프가 클라이언트를 맵 구석 존 경계에 가뒀다.

const NetWorldScript := preload("res://games/dagul/net/net_world.gd")
const ArenaGeo := preload("res://games/dagul/sim/arena_geometry.gd")
const SnapContract := preload("res://games/dagul/net/snap_contract.gd")
const Parser := preload("res://games/dagul/net/net_snap_parser.gd")

func run(t) -> void:
	t.check("게스트 아레나 크기가 시뮬과 같다", NetWorldScript.ARENA_SIZE == ArenaGeo.ARENA_SIZE)
	t.check("게스트 아레나 중심이 시뮬과 같다", NetWorldScript.ARENA_CENTER == ArenaGeo.ARENA_CENTER)
	_prediction_stays_on_full_map(t)
	_snap_hp_and_mag(t)
	_peer_fire_follows_aim(t)
	_guest_bullets_keep_own_velocity(t)
	_local_fire_shake_decays(t)
	_new_snap_bullet_emits_gun_fire(t)
	_interp_velocity_matches_tick_span(t)
	_same_snap_present_skips_reapply(t)
	_events_snap_gun_fire_once(t)
	_events_snap_skips_bullet_infer(t)
	_legacy_snap_still_infers_gun_fire(t)
	_effects_keep_local_prefix(t)

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
	var parsed: Array = Parser.parse_bullets(next, prev, NetWorldScript.snap_per_sec(0.0, 1.0))
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

func _same_snap_present_skips_reapply(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.effects.append({
		"kind": &"death_burst",
		"pos": Vector2.ZERO,
		"radius": 10.0,
		"time": 1.0,
		"max_time": 1.0,
		"color": Color.WHITE,
		"direction": Vector2.RIGHT,
		"label": "",
	})
	var first := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	first[SnapContract.TICK] = 30
	var second := first.duplicate(true)
	second[SnapContract.TICK] = 33
	nw.push_snap(first)
	nw.push_snap(second)
	var time_after_push := float(nw.effects[0]["time"])
	nw.present(1.0 / 60.0)
	var time_after_apply := float(nw.effects[0]["time"])
	var events_after_apply: int = nw.event_log.events.size()
	nw.present(1.0 / 60.0)
	nw.present(1.0 / 60.0)
	t.check("첫 present 는 apply 해서 이펙트가 줄었다", time_after_apply < time_after_push)
	t.check("같은 스냅 재present 는 이펙트를 더 깎지 않는다", is_equal_approx(float(nw.effects[0]["time"]), time_after_apply))
	t.check("같은 스냅 재present 는 이벤트 로그를 늘리지 않는다", nw.event_log.events.size() == events_after_apply)


func _gun_fire_count(nw) -> int:
	var n := 0
	for ev in nw.event_log.events:
		if StringName(ev.get("type", &"")) == &"gun_fire":
			n += 1
	return n

func _gun_fire_equipment(nw) -> String:
	for ev in nw.event_log.events:
		if StringName(ev.get("type", &"")) != &"gun_fire":
			continue
		return str((ev.get("data", {}) as Dictionary).get("equipment", ""))
	return ""

func _local_fx(kind: StringName) -> Dictionary:
	return {
		"kind": kind,
		"pos": Vector2.ZERO,
		"radius": 10.0,
		"time": 1.0,
		"max_time": 1.0,
		"color": Color.WHITE,
		"direction": Vector2.RIGHT,
		"label": "",
	}

func _events_snap_gun_fire_once(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	var snap := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	snap[SnapContract.EVENTS] = [{
		"t": 12, "k": "gun_fire", "a": 0, "b": -1,
		"d": {"equipment": "glock"},
	}]
	nw.push_snap(snap)
	nw.present(1.0 / 60.0)
	nw.present(1.0 / 60.0)
	nw.present(1.0 / 60.0)
	t.check("events 스냅 gun_fire 는 1회", _gun_fire_count(nw) == 1)
	t.check("서버 gun_fire equipment 를 유지한다", _gun_fire_equipment(nw) == "glock")

func _events_snap_skips_bullet_infer(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	var first := _center_snap(3920.0, 2380.0, 176.0, 18, 18)
	first[SnapContract.EVENTS] = []
	first[SnapContract.BULLETS] = []
	nw.push_snap(first)
	nw.present(1.0 / 60.0)
	var second := first.duplicate(true)
	second[SnapContract.TICK] = 13
	second[SnapContract.EVENTS] = []
	second[SnapContract.BULLETS] = [{
		SnapContract.B_ID: 4,
		SnapContract.B_X: 4000.0, SnapContract.B_Y: 2380.0,
		SnapContract.B_VX: 900.0, SnapContract.B_VY: 0.0,
		SnapContract.B_OWNER: 0,
	}]
	nw.push_snap(second)
	nw.present(1.0 / 60.0)
	t.check("events 채널이면 신규 탄 역추정 gun_fire 가 없다", _gun_fire_count(nw) == 0)

func _legacy_snap_still_infers_gun_fire(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	var first := _center_snap(3920.0, 2380.0, 176.0, 18, 18)
	first[SnapContract.BULLETS] = []
	t.check("구 스냅은 EVENTS 키가 없다", not first.has(SnapContract.EVENTS))
	nw.push_snap(first)
	nw.present(1.0 / 60.0)
	var second := first.duplicate(true)
	second[SnapContract.TICK] = 14
	second[SnapContract.BULLETS] = [{
		SnapContract.B_ID: 8,
		SnapContract.B_X: 4000.0, SnapContract.B_Y: 2380.0,
		SnapContract.B_VX: 900.0, SnapContract.B_VY: 0.0,
		SnapContract.B_OWNER: 0,
	}]
	nw.push_snap(second)
	nw.present(1.0 / 60.0)
	t.check("구 스냅은 신규 탄 역추정 gun_fire 를 유지한다", _gun_fire_count(nw) == 1)

func _effects_keep_local_prefix(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.effects.append(_local_fx(&"local_muzzle"))
	nw.effects.append(_local_fx(&"death_burst"))
	var snap := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	snap[SnapContract.EFFECTS] = [{
		"k": "hit", "x": 3.0, "y": 4.0, "r": 12.0, "t": 0.4, "maxT": 0.4,
	}]
	nw.push_snap(snap)
	var kinds: Array[String] = []
	for fx in nw.effects:
		kinds.append(str(fx.get("kind", "")))
	t.check("서버 이펙트가 들어간다", kinds.has("hit"))
	t.check("local_ 접두 이펙트는 산다", kinds.has("local_muzzle"))
	t.check("서버 교체 시 비로컬 클라 이펙트는 빠진다", not kinds.has("death_burst"))

func _interp_velocity_matches_tick_span(t) -> void:
	var phys := 300.0
	var v1 := _remote_lerp_vel_x(1, phys)
	var v3 := _remote_lerp_vel_x(3, phys)
	t.check("틱 간격 1(60Hz 스냅) 유도 속도가 물리 속도와 같다", is_equal_approx(v1, phys))
	t.check("틱 간격 3(20Hz 스냅) 유도 속도가 물리 속도와 같다", is_equal_approx(v3, phys))
	t.check("틱 간격이 달라도 유도 속도가 같다", is_equal_approx(v1, v3))
	var u1 := _unpack_vel_x(1, phys)
	var u3 := _unpack_vel_x(3, phys)
	t.check("언팩 간격 1 속도가 물리 속도와 같다", is_equal_approx(u1, phys))
	t.check("언팩 간격 3 속도가 물리 속도와 같다", is_equal_approx(u3, phys))

func _unpack_vel_x(tick_span: int, phys_speed: float) -> float:
	var old := {"pos": Vector2(100.0, 50.0)}
	var dx := phys_speed * float(tick_span) / NetWorldScript.TICK_RATE
	var packed := {
		SnapContract.P_SLOT: 0,
		SnapContract.P_X: 100.0 + dx,
		SnapContract.P_Y: 50.0,
		SnapContract.P_ALIVE: true,
	}
	var rate := NetWorldScript.snap_per_sec(0.0, float(tick_span))
	var hero := SnapContract.unpack_player(packed, old, 0, rate)
	return Vector2(hero["vel"]).x

func _remote_lerp_vel_x(tick_span: int, phys_speed: float) -> float:
	var nw = NetWorldScript.new()
	nw.local_slot = 1
	var x0 := 2000.0
	var y := 2380.0
	var t0 := 30
	var dx := phys_speed * float(tick_span) / NetWorldScript.TICK_RATE
	var first := _center_snap(x0, y, 176.0, 7, 18)
	first[SnapContract.TICK] = t0
	var second := _center_snap(x0 + dx, y, 176.0, 7, 18)
	second[SnapContract.TICK] = t0 + tick_span
	nw.push_snap(first)
	nw.push_snap(second)
	nw.present(1.0 / 60.0)
	if nw.heroes.is_empty():
		return -1.0
	return Vector2(nw.heroes[0]["vel"]).x

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
