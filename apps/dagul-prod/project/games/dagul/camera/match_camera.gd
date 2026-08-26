class_name MatchCamera
extends RefCounted

## Camera zoom, shake, and target tracking for a match.

var camera: Camera2D


func _init(cam: Camera2D) -> void:
	camera = cam


func compute_shake(world) -> Vector2:
	var shake := Vector2.ZERO
	if int(world.get("local_hit_shake")) > 0:
		var hit_n: int = int(world.local_hit_shake)
		shake = Vector2(sin(float(world.tick) * 5.2), cos(float(world.tick) * 7.1)) * (8.2 + float(hit_n) * 1.05)
	var fire_n: int = int(world.local_fire_shake)
	if fire_n > 0:
		shake += Vector2(sin(float(world.tick) * 11.0), cos(float(world.tick) * 13.4)) * (5.5 + float(fire_n) * 0.95)
	elif world.impact_ticks > 0:
		var target := _focus_pos(world, world.local_slot)
		var impact_distance := target.distance_to(Vector2(world.impact_pos))
		var attenuation := 1.0 - clampf(impact_distance / 900.0, 0.0, 0.90)
		shake = Vector2(sin(float(world.tick) * 2.8), cos(float(world.tick) * 4.1)) * (2.0 + world.impact_ticks * 0.4) * attenuation
	return shake


func zoom_target(world, spectate_slot: int) -> float:
	if world == null or world.heroes.is_empty():
		return 1.38
	if world.result != &"playing" and world.winner_slot >= 0:
		return 1.52
	if world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot == world.local_slot:
		return 1.48
	var me_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
	if not bool(world.heroes[me_slot]["alive"]):
		return 1.18
	var focus_pos: Vector2 = world.heroes[me_slot]["pos"]
	var nearby := 0
	for hero in world.heroes:
		if bool(hero["alive"]) and Vector2(hero["pos"]).distance_to(focus_pos) < 470.0:
			nearby += 1
	if nearby >= 4:
		return 1.20
	if nearby >= 2:
		return 1.28
	return 1.38


func target(world, spectate_slot: int, spectator_valid_fn: Callable) -> Vector2:
	if world == null:
		return Vector2(3920.0, 2380.0)
	if world.heroes.is_empty():
		return Vector2(world.ARENA_CENTER)
	var focus_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
	if world.result != &"playing" and world.winner_slot >= 0:
		focus_slot = world.winner_slot
	elif world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot == world.local_slot:
		focus_slot = world.local_slot
	elif bool(world.heroes[focus_slot]["eliminated"]) and spectator_valid_fn.call(spectate_slot):
		focus_slot = spectate_slot
	var focus: Dictionary = world.heroes[focus_slot]
	var cinematic: bool = (world.ultimate_focus_time > 0.0 and focus_slot == world.ultimate_focus_slot) or (world.result != &"playing" and focus_slot == world.winner_slot)
	var look_ahead := Vector2(focus["aim"]) * (52.0 if cinematic else (85.0 if focus_slot != world.local_slot else 135.0))
	look_ahead += Vector2(focus["vel"]) * 0.16
	look_ahead.y = maxf(look_ahead.y, -28.0)
	var zoom_value := maxf(1.10, camera.zoom.x)
	var hud_reserve := 150.0 / zoom_value
	var desired := Vector2(focus["pos"]) + look_ahead + Vector2(0.0, hud_reserve * 0.45)
	var half_view := Vector2(800.0, 450.0) / zoom_value
	var min_y := half_view.y + hud_reserve * 0.15
	return Vector2(clampf(desired.x, half_view.x, world.ARENA_SIZE.x - half_view.x), clampf(desired.y, min_y, world.ARENA_SIZE.y - half_view.y))


func update(world, spectate_slot: int, spectator_valid_fn: Callable) -> void:
	var shake := compute_shake(world)
	var zt := zoom_target(world, spectate_slot)
	camera.zoom = camera.zoom.lerp(Vector2.ONE * zt, 0.065)
	var camera_follow := 0.24 if world.ultimate_focus_time > 0.0 and world.ultimate_focus_slot == world.local_slot else 0.42
	camera.position = camera.position.lerp(target(world, spectate_slot, spectator_valid_fn), camera_follow) + shake


func _focus_pos(world, slot: int) -> Vector2:
	if world == null or world.heroes.is_empty():
		return Vector2.ZERO
	var me: Dictionary = world.heroes[clampi(slot, 0, world.heroes.size() - 1)]
	return Vector2(me["pos"])
