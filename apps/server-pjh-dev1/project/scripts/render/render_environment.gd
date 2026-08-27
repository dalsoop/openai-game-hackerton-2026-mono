class_name RenderEnvironment
extends RefCounted

const CRATE_ORB_ATLAS: Texture2D = preload("res://assets/fx/pickups/Tex_FX_CrateEnergyOrb_4x2.png")
const GRASS_PLAIN_TILES := [0, 1, 5, 6]
const GRASS_FLOWER_TILES := [2, 3, 4, 7]
const FLOWER_REGION_SIZE := 4
const GRASS_TILE_SIZE := 256.0
const GRASS_CULL_MARGIN_TILES := 1.0

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer

func draw_island() -> void:
	var arena := Rect2(Vector2.ZERO, world.ARENA_SIZE)
	r.draw_rect(arena.grow(900.0), Color("#17456f"))
	if r.grass_tile_textures.is_empty():
		return
	var prev_filter := r.texture_filter
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_draw_grass_tiles(arena)
	r.texture_filter = prev_filter

func _draw_grass_tiles(arena: Rect2) -> void:
	var tex_size: Vector2 = r.grass_tile_textures[0].get_size()
	var tile_bounds := _visible_grass_tile_bounds(arena)
	for tile_y in range(tile_bounds.position.y, tile_bounds.end.y):
		var y := float(tile_y) * GRASS_TILE_SIZE
		for tile_x in range(tile_bounds.position.x, tile_bounds.end.x):
			var x := float(tile_x) * GRASS_TILE_SIZE
			var dw := minf(GRASS_TILE_SIZE, arena.end.x - x)
			var dh := minf(GRASS_TILE_SIZE, arena.end.y - y)
			var src := Rect2(Vector2.ZERO, Vector2(tex_size.x * dw / GRASS_TILE_SIZE, tex_size.y * dh / GRASS_TILE_SIZE))
			var tile_index := _grass_tile_index(tile_x, tile_y, r.grass_tile_textures.size())
			var texture: Texture2D = r.grass_tile_textures[tile_index]
			r.draw_texture_rect_region(texture, Rect2(Vector2(x, y), Vector2(dw, dh)), src)

func _visible_grass_tile_bounds(arena: Rect2) -> Rect2i:
	var visible_world := arena
	var camera := r.get_viewport().get_camera_2d()
	if camera != null:
		var zoom := Vector2(maxf(camera.zoom.x, 0.01), maxf(camera.zoom.y, 0.01))
		var half_view := r.get_viewport_rect().size * 0.5 / zoom
		var margin := GRASS_TILE_SIZE * GRASS_CULL_MARGIN_TILES
		visible_world = Rect2(camera.get_screen_center_position() - half_view, half_view * 2.0).grow(margin).intersection(arena)
	var first := Vector2i(
		maxi(0, floori(visible_world.position.x / GRASS_TILE_SIZE)),
		maxi(0, floori(visible_world.position.y / GRASS_TILE_SIZE))
	)
	var last := Vector2i(
		mini(ceili(arena.end.x / GRASS_TILE_SIZE), ceili(visible_world.end.x / GRASS_TILE_SIZE)),
		mini(ceili(arena.end.y / GRASS_TILE_SIZE), ceili(visible_world.end.y / GRASS_TILE_SIZE))
	)
	return Rect2i(first, last - first)

func _grass_tile_index(tile_x: int, tile_y: int, tile_count: int) -> int:
	if tile_count < 8:
		return posmod(_tile_hash(tile_x, tile_y, 83492791), tile_count)
	var flower_index := _flower_tile_index(tile_x, tile_y)
	if flower_index >= 0:
		return flower_index
	var plain_hash := _tile_hash(tile_x, tile_y, 297121507)
	return GRASS_PLAIN_TILES[posmod(plain_hash, GRASS_PLAIN_TILES.size())]

