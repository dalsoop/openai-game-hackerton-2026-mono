class_name NetCoverMotion
extends RefCounted
## 커버 충돌 — net_pred.gd·net_pred_dash.gd 공용. match-covers.ts
## pointInCover · resolveCoverMotion · resolveCoverMotionSwept 줄 단위 이식.
## 별도 파일인 이유: 두 예측 모듈(이동·대시)이 서로를 preload 하지 않고
## 이 공용 유틸만 각자 preload 하게 해서 순환 참조를 피한다.

const HERO_RADIUS := 20.0
## 한 스텝의 최대 이동거리. 가장 얇은 커버(반지름 35 안팎)보다 확실히 작게
## 잡아 대시처럼 한 번에 300px 넘게 움직이는 이동이 벽을 관통하지 않게 한다.
const SWEPT_MAX_STEP := 24.0

## match-covers.ts pointInCover — 커버는 rect 중심 + 짧은 변 반지름의 원형.
static func point_in_cover(px: float, py: float, covers: Array, padding: float = 0.0) -> bool:
	for raw in covers:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var rect := _cover_rect(raw)
		var r := minf(rect.size.x, rect.size.y) * 0.5 + padding
		if Vector2(px, py).distance_to(rect.get_center()) <= r:
			return true
	return false

## match-covers.ts resolveCoverMotion — 축 분리 벽 슬라이딩. X 먼저, 그 결과 위에서 Y.
static func resolve(x: float, y: float, mx: float, my: float, covers: Array) -> Vector2:
	var rx := x
	if not point_in_cover(x + mx, y, covers, HERO_RADIUS):
		rx = x + mx
	var ry := y
	if not point_in_cover(rx, y + my, covers, HERO_RADIUS):
		ry = y + my
	return Vector2(rx, ry)

## match-covers.ts resolveCoverMotionSwept — 대시급 큰 이동을 SWEPT_MAX_STEP 이하
## 조각으로 나눠 resolve() 를 반복 적용한다. 한 조각이라도 완전히 막히면 그
## 지점에서 멈춘다(벽에 붙어 슬라이드하는 자연스러운 감속) — 더 밀어붙이지 않는다.
static func resolve_swept(x: float, y: float, mx: float, my: float, covers: Array) -> Vector2:
	var dist := Vector2(mx, my).length()
	if dist <= SWEPT_MAX_STEP:
		return resolve(x, y, mx, my, covers)
	var steps := int(ceil(dist / SWEPT_MAX_STEP))
	var step_x := mx / float(steps)
	var step_y := my / float(steps)
	var cx := x
	var cy := y
	for _i in steps:
		var next := resolve(cx, cy, step_x, step_y, covers)
		if is_equal_approx(next.x, cx) and is_equal_approx(next.y, cy):
			break
		cx = next.x
		cy = next.y
	return Vector2(cx, cy)

static func _cover_rect(cover: Dictionary) -> Rect2:
	if cover.has("rect"):
		return cover["rect"]
	return Rect2(float(cover.get("x", 0.0)), float(cover.get("y", 0.0)), float(cover.get("w", 0.0)), float(cover.get("h", 0.0)))
