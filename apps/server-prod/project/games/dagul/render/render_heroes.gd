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
	if slot < 0 and r.unknown_character_tex != null:
		r.draw_set_transform(sprite_pos, lean, draw_scale)
		r.draw_texture_rect(r.unknown_character_tex, Rect2(Vector2(-36.0, -36.0), Vector2(72.0, 72.0)), false, hit_tint)
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif r.animal_atlas != null:
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
	var mark := body_pos + Vector2(0.0, -124.0)
	var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.018)
	r.draw_circle(mark + Vector2(0.0, 2.0), 18.0 * pulse, Color(0.12, 0.02, 0.02, 0.55))
	r.draw_circle(mark, 16.0 * pulse, Color("#ff2a2a"))
	r.draw_circle(mark, 13.0 * pulse, Color("#ffef6a"))
	r.draw_string(GameFont.get_font(), mark + Vector2(-16.0, 10.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 32.0, 28, Color("#d40000"))

func draw_flee_mark(body_pos: Vector2, hero: Dictionary) -> void:
	if float(hero.get("flee_time", 0.0)) <= 0.0:
		return
	if r.flee_icon_tex == null:
		r.flee_icon_tex = r._load_tex("res://games/dagul/assets/fx/flee-icon.png")
	var mark := body_pos + Vector2(0.0, -118.0)
	if r.flee_icon_tex != null:
		r.draw_texture_rect(r.flee_icon_tex, Rect2(mark + Vector2(-28.0, -22.0), Vector2(56.0, 44.0)), false)
	else:
		r.draw_circle(mark, 16.0, Color("#ffcc33"))
	r.draw_string(GameFont.get_font(), mark + Vector2(-30.0, 28.0), "도망", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 12, Color("#ffe066"))

func draw_nametag(pos: Vector2, slot: int, hp_ratio: float, opacity: float = 1.0, display_name: String = "", hp_now: float = 0.0, hp_max: float = 0.0) -> void:
	var tag := display_name if display_name != "" else "P%d %s" % [slot + 1, r._zodiac_name(slot)]
	r.draw_string(GameFont.get_font(), pos + Vector2(-71.0, -78.0), tag, HORIZONTAL_ALIGNMENT_CENTER, 144.0, 14, Color(0.0, 0.0, 0.0, 0.85 * opacity))
	r.draw_string(GameFont.get_font(), pos + Vector2(-72.0, -79.0), tag, HORIZONTAL_ALIGNMENT_CENTER, 144.0, 14, Color(1.0, 1.0, 1.0, opacity))
	var bar := Rect2(pos + Vector2(-46.0, -64.0), Vector2(92.0, 16.0))
	r.draw_rect(bar.grow(2.0), Color(0.04, 0.05, 0.07, 0.92 * opacity))
	r.draw_rect(bar, Color(0.16, 0.18, 0.22, 0.95 * opacity))
	var fill := Color("#3fe37a") if hp_ratio > 0.34 else Color("#ff5d73")
	var fill_w := (bar.size.x - 4.0) * clampf(hp_ratio, 0.0, 1.0)
	r.draw_rect(Rect2(bar.position + Vector2(2.0, 2.0), Vector2(fill_w, bar.size.y - 4.0)), Color(fill, opacity))
	var hp_label := "%d / %d" % [roundi(hp_now), roundi(hp_max)]
	r.draw_string(GameFont.get_font(), bar.position + Vector2(1.0, 13.0), hp_label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 11, Color(0.0, 0.0, 0.0, 0.7 * opacity))
	r.draw_string(GameFont.get_font(), bar.position + Vector2(0.0, 12.0), hp_label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 11, Color(1.0, 1.0, 1.0, opacity))

func draw_knockouts() -> void:
	for knockout in world.knockouts:
		var knockout_slot := int(knockout["slot"])
		var knockout_fade := clampf(float(knockout["time"]) / 0.42, 0.0, 1.0)
		var knockout_pos: Vector2 = knockout["pos"]
		var spin := float(knockout.get("max_time", 1.0)) - float(knockout["time"])
		var knockout_trail: Array = knockout.get("trail", [])
		_draw_knockout_trail(knockout_trail, knockout_slot, knockout_fade, knockout_pos, spin)
		_draw_knockout_body(knockout_slot, knockout_pos, spin, knockout_fade)

func _draw_knockout_trail(knockout_trail: Array, knockout_slot: int, knockout_fade: float, knockout_pos: Vector2, spin: float) -> void:
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

func _draw_knockout_body(knockout_slot: int, knockout_pos: Vector2, spin: float, knockout_fade: float) -> void:
	if r.animal_atlas != null:
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
		r.wool_shield_tex = r._load_tex("res://games/dagul/assets/fx/sheep-wool-ring.png")
	for hero in world.heroes:
		if float(hero.get("wool_time", 0.0)) <= 0.0 or int(hero.get("wool_hp", 0)) <= 0:
			continue
		if bool(hero.get("eliminated", false)) or not bool(hero.get("alive", false)):
			continue
		var pos: Vector2 = hero["pos"]
		var hp_a := clampf(float(hero.get("wool_hp", 0)) / maxf(1.0, float(hero.get("wool_max", 5))), 0.45, 1.0)
		var sz := 128.0
		if r.wool_shield_tex != null:
			r.draw_texture_rect(r.wool_shield_tex, Rect2(pos - Vector2(sz, sz), Vector2(sz * 2.0, sz * 2.0)), false, Color(1.0, 1.0, 1.0, maxf(0.82, hp_a)))
		else:
			r.draw_arc(pos, 56.0, 0.0, TAU, 40, Color(1.0, 0.96, 0.88, 0.95), 14.0)

func draw_dog_bones() -> void:
	if world == null:
		return
	if r.dog_bone_tex == null:
		r.dog_bone_tex = r._load_tex("res://games/dagul/assets/fx/dog-bone.png")
	for bone in world.dog_bones:
		var pos: Vector2 = bone.get("pos", Vector2.ZERO)
		if r.dog_bone_tex != null:
			r.draw_texture_rect(r.dog_bone_tex, Rect2(pos + Vector2(-48.0, -22.0), Vector2(96.0, 44.0)), false)
		else:
			r.draw_circle(pos, 12.0, Color("#f3efe4"))

func draw_pig_muds() -> void:
	if world == null:
		return
	if r.pig_mud_tex == null:
		r.pig_mud_tex = r._load_tex("res://games/dagul/assets/fx/pig-mud.png")
	for mud in world.pig_muds:
		var pos: Vector2 = mud.get("pos", Vector2.ZERO)
		var rad := float(mud.get("radius", 200.0))
		var ttl := float(mud.get("ttl", 0.0))
		var fade := clampf(ttl / 1.4, 0.0, 1.0)
		var sz := rad * 2.15
		if r.pig_mud_tex != null:
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
		r.draw_set_transform(pos + Vector2(0.0, 4.0), 0.0, Vector2(1.0, 1.18))
		r.draw_circle(Vector2.ZERO, 16.0, Color("#f4e6c8"))
		r.draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 20, Color("#3a2a18"), 3.0)
		r.draw_circle(Vector2(-4.0, -5.0), 4.0, Color("#fff6e4"))
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
		var t := clampf(float(kick.get("age", 0.0)) / maxf(0.01, float(kick.get("life", 0.42))), 0.0, 1.0)
		var fade := 1.0 - t
		var ang := dir.angle()
		var pts: PackedVector2Array = PackedVector2Array()
		pts.append(pos)
		for i in range(12):
			var a := ang - 1.15 + 2.30 * (float(i) / 11.0)
			pts.append(pos + Vector2(cos(a), sin(a)) * reach)
		r.draw_colored_polygon(pts, Color(0.62, 0.42, 0.16, 0.16 * fade))
		r.draw_arc(pos, reach * (0.35 + t * 0.65), ang - 1.15, ang + 1.15, 28, Color(0.92, 0.72, 0.32, 0.85 * fade), 7.0)
		for i in range(6):
			var a := ang - 1.00 + 2.00 * (float(i) / 6.0)
			var p: Vector2 = pos + Vector2(cos(a), sin(a)) * (70.0 + t * 150.0)
			r.draw_circle(p, 10.0 + (1.0 - t) * 8.0, Color(0.45, 0.30, 0.12, 0.35 * fade))

