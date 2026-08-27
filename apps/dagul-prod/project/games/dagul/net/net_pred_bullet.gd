class_name NetPredBullet
extends RefCounted
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

const TTL := 0.22 ## 전형적 RTT + 여유. 그 전에 진짜 총알이 도착하면 자연히 겹쳐 보인다.
const SPEED := 1400.0 ## 특정 무기 속도를 모르니 일반적인 탄속으로 근사 — 시각 전용이라 무방.
const KIND := &"pellet"

## 발사 예측 성공 시 호출 — world._pred_bullets 에 유령 총알 하나를 쌓는다.
static func spawn(world, origin: Vector2, aim: Vector2, owner_slot: int) -> void:
	var dir := aim if aim.length_squared() > 0.0001 else Vector2.RIGHT
	dir = dir.normalized()
	world._pred_bullets.append({
		"pos": origin,
		"vel": dir * SPEED,
		"kind": String(KIND),
		"source": "predicted",
		"owner": owner_slot,
		"arc": false,
		"heavy": false,
		"ttl": TTL,
		"max_ttl": TTL,
		"trail": [],
	})

## 매 프레임 위치를 전진시키고 수명이 다한 항목을 버린다.
static func advance(world, dt: float) -> void:
	var live: Array[Dictionary] = []
	for bullet in world._pred_bullets:
		var b: Dictionary = bullet
		b["ttl"] = float(b["ttl"]) - dt
		if float(b["ttl"]) <= 0.0:
			continue
		b["pos"] = Vector2(b["pos"]) + Vector2(b["vel"]) * dt
		live.append(b)
	world._pred_bullets = live
