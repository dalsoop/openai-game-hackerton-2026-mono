class_name NetPredDash
extends RefCounted
## 로컬 대시 예측 — net_pred.gd 에서 분리. match-gun.ts applyMobility 와 같은 규칙.
## 커버 충돌은 net_cover_motion.gd 공용 모듈(스윕 포함) 사용 — 대시는 한 틱에
## 최대 305px(blade 기준) 움직이는데 얇은 커버는 반지름이 35px 밖에 안 돼서,
## 스윕 없이 한 번에 이동하면 시작점·도착점 둘 다 커버 밖이라 그대로 뚫고
## 지나간다("돌을 관통해서 대시") — resolve_swept 로 이 재발을 막는다.

const NetCoverMotion := preload("res://games/dagul/net/net_cover_motion.gd")

const FALLBACK_DIST := 138.0
const FALLBACK_CD := 5.0

static func apply(world, me: Dictionary, move: Vector2) -> void:
	if world._pred_dash_cd > 0.0:
		return
	if blocked(me):
		return
	var dir := direction(move, world._pred_aim)
	var stats := stats_for(world, me)
	var slid := NetCoverMotion.resolve_swept(world._pred_pos.x, world._pred_pos.y, dir.x * stats.x, dir.y * stats.x, world.covers)
	world._pred_pos = slid
	world._pred_dash_cd = stats.y

static func blocked(me: Dictionary) -> bool:
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

static func direction(move: Vector2, aim: Vector2) -> Vector2:
	var dir := move
	if dir.length_squared() <= 0.1:
		dir = aim
	var dlen := dir.length()
	if dlen <= 0.0001:
		return Vector2.RIGHT
	return dir / dlen

static func stats_for(world, me: Dictionary) -> Vector2:
	var eq := _equipment(me)
	if eq.has("mobility_distance"):
		var dist := float(eq["mobility_distance"])
		var cd := float(eq.get("mobility_cooldown", FALLBACK_CD))
		if cd <= 0.0:
			cd = FALLBACK_CD
		return Vector2(dist, cd)
	var eq_id := str(eq.get("id", ""))
	if eq_id == "" or eq_id == "net":
		return Vector2(FALLBACK_DIST, FALLBACK_CD)
	var mob: Dictionary = world._equip_reg.mobility_for(eq_id)
	return Vector2(float(mob.get("mobility_distance", FALLBACK_DIST)), float(mob.get("mobility_cooldown", FALLBACK_CD)))

static func _is_turtle(me: Dictionary) -> bool:
	if bool(me.get("turtle", false)):
		return true
	for raw in me.get("timed_buffs", []):
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
