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
	_prediction_freezes_in_countdown(t)
	_same_snap_present_skips_reapply(t)
	_events_snap_gun_fire_once(t)
	_empty_events_still_infer_gun_fire(t)
	_events_and_bullet_do_not_double(t)
	_legacy_snap_still_infers_gun_fire(t)
	_effects_keep_local_prefix(t)
	_effects_missing_key_keeps_existing(t)
	_effects_empty_array_clears_non_local(t)
	_slot_not_array_index(t)
	_dash_pred_moves_then_cools(t)
	_dash_pred_uses_equipment_distance(t)
	_dash_pred_blocked_by_cover(t)
	_dash_pred_ignored_during_cc(t)
	_pred_fire_skips_empty_mag(t)
	_launch_trail_accumulates_and_fades(t)

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


func _wire_bullet(id: int) -> Dictionary:
	return {
		SnapContract.B_ID: id,
		SnapContract.B_X: 4000.0, SnapContract.B_Y: 2380.0,
		SnapContract.B_VX: 900.0, SnapContract.B_VY: 0.0,
		SnapContract.B_OWNER: 0,
	}

func _world_after_new_bullet(second_events: Array):
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	var first := _center_snap(3920.0, 2380.0, 176.0, 18, 18)
	first[SnapContract.EVENTS] = []
	first[SnapContract.BULLETS] = []
	nw.push_snap(first)
	nw.present(1.0 / 60.0)
	var second := first.duplicate(true)
	second[SnapContract.TICK] = 13
	second[SnapContract.EVENTS] = second_events
	second[SnapContract.BULLETS] = [_wire_bullet(4)]
	nw.push_snap(second)
	nw.present(1.0 / 60.0)
	return nw

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

func _empty_events_still_infer_gun_fire(t) -> void:
	var nw = _world_after_new_bullet([])
	t.check("events 가 비면 신규 탄으로 gun_fire 를 역추정한다", _gun_fire_count(nw) == 1)

func _events_and_bullet_do_not_double(t) -> void:
	var nw = _world_after_new_bullet([{
		"t": 13, "k": "gun_fire", "a": 0, "b": -1,
		"d": {"equipment": "burst"},
	}])
	t.check("서버 gun_fire 가 있으면 탄 역추정을 더하지 않는다", _gun_fire_count(nw) == 1)
	t.check("서버 equipment 를 유지한다", _gun_fire_equipment(nw) == "burst")

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
	second[SnapContract.BULLETS] = [_wire_bullet(8)]
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

func _effect_kinds(nw) -> Array[String]:
	var kinds: Array[String] = []
	for fx in nw.effects:
		kinds.append(str(fx.get("kind", "")))
	return kinds

