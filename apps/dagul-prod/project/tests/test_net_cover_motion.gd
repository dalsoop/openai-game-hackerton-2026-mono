extends RefCounted
## NetCoverMotion — 대시급 큰 이동이 얇은 커버를 관통하지 않는지 검증한다.
## 회귀: "대시로 돌을 뚫고 지나간다" — 한 번에 커버보다 큰 거리를 이동하면
## 시작점·도착점 둘 다 커버 밖이라 충돌 판정 자체가 비었던 버그.

const Motion := preload("res://games/dagul/net/net_cover_motion.gd")

func run(t) -> void:
	_thin_cover_blocks_large_step(t)
	_small_step_matches_resolve(t)
	_large_step_slides_along_wall(t)
	_no_cover_moves_freely(t)

## 반지름 35짜리 얇은 커버(가로로 긴 벽) 정중앙을 관통하는 큰 이동은
## 한 번에 처리하면 뚫린다 — resolve() 단독 호출로 먼저 재현한다.
func _thin_cover_blocks_large_step(t) -> void:
	var cover := {"x": 400.0, "y": 490.0, "w": 300.0, "h": 70.0} # 중심 (550,525), r=35
	var covers := [cover]
	var start := Vector2(550.0, 300.0)
	var end := Vector2(550.0, 750.0) # 벽을 정면으로 관통하는 450px 이동
	var delta := end - start
	var one_shot: Vector2 = Motion.resolve(start.x, start.y, delta.x, delta.y, covers)
	t.check("한 번에 처리하면 뚫려서 반대편에 도달한다(재현)", absf(one_shot.y - end.y) < 1.0)
	var swept: Vector2 = Motion.resolve_swept(start.x, start.y, delta.x, delta.y, covers)
	t.check("스윕은 벽 앞에서 멈춘다", swept.y < 525.0 - 35.0 + 1.0)
	t.check("스윕은 반대편에 도달하지 않는다", swept.y < end.y - 100.0)

func _small_step_matches_resolve(t) -> void:
	var covers: Array = []
	var a: Vector2 = Motion.resolve(100.0, 100.0, 10.0, 5.0, covers)
	var b: Vector2 = Motion.resolve_swept(100.0, 100.0, 10.0, 5.0, covers)
	t.check("SWEPT_MAX_STEP 이하 이동은 resolve() 와 결과가 같다", a.is_equal_approx(b))

## 벽에 비스듬히 부딪히면 완전히 멈추는 게 아니라 옆으로 미끄러져야 한다
## (기존 축 분리 슬라이딩 성질이 스윕에서도 유지되는지).
func _large_step_slides_along_wall(t) -> void:
	var cover := {"x": 400.0, "y": 490.0, "w": 300.0, "h": 70.0}
	var covers := [cover]
	var start := Vector2(550.0, 300.0)
	var delta := Vector2(300.0, 220.0) # 벽쪽으로 대각선 대시
	var swept: Vector2 = Motion.resolve_swept(start.x, start.y, delta.x, delta.y, covers)
	t.check("대각선 이동은 X축으로는 계속 전진한다(슬라이딩)", swept.x > start.x + 250.0)

func _no_cover_moves_freely(t) -> void:
	var swept: Vector2 = Motion.resolve_swept(0.0, 0.0, 305.0, 0.0, [])
	t.check("커버가 없으면 스윕도 전체 거리를 그대로 이동한다", is_equal_approx(swept.x, 305.0))
