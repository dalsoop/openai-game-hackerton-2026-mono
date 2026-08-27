extends RefCounted
## 로컬 예측 대시 — 장비 교체 직후 pending 을 새 스탯으로 리플레이하지 않는다.

const NetWorldScript := preload("res://games/dagul/net/net_world.gd")
const SnapContract := preload("res://games/dagul/net/snap_contract.gd")

func run(t) -> void:
	_dash_replays_when_weapon_same(t)
	_dash_dropped_when_weapon_changes(t)
	_new_dash_after_swap_uses_new_distance(t)

func _dash_replays_when_weapon_same(t) -> void:
	var nw = _world_with_weapon("blade")
	if nw.heroes.is_empty():
		t.check("동일 장비 대시 히어로", false)
		return
	var origin := Vector2(nw.heroes[0]["pos"])
	nw.predict_local(Vector2.RIGHT, true, origin + Vector2(400.0, 0.0), 1.0 / 60.0)
	_push_unacked_swap(nw, origin, "blade", 15)
	nw.present(1.0 / 60.0)
	var dx := Vector2(nw.heroes[0]["pos"]).x - origin.x
	t.check("장비가 같으면 pending 대시를 리플레이한다", dx > 250.0)

func _dash_dropped_when_weapon_changes(t) -> void:
	var nw = _world_with_weapon("blade")
	if nw.heroes.is_empty():
		t.check("장비 교체 대시 히어로", false)
		return
	var origin := Vector2(nw.heroes[0]["pos"])
	nw.predict_local(Vector2.RIGHT, true, origin + Vector2(400.0, 0.0), 1.0 / 60.0)
	var predicted_dx := Vector2(nw.heroes[0]["pos"]).x - origin.x
	t.check("교체 전 대시 예측은 blade 거리", predicted_dx > 250.0)
	_push_unacked_swap(nw, origin, "breaker", 15)
	nw.present(1.0 / 60.0)
	var after_dx := Vector2(nw.heroes[0]["pos"]).x - origin.x
	t.check("장비 교체 스냅은 pending 대시를 새 거리로 리플레이하지 않는다", after_dx < 40.0)

func _new_dash_after_swap_uses_new_distance(t) -> void:
	var nw = _world_with_weapon("blade")
	if nw.heroes.is_empty():
		t.check("교체 후 대시 히어로", false)
		return
	var origin := Vector2(nw.heroes[0]["pos"])
	nw.predict_local(Vector2.RIGHT, true, origin + Vector2(400.0, 0.0), 1.0 / 60.0)
	_push_unacked_swap(nw, origin, "breaker", 15)
	nw.present(1.0 / 60.0)
	var before := Vector2(nw.heroes[0]["pos"])
	nw.predict_local(Vector2.RIGHT, true, before + Vector2(400.0, 0.0), 1.0 / 60.0)
	var dx := Vector2(nw.heroes[0]["pos"]).x - before.x
	t.check("교체 후 새 대시는 breaker 거리", absf(dx - 167.0) < 25.0)
	t.check("교체 후 새 대시는 blade 거리가 아니다", dx < 250.0)

func _world_with_weapon(weapon_id: String):
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	var snap := _center_snap(3920.0, 2380.0)
	snap[SnapContract.PLAYERS][0][SnapContract.P_WEAPON_ID] = weapon_id
	snap[SnapContract.PLAYERS][0][SnapContract.P_ACK] = 0
	nw.push_snap(snap)
	nw.present(1.0 / 60.0)
	return nw

func _push_unacked_swap(nw, origin: Vector2, weapon_id: String, tick_i: int) -> void:
	var snap := _center_snap(origin.x, origin.y)
	snap[SnapContract.TICK] = tick_i
	var p: Dictionary = snap[SnapContract.PLAYERS][0]
	p[SnapContract.P_WEAPON_ID] = weapon_id
	p[SnapContract.P_ACK] = 0
	nw.push_snap(snap)

func _center_snap(x: float, y: float) -> Dictionary:
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
			SnapContract.P_MAX_HP: 176.0,
			SnapContract.P_ALIVE: true,
			SnapContract.P_WEAPON: "GLOCK 18",
			SnapContract.P_MAG: 7,
			SnapContract.P_MAG_MAX: 18,
			SnapContract.P_KILLS: 0,
			SnapContract.P_ACK: 0,
		}],
	}
