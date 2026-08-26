class_name RenderWorldFx
extends RefCounted

const GunSig = preload("res://games/dagul/sim/gun_signature.gd")

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer


func tick_casings(dt: float) -> void:
	var alive: Array[Dictionary] = []
	for casing in r.world_casings:
		casing["age"] = float(casing.get("age", 0.0)) + dt
		if float(casing["age"]) < 0.95:
			alive.append(casing)
	r.world_casings = alive


func spawn_casing(slot: int) -> void:
	if slot < 0 or slot >= world.heroes.size():
		return
	var hero: Dictionary = world.heroes[slot]
	if not bool(hero.get("alive", false)):
		return
	var aim := Vector2(hero.get("aim", Vector2.RIGHT))
	if aim.length_squared() < 0.0001:
		aim = Vector2.RIGHT
	aim = aim.normalized()
	_append_casing(hero, aim, slot)


func _append_casing(hero: Dictionary, aim: Vector2, _slot: int) -> void:
	var side := Vector2(-aim.y, aim.x)
	var equipment: Dictionary = hero.get("equipment", {})
	var equipment_id := str(equipment.get("id", "burst"))
	r.world_casing_serial += 1
	var seed := fposmod(float(r.world_casing_serial * 37), 101.0) / 101.0
	r.world_casings.append({
		"pos": Vector2(hero.get("pos", Vector2.ZERO)) + aim * 24.0 + side * (7.0 + seed * 5.0),
		"aim": aim,
		"age": 0.0,
		"seed": seed,
		"spin": 1.5 + fposmod(float(r.world_casing_serial * 23), 100.0) / 100.0,
		"clockwise": 1.0 if r.world_casing_serial % 2 == 0 else -1.0,
		"size": _casing_size(equipment_id),
	})
	while r.world_casings.size() > 48:
		r.world_casings.pop_front()


func _casing_size(equipment_id: String) -> Vector2:
	var family := GunSig.family_of(equipment_id)
	match family:
		"pistol":
			return Vector2(10.0, 7.0)
		"smg":
			return Vector2(12.0, 8.0)
		"shotgun":
			return Vector2(16.0, 11.0)
		"heavy":
			return Vector2(18.0, 12.0)
		_:
			return Vector2(14.0, 9.0)


func draw_casings() -> void:
	for casing in r.world_casings:
		_draw_one_casing(casing)


func _draw_one_casing(casing: Dictionary) -> void:
	var age := float(casing.get("age", 0.0))
	var seed := float(casing.get("seed", 0.0))
	var aim := Vector2(casing.get("aim", Vector2.RIGHT))
	var origin := Vector2(casing.get("pos", Vector2.ZERO))
	var velocity := aim * (110.0 + seed * 34.0) + Vector2(0.0, -90.0 - seed * 24.0)
	var pos := origin + velocity * age + Vector2(0.0, 180.0 * age * age)
	var rotation := float(casing.get("clockwise", 1.0)) * TAU * float(casing.get("spin", 2.0)) * age + seed * TAU
	var alpha := 0.72 * (1.0 - clampf((age - 0.58) / 0.37, 0.0, 1.0))
	var casing_size := Vector2(casing.get("size", Vector2(14.0, 9.0)))
	r.draw_set_transform(pos, rotation, Vector2.ONE)
	_blit_casing(casing_size, alpha)
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _blit_casing(casing_size: Vector2, alpha: float) -> void:
	if r.ammo_casing_texture != null:
		r.draw_texture_rect_region(r.ammo_casing_texture, Rect2(-casing_size * 0.5, casing_size), Rect2(240.0, 280.0, 800.0, 680.0), Color(1.0, 1.0, 1.0, alpha))
	else:
		r.draw_rect(Rect2(-casing_size * 0.5, casing_size), Color(0.95, 0.64, 0.18, alpha))


func zone_impact_src(frame: int) -> Rect2:
	if r.zone_impact_atlas == null:
		return Rect2()
	var cell := Vector2(float(r.zone_impact_atlas.get_width()) / 4.0, float(r.zone_impact_atlas.get_height()) / 2.0)
	var safe_frame := clampi(frame, 0, 7)
	return Rect2(Vector2(float(safe_frame % 4), float(safe_frame / 4)) * cell, cell)


func draw_zone_impacts() -> void:
	if r.zone_impact_atlas == null:
		return
	for effect in world.effects:
		if StringName(effect.get("kind", &"")) != &"zone_impact":
			continue
		_draw_zone_impact(effect)


func _draw_zone_impact(effect: Dictionary) -> void:
	var ratio := clampf(float(effect["time"]) / maxf(0.001, float(effect["max_time"])), 0.0, 1.0)
	var progress := 1.0 - ratio
	var effect_pos: Vector2 = effect["pos"]
	var follow_slot := int(effect.get("follow_slot", -1))
	if follow_slot >= 0 and follow_slot < world.heroes.size():
		effect_pos = Vector2(world.heroes[follow_slot].get("pos", effect_pos))
	var frame := clampi(int(progress * 8.0), 0, 7)
	var size := Vector2.ONE * 164.0
	var alpha := clampf(ratio * 1.35, 0.24, 1.0)
	r.draw_set_transform(effect_pos, 0.0, Vector2.ONE)
	r.draw_texture_rect_region(r.zone_impact_atlas, Rect2(-size * 0.5, size), zone_impact_src(frame), Color(1.0, 1.0, 1.0, alpha))
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
