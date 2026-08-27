class_name RenderHeroes
extends RefCounted

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer

func draw_blob_shadow(ground_pos: Vector2, hop_lift: float, opacity: float) -> void:
	var height_t: float = clampf(hop_lift / 19.0, 0.0, 1.0)
	var size_mul: float = lerpf(1.0, 0.52, height_t)
	var alpha_mul: float = lerpf(1.0, 0.38, height_t)
	var radius_x: float = 26.0 * size_mul
	var radius_y: float = 11.5 * size_mul
	var center: Vector2 = ground_pos + Vector2(1.5, 34.0)
	if r.character_shadow_tex != null:
		var shadow_size := Vector2(radius_x * 2.4, radius_y * 2.4)
		r.draw_texture_rect(r.character_shadow_tex, Rect2(center - shadow_size * 0.5, shadow_size), false, Color(1.0, 1.0, 1.0, alpha_mul * opacity))
		return
	r.draw_set_transform(center, 0.0, Vector2(1.0, radius_y / radius_x))
	var rings: Array = [[1.00, 0.07], [0.88, 0.10], [0.74, 0.13], [0.58, 0.16], [0.40, 0.17], [0.22, 0.14]]
	for ring in rings:
		r.draw_circle(Vector2.ZERO, radius_x * float(ring[0]), Color(0.0, 0.0, 0.0, float(ring[1]) * alpha_mul * opacity))
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_hero_sprite(pos: Vector2, slot: int, aim: Vector2, opacity: float = 1.0, hop_lift: float = 0.0, hop_scale: Vector2 = Vector2.ONE, hit_flash: float = 0.0, lean: float = 0.0) -> void:
	var hit_tint: Color = Color(3.4, 3.4, 3.4, opacity) if hit_flash > 0.0 else Color(1.0, 1.0, 1.0, opacity)
	if hit_flash <= 0.0 and world != null and pos.distance_to(Vector2(world.safe_zone_center)) > float(world.safe_zone_radius):
		var zone_flicker := 0.78 + 0.12 * sin(float(world.tick) * 0.34 + float(slot))
		hit_tint = Color(1.08, zone_flicker, 1.28, opacity)
	draw_blob_shadow(pos, hop_lift, opacity)
	r.draw_arc(pos, 30.0, 0.0, TAU, 28, Color(r._slot_color(slot), 0.85 * opacity), 3.5)
	var sprite_pos: Vector2 = pos + Vector2(0.0, -hop_lift)
	var flip: float = -1.0 if aim.x < -0.05 else 1.0
	var draw_scale: Vector2 = Vector2(flip * hop_scale.x, hop_scale.y)
	if r.animal_atlas != null:
		r.draw_set_transform(sprite_pos, lean, draw_scale)
		r.draw_texture_rect_region(r.animal_atlas, Rect2(Vector2(-36.0, -36.0), Vector2(72.0, 72.0)), r._animal_src_rect(slot), hit_tint)
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var tex = r._zodiac_texture(slot)
		if tex != null:
			r.draw_set_transform(sprite_pos, lean, draw_scale)
			r.draw_texture_rect(tex, Rect2(Vector2(-33.0, -33.0), Vector2(66.0, 66.0)), false, hit_tint)
			r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			r.draw_circle(sprite_pos, 22.0, Color(r._slot_color(slot), opacity))
			r.draw_arc(sprite_pos, 22.0, 0.0, TAU, 24, Color(0.0, 0.0, 0.0, 0.8 * opacity), 3.0)

func draw_hero_gun(pos: Vector2, slot: int, aim: Vector2, opacity: float = 1.0, extra_squash: float = 0.0) -> void:
	r._draw_hero_gun(pos, slot, aim, opacity, extra_squash)

func draw_down_sprite(pos: Vector2, animal: int, opacity: float = 1.0, rotation: float = 0.0, size: float = 78.0) -> bool:
	if r.animal_down_atlas == null:
		return false
	r.draw_set_transform(pos, rotation, Vector2.ONE)
	r.draw_texture_rect_region(r.animal_down_atlas, Rect2(Vector2(-size * 0.5, -size * 0.5), Vector2.ONE * size), r._animal_down_src_rect(animal), Color(1.0, 1.0, 1.0, opacity))
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func draw_emote(body_pos: Vector2, hero: Dictionary, slot: int) -> void:
	if float(hero.get("emote_time", 0.0)) <= 0.0:
		return
	var animal := posmod(int(hero.get("animal", slot)), 12)
	var texture: Texture2D = r.emote_atlases.get(animal)
	if texture == null:
		return
	var frame := clampi(int(hero.get("emote", 0)), 0, 3)
	var cell := Vector2(float(texture.get_width()) / 4.0, float(texture.get_height()))
	var size := Vector2(132.0, 99.0)
	var center := body_pos + Vector2(-78.0, -68.0)
	var alpha := clampf(float(hero.get("emote_time", 0.0)) * 3.0, 0.0, 1.0)
	r.draw_texture_rect_region(texture, Rect2(center - size * 0.5, size), Rect2(Vector2(cell.x * frame, 0.0), cell), Color(1.0, 1.0, 1.0, alpha))

