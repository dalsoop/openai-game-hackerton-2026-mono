extends RefCounted
## 런치(넉백 비행) 궤적 합성 — net_world 에서 분리.
## 원본 sim: tick%2 샘플, cap 14, fade 0.34 (hero_movement / match_lifecycle).

const LAUNCH_TRAIL_CAP := 14
const LAUNCH_TRAIL_FADE := 0.34

static func synth(world, dt: float) -> void:
	var live := {}
	for hero in world.heroes:
		if not hero.has("slot"):
			continue
		var slot := int(hero["slot"])
		var st: Dictionary = world._launch_trails.get(slot, {"pts": [], "fade": 0.0, "tick": -1})
		_advance(world, hero, st, dt)
		hero["launch_trail"] = st["pts"]
		hero["launch_trail_fade"] = st["fade"]
		live[slot] = st
	world._launch_trails = live

static func _advance(world, hero: Dictionary, st: Dictionary, dt: float) -> void:
	if float(hero.get("launch_time", 0.0)) > 0.0:
		st["fade"] = LAUNCH_TRAIL_FADE
		_sample(world, hero, st)
		return
	st["fade"] = maxf(0.0, float(st["fade"]) - dt)
	if float(st["fade"]) <= 0.0:
		st["pts"] = []
		st["tick"] = -1

static func _sample(world, hero: Dictionary, st: Dictionary) -> void:
	var pts: Array = st["pts"]
	var pos := Vector2(hero["pos"])
	if pts.is_empty():
		st["pts"] = [pos]
		st["tick"] = world.tick
		return
	if world.tick % 2 != 0 or world.tick == int(st["tick"]):
		return
	pts.append(pos)
	if pts.size() > LAUNCH_TRAIL_CAP:
		pts.pop_front()
	st["pts"] = pts
	st["tick"] = world.tick