func _flower_tile_index(tile_x: int, tile_y: int) -> int:
	var region_x := floori(float(tile_x) / float(FLOWER_REGION_SIZE))
	var region_y := floori(float(tile_y) / float(FLOWER_REGION_SIZE))
	var region_hash := _tile_hash(region_x, region_y, 433494437)
	if posmod(region_hash, 100) >= 48:
		return -1
	var center_x := region_x * FLOWER_REGION_SIZE + posmod(region_hash, FLOWER_REGION_SIZE)
	var center_hash := _tile_hash(region_x, region_y, 982451653)
	var center_y := region_y * FLOWER_REGION_SIZE + posmod(center_hash, FLOWER_REGION_SIZE)
	var radius := 1.2 + float(posmod(region_hash, 6)) * 0.1
	if Vector2(tile_x, tile_y).distance_to(Vector2(center_x, center_y)) > radius:
		return -1
	var base_flower := posmod(region_hash, GRASS_FLOWER_TILES.size())
	var mix_hash := _tile_hash(tile_x, tile_y, 15485863)
	var flower_offset := 0 if posmod(mix_hash, 100) < 65 else 1
	return GRASS_FLOWER_TILES[posmod(base_flower + flower_offset, GRASS_FLOWER_TILES.size())]

func _tile_hash(tile_x: int, tile_y: int, seed: int) -> int:
	return tile_x * 73856093 ^ tile_y * 19349663 ^ seed

func draw_trees() -> void:
	if r.tree_atlas == null:
		return
	var prev_filter := r.texture_filter
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var spots: Array[Vector3] = [
		Vector3(420, 280, 0), Vector3(680, 420, 1), Vector3(320, 520, 2), Vector3(860, 220, 1), Vector3(180, 180, 0),
		Vector3(7480, 300, 0), Vector3(7200, 480, 1), Vector3(7620, 560, 2), Vector3(7000, 200, 1),
		Vector3(380, 4480, 0), Vector3(640, 4320, 1), Vector3(220, 4580, 2), Vector3(900, 4520, 1), Vector3(140, 4200, 2),
		Vector3(7520, 4460, 0), Vector3(7180, 4320, 1), Vector3(7680, 4580, 2), Vector3(7000, 4520, 1), Vector3(7380, 4100, 2),
		Vector3(180, 1800, 1), Vector3(280, 3200, 2), Vector3(7600, 1600, 1), Vector3(7720, 3000, 0)
	]
	spots.sort_custom(func(a, b): return a.y < b.y)
	var dw := 48.0 * 3.2
	var dh := 64.0 * 3.2
	for spot in spots:
		var feet := Vector2(spot.x, spot.y)
		if not r.is_world_visible(feet, dh):
			continue
		r.draw_circle(feet + Vector2(0, 4), 22.0, Color(0.05, 0.04, 0.03, 0.28))
		var src := Rect2(Vector2(spot.z * 48.0, 0.0), Vector2(48, 64))
		r.draw_texture_rect_region(r.tree_atlas, Rect2(feet - Vector2(dw * 0.5, dh - 10.0), Vector2(dw, dh)), src)
	r.texture_filter = prev_filter

