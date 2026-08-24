class_name DeployableSystem
extends RefCounted

var w

func _init(world) -> void:
	w = world

func place_mine(owner: int, desired_pos: Vector2, damage: float, blast_radius: float, arm_time: float = 0.62, lifetime: float = 8.0, fuse_time: float = 0.38, ultimate_mine: bool = false, auto_detonate: float = -1.0) -> void:
	var owner_pos: Vector2 = w.heroes[owner]["pos"]
	var mine_pos = w.arena.resolve_cover_motion(owner_pos, desired_pos - owner_pos)
	mine_pos.x = clampf(mine_pos.x, w.ARENA_MARGIN + 18.0, w.ARENA_SIZE.x - w.ARENA_MARGIN - 18.0)
	mine_pos.y = clampf(mine_pos.y, w.ARENA_MARGIN + 18.0, w.ARENA_SIZE.y - w.ARENA_MARGIN - 18.0)
	if not ultimate_mine:
		var owner_mines: Array[int] = []
		for mine_index in range(w.deployables.size()):
			if int(w.deployables[mine_index]["owner"]) == owner and not bool(w.deployables[mine_index].get("ultimate", false)):
				owner_mines.append(mine_index)
		if owner_mines.size() >= 2:
			var removed_index := owner_mines[0]
			w.proj.add_effect(&"mine_fizzle", Vector2(w.deployables[removed_index]["pos"]), 42.0, 0.24, Color("#8ca0b8"), "REPLACED")
			w.deployables.remove_at(removed_index)
	w.deployables.append({
		"id":w.next_entity_id, "type":&"mine", "owner":owner, "pos":mine_pos,
		"damage":damage, "blast_radius":blast_radius,
		"trigger_radius":minf(126.0, blast_radius * 0.72),
		"arm_time":arm_time, "arm_duration":arm_time,
		"lifetime":lifetime, "max_lifetime":lifetime,
		"triggered":false, "fuse_time":fuse_time, "fuse_duration":fuse_time,
		"cc_time":0.55 if ultimate_mine else 0.40,
		"knockback":175.0 if ultimate_mine else 140.0,
		"ultimate":ultimate_mine, "auto_detonate":auto_detonate
	})
	w.next_entity_id += 1
	w.proj.add_effect(&"mine_place", mine_pos, 48.0, 0.28, Color("#ff765f"), "MINE")
	w.event_log.emit(w.tick, &"mine_placed", owner, -1, {"ultimate":ultimate_mine})

func place_bounce_wall(owner: int, desired_pos: Vector2, facing: Vector2, half_length: float, lifetime: float, speed: float, damage: float, knockback: float) -> void:
	for wall_index in range(w.deployables.size() - 1, -1, -1):
		if int(w.deployables[wall_index]["owner"]) == owner and StringName(w.deployables[wall_index].get("type", &"mine")) == &"wall":
			w.proj.add_effect(&"mine_fizzle", Vector2(w.deployables[wall_index]["pos"]), 58.0, 0.26, Color("#8de1ff"), "REPLACED")
			w.deployables.remove_at(wall_index)
	var owner_pos: Vector2 = w.heroes[owner]["pos"]
	var wall_pos = w.arena.resolve_cover_motion(owner_pos, desired_pos - owner_pos)
	var travel_direction = w.dmg.attack_direction(facing)
	wall_pos.x = clampf(wall_pos.x, w.ARENA_MARGIN + 26.0, w.ARENA_SIZE.x - w.ARENA_MARGIN - 26.0)
	wall_pos.y = clampf(wall_pos.y, w.ARENA_MARGIN + 26.0, w.ARENA_SIZE.y - w.ARENA_MARGIN - 26.0)
	w.deployables.append({
		"id":w.next_entity_id, "type":&"wall", "owner":owner, "pos":wall_pos,
		"direction":travel_direction.orthogonal(), "travel_direction":travel_direction,
		"half_length":half_length, "speed":speed, "damage":damage, "knockback":knockback,
		"arm_time":0.18, "arm_duration":0.18,
		"lifetime":lifetime, "max_lifetime":lifetime, "hit_slots":[], "hit_cores":[]
	})
	w.next_entity_id += 1
	w.proj.add_effect(&"charge_release", wall_pos, half_length, 0.18, Color("#8de1ff"), "INCOMING", travel_direction)
	w.event_log.emit(w.tick, &"wall_placed", owner, -1, {"half_length":half_length, "speed":speed})

