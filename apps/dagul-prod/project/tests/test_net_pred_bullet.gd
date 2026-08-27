extends RefCounted
## NetPredBullet — 발사 순간 로컬 예측 위치에서 시각 전용 총알이 나가고,
## 수명이 다하면 사라지는지를 검증한다. 회귀: "이동한 자리가 아니라 그 전
## 자리에서 총알이 나간다"는 실측 버그의 재발 방지.

const Bullet := preload("res://games/dagul/net/net_pred_bullet.gd")
const NetWorldScript := preload("res://games/dagul/net/net_world.gd")
const SnapContract := preload("res://games/dagul/net/snap_contract.gd")

class FakeWorld extends RefCounted:
	var _pred_bullets: Array[Dictionary] = []
	var covers: Array = []

func run(t) -> void:
	_spawn_pure(t)
	_advance_moves_and_expires(t)
	_zero_aim_falls_back_to_right(t)
	_integration_fire_spawns_into_projectiles(t)
	_integration_bullet_bridges_until_expiry(t)
	_sustained_fire_waits_for_weapon_interval(t)
	_sustained_fire_ignored_for_semi_weapons(t)
	_absorbed_by_cover_not_bounced(t)

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

## 회귀: 이동하며 연사(auto)할 때 첫 발 이후로도 예측 총알이 이동 자리에서
## 계속 나가는지 — 무기 간격(normal_interval) 전엔 다시 안 나가고, 지나면 다시 나간다.
func _sustained_fire_waits_for_weapon_interval(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	# leech(MP5) 는 auto, normal_interval 0.095.
	nw.push_snap(_snap(3920.0, 2380.0, 25, "leech"))
	t.check("첫 발(클릭 엣지)은 즉시 나간다", nw.predict_local_fire())
	t.check("간격이 안 지나면 연사 예측은 재발사하지 않는다", not nw.predict_local_fire(Vector2.ZERO, true))
	nw.predict_local(Vector2.ZERO, false, Vector2.RIGHT, 0.2) # 간격(0.095s)보다 길게 흘려보낸다.
	t.check("간격이 지나면 연사 예측이 다시 발사한다", nw.predict_local_fire(Vector2.ZERO, true))

## semi/bolt/gl/lever 무기는 쥐고 있어도 연사하지 않는다 — 예측도 같이 막아야
## 클릭 한 번에 트레이서가 여러 번 나가는 고스트 연사가 생기지 않는다.
func _sustained_fire_ignored_for_semi_weapons(t) -> void:
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	# brawler(M1911) 는 semi.
	nw.push_snap(_snap(3920.0, 2380.0, 7, "brawler"))
	t.check("첫 발(클릭 엣지)은 semi 에도 나간다", nw.predict_local_fire())
	nw.predict_local(Vector2.ZERO, false, Vector2.RIGHT, 1.0)
	t.check("semi 무기는 쥐고 있어도 연사 예측이 나가지 않는다", not nw.predict_local_fire(Vector2.ZERO, true))

## 회귀: match-sim.ts expireOrHit 는 커버에 닿은 실탄을 튕기지 않고 그 자리에서
## 소멸시킨다(pointInCover → splashAround → 제거). 예측 총알도 같은 규칙을
## 따라야 한다 — 안 그러면 실탄은 막히는데 내 트레이서만 돌을 뚫고 지나가는
## 것처럼 보인다.
func _absorbed_by_cover_not_bounced(t) -> void:
	var w := FakeWorld.new()
	w.covers = [{"x": 90.0, "y": -35.0, "w": 70.0, "h": 70.0}] # 중심 (125,0), r=35
	Bullet.spawn(w, Vector2.ZERO, Vector2(1.0, 0.0), 0, 1000.0, 1.0)
	for i in range(30): # 0.5s, 500px 전진 — 커버(중심 x=125)를 한참 지나칠 거리
		Bullet.advance(w, 1.0 / 60.0)
		if w._pred_bullets.is_empty():
			break
	t.check("커버에 닿으면 튕기지 않고 소멸한다", w._pred_bullets.is_empty())

func _snap(x: float, y: float, mag: int, weapon_id: String = "net") -> Dictionary:
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
			SnapContract.P_WEAPON_ID: weapon_id,
			SnapContract.P_MAG: mag,
			SnapContract.P_MAG_MAX: 18,
			SnapContract.P_KILLS: 0,
			SnapContract.P_ACK: 0,
		}],
	}