func _effects_missing_key_keeps_existing(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.effects.append(_local_fx(&"local_muzzle"))
	nw.effects.append(_local_fx(&"death_burst"))
	var snap := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	t.check("스냅에 effects 키가 없다", not snap.has(SnapContract.EFFECTS))
	nw.push_snap(snap)
	var kinds := _effect_kinds(nw)
	t.check("키 부재면 서버 교체를 건너뛴다", kinds.has("death_burst"))
	t.check("키 부재면 local_ 도 남는다", kinds.has("local_muzzle"))

func _effects_empty_array_clears_non_local(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.effects.append(_local_fx(&"local_muzzle"))
	nw.effects.append(_local_fx(&"death_burst"))
	var snap := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	snap[SnapContract.EFFECTS] = []
	nw.push_snap(snap)
	var kinds := _effect_kinds(nw)
	t.check("빈 effects 배열은 서버 권위로 비운다", not kinds.has("death_burst"))
	t.check("빈 배열이어도 local_ 접두는 산다", kinds.has("local_muzzle"))

func _slot_not_array_index(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 3
	var snap := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	var player: Dictionary = snap[SnapContract.PLAYERS][0]
	player[SnapContract.P_SLOT] = 3
	player[SnapContract.P_SCORE] = 12.0
	player[SnapContract.P_KILLS] = 2
	nw.push_snap(snap)
	t.check("히어로 1명", nw.heroes.size() == 1)
	if nw.heroes.is_empty():
		return
	t.check("배열[0] 의 slot 은 3", int(nw.heroes[0]["slot"]) == 3)
	var found: Dictionary = nw.hero_at_slot(3)
	t.check("hero_at_slot(3) 이 그 히어로다", int(found.get("slot", -1)) == 3)
	t.check("hero_at_slot(0) 은 비다", nw.hero_at_slot(0).is_empty())
	var board: Array = nw.leaderboard()
	t.check("leaderboard slot 은 3", int(board[0]["slot"]) == 3)
	var standings: Array = nw.final_standings()
	t.check("final_standings slot 은 3", int(standings[0]["slot"]) == 3)
	nw.present(1.0 / 60.0)
	nw.predict_local(Vector2.RIGHT, false, Vector2(4100.0, 2380.0), 1.0 / 60.0)
	t.check("예측이 slot 3 히어로를 움직인다", Vector2(nw.heroes[0]["pos"]).x > 3920.0 + 2.0)

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

func _prediction_freezes_in_countdown(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	var snap := _center_snap(2000.0, 2380.0, 176.0, 7, 18)
	snap[SnapContract.START_COUNTDOWN] = 2.0
	nw.push_snap(snap)
	nw.present(1.0 / 60.0)
	if nw.heroes.is_empty():
		t.check("카운트다운 스냅이 히어로를 만든다", false)
		return
	var before: Vector2 = nw.heroes[0]["pos"]
	for i in range(30):
		nw.predict_local(Vector2.RIGHT, false, before + Vector2(100, 0), 1.0 / 60.0)
	t.check("카운트다운 중 예측 이동이 얼어 있다", Vector2(nw.heroes[0]["pos"]).distance_to(before) < 1.0)
	nw.start_countdown = 0.0
	for i in range(30):
		nw.predict_local(Vector2.RIGHT, false, before + Vector2(400, 0), 1.0 / 60.0)
	t.check("카운트다운 해제 후 예측이 움직인다", Vector2(nw.heroes[0]["pos"]).x > before.x + 10.0)

func _kind_count(nw, kind: StringName) -> int:
	var n := 0
	for fx in nw.effects:
		if StringName(fx.get("kind", &"")) == kind:
			n += 1
	return n

func _dash_pred_moves_then_cools(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	nw.push_snap(_center_snap(3920.0, 2380.0, 176.0, 7, 18))
	nw.present(1.0 / 60.0)
	if nw.heroes.is_empty():
		t.check("대시 예측 히어로가 있다", false)
		return
	var before: Vector2 = nw.heroes[0]["pos"]
	var aim := before + Vector2(200.0, 0.0)
	nw.predict_local(Vector2.RIGHT, true, aim, 1.0 / 60.0)
	var after_dash: Vector2 = nw.heroes[0]["pos"]
	var first := after_dash.x - before.x
	t.check("대시 예측이 위치를 즉시 바꾼다", first > NetWorldScript.DASH_DISTANCE * 0.8)
	nw.predict_local(Vector2.RIGHT, true, aim, 1.0 / 60.0)
	var after_cd: Vector2 = nw.heroes[0]["pos"]
	t.check("대시 쿨다운 중엔 두 번째 점프가 없다", after_cd.x - after_dash.x < 20.0)

func _dash_pred_uses_equipment_distance(t) -> void:
	var blade := _dash_dx_for_weapon("blade")
	var breaker := _dash_dx_for_weapon("breaker")
	t.check("장비별 대시 거리 반영: blade 가 breaker 보다 길다", blade > breaker + 80.0)
	t.check("장비별 대시 거리 반영: blade 가 305 근처다", absf(blade - 305.0) < 20.0)

func _dash_dx_for_weapon(weapon_id: String) -> float:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	var snap := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	snap[SnapContract.PLAYERS][0][SnapContract.P_WEAPON_ID] = weapon_id
	nw.push_snap(snap)
	nw.present(1.0 / 60.0)
	if nw.heroes.is_empty():
		return -1.0
	var before: Vector2 = nw.heroes[0]["pos"]
	nw.predict_local(Vector2.RIGHT, true, before + Vector2(400.0, 0.0), 1.0 / 60.0)
	return Vector2(nw.heroes[0]["pos"]).x - before.x

func _dash_pred_blocked_by_cover(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	var snap := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	snap[SnapContract.PLAYERS][0][SnapContract.P_WEAPON_ID] = "blade"
	# 짧은 변 반지름 150 + 히어로 패딩 20. blade 대시(305) 착지점이 원 안에 남는다.
	snap[SnapContract.COVERS] = [{"x": 3950.0, "y": 2230.0, "w": 300.0, "h": 300.0}]
	nw.push_snap(snap)
	nw.present(1.0 / 60.0)
	if nw.heroes.is_empty():
		t.check("엄폐 예측 히어로가 있다", false)
		return
	var before: Vector2 = nw.heroes[0]["pos"]
	nw.predict_local(Vector2.RIGHT, true, before + Vector2(400.0, 0.0), 1.0 / 60.0)
	var dx := Vector2(nw.heroes[0]["pos"]).x - before.x
	t.check("엄폐에 막히는 예측: 대시가 커버를 통과하지 않는다", dx < 20.0)

func _dash_pred_ignored_during_cc(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	var snap := _center_snap(3920.0, 2380.0, 176.0, 7, 18)
	snap[SnapContract.PLAYERS][0][SnapContract.P_WEAPON_ID] = "blade"
	snap[SnapContract.PLAYERS][0][SnapContract.P_STUN_T] = 1.0
	nw.push_snap(snap)
	nw.present(1.0 / 60.0)
	if nw.heroes.is_empty():
		t.check("CC 예측 히어로가 있다", false)
		return
	var before: Vector2 = nw.heroes[0]["pos"]
	nw.predict_local(Vector2.RIGHT, true, before + Vector2(400.0, 0.0), 1.0 / 60.0)
	t.check("CC 중 대시 무시: stun 이면 위치가 안 바뀐다", Vector2(nw.heroes[0]["pos"]).distance_to(before) < 1.0)

func _pred_fire_skips_empty_mag(t) -> void:
	var loaded = NetWorldScript.new()
	loaded.local_slot = 0
	loaded.start_countdown = 0.0
	loaded.push_snap(_center_snap(3920.0, 2380.0, 176.0, 7, 18))
	t.check("탄창이 있으면 발사 예측 이펙트가 나간다", loaded.predict_local_fire())
	t.check("발사 예측이 local_tracer 를 남긴다", _kind_count(loaded, &"local_tracer") == 1)
	var empty = NetWorldScript.new()
	empty.local_slot = 0
	empty.start_countdown = 0.0
	empty.push_snap(_center_snap(3920.0, 2380.0, 176.0, 0, 18))
	t.check("탄창 0이면 발사 예측이 거부된다", not empty.predict_local_fire())
	t.check("탄창 0이면 발사 예측 이펙트가 안 나간다", _kind_count(empty, &"local_tracer") == 0)

func _launch_trail_accumulates_and_fades(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	var dt := 1.0 / 60.0
	var x0 := 3920.0
	var y0 := 2380.0
	for i in range(16):
		nw.push_snap(_launch_snap(12 + i * 2, x0 + float(i) * 12.0, y0, 0.8))
		nw.present(dt)
	if nw.heroes.is_empty():
		t.check("launch_trail 합성 히어로", false)
		return
	var trail: Array = nw.heroes[0].get("launch_trail", [])
	t.check("launch_trail 이 누적되고 cap 14 를 지킨다", trail.size() == 14)
	t.check("launch 중 fade 가 0.34 다", is_equal_approx(float(nw.heroes[0].get("launch_trail_fade", 0.0)), 0.34))
	nw.heroes[0]["launch_time"] = 0.0
	nw.present(0.17)
	t.check("launch 종료 후 궤적이 감쇠한다", not (nw.heroes[0].get("launch_trail", []) as Array).is_empty() and absf(float(nw.heroes[0].get("launch_trail_fade", 0.0)) - 0.17) < 0.01)
	nw.present(0.18)
	t.check("fade 가 끝나면 launch_trail 이 비다", (nw.heroes[0].get("launch_trail", []) as Array).is_empty())

func _launch_snap(tick_i: int, x: float, y: float, launch_t: float) -> Dictionary:
	var snap := _center_snap(x, y, 176.0, 7, 18)
	snap[SnapContract.TICK] = tick_i
	var player: Dictionary = snap[SnapContract.PLAYERS][0]
	player[SnapContract.P_LAUNCH_T] = launch_t
	player[SnapContract.P_LAUNCH_VX] = 400.0
	return snap

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
