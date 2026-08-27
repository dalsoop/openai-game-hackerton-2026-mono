extends RefCounted
## 이동 연출 합성 — 출발 스쿼시·급정지 눌림·기울임이 vel 만으로 살아나는지.

const LocoScript := preload("res://games/dagul/render/render_locomotion.gd")


class FakeWorld:
	var heroes: Array[Dictionary] = []


func run(t) -> void:
	_start_squash(t)
	_stop_plant(t)
	_lean_follows_velocity(t)


func _hero(vel: Vector2) -> Dictionary:
	return {"slot": 0, "vel": vel, "hop_time": 0.0, "equipment": {"move_speed": 400.0}}


func _start_squash(t) -> void:
	var loco = LocoScript.new()
	var w := FakeWorld.new()
	w.heroes = [_hero(Vector2.ZERO)]
	loco.synth(w, 1.0 / 60.0)
	w.heroes[0]["vel"] = Vector2(120.0, 0.0)
	loco.synth(w, 1.0 / 60.0)
	t.check("출발 순간 plant 가 음수(스쿼시)다", float(w.heroes[0].get("move_plant", 0.0)) < -0.5)


func _stop_plant(t) -> void:
	var loco = LocoScript.new()
	var w := FakeWorld.new()
	w.heroes = [_hero(Vector2(400.0, 0.0))]
	loco.synth(w, 1.0 / 60.0)
	w.heroes[0]["vel"] = Vector2(120.0, 0.0)
	loco.synth(w, 1.0 / 60.0)
	w.heroes[0]["vel"] = Vector2.ZERO
	loco.synth(w, 1.0 / 60.0)
	t.check("급정지 순간 plant 가 양수(눌림)다", float(w.heroes[0].get("move_plant", 0.0)) > 0.5)


func _lean_follows_velocity(t) -> void:
	var loco = LocoScript.new()
	var w := FakeWorld.new()
	w.heroes = [_hero(Vector2(400.0, 0.0))]
	for i in range(30):
		loco.synth(w, 1.0 / 60.0)
	t.check("우측 이동이면 우측 기울임", float(w.heroes[0].get("move_lean", 0.0)) > 0.05)
	w.heroes[0]["vel"] = Vector2(-400.0, 0.0)
	for i in range(30):
		loco.synth(w, 1.0 / 60.0)
	t.check("좌측 이동이면 좌측 기울임", float(w.heroes[0].get("move_lean", 0.0)) < -0.05)