func draw_rabbit_holes() -> void:
	if world == null:
		return
	if r.rabbit_hole_tex == null:
		r.rabbit_hole_tex = r._load_tex("res://games/dagul/assets/fx/rabbit-hole.png")
	for hole in world.rabbit_holes:
		var pos: Vector2 = hole.get("pos", Vector2.ZERO)
		var ttl := float(hole.get("ttl", 0.0))
		var fade := clampf(ttl / 1.2, 0.0, 1.0)
		var sz := 118.0
		if r.rabbit_hole_tex != null:
			r.draw_texture_rect(r.rabbit_hole_tex, Rect2(pos - Vector2(sz * 0.5, sz * 0.42), Vector2(sz, sz * 0.86)), false, Color(1, 1, 1, 0.35 + 0.65 * fade))
		else:
			r.draw_circle(pos, 34.0, Color(0.18, 0.08, 0.04, 0.85 * fade))

func draw_tiger_roars() -> void:
	if world == null:
		return
	for roar_data in world.tiger_roars:
		var pos: Vector2 = roar_data.get("pos", Vector2.ZERO)
		var rad := float(roar_data.get("radius", 300.0))
		var life := maxf(0.01, float(roar_data.get("life", 1.15)))
		var t := clampf(float(roar_data.get("age", 0.0)) / life, 0.0, 1.0)
		var front := rad * t
		var fade := 1.0 - t * 0.28
		r.draw_circle(pos, front, Color(1.0, 0.72, 0.12, 0.10 * fade))
		r.draw_arc(pos, front, 0.0, TAU, 64, Color(1.0, 0.86, 0.26, 0.95 * fade), 8.0)