func draw_safe_zone() -> void:
	var center: Vector2 = world.safe_zone_center
	var radius: float = maxf(8.0, float(world.safe_zone_radius))
	var target_radius: float = maxf(8.0, float(world.safe_zone_target_radius))
	var outer := maxf(world.ARENA_SIZE.x, world.ARENA_SIZE.y)
	var mid := (radius + outer) * 0.5
	var width := maxf(12.0, outer - radius)
	var seg := 32 if r.lite_draw else 96
	r.draw_arc(center, mid, 0.0, TAU, seg, Color(0.42, 0.06, 0.68, 0.40), width)
	if not r.lite_draw:
		r.draw_arc(center, mid, 0.0, TAU, seg, Color(0.28, 0.02, 0.48, 0.34), width * 0.55)
	var shrinking := bool(world.safe_zone_shrinking)
	var ring: Color = r.ZONE_RING_HOT if shrinking else r.ZONE_RING
	var pulse := 6.0 + (2.0 if shrinking else 0.0) + sin(float(world.tick) * 0.12) * 1.0
	# Layered broken bands read like a pixel-energy wall instead of a vector circle.
	var band_count := 24 if r.lite_draw else 48
	var phase_speed := 0.026 if shrinking else 0.007
	var phase := float(world.tick) * phase_speed
	for band_index in range(band_count):
		if posmod(band_index + int(world.tick / 8), 5) == 0:
			continue
		var a0 := TAU * float(band_index) / float(band_count) + phase
		var a1 := a0 + TAU / float(band_count) * 0.72
		var band_radius := radius + (4.0 if band_index % 2 == 0 else -3.0)
		var band_color := Color(ring, 0.82 if band_index % 3 else 0.52)
		r.draw_arc(center, band_radius, a0, a1, 3, band_color, pulse)
		if not r.lite_draw and band_index % 4 == 0:
			var spark_pos := center + Vector2.RIGHT.rotated(a0) * (radius + 11.0)
			var spark_size := 4.0 + float(posmod(band_index, 3)) * 2.0
			r.draw_rect(Rect2(spark_pos - Vector2.ONE * spark_size * 0.5, Vector2.ONE * spark_size), Color("#e8c8ff", 0.64))
	r.draw_arc(center, radius, 0.0, TAU, 64, Color(ring, 0.22), pulse * 2.5)
	# Short angular bolts sell the boundary as electricity without hiding gameplay.
	if not r.lite_draw:
		var bolt_count := 12 if shrinking else 7
		var bolt_step := int(world.tick / (2 if shrinking else 5))
		for bolt_index in range(bolt_count):
			var bolt_life := fmod(float(world.tick) * (0.052 if shrinking else 0.025) + float(bolt_index) * 0.173, 1.0)
			if bolt_life > 0.64:
				continue
			var seed := bolt_index * 37 + bolt_step * 17
			var bolt_angle := TAU * float(posmod(seed, 997)) / 997.0
			var tangent := Vector2.RIGHT.rotated(bolt_angle + PI * 0.5)
			var radial := Vector2.RIGHT.rotated(bolt_angle)
			var bolt_center := center + radial * radius
			var bolt_length := 34.0 + float(posmod(seed * 11, 32))
			var life_envelope := sin(bolt_life / 0.64 * PI)
			var bolt_alpha := (0.98 if shrinking else 0.82) * life_envelope
			if r.zone_lightning_atlas != null:
				var frame := posmod(seed + bolt_step, 8)
				var bolt_size := Vector2(54.0, 92.0) * (1.10 if shrinking else 0.92)
				var bolt_rotation := tangent.angle() + PI * 0.5
				r.draw_set_transform(bolt_center, bolt_rotation, Vector2.ONE)
				r.draw_texture_rect_region(r.zone_lightning_atlas, Rect2(-bolt_size * 0.5, bolt_size), r._zone_lightning_src_rect(frame), Color(1.0, 1.0, 1.0, bolt_alpha))
				r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				var bolt_color := Color("#f1d9ff", bolt_alpha)
				var bolt_points := PackedVector2Array()
				for point_index in range(5):
					var along := (float(point_index) / 4.0 - 0.5) * bolt_length
					var jitter_seed := posmod(seed + point_index * 23, 9) - 4
					var jitter := float(jitter_seed) * (2.2 if shrinking else 1.5)
					bolt_points.append(bolt_center + tangent * along + radial * jitter)
				r.draw_polyline(bolt_points, Color(ring, bolt_alpha * 0.42), 6.0)
				r.draw_polyline(bolt_points, bolt_color, 2.0)
	if shrinking or absf(target_radius - radius) > 4.0:
		r._draw_dashed_circle(center, target_radius, Color(0.90, 0.76, 1.0, 0.55), 3.0, 0.075, 0.075)

