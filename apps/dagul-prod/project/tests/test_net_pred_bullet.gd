extends RefCounted
## NetPredBullet — 발사 순간 로컬 예측 위치에서 시각 전용 총알이 나가고,
## 수명이 다하면 사라지는지를 검증한다. 회귀: "이동한 자리가 아니라 그 전
## 자리에서 총알이 나간다"는 실측 버그의 재발 방지.

const Bullet := preload("res://games/dagul/net/net_pred_bullet.gd")
const NetWorldScript := preload("res://games/dagul/net/net_world.gd")
const SnapContract := preload("res://games/dagul/net/snap_contract.gd")

class FakeWorld extends RefCounted:
	var _pred_bullets: Array[Dictionary] = []

func run(t) -> void:
	_spawn_pure(t)
	_advance_moves_and_expires(t)
	_zero_aim_falls_back_to_right(t)
	_integration_fire_spawns_into_projectiles(t)
	_integration_bullet_bridges_until_expiry(t)

func _spawn_pure(t) -> void:
	var w := FakeWorld.new()
	Bullet.spawn(w, Vector2(100.0, 200.0), Vector2(1.0, 0.0), 3)
	t.check("spawn 은 정확히 하나를 쌓는다", w._pred_bullets.size() == 1)
	var b: Dictionary = w._pred_bullets[0]
	t.check("스폰 위치가 예측 위치 그대로", Vector2(b["pos"]) == Vector2(100.0, 200.0))
	t.check("owner 가 발사자 slot", int(b["owner"]) == 3)
	t.check("피해 판정 필드가 없다(시각 전용)", not b.has("damage"))
	t.check("vel 방향이 조준과 같다", Vector2(b["vel"]).normalized().is_equal_approx(Vector2(1.0, 0.0)))

func _advance_moves_and_expires(t) -> void:
	var w := FakeWorld.new()
	Bullet.spawn(w, Vector2.ZERO, Vector2(1.0, 0.0), 0)
	var start_pos: Vector2 = w._pred_bullets[0]["pos"]
	Bullet.advance(w, 0.05)
	t.check("advance 는 vel*dt 만큼 전진한다", not Vector2(w._pred_bullets[0]["pos"]).is_equal_approx(start_pos))
	t.check("전진 방향이 조준과 같다", Vector2(w._pred_bullets[0]["pos"]).x > 0.0)
	# TTL(0.22s) 을 넘기면 사라진다.
	Bullet.advance(w, 1.0)
	t.check("TTL 만료 후 사라진다", w._pred_bullets.is_empty())

func _zero_aim_falls_back_to_right(t) -> void:
	var w := FakeWorld.new()
	Bullet.spawn(w, Vector2.ZERO, Vector2.ZERO, 0)
	t.check("조준이 0벡터면 오른쪽으로 폴백", Vector2(w._pred_bullets[0]["vel"]).normalized().is_equal_approx(Vector2.RIGHT))

func _integration_fire_spawns_into_projectiles(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	nw.push_snap(_snap(3920.0, 2380.0, 7))
	var moved_x := 3920.0 + 200.0
	# 이동 예측으로 자리를 옮긴 뒤 그 자리에서 발사 — 실측 버그의 핵심 시나리오.
	nw._pred_pos = Vector2(moved_x, 2380.0)
	nw._has_pred = true
	t.check("발사 예측 성공", nw.predict_local_fire())
	nw.present(0.0) # projectiles 병합은 present() 프레임에 일어난다 — 실제 렌더 루프와 같은 순서.
	var pred := _find_predicted(nw)
	t.check("예측 총알이 projectiles 에 있다", not pred.is_empty())
	if pred.is_empty():
		return
	t.check("예측 총알이 옛 자리가 아니라 이동한 자리에서 나간다", Vector2(pred["pos"]).x > 3920.0 + 100.0)

func _integration_bullet_bridges_until_expiry(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	nw.push_snap(_snap(3920.0, 2380.0, 7))
	nw.predict_local_fire()
	nw.present(0.05)
	t.check("발사 직후에도 예측 총알이 남아 있다", not _find_predicted(nw).is_empty())
	nw.present(1.0)
	t.check("충분히 지나면 예측 총알이 사라진다", _find_predicted(nw).is_empty())

func _find_predicted(nw) -> Dictionary:
	for p in nw.projectiles:
		if str(p.get("source", "")) == "predicted":
			return p
	return {}

func _snap(x: float, y: float, mag: int) -> Dictionary:
	return {
		SnapContract.TICK: 12,
		SnapContract.TIME: 1.0,
		SnapContract.RESULT: "playing",
		SnapContract.ZONE_R: 3304.0,
		SnapContract.ZONE_CX: 3920.0,
		SnapContract.ZONE_CY: 2380.0,
		SnapContract.PLAYERS: [{
			SnapContract.P_SLOT: 0,
			SnapContract.P_NAME: "호스트",
			SnapContract.P_X: x, SnapContract.P_Y: y,
			SnapContract.P_AIM_X: x + 100.0, SnapContract.P_AIM_Y: y,
			SnapContract.P_HP: 204.0,
			SnapContract.P_MAX_HP: 204.0,
			SnapContract.P_ALIVE: true,
			SnapContract.P_WEAPON: "GLOCK 18",
			SnapContract.P_MAG: mag,
			SnapContract.P_MAG_MAX: 18,
			SnapContract.P_KILLS: 0,
			SnapContract.P_ACK: 0,
		}],
	}