func draw_dog_alert(body_pos: Vector2, hero: Dictionary) -> void:
	if float(hero.get("dog_windup", 0.0)) <= 0.0 and not bool(hero.get("dog_rush", false)):
		return
	var mark := body_pos + Vector2(0.0, -112.0)
	var frame := posmod(int(world.tick / 4), 4)
	if r.draw_ultimate_frame(10, mark, Vector2.ONE * 72.0, frame, 0, 0.0, 0.92):
		return
	var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.018)
	r.draw_circle(mark, 16.0 * pulse, Color("#ff2a2a"))
	r.draw_circle(mark, 13.0 * pulse, Color("#ffef6a"))
	r.draw_string(GameFont.get_font(), mark + Vector2(-16.0, 10.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 32.0, 28, Color("#d40000"))

func draw_flee_mark(body_pos: Vector2, hero: Dictionary) -> void:
	if float(hero.get("flee_time", 0.0)) <= 0.0:
		return
	if r.flee_icon_tex == null:
		r.flee_icon_tex = r._load_tex("res://assets/fx/flee-icon.png")
	var mark := body_pos + Vector2(0.0, -118.0)
	if r.flee_icon_tex != null:
		r.draw_texture_rect(r.flee_icon_tex, Rect2(mark + Vector2(-28.0, -22.0), Vector2(56.0, 44.0)), false)
	else:
		r.draw_circle(mark, 16.0, Color("#ffcc33"))
	r.draw_string(GameFont.get_font(), mark + Vector2(-30.0, 28.0), "도망", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 12, Color("#ffe066"))

func draw_nametag(pos: Vector2, slot: int, hp_ratio: float, opacity: float = 1.0, display_name: String = "", wanted: bool = false, kill_streak: int = 0) -> void:
	var tag := display_name if display_name != "" else "P%d" % (slot + 1)
	var plate := Rect2(pos + Vector2(-47.0, -84.0), Vector2(94.0, 17.0))
	var slot_color := Color(r._slot_color(slot), opacity)
	var plate_points := PackedVector2Array([
		plate.position + Vector2(4.0, 0.0), plate.position + Vector2(plate.size.x, 0.0),
		plate.position + plate.size, plate.position + Vector2(0.0, plate.size.y),
		plate.position + Vector2(0.0, 4.0), plate.position + Vector2(4.0, 0.0),
	])
	r.draw_colored_polygon(plate_points, Color(0.015, 0.022, 0.034, 0.84 * opacity))
	r.draw_polyline(plate_points, Color(slot_color, 0.88 if slot == world.local_slot else 0.55), 1.5)
	r.draw_string(GameFont.get_font(), plate.position + Vector2(3.0, 13.0), tag, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x - 6.0, 12, Color(1.0, 1.0, 1.0, opacity))
	if wanted:
		var badge := Rect2(plate.position + Vector2(-17.0, 0.0), Vector2(14.0, 17.0))
		r.draw_rect(badge, Color("#7a121c", 0.92 * opacity))
		r.draw_rect(badge, Color("#ff5d73", opacity), false, 1.5)
		r.draw_string(GameFont.get_font(), badge.position + Vector2(0.0, 14.0), "!", HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 13, Color("#ffd166", opacity))
	if kill_streak >= 2:
		var streak_badge := Rect2(plate.position + Vector2(plate.size.x + 3.0, 0.0), Vector2(23.0, 17.0))
		r.draw_rect(streak_badge, Color(0.10, 0.07, 0.02, 0.88 * opacity))
		r.draw_rect(streak_badge, Color("#ffd166", 0.82 * opacity), false, 1.5)
		r.draw_string(GameFont.get_font(), streak_badge.position + Vector2(1.0, 13.0), "x%d" % kill_streak, HORIZONTAL_ALIGNMENT_CENTER, streak_badge.size.x - 2.0, 10, Color("#ffd166", opacity))
	var hp_color := Color("#3fe37a")
	if hp_ratio <= 0.30:
		hp_color = Color("#ff5d73")
	elif hp_ratio <= 0.60:
		hp_color = Color("#ffb347")
	var segments := 8
	var gap := 2.0
	var hp_rect := Rect2(pos + Vector2(-42.0, -63.0), Vector2(84.0, 9.0))
	var segment_width := (hp_rect.size.x - gap * float(segments - 1)) / float(segments)
	var filled_units := clampf(hp_ratio, 0.0, 1.0) * float(segments)
	for index in range(segments):
		var block := Rect2(hp_rect.position + Vector2(float(index) * (segment_width + gap), 0.0), Vector2(segment_width, hp_rect.size.y))
		var portion := clampf(filled_units - float(index), 0.0, 1.0)
		r.draw_rect(block, Color(0.025, 0.035, 0.050, 0.88 * opacity))
		if portion > 0.0:
			r.draw_rect(Rect2(block.position + Vector2(1.0, 1.0), Vector2((block.size.x - 2.0) * portion, block.size.y - 2.0)), Color(hp_color, opacity))
		r.draw_rect(block, Color(hp_color, (0.62 if portion > 0.0 else 0.18) * opacity), false, 1.0)

func draw_knockouts() -> void:
	for knockout in world.knockouts:
		var knockout_slot := int(knockout["slot"])
		var knockout_fade := clampf(float(knockout["time"]) / 0.42, 0.0, 1.0)
		var knockout_pos: Vector2 = knockout["pos"]
		if not r.is_world_visible(knockout_pos, 320.0):
			continue
		var spin := float(knockout.get("max_time", 1.0)) - float(knockout["time"])
		var knockout_trail: Array = knockout.get("trail", [])
		if r.knockout_trail_atlas != null and not knockout_trail.is_empty():
			var trail_origin: Vector2 = knockout_trail[0]
			var trail_vector := knockout_pos - trail_origin
			if trail_vector.length_squared() > 1.0:
				var trail_frame := posmod(int(spin / 0.065), 4)
				var trail_length := clampf(trail_vector.length() + 52.0, 84.0, 260.0)
				var trail_center := knockout_pos - trail_vector.normalized() * trail_length * 0.43
				var trail_rect := Rect2(Vector2(-trail_length * 0.5, -38.0), Vector2(trail_length, 76.0))
				r.draw_set_transform(trail_center, trail_vector.angle(), Vector2.ONE)
				r.draw_texture_rect_region(r.knockout_trail_atlas, trail_rect, r._horizontal_fx_src_rect(r.knockout_trail_atlas, 4, trail_frame), Color(1.0, 1.0, 1.0, knockout_fade))
				r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			r._draw_motion_trail(knockout_trail, r._slot_color(knockout_slot), 9.0, knockout_fade)
		if r.animal_down_atlas != null:
			draw_down_sprite(knockout_pos, knockout_slot, 0.78 * knockout_fade, spin * 5.0, 68.0)
		elif r.animal_atlas != null:
			r.draw_set_transform(knockout_pos, spin * 5.0, Vector2.ONE)
			r.draw_texture_rect_region(r.animal_atlas, Rect2(Vector2(-30.0, -30.0), Vector2(60.0, 60.0)), r._animal_src_rect(knockout_slot), Color(1.0, 1.0, 1.0, 0.72 * knockout_fade))
			r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var tex = r._zodiac_texture(knockout_slot)
			if tex != null:
				r.draw_set_transform(knockout_pos, spin * 5.0, Vector2.ONE)
				r.draw_texture_rect(tex, Rect2(Vector2(-30.0, -30.0), Vector2(60.0, 60.0)), false, Color(1.0, 1.0, 1.0, 0.72 * knockout_fade))
				r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				r.draw_circle(knockout_pos, 22.0, Color(r._slot_color(knockout_slot), 0.72 * knockout_fade))

func _timed_ids(hero: Dictionary) -> Array:
	var ids: Array = []
	for buff in hero.get("rl_timed", []):
		ids.append(str(buff.get("id", "")))
	return ids

func _timed_body_scale(hero: Dictionary) -> float:
	var ids: Array = _timed_ids(hero)
	if ids.has("double_giant"):
		return 2.05
	if ids.has("giant"):
		return 1.55
	if ids.has("turtle"):
		return 0.0
	return 1.0

func draw_smoke_lost_self(hero: Dictionary) -> void:
	var pos: Vector2 = hero.get("pos", Vector2.ZERO)
	var wob := Vector2(sin(float(world.tick) * 0.21) * 54.0, cos(float(world.tick) * 0.17) * 46.0)
	var ghost: Vector2 = pos + wob
	var aim := Vector2(hero.get("aim", Vector2.RIGHT))
	var animal := int(hero.get("animal", 0))
	draw_hero_sprite(ghost, animal, aim, 0.28, 0.0, Vector2(1.05, 0.92), 0.0)

func draw_wool_shields() -> void:
	if world == null:
		return
	if r.wool_shield_tex == null:
		r.wool_shield_tex = r._load_tex("res://assets/fx/sheep-wool-ring.png")
	for hero in world.heroes:
		if float(hero.get("wool_time", 0.0)) <= 0.0 or int(hero.get("wool_hp", 0)) <= 0:
			continue
		if bool(hero.get("eliminated", false)) or not bool(hero.get("alive", false)):
			continue
		var pos: Vector2 = hero["pos"]
		if not r.is_world_visible(pos, 180.0):
			continue
		var hp_a := clampf(float(hero.get("wool_hp", 0)) / maxf(1.0, float(hero.get("wool_max", 5))), 0.45, 1.0)
		var sz := 164.0
		if r.draw_ultimate_frame(7, pos, Vector2.ONE * sz, posmod(int(world.tick / 6), 4), 0, 0.0, maxf(0.82, hp_a)):
			pass
		elif r.wool_shield_tex != null:
			r.draw_texture_rect(r.wool_shield_tex, Rect2(pos - Vector2(sz, sz) * 0.5, Vector2.ONE * sz), false, Color(1.0, 1.0, 1.0, maxf(0.82, hp_a)))
		else:
			r.draw_arc(pos, 56.0, 0.0, TAU, 40, Color(1.0, 0.96, 0.88, 0.95), 14.0)

func draw_dog_bones() -> void:
	if world == null:
		return
	if r.dog_bone_tex == null:
		r.dog_bone_tex = r._load_tex("res://assets/fx/dog-bone.png")
	for bone in world.dog_bones:
		var pos: Vector2 = bone.get("pos", Vector2.ZERO)
		if not r.is_world_visible(pos, 100.0):
			continue
		if r.dog_bone_tex != null:
			r.draw_texture_rect(r.dog_bone_tex, Rect2(pos + Vector2(-48.0, -22.0), Vector2(96.0, 44.0)), false)
		else:
			r.draw_circle(pos, 12.0, Color("#f3efe4"))

func draw_pig_muds() -> void:
	if world == null:
		return
	if r.pig_mud_tex == null:
		r.pig_mud_tex = r._load_tex("res://assets/fx/pig-mud.png")
	for mud in world.pig_muds:
		var pos: Vector2 = mud.get("pos", Vector2.ZERO)
		var rad := float(mud.get("radius", 200.0))
		if not r.is_world_visible(pos, rad + 48.0):
			continue
		var ttl := float(mud.get("ttl", 0.0))
		var fade := clampf(ttl / 1.4, 0.0, 1.0)
		var sz := rad * 2.15
		if r.draw_ultimate_frame(11, pos, Vector2(sz, sz * 0.76), posmod(int(world.tick / 8), 4), 0, 0.0, 0.4 + 0.6 * fade):
			pass
		elif r.pig_mud_tex != null:
			r.draw_texture_rect(r.pig_mud_tex, Rect2(pos - Vector2(sz * 0.5, sz * 0.38), Vector2(sz, sz * 0.76)), false, Color(1, 1, 1, 0.4 + 0.6 * fade))
		else:
			r.draw_circle(pos, rad, Color(0.36, 0.22, 0.08, 0.55 * fade))
		r.draw_arc(pos, rad, 0.0, TAU, 48, Color(0.42, 0.24, 0.08, 0.55 * fade), 3.0)

func draw_rooster_eggs() -> void:
	if world == null:
		return
	for egg in world.rooster_eggs:
		if not bool(egg.get("alive", true)):
			continue
		var pos: Vector2 = egg.get("pos", Vector2.ZERO)
		if not r.is_world_visible(pos, 80.0):
			continue
		var arm := float(egg.get("arm", 0.0))
		var ttl := float(egg.get("ttl", 0.0))
		var frame := 0 if arm > 0.35 else (1 if arm > 0.0 else 2 + posmod(int(ttl * 8.0), 2))
		if not r.draw_ultimate_frame(9, pos + Vector2(0.0, -4.0), Vector2.ONE * 58.0, frame, 0):
			r.draw_circle(pos, 16.0, Color("#f4e6c8"))

func draw_horse_kicks() -> void:
	if world == null:
		return
	for kick in world.horse_kicks:
		var pos: Vector2 = kick.get("pos", Vector2.ZERO)
		var dir: Vector2 = kick.get("dir", Vector2.LEFT)
		if dir.length_squared() < 0.01:
			dir = Vector2.LEFT
		dir = dir.normalized()
		var reach := float(kick.get("reach", 400.0))
		if not r.is_world_visible(pos, reach + 80.0):
			continue
		var t := clampf(float(kick.get("age", 0.0)) / maxf(0.01, float(kick.get("life", 0.42))), 0.0, 1.0)
		var fade := 1.0 - t
		var ang := dir.angle()
		var frame := clampi(int(t * 4.0), 0, 3)
		if not r.draw_ultimate_frame(6, pos + dir * reach * 0.28, Vector2(reach * 1.18, reach * 0.82), frame, 0, ang, fade):
			r.draw_arc(pos, reach * (0.35 + t * 0.65), ang - 1.15, ang + 1.15, 28, Color(0.92, 0.72, 0.32, 0.85 * fade), 7.0)

func draw_rabbit_holes() -> void:
	if world == null:
		return
	if r.rabbit_hole_tex == null:
		r.rabbit_hole_tex = r._load_tex("res://assets/fx/rabbit-hole.png")
	for hole in world.rabbit_holes:
		var pos: Vector2 = hole.get("pos", Vector2.ZERO)
		if not r.is_world_visible(pos, 100.0):
			continue
		var ttl := float(hole.get("ttl", 0.0))
		var fade := clampf(ttl / 1.2, 0.0, 1.0)
		var sz := 118.0
		var is_entry := str(hole.get("kind", "in")) == "in"
		var row := 0 if is_entry else 1
		var initial_ttl := 4.5 if is_entry else 3.5
		var animation_age := maxf(0.0, initial_ttl - ttl)
		var frame := clampi(int(animation_age / 0.12), 0, 3)
		if r.draw_ultimate_frame(3, pos, Vector2(sz, sz * 0.86), frame, row, 0.0, 0.35 + 0.65 * fade):
			pass
		elif r.rabbit_hole_tex != null:
			r.draw_texture_rect(r.rabbit_hole_tex, Rect2(pos - Vector2(sz * 0.5, sz * 0.42), Vector2(sz, sz * 0.86)), false, Color(1, 1, 1, 0.35 + 0.65 * fade))
		else:
			r.draw_circle(pos, 34.0, Color(0.18, 0.08, 0.04, 0.85 * fade))

func draw_tiger_roars() -> void:
	if world == null:
		return
	for roar_data in world.tiger_roars:
		var pos: Vector2 = roar_data.get("pos", Vector2.ZERO)
		var rad := float(roar_data.get("radius", 300.0))
		if not r.is_world_visible(pos, rad + 80.0):
			continue
		var life := maxf(0.01, float(roar_data.get("life", 1.15)))
		var age := float(roar_data.get("age", 0.0))
		var t := clampf(age / life, 0.0, 1.0)
		var front := rad * t
		var fade := 1.0 - t * 0.28
		var sprite_frame := clampi(int(age / 0.085), 0, 7)
		var frame := sprite_frame % 4
		var row := int(sprite_frame / 4)
		if not r.draw_ultimate_frame(2, pos, Vector2.ONE * maxf(84.0, front * 2.15), frame, row, 0.0, fade):
			r.draw_arc(pos, front, 0.0, TAU, 64, Color(1.0, 0.86, 0.26, 0.95 * fade), 8.0)

func draw_dragon_smokes() -> void:
	if world == null:
		return
	if r.dragon_smoke_tex == null:
		r.dragon_smoke_tex = r._load_tex("res://assets/fx/dragon-smoke.png")
	for smoke in world.dragon_smokes:
		var pos: Vector2 = smoke.get("pos", Vector2.ZERO)
		var rad := float(smoke.get("radius", 300.0))
		if not r.is_world_visible(pos, rad + 48.0):
			continue
		var life := clampf(float(smoke.get("ttl", 0.0)) / 15.0, 0.0, 1.0)
		var sz := rad * 2.0
		if not r.draw_ultimate_frame(4, pos, Vector2.ONE * sz, posmod(int(world.tick / 9), 4), 0, 0.0, 0.78 * life + 0.18) and r.dragon_smoke_tex != null:
			r.draw_texture_rect(r.dragon_smoke_tex, Rect2(pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), false, Color(1.0, 1.0, 1.0, 0.78 * life + 0.18))

func draw_snake_skins() -> void:
	for skin in world.snake_skins:
		if not bool(skin.get("alive", true)):
			continue
		var pos: Vector2 = skin.get("pos", Vector2.ZERO)
		if not r.is_world_visible(pos, 180.0):
			continue
		if world._pos_in_dragon_smoke(pos) and int(skin.get("owner", -1)) != int(world.local_slot):
			continue
		var aim: Vector2 = skin.get("aim", Vector2.RIGHT)
		var flash := float(skin.get("flash", 0.0))
		var sc := float(skin.get("scale", 1.5))
		r.draw_ultimate_frame(5, pos, Vector2.ONE * 132.0 * sc, posmod(int(world.tick / 8), 4), 0, 0.0, 0.58)
		draw_hero_sprite(pos, 5, aim, 0.78, 0.0, Vector2(1.02 * sc, 0.92 * sc), flash)
		var hp_now := float(skin.get("hp", 0.0))
		var hp_max := float(skin.get("max_hp", 1.0))
		var hp_ratio := clampf(hp_now / maxf(1.0, hp_max), 0.0, 1.0)
		var bar := Rect2(pos + Vector2(-42.0, -68.0), Vector2(84.0, 10.0))
		r.draw_rect(bar, Color(0.05, 0.08, 0.06, 0.72))
		r.draw_rect(Rect2(bar.position + Vector2(1.0, 1.0), Vector2((bar.size.x - 2.0) * hp_ratio, bar.size.y - 2.0)), Color("#8fd36a"))
		r.draw_string(GameFont.get_font(), pos + Vector2(-36.0, -76.0), "허물", HORIZONTAL_ALIGNMENT_CENTER, 72.0, 13, Color("#d8f5c4"))

func draw_rat_tides() -> void:
	if world == null:
		return
	if r.rat_run_tex == null:
		r.rat_run_tex = r._load_tex("res://assets/fx/rat-run.png")
	if r.rat_run_tex == null:
		return
	for tide in world.rat_tides:
		var pos: Vector2 = tide.get("pos", Vector2.ZERO)
		var dir: Vector2 = tide.get("dir", Vector2.RIGHT)
		if dir.length_squared() < 0.01:
			dir = Vector2.RIGHT
		dir = dir.normalized()
		var leng := float(tide.get("length", 360.0))
		var half_w := float(tide.get("half_w", 118.0))
		if not r.is_world_visible(pos, leng + half_w):
			continue
		var face_left := dir.x < 0.0
		var travel_angle := dir.angle()
		if face_left:
			travel_angle = wrapf(travel_angle + PI, -PI, PI)
		if r.draw_ultimate_frame(0, pos + dir * leng * 0.16, Vector2(leng * 0.86, half_w * 1.65), posmod(int(world.tick / 5), 4), 0, travel_angle, 1.0, face_left):
			continue

func draw_heroes() -> void:
	for hero in world.heroes:
		var slot := int(hero["slot"])
		if not bool(hero["alive"]):
			continue
		if bool(hero.get("burrowed", false)):
			continue
		if world.hero_hidden_in_smoke(slot):
			continue
		var pos: Vector2 = hero["pos"]
		var speed_margin := minf(Vector2(hero.get("vel", Vector2.ZERO)).length() * 0.35, 260.0)
		if not r.is_world_visible(pos, 220.0 + speed_margin):
			continue
		var aim := Vector2(hero["aim"])
		var is_down := bool(hero.get("downed", false))
		var launch_trail_opacity := clampf(float(hero.get("launch_trail_fade", 0.0)) / 0.34, 0.0, 1.0)
		r._draw_motion_trail(hero.get("launch_trail", []), r._slot_color(slot), 6.5, launch_trail_opacity)
		if float(hero.get("launch_time", 0.0)) > 0.0 and Vector2(hero.get("launch_vel", Vector2.ZERO)).length_squared() > 1.0:
			var launch_dir := Vector2(hero["launch_vel"]).normalized()
			r.draw_line(pos - launch_dir * 94.0, pos - launch_dir * 18.0, Color(r._slot_color(slot), 0.28), 9.0)
		_draw_hero_status_arcs(pos, hero, slot)
		var hop_time: float = float(hero.get("hop_time", 0.0))
		var hop_lift: float = 0.0
		var hop_scale: Vector2 = Vector2.ONE
		if hop_time > 0.0:
			var hop_max: float = maxf(0.001, float(hero.get("hop_max", 0.30)))
			var hop_t: float = clampf(1.0 - hop_time / hop_max, 0.0, 1.0)
			var hop_height: float = float(hero.get("hop_height", 19.0))
			hop_lift = hop_height * sin(PI * hop_t)
			var hop_squash: float = cos(PI * hop_t)
			hop_scale = Vector2(1.00 + 0.12 * hop_squash, 1.02 - 0.14 * hop_squash)
		elif (not is_down) and float(hero.get("launch_time", 0.0)) <= 0.0 and float(hero.get("stun_time", 0.0)) <= 0.0:
			var run_spd := Vector2(hero.get("vel", Vector2.ZERO)).length()
			var run_t := clampf((run_spd - 50.0) / 340.0, 0.0, 1.0)
			if run_t > 0.05:
				var gait := float(world.tick) * 0.20 + float(slot) * 1.37
				var bob := sin(gait)
				hop_lift = 6.8 * run_t * maxf(0.0, bob)
				hop_scale = Vector2(1.0 + 0.08 * run_t * (1.0 - bob), 1.0 + 0.11 * run_t * bob)
				if slot == int(world.local_slot) and posmod(int(world.tick), 90) == 0:
					print("[gangup] run_gait t=" + str(snapped(run_t, 0.01)) + " lift=" + str(snapped(hop_lift, 0.1)) + " state=" + str(hero.get("move_state", "")))
		var plant := float(hero.get("move_plant", 0.0))
		if hop_time <= 0.0 and absf(plant) > 0.03:
			hop_scale = Vector2(hop_scale.x * (1.0 + 0.14 * plant), hop_scale.y * (1.0 - 0.16 * plant))
			if plant > 0.0:
				hop_lift *= (1.0 - 0.55 * plant)
		var lean := 0.0
		if (not is_down) and hop_time <= 0.0 and float(hero.get("launch_time", 0.0)) <= 0.0 and float(hero.get("stun_time", 0.0)) <= 0.0:
			lean = float(hero.get("move_lean", 0.0))
			if absf(lean) < 0.004:
				lean = clampf(Vector2(hero.get("vel", Vector2.ZERO)).x / 400.0, -1.0, 1.0) * 0.14
		var body_pos: Vector2 = pos + Vector2(0.0, -hop_lift)
		var ultimate_animal := posmod(int(hero.get("animal", slot)), 12)
		var ox_phase := str(hero.get("ox_phase", ""))
		if ultimate_animal == 1 and ox_phase != "":
			var ox_dir := Vector2(hero.get("ox_dir", aim)).normalized()
			if ox_dir.length_squared() < 0.01:
				ox_dir = aim.normalized()
			var ox_frame := clampi(int((1.0 - clampf(float(hero.get("ox_time", 0.0)) / (0.38 if ox_phase == "rush" else 0.18), 0.0, 1.0)) * 4.0), 0, 3)
			r.draw_ultimate_frame(1, pos - ox_dir * 42.0, Vector2(178.0, 104.0), ox_frame, 0, ox_dir.angle(), 0.86)
		if ultimate_animal == 8 and float(hero.get("ult_clone_time", 0.0)) > 0.0:
			r.draw_ultimate_frame(8, pos, Vector2.ONE * 148.0, posmod(int(world.tick / 5), 4), 0, 0.0, 0.52)
		if ultimate_animal == 10 and bool(hero.get("dog_rush", false)):
			var dog_dir := Vector2(hero.get("facing", aim)).normalized()
			r.draw_ultimate_frame(10, pos - dog_dir * 46.0, Vector2(158.0, 92.0), posmod(int(world.tick / 4), 4), 1, dog_dir.angle(), 0.78)
		var body_squash := 0.0
		if slot < r.recoil_body.size():
			body_squash = float(r.recoil_body[slot])
		if posmod(int(hero.get("animal", slot)), 12) == 11:
			hop_scale = Vector2(hop_scale.x * (1.0 + body_squash * 1.35), hop_scale.y * (1.0 - body_squash * 1.55))
		else:
			hop_scale = Vector2(hop_scale.x * (1.0 + body_squash), hop_scale.y * (1.0 - body_squash))
		var timed_ids: Array = _timed_ids(hero)
		var is_turtle: bool = timed_ids.has("turtle")
		var body_mul := _timed_body_scale(hero)
		if is_turtle:
			hop_scale = Vector2(1.25, 0.68)
			lean = 0.0
		elif body_mul > 1.01:
			hop_scale = Vector2(hop_scale.x * body_mul, hop_scale.y * body_mul)
		var comb_nudge := 0.0
		if posmod(int(hero.get("animal", slot)), 12) == 9 and r.rooster_comb_lag > 0.0:
			comb_nudge = 1.0
		var ghost := 1.0
		if float(hero.get("spawn_protect_time", 0.0)) > 0.0:
			ghost = 0.38 + 0.38 * absf(sin(float(world.tick) * 0.35))
		if float(hero.get("dmg_orb_time", 0.0)) > 0.0:
			r.draw_arc(pos, 33.0 + sin(float(world.tick) * 0.28) * 2.0, 0.0, TAU, 28, Color(Color("#ff4f4f"), 0.80), 4.0)
		var shield_hp := 0.0
		for buff in hero.get("rl_timed", []):
			shield_hp += float(buff.get("shield", 0.0))
		if (shield_hp > 0.01 or timed_ids.has("shield")) and float(hero.get("wool_time", 0.0)) <= 0.0:
			r.draw_circle(pos, 40.0, Color(0.25, 0.78, 1.0, 0.16))
			r.draw_arc(pos, 42.0 + sin(float(world.tick) * 0.22) * 2.0, 0.0, TAU, 36, Color(Color("#70e7ff"), 0.95), 6.0)
		var hit_flash: float = float(hero.get("hit_flash", 0.0))
		draw_emote(body_pos, hero, slot)
		_draw_hero_body(pos, body_pos, slot, aim, hero, is_down, is_turtle, hop_lift, hop_scale, body_squash, ghost, hit_flash, comb_nudge, timed_ids, lean)
		_draw_hero_buff_icons(body_pos, timed_ids)
		var hp_ratio := maxf(0.0, float(hero["hp"]) / float(hero["max_hp"]))
		var tag := str(hero.get("display_name", ""))
		if tag == "":
			tag = "P%d" % (slot + 1)
		draw_nametag(body_pos, slot, hp_ratio, ghost, tag, slot == world.wanted_slot, int(hero.get("kill_streak", 0)))
		r._overlay.draw_reload_bubble(body_pos, hero)
		r._overlay.draw_head_roulette(body_pos, hero)

func _draw_hero_status_arcs(pos: Vector2, hero: Dictionary, slot: int) -> void:
	if float(hero["cc_time"]) > 0.0:
		r.draw_arc(pos, 34.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(hero["cc_time"]) / 1.5, 0.15, 1.0), 24, Color("#63d8ff"), 5.0)
	if float(hero.get("root_time", 0.0)) > 0.0:
		var root_spin := float(world.tick) * 0.018
		for link_index in range(4):
			var link_dir := Vector2.RIGHT.rotated(root_spin + TAU * float(link_index) / 4.0)
			var link_center := pos + link_dir * 40.0
			r.draw_arc(link_center, 7.0, 0.0, TAU, 12, Color("#b78cff"), 3.0)
			r.draw_line(pos + link_dir * 31.0, pos + link_dir * 36.0, Color("#e2c9ff"), 3.0)
	if float(hero.get("stun_time", 0.0)) > 0.0:
		var stun_spin := float(world.tick) * 0.16
		for star_index in range(3):
			var star_pos := pos + Vector2(26.0, 8.0).rotated(stun_spin + TAU * float(star_index) / 3.0) + Vector2(0.0, -58.0)
			if r.stun_spin_tex != null:
				r.draw_set_transform(star_pos, stun_spin * 1.4, Vector2.ONE)
				r.draw_texture_rect(r.stun_spin_tex, Rect2(Vector2(-12.0, -12.0), Vector2(24.0, 24.0)), false)
				r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				r.draw_colored_polygon(PackedVector2Array([star_pos + Vector2(0.0, -8.0), star_pos + Vector2(7.0, 0.0), star_pos + Vector2(0.0, 8.0), star_pos + Vector2(-7.0, 0.0)]), Color("#ffe27a"))
	if float(hero.get("guard_time", 0.0)) > 0.0:
		r.draw_arc(pos, 38.0, -PI * 0.82, PI * 0.82, 28, Color("#ffe066"), 7.0)
	if float(hero.get("super_armor_time", 0.0)) > 0.0:
		var armor_pulse := 42.0 + sin(float(world.tick) * 0.34 + slot) * 2.0
		r.draw_arc(pos, armor_pulse, 0.0, TAU, 32, Color(Color("#ff8dac"), 0.82), 4.0)
	if bool(hero.get("charging_skill", false)):
		var charge_ratio := clampf(float(hero.get("charge_time", 0.0)) / 1.15, 0.0, 1.0)
		r.draw_arc(pos, 45.0, -PI * 0.5, -PI * 0.5 + TAU * charge_ratio, 36, Color("#dff8ff"), 6.0)
	if world.result != &"playing" and int(hero["slot"]) == world.winner_slot:
		var winner_pulse := 56.0 + sin(float(world.tick) * 0.11) * 4.0
		r.draw_circle(pos, winner_pulse + 18.0, Color(1.0, 0.78, 0.24, 0.07))
		r.draw_arc(pos, winner_pulse, 0.0, TAU, 48, Color("#ffd166"), 6.0)
		r.draw_arc(pos, winner_pulse + 11.0, float(world.tick) * 0.025, float(world.tick) * 0.025 + PI * 1.45, 38, Color(Color.WHITE, 0.72), 3.0)
		var crown_y := -86.0 + sin(float(world.tick) * 0.08) * 2.0
		r.draw_colored_polygon(PackedVector2Array([pos + Vector2(-22.0, crown_y + 17.0), pos + Vector2(-20.0, crown_y), pos + Vector2(-7.0, crown_y + 10.0), pos + Vector2(0.0, crown_y - 6.0), pos + Vector2(7.0, crown_y + 10.0), pos + Vector2(20.0, crown_y), pos + Vector2(22.0, crown_y + 17.0)]), Color("#ffd166"))

