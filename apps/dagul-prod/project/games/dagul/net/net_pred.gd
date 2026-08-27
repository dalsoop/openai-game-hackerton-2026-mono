extends RefCounted
## 로컬 예측 — match-gun.applyMobility / match-sim.stepHeroMove 와 같은 규칙.
## 커버 수식은 match-covers.ts pointInCover · resolveCoverMotion 줄 단위 이식.

const ArenaGeo := preload("res://games/dagul/sim/arena_geometry.gd")

const HERO_RADIUS := ArenaGeo.HERO_RADIUS
const FALLBACK_DIST := 138.0
const FALLBACK_CD := 5.0
const FALLBACK_MOVE := 340.0
const CC_SLOW_MOVE_MULT := 0.42
## match-cc.ts HITSTUN_MOVE_MULT — 히트스턴·콤보캡처 중 28% 감속.
const HITSTUN_MOVE_MULT := 0.72
## match-sim.ts MOVE_SPEED · match-life.ts DOWN_MOVE_MULT — 다운 포복은 장비 속도를 안 탄다.
const BASE_MOVE_SPEED := 419.0
const DOWN_MOVE_MULT := 0.16

static func step(world, mx: float, my: float, dash: bool, aim: Vector2, dt: float) -> void:
	world._pred_dash_cd = maxf(0.0, world._pred_dash_cd - dt)
	var me: Dictionary = world.hero_at_slot(world.local_slot)
	var move := Vector2(mx, my)
	apply_move(world, me, move, dt)
	if dash:
		apply_dash(world, me, move)
	world._pred_pos = world.clamp_arena(world._pred_pos)
	if aim.distance_squared_to(world._pred_pos) > 1.0:
		world._pred_aim = world._pred_pos.direction_to(aim)

static func apply_move(world, me: Dictionary, move: Vector2, dt: float) -> void:
	if not bool(me.get("alive", true)) and not me.is_empty():
		return
	if bool(me.get("downed", false)):
		_apply_crawl(world, move, dt)
		return
	if _move_locked(me):
		return
	var mlen := move.length()
	if mlen <= 0.05:
		return
	var mx := move.x
	var my := move.y
	if mlen > 1.0:
		mx /= mlen
		my /= mlen
	var delta := Vector2(mx, my) * move_speed(world, me) * _move_mult(me) * dt
	var slid := resolve_cover_motion(world._pred_pos.x, world._pred_pos.y, delta.x, delta.y, world.covers)
	world._pred_pos = slid

## match-life.ts crawlDowned — 다운 중엔 기본 속도 * 0.16 로만 긴다. CC·장비 배율 무시.
static func _apply_crawl(world, move: Vector2, dt: float) -> void:
	var mlen := move.length()
	if mlen <= 0.05:
		return
	var dir := move / mlen if mlen > 1.0 else move
	var delta := dir * BASE_MOVE_SPEED * DOWN_MOVE_MULT * dt
	world._pred_pos = resolve_cover_motion(world._pred_pos.x, world._pred_pos.y, delta.x, delta.y, world.covers)

static func apply_dash(world, me: Dictionary, move: Vector2) -> void:
	if world._pred_dash_cd > 0.0:
		return
	if dash_blocked(me):
		return
	var dir := dash_dir(move, world._pred_aim)
	var stats := dash_stats(world, me)
	var slid := resolve_cover_motion(world._pred_pos.x, world._pred_pos.y, dir.x * stats.x, dir.y * stats.x, world.covers)
	world._pred_pos = slid
	world._pred_dash_cd = stats.y

static func dash_blocked(me: Dictionary) -> bool:
	if me.is_empty():
		return false
	if not bool(me.get("alive", true)):
		return true
	# 서버는 downed 면 포복 분기에서 끝나 대시를 안 받는다 (match-sim applyHero).
	if bool(me.get("downed", false)):
		return true
	if float(me.get("stun_time", 0.0)) > 0.0:
		return true
	if float(me.get("root_time", 0.0)) > 0.0:
		return true
	if float(me.get("launch_time", 0.0)) > 0.0:
		return true
	return _is_turtle(me)

static func dash_dir(move: Vector2, aim: Vector2) -> Vector2:
	var dir := move
	if dir.length_squared() <= 0.1:
		dir = aim
	var dlen := dir.length()
	if dlen <= 0.0001:
		return Vector2.RIGHT
	return dir / dlen

static func dash_stats(world, me: Dictionary) -> Vector2:
	var eq := _equipment(me)
	if eq.has("mobility_distance") and eq.has("mobility_cooldown"):
		return Vector2(float(eq["mobility_distance"]), float(eq["mobility_cooldown"]))
	var eq_id := str(eq.get("id", ""))
	if eq_id == "" or eq_id == "net":
		return Vector2(FALLBACK_DIST, FALLBACK_CD)
	var mob: Dictionary = world._equip_reg.mobility_for(eq_id)
	return Vector2(float(mob.get("mobility_distance", FALLBACK_DIST)), float(mob.get("mobility_cooldown", FALLBACK_CD)))

static func move_speed(world, me: Dictionary) -> float:
	if me.has("move_speed") and float(me.get("move_speed", 0.0)) > 0.0:
		return float(me["move_speed"])
	var eq := _equipment(me)
	if eq.has("move_speed"):
		return float(eq["move_speed"])
	var combat: Dictionary = world._equip_reg.combat_stats_for(str(eq.get("id", "")))
	return float(combat.get("move_speed", FALLBACK_MOVE))

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
static func resolve_cover_motion(x: float, y: float, mx: float, my: float, covers: Array) -> Vector2:
	var rx := x
	if not point_in_cover(x + mx, y, covers, HERO_RADIUS):
		rx = x + mx
	var ry := y
	if not point_in_cover(rx, y + my, covers, HERO_RADIUS):
		ry = y + my
	return Vector2(rx, ry)

static func _move_locked(me: Dictionary) -> bool:
	if me.is_empty():
		return false
	if not bool(me.get("alive", true)):
		return true
	if float(me.get("stun_time", 0.0)) > 0.0:
		return true
	return float(me.get("launch_time", 0.0)) > 0.0

static func _move_mult(me: Dictionary) -> float:
	if me.is_empty():
		return 1.0
	var mult := 1.0
	if float(me.get("root_time", 0.0)) > 0.0:
		mult = 0.0
	elif float(me.get("cc_time", 0.0)) > 0.0:
		mult = CC_SLOW_MOVE_MULT
	if float(me.get("hitstun_time", 0.0)) > 0.0 or float(me.get("combo_capture_time", 0.0)) > 0.0:
		mult *= HITSTUN_MOVE_MULT
	return mult

static func _is_turtle(me: Dictionary) -> bool:
	if bool(me.get("turtle", false)):
		return true
	for raw in me.get("rl_timed", []):
		if _timed_is_turtle(raw):
			return true
	return false

static func _timed_is_turtle(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY:
		return false
	var buff: Dictionary = raw
	if str(buff.get("id", "")) != "turtle":
		return false
	return float(buff.get("time", 0.0)) > 0.0

static func _equipment(me: Dictionary) -> Dictionary:
	var eq: Variant = me.get("equipment", {})
	if eq is Dictionary:
		return eq
	return {}

static func _cover_rect(cover: Dictionary) -> Rect2:
	if cover.has("rect"):
		return cover["rect"]
	return Rect2(float(cover.get("x", 0.0)), float(cover.get("y", 0.0)), float(cover.get("w", 0.0)), float(cover.get("h", 0.0)))