func draw_dragon_smokes() -> void:
	if world == null:
		return
	if r.dragon_smoke_tex == null:
		r.dragon_smoke_tex = r._load_tex("res://games/dagul/assets/fx/dragon-smoke.png")
	if r.dragon_smoke_tex == null:
		return
	for smoke in world.dragon_smokes:
		var pos: Vector2 = smoke.get("pos", Vector2.ZERO)
		var rad := float(smoke.get("radius", 300.0))
		var life := clampf(float(smoke.get("ttl", 0.0)) / 15.0, 0.0, 1.0)
		var sz := rad * 2.0
		r.draw_texture_rect(r.dragon_smoke_tex, Rect2(pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), false, Color(1.0, 1.0, 1.0, 0.78 * life + 0.18))

func draw_snake_skins() -> void:
	for skin in world.snake_skins:
		if not bool(skin.get("alive", true)):
			continue
		var pos: Vector2 = skin.get("pos", Vector2.ZERO)
		if world._pos_in_dragon_smoke(pos) and int(skin.get("owner", -1)) != int(world.local_slot):
			continue
		var aim: Vector2 = skin.get("aim", Vector2.RIGHT)
		var flash := float(skin.get("flash", 0.0))
		var sc := float(skin.get("scale", 1.5))
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
		r.rat_run_tex = r._load_tex("res://games/dagul/assets/fx/rat-run.png")
	if r.rat_run_tex == null:
		return
	for tide in world.rat_tides:
		var pos: Vector2 = tide.get("pos", Vector2.ZERO)
		var dir: Vector2 = tide.get("dir", Vector2.RIGHT)
		if dir.length_squared() < 0.01:
			dir = Vector2.RIGHT
		dir = dir.normalized()
		var perp := dir.rotated(PI * 0.5)
		var leng := float(tide.get("length", 360.0))
		var half_w := float(tide.get("half_w", 118.0))
		var ang := dir.angle()
		for i in range(30):
			var u := fposmod(float(i) * 0.173 + float(world.tick) * 0.045, 1.0)
			var along := (u - 0.28) * leng
			var side := sin(float(i) * 2.1 + float(world.tick) * 0.31) * half_w * 0.82
			var p: Vector2 = pos + dir * along + perp * side
			var bob := 1.0 + 0.08 * sin(float(world.tick) * 0.4 + float(i))
			r.draw_set_transform(p, ang, Vector2(bob, bob))
			r.draw_texture_rect(r.rat_run_tex, Rect2(Vector2(-34.0, -24.0), Vector2(68.0, 48.0)), false)
			r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
		var aim := Vector2(hero["aim"])
		var is_down := bool(hero.get("downed", false))
		var launch_trail_opacity := clampf(float(hero.get("launch_trail_fade", 0.0)) / 0.34, 0.0, 1.0)
		r._draw_motion_trail(hero.get("launch_trail", []), r._slot_color(slot), 6.5, launch_trail_opacity)
		if float(hero.get("launch_time", 0.0)) > 0.0 and Vector2(hero.get("launch_vel", Vector2.ZERO)).length_squared() > 1.0:
			var launch_dir := Vector2(hero["launch_vel"]).normalized()
			r.draw_line(pos - launch_dir * 94.0, pos - launch_dir * 18.0, Color(r._slot_color(slot), 0.28), 9.0)
		if slot == world.wanted_slot:
			r.draw_colored_polygon(PackedVector2Array([pos + Vector2(-18.0, -58.0), pos + Vector2(-15.0, -74.0), pos + Vector2(-5.0, -65.0), pos + Vector2(0.0, -80.0), pos + Vector2(5.0, -65.0), pos + Vector2(15.0, -74.0), pos + Vector2(18.0, -58.0)]), Color("#ff3349"))
			r.draw_string(GameFont.get_font(), pos + Vector2(-40.0, -86.0), "WANTED", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 11, Color("#ffd166"))
		_draw_hero_status_arcs(pos, hero, slot)
		_draw_live_hero(hero, slot, pos, aim, is_down)