func _draw_hero_body(pos: Vector2, body_pos: Vector2, slot: int, aim: Vector2, hero: Dictionary, is_down: bool, is_turtle: bool, hop_lift: float, hop_scale: Vector2, body_squash: float, ghost: float, hit_flash: float, comb_nudge: float, timed_ids: Array, lean: float = 0.0) -> void:
	if is_down and r.animal_down_atlas != null:
		var animal := int(hero.get("animal", slot))
		draw_blob_shadow(pos, 0.0, 0.9)
		draw_down_sprite(pos + Vector2(0.0, -2.0), animal, 0.98, 0.0, 82.0)
		var bleed := clampf(float(hero.get("down_left", 0.0)) / 5.0, 0.0, 1.0)
		r.draw_arc(pos, 38.0, -PI * 0.5, -PI * 0.5 + TAU * bleed, 28, Color("#ff8d93"), 4.0)
		var fin := clampf(float(hero.get("down_taken", 0.0)) / 48.0, 0.0, 1.0)
		r.draw_arc(pos, 32.0, -PI * 0.5, -PI * 0.5 + TAU * fin, 22, Color("#ff3349"), 3.0)
		r.draw_string(GameFont.get_font(), pos + Vector2(-36.0, 54.0), "DOWN %.1f" % float(hero.get("down_left", 0.0)), HORIZONTAL_ALIGNMENT_CENTER, 72.0, 12, Color("#ffe066"))
		return
	if is_turtle:
		var turtle_tex: Texture2D = r.turtle_body_tex if r.turtle_body_tex != null else r.roulette_icons.get("turtle", null)
		var turtle_size := 110.0
		var flip: float = -1.0 if aim.x < -0.05 else 1.0
		if turtle_tex != null:
			r.draw_set_transform(pos + Vector2(0.0, 8.0), 0.0, Vector2(flip, 1.0))
			r.draw_texture_rect(turtle_tex, Rect2(Vector2(-turtle_size * 0.5, -turtle_size * 0.62), Vector2(turtle_size, turtle_size)), false)
			r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			r.draw_circle(pos + Vector2(0.0, 6.0), 28.0, Color("#3d8f4a"))
			r.draw_circle(pos + Vector2(0.0, 6.0), 16.0, Color("#6ef3a5"))
	else:
		var animal := int(hero.get("animal", slot))
		if is_down:
			r.draw_set_transform(pos + Vector2(0.0, 10.0), 1.25, Vector2(1.0, 0.72))
			draw_hero_sprite(Vector2.ZERO, animal, aim, 0.95, 0.0, Vector2.ONE, 0.15)
			r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var bleed := clampf(float(hero.get("down_left", 0.0)) / 5.0, 0.0, 1.0)
			r.draw_arc(pos, 34.0, -PI * 0.5, -PI * 0.5 + TAU * bleed, 28, Color("#ff8d93"), 4.0)
			var fin := clampf(float(hero.get("down_taken", 0.0)) / 48.0, 0.0, 1.0)
			r.draw_arc(pos, 28.0, -PI * 0.5, -PI * 0.5 + TAU * fin, 22, Color("#ff3349"), 3.0)
			r.draw_string(GameFont.get_font(), pos + Vector2(-36.0, 48.0), "DOWN %.1f" % float(hero.get("down_left", 0.0)), HORIZONTAL_ALIGNMENT_CENTER, 72.0, 12, Color("#ffe066"))
		else:
			draw_hero_sprite(pos + Vector2(0.0, comb_nudge), animal, aim, ghost, hop_lift, hop_scale, hit_flash, lean)
			r._draw_hero_gun(body_pos, slot, aim, ghost, body_squash)
			draw_flee_mark(body_pos, hero)
			draw_dog_alert(body_pos, hero)
		for clone in hero.get("ult_clones", []):
			if not bool(clone.get("alive", true)):
				continue
			var cpos: Vector2 = clone.get("pos", pos)
			if world._pos_in_dragon_smoke(cpos) and slot != int(world.local_slot):
				continue
			var caim: Vector2 = clone.get("aim", aim)
			var chop := hop_lift
			var cbody: Vector2 = cpos + Vector2(0.0, -chop)
			draw_hero_sprite(cpos, animal, caim, 0.94, chop, hop_scale, 0.0, lean)
			r._draw_hero_gun(cbody, slot, caim, 0.94, body_squash)

func _draw_hero_buff_icons(body_pos: Vector2, timed_ids: Array) -> void:
	var icon_y := -84.0
	for mark_id in ["berserk", "sniper", "shield"]:
		if not timed_ids.has(mark_id):
			continue
		var mark_tex: Texture2D = r.roulette_icons.get(mark_id, null)
		var mark_pos: Vector2 = body_pos + Vector2(51.0, icon_y)
		if mark_tex != null:
			r.draw_texture_rect(mark_tex, Rect2(mark_pos, Vector2(22.0, 22.0)), false)
		else:
			r.draw_circle(mark_pos + Vector2(11.0, 11.0), 9.0, Color.WHITE)
		icon_y += 24.0