func moving_wall_sweep(wall: Dictionary, old_pos: Vector2, new_pos: Vector2) -> Dictionary:
	var owner := int(wall["owner"])
	var forward := Vector2(wall["travel_direction"]).normalized()
	var side := Vector2(wall["direction"]).normalized()
	var travel_distance := old_pos.distance_to(new_pos)
	var hit_slots: Array = wall.get("hit_slots", [])
	for target in range(w.PLAYER_COUNT):
		if target == owner or target in hit_slots or not bool(w.heroes[target]["alive"]):
			continue
		var relative := Vector2(w.heroes[target]["pos"]) - old_pos
		var forward_distance := relative.dot(forward)
		var side_distance := absf(relative.dot(side))
		if forward_distance < -w.HERO_RADIUS - 10.0 or forward_distance > travel_distance + w.HERO_RADIUS + 14.0 or side_distance > float(wall["half_length"]) + w.HERO_RADIUS:
			continue
		hit_slots.append(target)
		w.dmg.damage_hero(owner, target, float(wall["damage"]), &"equipment", 0.32, float(wall["knockback"]), Vector2(w.heroes[target]["pos"]) - forward * 34.0, "WALL SLAM", &"shield_bash", true)
		var victim: Dictionary = w.heroes[target]
		victim["wall_hit_cd"] = 0.78
		w.heroes[target] = victim
		w.proj.add_effect(&"wall_impact", Vector2(w.heroes[target]["pos"]), 102.0, 0.30, Color("#8de1ff"), "SLAM", forward)
	wall["hit_slots"] = hit_slots
	var hit_cores: Array = wall.get("hit_cores", [])
	for target in range(w.PLAYER_COUNT):
		if target == owner or target in hit_cores or not bool(w.cores[target]["alive"]) or not w._core_exposed(target):
			continue
		var relative := Vector2(w.cores[target]["pos"]) - old_pos
		if relative.dot(forward) < -w.CORE_RADIUS or relative.dot(forward) > travel_distance + w.CORE_RADIUS or absf(relative.dot(side)) > float(wall["half_length"]) + w.CORE_RADIUS:
			continue
		hit_cores.append(target)
		w.dmg.damage_core(owner, target, float(wall["damage"]) * 0.62, &"equipment")
	wall["hit_cores"] = hit_cores
	return wall

func mine_has_target(mine: Dictionary) -> bool:
	var owner := int(mine["owner"])
	var mine_pos: Vector2 = mine["pos"]
	var trigger_radius := float(mine["trigger_radius"])
	for target in range(w.PLAYER_COUNT):
		if target == owner:
			continue
		if bool(w.heroes[target]["alive"]) and mine_pos.distance_to(Vector2(w.heroes[target]["pos"])) <= trigger_radius + w.HERO_RADIUS:
			return true
		if bool(w.cores[target]["alive"]) and w._core_exposed(target) and mine_pos.distance_to(Vector2(w.cores[target]["pos"])) <= trigger_radius + w.CORE_RADIUS:
			return true
	return false

