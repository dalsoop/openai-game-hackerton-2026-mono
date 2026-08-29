class_name RenderHeroLayer
extends RefCounted

const GunSig = preload("res://games/dagul/sim/gun_signature.gd")

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer

func gun_src_rect(frame: int) -> Rect2:
	var cell: Vector2 = Vector2(float(r.gun_atlas.get_width()) / 4.0, float(r.gun_atlas.get_height()) / 3.0)
	var col := posmod(frame, 4)
	var row := int(frame / 4)
	return Rect2(Vector2(float(col), float(row)) * cell, cell)

func muzzle_src_rect(row: int, col: int) -> Rect2:
	var cell: Vector2 = Vector2(float(r.muzzle_atlas.get_width()) / 4.0, float(r.muzzle_atlas.get_height()) / 3.0)
	return Rect2(Vector2(float(posmod(col, 4)), float(posmod(row, 3))) * cell, cell)

func animal_src_rect(animal: int) -> Rect2:
	var frame := int(r.ANIMAL_ATLAS_FRAME[posmod(animal, CharacterCatalog.bind_count("animal"))])
	var cell := Vector2(float(r.animal_atlas.get_width()) / float(r.ANIMAL_COLS), float(r.animal_atlas.get_height()) / float(r.ANIMAL_ROWS))
	var col: int = frame % int(r.ANIMAL_COLS)
	var row := int(frame / r.ANIMAL_COLS)
	return Rect2(Vector2(float(col), float(row)) * cell, cell)

func animal_down_src_rect(animal: int) -> Rect2:
	if r.animal_down_atlas == null:
		return Rect2()
	var frame := int(r.ANIMAL_ATLAS_FRAME[posmod(animal, CharacterCatalog.bind_count("animal"))])
	var cell := Vector2(float(r.animal_down_atlas.get_width()) / float(r.ANIMAL_COLS), float(r.animal_down_atlas.get_height()) / float(r.ANIMAL_ROWS))
	var col: int = frame % int(r.ANIMAL_COLS)
	var row := int(frame / r.ANIMAL_COLS)
	return Rect2(Vector2(float(col), float(row)) * cell, cell)

func zodiac_texture(animal: int) -> Texture2D:
	if r.zodiac_textures.is_empty():
		return null
	return r.zodiac_textures[posmod(animal, CharacterCatalog.bind_count("animal"))]

func zodiac_name(animal: int) -> String:
	return HudStrings.zodiac(animal)