func draw_covers() -> void:
	for cover_index in range(world.covers.size()):
		var cover: Dictionary = world.covers[cover_index]
		var rect: Rect2 = cover["rect"]
		var c := rect.get_center()
		var base := minf(rect.size.x, rect.size.y) * 0.5
		if not r.is_world_visible(c, rect.size.length() * 0.5 + 32.0):
			continue
		if r.rock_atlas != null:
			var src: Rect2 = r.ROCK_SOURCE_RECTS[cover_index % r.ROCK_SOURCE_RECTS.size()]
			var max_size := Vector2(base * 2.0, base * 2.0)
			var scale_factor: float = minf(max_size.x / src.size.x, max_size.y / src.size.y)
			var draw_size := src.size * scale_factor
			var dest := Rect2(c + Vector2(-draw_size.x * 0.5, base - draw_size.y), draw_size)
			r.draw_texture_rect_region(r.rock_atlas, dest, src)
			continue
		r.draw_circle(c + Vector2(3.0, 5.0), base, Color(0.16, 0.17, 0.19, 0.85))
		r.draw_circle(c, base, Color("#7d838e"))
		r.draw_circle(c - Vector2(base * 0.25, base * 0.30), base * 0.55, Color("#9aa1ac"))
		r.draw_circle(c + Vector2(base * 0.35, base * 0.25), base * 0.34, Color("#6a707a"))

func _item_display_kind(pickup: Dictionary) -> String:
	var kind := str(pickup.get("kind", ""))
	if kind == "":
		return "medkit"
	if kind == "decoy":
		return str(pickup.get("disguise", "medkit"))
	return kind

func _item_tint(kind: String) -> Color:
	match kind:
		"spring": return Color("#ffe066")
		"slide": return Color("#70e7ff")
		"pull": return Color("#b78cff")
		"pocket": return Color("#f4e2ff")
		_: return Color("#6ef3a5")

func _item_label(kind: String) -> String:
	match kind:
		"spring": return "SPRING"
		"slide": return "SLIDE"
		"pull": return "PULL"
		"pocket": return "POCKET"
		_: return "MEDKIT"

func draw_pickups() -> void:
	for pickup in world.health_pickups:
		if not bool(pickup["active"]):
			continue
		var pickup_pos: Vector2 = pickup["pos"]
		if not r.is_world_visible(pickup_pos, 100.0):
			continue
		var pulse := 1.0 + sin(float(world.tick) * 0.10 + float(pickup["id"])) * 0.10
		var gun_name := str(pickup.get("gun_name", ""))
		if gun_name != "":
			r.draw_circle(pickup_pos, 24.0 * pulse, Color(1.0, 0.82, 0.25, 0.16))
			r.draw_arc(pickup_pos, 27.0, 0.0, TAU, 28, Color("#ffd166"), 3.5)
			var pickup_equip := str(pickup.get("equipment", pickup.get("gun_id", "")))
			if r.gun_atlas != null and pickup_equip != "":
				var vis: Dictionary = r.GunSig.visual_for_equipment(pickup_equip)
				r.draw_texture_rect_region(r.gun_atlas, Rect2(pickup_pos - Vector2(26.0, 14.0) * pulse, Vector2(52.0, 28.0) * pulse), r._gun_src_rect(int(vis.get("frame", 0))))
			elif r.gun_texture != null:
				r.draw_texture_rect(r.gun_texture, Rect2(pickup_pos - Vector2(24.0, 14.0) * pulse, Vector2(48.0, 28.0) * pulse), false)
			r.draw_string(GameFont.get_font(), pickup_pos + Vector2(-60.0, 44.0), gun_name, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Color("#ffd166"))
			continue
		var show_kind := _item_display_kind(pickup)
		var tint: Color = _item_tint(show_kind)
		var is_medkit := show_kind == "medkit"
		var magnet_slot := int(pickup.get("magnet_slot", -1))
		if magnet_slot >= 0 and magnet_slot < world.heroes.size():
			var magnet_dir := pickup_pos.direction_to(Vector2(world.heroes[magnet_slot]["pos"]))
			for trail_index in range(3):
				var side := magnet_dir.orthogonal() * (float(trail_index) - 1.0) * 7.0
				for pixel_index in range(3):
					var pixel_pos := pickup_pos - magnet_dir * (24.0 + float(trail_index) * 8.0 + float(pixel_index) * 10.0) + side
					var pixel_size := 5.0 - float(pixel_index)
					r.draw_rect(Rect2(pixel_pos - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), Color(tint, 0.80 - float(pixel_index) * 0.18))
		else:
			if is_medkit:
				var orbit_phase := float(world.tick) * 0.035 + float(pickup["id"])
				for pixel_index in range(8):
					var pixel_angle := orbit_phase + TAU * float(pixel_index) / 8.0
					var pixel_pos := pickup_pos + Vector2.RIGHT.rotated(pixel_angle) * (27.0 + float(pixel_index % 2) * 3.0)
					var pixel_size := 4.0 if pixel_index % 3 else 6.0
					r.draw_rect(Rect2(pixel_pos - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), Color(tint, 0.52 + float(pixel_index % 2) * 0.24))
				r.draw_rect(Rect2(pickup_pos + Vector2(-21.0, 17.0), Vector2(42.0, 4.0)), Color(0.02, 0.07, 0.05, 0.50))
			else:
				r.draw_circle(pickup_pos, 24.0 * pulse, Color(tint, 0.16))
				r.draw_arc(pickup_pos, 27.0, 0.0, TAU, 28, tint, 3.5)
		if show_kind == "medkit" and r.medkit_texture != null:
			r.draw_texture_rect(r.medkit_texture, Rect2(pickup_pos - Vector2(19.0, 19.0) * pulse, Vector2(38.0, 38.0) * pulse), false)
		elif show_kind == "medkit":
			r.draw_rect(Rect2(pickup_pos + Vector2(-5.0, -16.0), Vector2(10.0, 32.0)), Color("#d9ffe8"))
			r.draw_rect(Rect2(pickup_pos + Vector2(-16.0, -5.0), Vector2(32.0, 10.0)), Color("#d9ffe8"))
		else:
			r.draw_circle(pickup_pos, 11.0 * pulse, Color(tint, 0.92))
			r.draw_arc(pickup_pos, 16.0 * pulse, 0.0, TAU, 20, Color.WHITE, 2.0)
		if show_kind != "medkit" or str(pickup.get("kind", "")) != "":
			r.draw_string(GameFont.get_font(), pickup_pos + Vector2(-48.0, 42.0), _item_label(show_kind), HORIZONTAL_ALIGNMENT_CENTER, 96.0, 11, tint)