func _draw_live_hero(hero: Dictionary, slot: int, pos: Vector2, aim: Vector2, is_down: bool) -> void:
	var hop := _hero_hop(hero)
	var hop_lift: float = hop["lift"]
	var body_pos: Vector2 = pos + Vector2(0.0, -hop_lift)
	var timed_ids: Array = _timed_ids(hero)
	var comb_nudge := 0.0
	if posmod(int(hero.get("animal", slot)), 12) == 9 and r.rooster_comb_lag > 0.0:
		comb_nudge = 1.0
	var ghost := _hero_ghost(hero)
	_draw_hero_auras(hero, pos, timed_ids)
	var hop_scale := _hero_hop_scale(hero, slot, hop["scale"])
	var is_turtle: bool = timed_ids.has("turtle")
	var lean := 0.0 if is_turtle else _hero_lean(hero, is_down, hop_lift)
	_draw_hero_body(pos, body_pos, slot, aim, hero, is_down, is_turtle, hop_lift, hop_scale, _hero_body_squash(slot), ghost, float(hero.get("hit_flash", 0.0)), comb_nudge, timed_ids, lean)
	draw_emote(body_pos, hero, slot)
	_draw_hero_buff_icons(body_pos, timed_ids)
	_draw_hero_tag(body_pos, slot, hero, ghost)
	r._overlay.draw_reload_bubble(body_pos, hero)
	r._overlay.draw_head_roulette(body_pos, hero)

func _hero_lean(hero: Dictionary, is_down: bool, hop_lift: float) -> float:
	if is_down or hop_lift > 0.05:
		return 0.0
	if float(hero.get("launch_time", 0.0)) > 0.0 or float(hero.get("stun_time", 0.0)) > 0.0:
		return 0.0
	var lean := float(hero.get("move_lean", 0.0))
	if absf(lean) < 0.004:
		lean = clampf(Vector2(hero.get("vel", Vector2.ZERO)).x / 400.0, -1.0, 1.0) * 0.14
	return lean

func _hero_hop(hero: Dictionary) -> Dictionary:
	var hop_time: float = float(hero.get("hop_time", 0.0))
	var lift: float = 0.0
	var scale: Vector2 = Vector2.ONE
	if hop_time > 0.0:
		var hop_max: float = maxf(0.001, float(hero.get("hop_max", 0.30)))
		var hop_t: float = clampf(1.0 - hop_time / hop_max, 0.0, 1.0)
		var hop_height: float = float(hero.get("hop_height", 19.0))
		lift = hop_height * sin(PI * hop_t)
		var hop_squash: float = cos(PI * hop_t)
		scale = Vector2(1.00 + 0.12 * hop_squash, 1.02 - 0.14 * hop_squash)
	elif float(hero.get("launch_time", 0.0)) <= 0.0 and float(hero.get("stun_time", 0.0)) <= 0.0:
		var run_t := clampf((Vector2(hero.get("vel", Vector2.ZERO)).length() - 50.0) / 340.0, 0.0, 1.0)
		if run_t > 0.05:
			var gait := float(world.tick) * 0.20 + float(int(hero.get("slot", 0))) * 1.37
			var bob := sin(gait)
			lift = 6.8 * run_t * maxf(0.0, bob)
			scale = Vector2(1.0 + 0.08 * run_t * (1.0 - bob), 1.0 + 0.11 * run_t * bob)
	var plant := float(hero.get("move_plant", 0.0))
	if hop_time <= 0.0 and absf(plant) > 0.03:
		scale = Vector2(scale.x * (1.0 + 0.14 * plant), scale.y * (1.0 - 0.16 * plant))
		if plant > 0.0:
			lift *= (1.0 - 0.55 * plant)
	return {"lift": lift, "scale": scale}