func draw_blob_shadow(ground_pos: Vector2, hop_lift: float, opacity: float) -> void:
	var height_t: float = clampf(hop_lift / 19.0, 0.0, 1.0)
	var size_mul: float = lerpf(1.0, 0.52, height_t)
	var alpha_mul: float = lerpf(1.0, 0.38, height_t)
	var radius_x: float = 26.0 * size_mul
	var radius_y: float = 11.5 * size_mul
	var center: Vector2 = ground_pos + Vector2(1.5, 34.0)
	r.draw_set_transform(center, 0.0, Vector2(1.0, radius_y / radius_x))
	var rings: Array = [
		[1.00, 0.07], [0.88, 0.10], [0.74, 0.13],
		[0.58, 0.16], [0.40, 0.17], [0.22, 0.14]
	]
	for ring in rings:
		r.draw_circle(Vector2.ZERO, radius_x * float(ring[0]), Color(0.0, 0.0, 0.0, float(ring[1]) * alpha_mul * opacity))
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_hero_gun(pos: Vector2, slot: int, aim: Vector2, opacity: float = 1.0, extra_squash: float = 0.0) -> void:
	var dir := aim if aim.length_squared() > 0.0001 else Vector2.RIGHT
	var equip_id := "burst"
	if r.world != null and slot >= 0 and slot < r.world.heroes.size():
		var held = r.world.heroes[slot].get("equipment", {})
		if typeof(held) == TYPE_DICTIONARY:
			equip_id = str(held.get("id", "burst"))
	var vis: Dictionary = GunSig.visual_for_equipment(equip_id)
	var family := str(vis.get("family", "rifle"))
	var kick := 0.0
	var rot_kick := 0.0
	var strap_kick := 0.0
	if slot >= 0 and slot < r.recoil_kick.size():
		kick = float(r.recoil_kick[slot])
		rot_kick = float(r.recoil_rot[slot])
		strap_kick = float(r.recoil_strap[slot])
	if extra_squash > 0.0 and posmod(slot, 12) == 11:
		extra_squash += 0.04
	var flip := -1.0 if dir.x < 0.0 else 1.0
	var mount: Vector2 = pos + Vector2(flip * 6.0, 4.0) + dir * (18.0 - kick)
	var angle := dir.angle() + rot_kick * (-1.0 if flip < 0.0 else 1.0)
	const GUN_TSCN_SCALE := 0.645
	if r.gun_atlas != null:
		_draw_atlas_gun(vis, mount, angle, flip, opacity, slot, GUN_TSCN_SCALE)
	elif r.gun_texture != null:
		r.draw_set_transform(mount, angle, Vector2(1.0, flip))
		r.draw_texture_rect(r.gun_texture, Rect2(Vector2(-5.0, -9.0), Vector2(34.0, 18.0)), false, Color(1.0, 1.0, 1.0, opacity))
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_atlas_gun(vis: Dictionary, mount: Vector2, angle: float, flip: float, opacity: float, slot: int, gun_tscn_scale: float) -> void:
	var src := gun_src_rect(int(vis.get("frame", 0)))
	var cell := Vector2(float(r.gun_atlas.get_width()) / 4.0, float(r.gun_atlas.get_height()) / 3.0)
	var world_s := 72.0 / (cell.x * gun_tscn_scale)
	r.draw_set_transform(mount, angle, Vector2(world_s, world_s * flip))
	var off := Vector2(float(vis.get("ox", 0.0)), float(vis.get("oy", 0.0)))
	var gun_rect := Rect2((-cell * 0.5 + off) * gun_tscn_scale, cell * gun_tscn_scale)
	r.draw_texture_rect_region(r.gun_atlas, gun_rect, src, Color(1.0, 1.0, 1.0, opacity))
	draw_muzzle_flash(slot, vis, opacity)
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_muzzle_flash(slot: int, vis: Dictionary, opacity: float) -> void:
	const MUZZLE_LOCAL := Vector2(49.536, 0.0)
	const MUZZLE_TSCN_SCALE := 0.74175
	var hero_muzzle := 0.0
	var hero_mrow := 0
	if r.world != null and slot >= 0 and slot < r.world.heroes.size():
		hero_muzzle = float(r.world.heroes[slot].get("muzzle_time", 0.0))
		hero_mrow = int(r.world.heroes[slot].get("muzzle_row", 0))
	if r.muzzle_atlas == null or not (hero_muzzle > 0.0 or (slot >= 0 and slot < r.muzzle_life.size() and float(r.muzzle_life[slot]) > 0.0)):
		return
	var counts := [2, 3, 4]
	var row := hero_mrow if hero_muzzle > 0.0 else int(vis.get("muzzle_row", 0))
	var n := int(counts[clampi(row, 0, 2)])
	var life := hero_muzzle if hero_muzzle > 0.0 else float(r.muzzle_life[slot])
	var played := maxf(0.0, float(r.feel_muzzle_max(row)) - life)
	var col := clampi(int(played / 0.055), 0, n - 1)
	var mcell := Vector2(float(r.muzzle_atlas.get_width()) / 4.0, float(r.muzzle_atlas.get_height()) / 3.0)
	var mscale := 1.0
	if r.world != null and slot >= 0 and slot < r.world.heroes.size():
		mscale = float(r.world.heroes[slot].get("muzzle_scale", 1.0))
	var msize := mcell * MUZZLE_TSCN_SCALE * mscale
	var mcenter := Vector2(float(vis.get("mx", 90.0)), float(vis.get("my", -18.0))) + MUZZLE_LOCAL
	r.draw_texture_rect_region(r.muzzle_atlas, Rect2(mcenter - msize * 0.5, msize), muzzle_src_rect(row, col), Color(1.0, 1.0, 1.0, opacity))
