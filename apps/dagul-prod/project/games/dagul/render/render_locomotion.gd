extends RefCounted
## 이동 연출 합성 — 원본 hero_movement.gd apply_locomotion/_refresh_lean 의 클라 근사.
## 서버는 vel 만 주므로, 속도 변화로 상태(idle/accel/cruise/brake)를 추정해
## move_lean(기울임)·move_plant(출발 스쿼시/급정지 눌림)를 렌더 직전에 채운다.

const IDLE_SPD := 30.0
const LEAN_MIN_SPD := 28.0
const CRUISE_RATIO := 0.86
const PLANT_STOP := 1.0
const PLANT_START := -0.7
const PLANT_DECAY_POS := 4.8
const PLANT_DECAY_NEG := 5.2
const LEAN_SMOOTH := 14.0
const FALLBACK_MOVE := 340.0

var _states: Dictionary = {}


func synth(world, dt: float) -> void:
	var live := {}
	for hero in world.heroes:
		var slot := int(hero.get("slot", -1))
		var st: Dictionary = _states.get(slot, {"spd": 0.0, "state": "idle", "plant": 0.0, "lean": 0.0})
		_advance(hero, st, dt)
		hero["move_lean"] = st["lean"]
		hero["move_plant"] = st["plant"]
		live[slot] = st
	_states = live


func _advance(hero: Dictionary, st: Dictionary, dt: float) -> void:
	var vel := Vector2(hero.get("vel", Vector2.ZERO))
	var spd := vel.length()
	var max_speed := _max_speed(hero)
	var state := _classify(spd, float(st["spd"]), max_speed)
	_advance_plant(hero, st, state, dt)
	_advance_lean(st, vel, max_speed, state, dt)
	st["spd"] = spd
	st["state"] = state


## 원본 apply_locomotion 의 상태 판정 근사 — wish 없이 속도 증감으로 추정.
func _classify(spd: float, prev_spd: float, max_speed: float) -> String:
	if spd < IDLE_SPD:
		return "idle"
	if spd >= max_speed * CRUISE_RATIO:
		return "cruise"
	if spd < prev_spd - 1.0:
		return "brake"
	return "accel"


func _advance_plant(hero: Dictionary, st: Dictionary, state: String, dt: float) -> void:
	if float(hero.get("hop_time", 0.0)) > 0.0:
		st["plant"] = 0.0
		return
	var prev := str(st["state"])
	var plant := float(st["plant"])
	if prev == "brake" and state == "idle":
		plant = PLANT_STOP
	elif prev == "idle" and state == "accel":
		plant = PLANT_START
	elif plant > 0.0:
		plant = maxf(0.0, plant - dt * PLANT_DECAY_POS)
	elif plant < 0.0:
		plant = minf(0.0, plant + dt * PLANT_DECAY_NEG)
	st["plant"] = plant


## 원본 _refresh_lean 그대로 — 상태별 배율·지수 스무딩.
func _advance_lean(st: Dictionary, vel: Vector2, max_speed: float, state: String, dt: float) -> void:
	var lean_tgt := 0.0
	if vel.length() > LEAN_MIN_SPD:
		lean_tgt = clampf(vel.x / maxf(max_speed, 1.0), -1.0, 1.0) * 0.20
		if state == "accel":
			lean_tgt *= 1.35
		elif state == "brake":
			lean_tgt *= -0.6
		elif state == "cruise":
			lean_tgt *= 0.72
	st["lean"] = lerpf(float(st["lean"]), lean_tgt, 1.0 - exp(-LEAN_SMOOTH * dt))


func _max_speed(hero: Dictionary) -> float:
	var eq: Variant = hero.get("equipment", {})
	if eq is Dictionary and float((eq as Dictionary).get("move_speed", 0.0)) > 0.0:
		return maxf(80.0, float((eq as Dictionary)["move_speed"]))
	return FALLBACK_MOVE