func _hero_body_squash(slot: int) -> float:
	if slot < r.recoil_body.size():
		return float(r.recoil_body[slot])
	return 0.0

func _hero_hop_scale(hero: Dictionary, slot: int, hop_scale: Vector2) -> Vector2:
	var body_squash := _hero_body_squash(slot)
	if posmod(int(hero.get("animal", slot)), 12) == 11:
		hop_scale = Vector2(hop_scale.x * (1.0 + body_squash * 1.35), hop_scale.y * (1.0 - body_squash * 1.55))
	else:
		hop_scale = Vector2(hop_scale.x * (1.0 + body_squash), hop_scale.y * (1.0 - body_squash))
	var timed_ids: Array = _timed_ids(hero)
	var body_mul := _timed_body_scale(hero)
	if timed_ids.has("turtle"):
		return Vector2(1.25, 0.68)
	if body_mul > 1.01:
		hop_scale = Vector2(hop_scale.x * body_mul, hop_scale.y * body_mul)
	return hop_scale

func _hero_ghost(hero: Dictionary) -> float:
	if float(hero.get("spawn_protect_time", 0.0)) > 0.0:
		return 0.38 + 0.38 * absf(sin(float(world.tick) * 0.35))
	return 1.0

func _draw_hero_auras(hero: Dictionary, pos: Vector2, timed_ids: Array) -> void:
	if float(hero.get("dmg_orb_time", 0.0)) > 0.0:
		r.draw_arc(pos, 33.0 + sin(float(world.tick) * 0.28) * 2.0, 0.0, TAU, 28, Color(Color("#ff4f4f"), 0.80), 4.0)
	var shield_hp := 0.0
	for buff in hero.get("rl_timed", []):
		shield_hp += float(buff.get("shield", 0.0))
	if (shield_hp > 0.01 or timed_ids.has("shield")) and float(hero.get("wool_time", 0.0)) <= 0.0:
		r.draw_circle(pos, 40.0, Color(0.25, 0.78, 1.0, 0.16))
		r.draw_arc(pos, 42.0 + sin(float(world.tick) * 0.22) * 2.0, 0.0, TAU, 36, Color(Color("#70e7ff"), 0.95), 6.0)

func _draw_hero_tag(body_pos: Vector2, slot: int, hero: Dictionary, ghost: float) -> void:
	var hp_ratio := maxf(0.0, float(hero["hp"]) / float(hero["max_hp"]))
	var animal_name = r._zodiac_name(int(hero.get("animal", slot)))
	var tag := str(hero.get("display_name", ""))
	if tag == "":
		tag = "P%d %s" % [slot + 1, animal_name]
	draw_nametag(body_pos, slot, hp_ratio, ghost, tag, float(hero["hp"]), float(hero["max_hp"]))
	if int(hero.get("kill_streak", 0)) >= 2:
		r.draw_string(GameFont.get_font(), body_pos + Vector2(-40.0, -62.0), "x%d 연속" % int(hero["kill_streak"]), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 11, Color("#ffd166"))

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
		_draw_stun_stars(pos, stun_spin)
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

func _draw_stun_stars(pos: Vector2, stun_spin: float) -> void:
	for star_index in range(3):
		var star_pos := pos + Vector2(26.0, 8.0).rotated(stun_spin + TAU * float(star_index) / 3.0) + Vector2(0.0, -58.0)
		if r.stun_spin_tex != null:
			r.draw_set_transform(star_pos, stun_spin * 1.4, Vector2.ONE)
			r.draw_texture_rect(r.stun_spin_tex, Rect2(Vector2(-12.0, -12.0), Vector2(24.0, 24.0)), false)
			r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			r.draw_colored_polygon(PackedVector2Array([star_pos + Vector2(0.0, -8.0), star_pos + Vector2(7.0, 0.0), star_pos + Vector2(0.0, 8.0), star_pos + Vector2(-7.0, 0.0)]), Color("#ffe27a"))

