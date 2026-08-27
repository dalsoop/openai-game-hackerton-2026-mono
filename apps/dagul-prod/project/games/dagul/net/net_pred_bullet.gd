class_name NetPredBullet
extends RefCounted
const NetCoverMotion := preload("res://games/dagul/net/net_cover_motion.gd")
## 로컬 발사 예측 총알 — net_world 에서 분리.
##
## 왜 필요한가: net_pred.gd 는 이동만 예측한다. 발사는 순수 서버 권위라
## MatchBulletSchema 총알이 서버가 그 틱에 계산한 위치(≈1 RTT 전, 예측으로
## 화면에 보이는 "지금" 위치보다 뒤처짐)에서 나간다 — 캐릭터는 이동한 자리에
## 서 있는데 총알은 그 전 자리에서 나가는 걸로 보인다.
##
## 해법: 발사 입력이 들어온 프레임에 로컬 예측 위치(_pred_pos)·조준 방향으로
## 시각 전용(피해 판정 없음) 총알을 즉시 하나 그린다. 서버 진짜 총알이
## snap 으로 도착하면 그걸로 이어받고, 예측 총알은 짧은 수명(TTL) 뒤 사라진다.
## 판정 권위는 100% 서버에 남는다 — 여기서 만든 항목은 draw_projectiles_main
## 이 world.projectiles 를 읽을 때만 보이는 순수 연출이다.

## 폴백값 — fire_profile_for 가 무기를 못 찾았을 때만 쓴다(시각 전용이라 무방).
const TTL := 0.22
const SPEED := 1400.0
const KIND := &"pellet"

## 발사 예측 성공 시 호출 — world._pred_bullets 에 유령 총알 하나를 쌓는다.
## speed·ttl 은 실탄과 같은 무기 프로필(fire_profile_for)에서 받는다 — 고정값을 쓰면
## 실탄 사거리(speed*ttl)보다 짧아서 진짜 총알보다 먼저 사라져 "쏘다 마는" 것처럼 보인다.
static func spawn(
	world, origin: Vector2, aim: Vector2, owner_slot: int,
	speed: float = SPEED, ttl: float = TTL,
) -> void:
	var dir := aim if aim.length_squared() > 0.0001 else Vector2.RIGHT
	dir = dir.normalized()
	world._pred_bullets.append({
		"pos": origin,
		"vel": dir * speed,
		"kind": String(KIND),
		"source": "predicted",
		"owner": owner_slot,
		"arc": false,
		"heavy": false,
		"ttl": ttl,
		"max_ttl": ttl,
		"trail": [],
	})

## 매 프레임 위치를 전진시키고 수명이 다하거나 커버(돌)에 닿은 항목을 버린다.
## match-sim.ts expireOrHit 의 pointInCover 분기와 같은 규칙 — 실탄은 커버에
## 닿으면 튕기지 않고 그 자리에서 소멸한다. 이 체크가 없으면 예측 총알(시각
## 전용)만 커버를 그대로 뚫고 지나가는 것처럼 보여서, 진짜 총알은 막히는데
## 자기 트레이서는 돌을 통과하는 것처럼 보이는 불일치가 생긴다.
static func advance(world, dt: float) -> void:
	var live: Array[Dictionary] = []
	var covers: Array = world.get("covers") if world.get("covers") != null else []
	for bullet in world._pred_bullets:
		var b: Dictionary = bullet
		b["ttl"] = float(b["ttl"]) - dt
		if float(b["ttl"]) <= 0.0:
			continue
		var next_pos: Vector2 = Vector2(b["pos"]) + Vector2(b["vel"]) * dt
		if NetCoverMotion.point_in_cover(next_pos.x, next_pos.y, covers):
			continue
		b["pos"] = next_pos
		live.append(b)
	world._pred_bullets = live