func update_deployables(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for mine0 in w.deployables:
		var mine: Dictionary = mine0
		if StringName(mine.get("type", &"mine")) == &"wall":
			if float(mine.get("arm_time", 0.0)) > 0.0:
				mine["arm_time"] = maxf(0.0, float(mine["arm_time"]) - dt)
				kept.append(mine)
				continue
			mine["lifetime"] = float(mine["lifetime"]) - dt
			if float(mine["lifetime"]) <= 0.0:
				w.proj.add_effect(&"mine_fizzle", Vector2(mine["pos"]), float(mine["half_length"]), 0.24, Color("#8de1ff"), "")
				continue
			var old_wall_pos: Vector2 = mine["pos"]
			var wall_motion := Vector2(mine["travel_direction"]) * float(mine["speed"]) * dt
			var next_wall_pos := old_wall_pos + wall_motion
			var hit_boundary = next_wall_pos.x < w.ARENA_MARGIN + 24.0 or next_wall_pos.x > w.ARENA_SIZE.x - w.ARENA_MARGIN - 24.0 or next_wall_pos.y < w.ARENA_MARGIN + 24.0 or next_wall_pos.y > w.ARENA_SIZE.y - w.ARENA_MARGIN - 24.0
			var hit_cover = w.arena.point_in_cover(next_wall_pos, 34.0)
			if hit_boundary or hit_cover:
				w.proj.add_effect(&"wall_impact", old_wall_pos, float(mine["half_length"]), 0.30, Color("#8de1ff"), "CRASH", Vector2(mine["travel_direction"]))
				continue
			mine["pos"] = next_wall_pos
			mine = moving_wall_sweep(mine, old_wall_pos, next_wall_pos)
			kept.append(mine)
			continue
		mine["lifetime"] = float(mine["lifetime"]) - dt
		if float(mine["lifetime"]) <= 0.0:
			w.proj.add_effect(&"mine_fizzle", Vector2(mine["pos"]), 42.0, 0.24, Color("#8ca0b8"), "EXPIRED")
			continue
		if float(mine["arm_time"]) > 0.0:
			mine["arm_time"] = maxf(0.0, float(mine["arm_time"]) - dt)
			kept.append(mine)
			continue
		if not bool(mine["triggered"]):
			if float(mine.get("auto_detonate", -1.0)) >= 0.0:
				mine["auto_detonate"] = float(mine["auto_detonate"]) - dt
			if mine_has_target(mine) or (float(mine.get("auto_detonate", -1.0)) >= -0.5 and float(mine.get("auto_detonate", -1.0)) <= 0.0):
				mine["triggered"] = true
				mine["fuse_time"] = float(mine["fuse_duration"])
				w.proj.add_effect(&"fuse", Vector2(mine["pos"]), float(mine["trigger_radius"]), float(mine["fuse_duration"]), Color("#ff554a"), "MOVE!")
				w.event_log.emit(w.tick, &"mine_triggered", int(mine["owner"]), -1, {})
			kept.append(mine)
			continue
		mine["fuse_time"] = float(mine["fuse_time"]) - dt
		if float(mine["fuse_time"]) <= 0.0:
			w.proj.add_zone(int(mine["owner"]), Vector2(mine["pos"]), float(mine["blast_radius"]), 0.01, float(mine["damage"]), &"ultimate" if bool(mine["ultimate"]) else &"equipment", float(mine["cc_time"]), float(mine["knockback"]), "PANIC MINE" if bool(mine["ultimate"]) else "PROX MINE", Color("#ff554a"), false, &"explosion", true)
			continue
		kept.append(mine)
	w.deployables = kept

func deployable_wall_hit(slot: int, old_pos: Vector2, new_pos: Vector2) -> Dictionary:
	if float(w.heroes[slot].get("wall_hit_cd", 0.0)) > 0.0:
		return {}
	for wall in w.deployables:
		if StringName(wall.get("type", &"mine")) != &"wall" or int(wall["owner"]) == slot or float(wall.get("arm_time", 0.0)) > 0.0 or slot in Array(wall.get("hit_slots", [])):
			continue
		var wall_pos: Vector2 = wall["pos"]
		var wall_dir := Vector2(wall["direction"]).normalized()
		var wall_a := wall_pos - wall_dir * float(wall["half_length"])
		var wall_b := wall_pos + wall_dir * float(wall["half_length"])
		var closest := Geometry2D.get_closest_point_to_segment(new_pos, wall_a, wall_b)
		var crossed := Geometry2D.segment_intersects_segment(old_pos, new_pos, wall_a, wall_b) != null
		if not crossed and new_pos.distance_to(closest) > w.HERO_RADIUS + 9.0:
			continue
		var normal := Vector2(wall.get("travel_direction", wall_dir.orthogonal())).normalized()
		if not crossed and (new_pos - old_pos).dot(normal) >= 0.0:
			continue
		return {"id":int(wall["id"]), "owner":int(wall["owner"]), "pos":closest, "normal":normal, "damage":float(wall["damage"]), "knockback":float(wall["knockback"])}
	return {}

func mark_wall_hit(wall_id: int, slot: int) -> void:
	for index in range(w.deployables.size()):
		if int(w.deployables[index].get("id", -1)) != wall_id:
			continue
		var hit_slots: Array = w.deployables[index].get("hit_slots", [])
		if slot not in hit_slots:
			hit_slots.append(slot)
			w.deployables[index]["hit_slots"] = hit_slots
		return