func _draw_hero_body(pos: Vector2, body_pos: Vector2, slot: int, aim: Vector2, hero: Dictionary, is_down: bool, is_turtle: bool, hop_lift: float, hop_scale: Vector2, body_squash: float, ghost: float, hit_flash: float, comb_nudge: float, timed_ids: Array, lean: float = 0.0) -> void:
	if is_turtle:
		_draw_turtle_body(pos, aim)
		return
	var animal := int(hero.get("animal", slot))
	if is_down:
		_draw_downed_hero(pos, animal, aim, hero)
	else:
		draw_hero_sprite(pos + Vector2(0.0, comb_nudge), animal, aim, ghost, hop_lift, hop_scale, hit_flash, lean)
		r._draw_hero_gun(body_pos, slot, aim, ghost, body_squash)
		draw_flee_mark(body_pos, hero)
		draw_dog_alert(body_pos, hero)
	for clone in hero.get("ult_clones", []):
		_draw_ult_clone(clone, pos, slot, aim, animal, hop_lift, hop_scale, body_squash)

func _draw_turtle_body(pos: Vector2, aim: Vector2) -> void:
	var turtle_tex: Texture2D = r.turtle_body_tex if r.turtle_body_tex != null else r.roulette_icons.get("turtle", null)
	var turtle_size := 110.0
	var flip: float = -1.0 if aim.x < -0.05 else 1.0
	if turtle_tex != null:
		r.draw_set_transform(pos + Vector2(0.0, 8.0), 0.0, Vector2(flip, 1.0))
		r.draw_texture_rect(turtle_tex, Rect2(Vector2(-turtle_size * 0.5, -turtle_size * 0.62), Vector2(turtle_size, turtle_size)), false)
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	r.draw_circle(pos + Vector2(0.0, 6.0), 28.0, Color("#3d8f4a"))
	r.draw_circle(pos + Vector2(0.0, 6.0), 16.0, Color("#6ef3a5"))

func _draw_downed_hero(pos: Vector2, animal: int, aim: Vector2, hero: Dictionary) -> void:
	if not draw_down_sprite(pos + Vector2(0.0, -2.0), animal, 0.98, 0.0, 82.0):
		r.draw_set_transform(pos + Vector2(0.0, 10.0), 1.25, Vector2(1.0, 0.72))
		draw_hero_sprite(Vector2.ZERO, animal, aim, 0.95, 0.0, Vector2.ONE, 0.15)
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var bleed := clampf(float(hero.get("down_left", 0.0)) / 5.0, 0.0, 1.0)
	r.draw_arc(pos, 34.0, -PI * 0.5, -PI * 0.5 + TAU * bleed, 28, Color("#ff8d93"), 4.0)
	var fin := clampf(float(hero.get("down_taken", 0.0)) / 48.0, 0.0, 1.0)
	r.draw_arc(pos, 28.0, -PI * 0.5, -PI * 0.5 + TAU * fin, 22, Color("#ff3349"), 3.0)
	r.draw_string(GameFont.get_font(), pos + Vector2(-36.0, 48.0), "DOWN %.1f" % float(hero.get("down_left", 0.0)), HORIZONTAL_ALIGNMENT_CENTER, 72.0, 12, Color("#ffe066"))

func _draw_ult_clone(clone: Dictionary, pos: Vector2, slot: int, aim: Vector2, animal: int, hop_lift: float, hop_scale: Vector2, body_squash: float) -> void:
	if not bool(clone.get("alive", true)):
		return
	var cpos: Vector2 = clone.get("pos", pos)
	if world._pos_in_dragon_smoke(cpos) and slot != int(world.local_slot):
		return
	var caim: Vector2 = clone.get("aim", aim)
	var chop := hop_lift
	var cbody: Vector2 = cpos + Vector2(0.0, -chop)
	draw_hero_sprite(cpos, animal, caim, 0.94, chop, hop_scale, 0.0)
	r._draw_hero_gun(cbody, slot, caim, 0.94, body_squash)

func _draw_hero_buff_icons(body_pos: Vector2, timed_ids: Array) -> void:
	var icon_x := -18.0
	for mark_id in ["berserk", "sniper", "shield"]:
		if not timed_ids.has(mark_id):
			continue
		var mark_tex: Texture2D = r.roulette_icons.get(mark_id, null)
		var mark_pos: Vector2 = body_pos + Vector2(icon_x, -108.0)
		if mark_tex != null:
			r.draw_texture_rect(mark_tex, Rect2(mark_pos, Vector2(36.0, 36.0)), false)
		else:
			r.draw_circle(mark_pos + Vector2(18.0, 18.0), 14.0, Color.WHITE)
		icon_x += 40.0