func draw_cores() -> void:
	for core in world.cores:
		var slot := int(core["slot"])
		var pos: Vector2 = core["pos"]
		if not r.is_world_visible(pos, 80.0):
			continue
		var color: Color = Color(r._slot_color(slot))
		r.draw_circle(pos, 20.0, Color(color, 0.10))
		r.draw_arc(pos, 20.0, 0.0, TAU, 24, Color(color, 0.26), 2.0)
		r.draw_string(GameFont.get_font(), pos + Vector2(-18.0, 5.0), "P%d" % (slot + 1), HORIZONTAL_ALIGNMENT_CENTER, 36.0, 11, Color(color, 0.5))

func draw_crates() -> void:
	if world.crates.is_empty():
		return
	for crate in world.crates:
		if not bool(crate.get("alive", false)):
			continue
		var pos: Vector2 = crate["pos"]
		if not r.is_world_visible(pos, 90.0):
			continue
		var body := Rect2(pos + Vector2(-22.0, -20.0), Vector2(44.0, 40.0))
		var hp_now := float(crate.get("hp", 0.0))
		var hp_max := float(crate.get("max_hp", 48.0))
		var hp_ratio := clampf(hp_now / maxf(1.0, hp_max), 0.0, 1.0)
		if r.crate_atlas != null:
			var frame := 0 if hp_ratio > 0.66 else (1 if hp_ratio > 0.33 else 2)
			r.draw_texture_rect_region(r.crate_atlas, body, r.CRATE_SOURCE_RECTS[frame])
		else:
			r.draw_rect(body, Color("#5a3a1c"))
			r.draw_rect(body, Color("#3b2410"), false, 2.0)
			r.draw_rect(Rect2(pos + Vector2(-20.0, -16.0), Vector2(40.0, 5.0)), Color("#7a5130"))
			r.draw_rect(Rect2(pos + Vector2(-20.0, -4.0), Vector2(40.0, 5.0)), Color("#6b4526"))
			r.draw_rect(Rect2(pos + Vector2(-20.0, 8.0), Vector2(40.0, 5.0)), Color("#7a5130"))
		if hp_ratio < 0.999:
			var bar := Rect2(pos + Vector2(-31.0, -49.0), Vector2(62.0, 10.0))
			r.draw_rect(bar.grow(2.0), Color(0.04, 0.05, 0.07, 0.9))
			r.draw_rect(bar, Color(0.16, 0.18, 0.22, 0.95))
			r.draw_rect(Rect2(bar.position + Vector2(2.0, 2.0), Vector2((bar.size.x - 4.0) * hp_ratio, bar.size.y - 4.0)), Color("#e0a15a"))
			var hp_label := "%d / %d" % [roundi(hp_now), roundi(hp_max)]
			r.draw_string(GameFont.get_font(), bar.position + Vector2(1.0, 9.0), hp_label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 9, Color(0.0, 0.0, 0.0, 0.72))
			r.draw_string(GameFont.get_font(), bar.position + Vector2(0.0, 8.0), hp_label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 9, Color.WHITE)

