extends RefCounted
## 로컬 예측 — match-gun.applyMobility / match-sim.stepHeroMove 와 같은 규칙.
## 커버 충돌은 net_cover_motion.gd 로 뺐다(net_pred_dash.gd 와 공용, 순환
## 참조 방지). 대시 자체는 net_pred_dash.gd — 이 파일은 이동·CC 상태만 본다.

const NetCoverMotion := preload("res://games/dagul/net/net_cover_motion.gd")
const NetPredDash := preload("res://games/dagul/net/net_pred_dash.gd")

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
	_stamp_pending_weapon(world, me)
	_strip_stale_pending_dashes(world, me)
	var move := Vector2(mx, my)
	apply_move(world, me, move, dt)
	if dash and _pending_allows_dash(world, me):
		NetPredDash.apply(world, me, move)
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
	var slid := NetCoverMotion.resolve(world._pred_pos.x, world._pred_pos.y, delta.x, delta.y, world.covers)
	world._pred_pos = slid

## match-life.ts crawlDowned — 다운 중엔 기본 속도 * 0.16 로만 긴다. CC·장비 배율 무시.
static func _apply_crawl(world, move: Vector2, dt: float) -> void:
	var mlen := move.length()
	if mlen <= 0.05:
		return
	var dir := move / mlen if mlen > 1.0 else move
	var delta := dir * BASE_MOVE_SPEED * DOWN_MOVE_MULT * dt
	world._pred_pos = NetCoverMotion.resolve(world._pred_pos.x, world._pred_pos.y, delta.x, delta.y, world.covers)

static func move_speed(world, me: Dictionary) -> float:
	if me.has("move_speed") and float(me.get("move_speed", 0.0)) > 0.0:
		return float(me["move_speed"])
	var eq := _equipment(me)
	if eq.has("move_speed"):
		return float(eq["move_speed"])
	var combat: Dictionary = world._equip_reg.combat_stats_for(str(eq.get("id", "")))
	return float(combat.get("move_speed", FALLBACK_MOVE))

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

static func _equipment(me: Dictionary) -> Dictionary:
	var eq: Variant = me.get("equipment", {})
	if eq is Dictionary:
		return eq
	return {}

static func _weapon_id(me: Dictionary) -> String:
	return str(_equipment(me).get("id", ""))

static func _pending_list(world) -> Array:
	var raw: Variant = world.get("_pending")
	if raw is Array:
		return raw
	return []

## 입력이 처음 예측될 때의 장비 id. 리플레이는 이미 찍혀 있어 덮지 않는다.
static func _stamp_pending_weapon(world, me: Dictionary) -> void:
	var pending := _pending_list(world)
	if pending.is_empty():
		return
	var last: Variant = pending.back()
	if typeof(last) != TYPE_DICTIONARY:
		return
	var item: Dictionary = last
	if item.has("weapon_id"):
		return
	item["weapon_id"] = _weapon_id(me)

## ack 스냅 장비가 바뀌었으면 옛 장비로 넣은 pending dash 를 버린다.
static func _strip_stale_pending_dashes(world, me: Dictionary) -> void:
	var cur := _weapon_id(me)
	for raw in _pending_list(world):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = raw
		if not bool(item.get("dash", false)):
			continue
		if str(item.get("weapon_id", cur)) == cur:
			continue
		item["dash"] = false

static func _pending_allows_dash(world, me: Dictionary) -> bool:
	var pending := _pending_list(world)
	if pending.is_empty():
		return true
	var cur := _weapon_id(me)
	for raw in pending:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = raw
		if not bool(item.get("dash", false)):
			continue
		if str(item.get("weapon_id", cur)) == cur:
			return true
	return false

