class_name LagCompensator
extends RefCounted

const HISTORY_FRAMES := 15
const MAX_REWIND_MS := 250
const HERO_RADIUS := 20.0

var _history: Array[Dictionary] = []

func record_tick(tick: int, heroes: Array) -> void:
	var positions := {}
	for i in heroes.size():
		var h: Dictionary = heroes[i]
		if not bool(h.get("alive", false)):
			continue
		positions[i] = Vector2(float(h.get("x", 0.0)), float(h.get("y", 0.0)))
	_history.append({"tick": tick, "positions": positions})
	if _history.size() > HISTORY_FRAMES:
		_history.pop_front()

func rewind_hit_check(fire_tick: int, attacker_slot: int, attacker_pos: Vector2, aim_dir: Vector2, weapon_range: float, weapon_spread: float, current_heroes: Array) -> Array[int]:
	var frame = _find_frame(fire_tick)
	if frame == null:
		return _check_current(attacker_slot, attacker_pos, aim_dir, weapon_range, weapon_spread, current_heroes)
	var hit_slots: Array[int] = []
	var positions: Dictionary = frame["positions"]
	for slot in positions:
		if int(slot) == attacker_slot:
			continue
		var target_pos: Vector2 = positions[slot]
		if _ray_hits_circle(attacker_pos, aim_dir, target_pos, HERO_RADIUS, weapon_range):
			hit_slots.append(int(slot))
	return hit_slots

func _find_frame(fire_tick: int):
	if _history.is_empty():
		return null
	var current_tick: int = _history.back()["tick"]
	var delta_ticks := current_tick - fire_tick
	if delta_ticks < 0 or delta_ticks > HISTORY_FRAMES:
		return null
	for frame in _history:
		if int(frame["tick"]) >= fire_tick:
			return frame
	return _history.back()

func _check_current(attacker_slot: int, attacker_pos: Vector2, aim_dir: Vector2, weapon_range: float, _weapon_spread: float, heroes: Array) -> Array[int]:
	var hit_slots: Array[int] = []
	for i in heroes.size():
		if i == attacker_slot:
			continue
		var h: Dictionary = heroes[i]
		if not bool(h.get("alive", false)):
			continue
		var pos := Vector2(float(h.get("x", 0.0)), float(h.get("y", 0.0)))
		if _ray_hits_circle(attacker_pos, aim_dir, pos, HERO_RADIUS, weapon_range):
			hit_slots.append(i)
	return hit_slots

func _ray_hits_circle(ray_origin: Vector2, ray_dir: Vector2, circle_center: Vector2, circle_radius: float, max_dist: float) -> bool:
	var to_circle := circle_center - ray_origin
	var proj := to_circle.dot(ray_dir)
	if proj < 0.0 or proj > max_dist:
		return false
	var closest := ray_origin + ray_dir * proj
	return closest.distance_to(circle_center) <= circle_radius