func draw_crate_orbs() -> void:
	if world.crate_orbs.is_empty():
		return
	for orb in world.crate_orbs:
		if not bool(orb.get("active", true)):
			continue
		var pos: Vector2 = orb["pos"]
		if not r.is_world_visible(pos, 80.0):
			continue
		var frame := posmod(int(world.tick / 5), 4)
		var row := 0 if bool(orb.get("red", true)) else 1
		var cell_size := Vector2(
			float(CRATE_ORB_ATLAS.get_width()) / 4.0,
			float(CRATE_ORB_ATLAS.get_height()) / 2.0
		)
		# The generated cells are portrait-shaped; crop their centered square so the orb is not squashed.
		var crop_size := minf(cell_size.x, cell_size.y)
		var src_pos := Vector2(
			float(frame) * cell_size.x + (cell_size.x - crop_size) * 0.5,
			float(row) * cell_size.y + (cell_size.y - crop_size) * 0.5
		)
		var pulse := 1.0 + sin(float(world.tick) * 0.12) * 0.04
		var draw_size := Vector2.ONE * 58.0 * pulse
		r.draw_texture_rect_region(CRATE_ORB_ATLAS, Rect2(pos - draw_size * 0.5, draw_size), Rect2(src_pos, Vector2.ONE * crop_size))

func draw_mid_tower() -> void:
	if world == null or not bool(world.mid_tower.get("alive", false)):
		return
	var pos: Vector2 = world.mid_tower["pos"]
	if not r.is_world_visible(pos, 240.0):
		return
	var boing := float(world.mid_tower.get("boing", 0.0))
	var squash := 1.0 + sin(boing * PI / 0.22) * 0.16 if boing > 0.0 else 1.0
	var sz := Vector2(210.0, 278.0) * squash
	if r.tower_texture != null:
		r.draw_texture_rect(r.tower_texture, Rect2(pos - sz * 0.5 + Vector2(0, -22.0), sz), false)
	var hp_now := float(world.mid_tower.get("hp", 0.0))
	var hp_max := float(world.mid_tower.get("max_hp", 1.0))
	var ratio := clampf(hp_now / maxf(1.0, hp_max), 0.0, 1.0)
	var bar := Rect2(pos + Vector2(-88.0, -150.0), Vector2(176.0, 18.0))
	r.draw_rect(bar.grow(2.0), Color(0.04, 0.05, 0.07, 0.9))
	r.draw_rect(bar, Color(0.16, 0.18, 0.22, 0.95))
	r.draw_rect(Rect2(bar.position + Vector2(2.0, 2.0), Vector2((bar.size.x - 4.0) * ratio, bar.size.y - 4.0)), Color("#ff5a4a"))
	var label := "%d / %d" % [roundi(hp_now), roundi(hp_max)]
	r.draw_string(GameFont.get_font(), bar.position + Vector2(0.0, 13.0), label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 12, Color.WHITE)
