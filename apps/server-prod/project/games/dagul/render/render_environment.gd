class_name RenderEnvironment
extends RefCounted

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer

func draw_island() -> void:
	var arena := Rect2(Vector2.ZERO, world.ARENA_SIZE)
	r.draw_rect(arena.grow(900.0), Color("#17456f"))
	if r.island_texture == null:
		r.draw_rect(arena, Color("#cbb37a"))
		r.draw_circle(Vector2(world.ARENA_CENTER), world.ARENA_SIZE.y * 0.48, Color("#d9c088"))
		return
	var prev_filter := r.texture_filter
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_draw_grass_tiles(arena)
	_draw_dirt_patches()
	r.texture_filter = prev_filter

func _draw_grass_tiles(arena: Rect2) -> void:
	var tex_size: Vector2 = r.island_texture.get_size()
	var cell := tex_size.x * 12.0
	var y := 0.0
	while y < arena.size.y - 0.5:
		var x := 0.0
		while x < arena.size.x - 0.5:
			var dw := minf(cell, arena.size.x - x)
			var dh := minf(cell, arena.size.y - y)
			var src := Rect2(Vector2.ZERO, Vector2(tex_size.x * dw / cell, tex_size.y * dh / cell))
			r.draw_texture_rect_region(r.island_texture, Rect2(Vector2(x, y), Vector2(dw, dh)), src)
			x += cell
		y += cell

const DIRT_SPOTS := [
	[1720.0, 1620.0, 170.0], [1960.0, 1760.0, 150.0], [1800.0, 1860.0, 130.0],
	[6040.0, 3460.0, 140.0], [6220.0, 3580.0, 115.0], [1380.0, 3680.0, 155.0],
	[1600.0, 3840.0, 130.0], [1480.0, 3960.0, 110.0], [5480.0, 980.0, 125.0],
	[5680.0, 1120.0, 105.0], [3100.0, 4120.0, 140.0], [3320.0, 4240.0, 115.0],
	[6880.0, 2280.0, 150.0], [7080.0, 2460.0, 125.0], [6940.0, 2560.0, 100.0],
	[780.0, 2680.0, 120.0], [960.0, 2820.0, 100.0],
]

func _dirt_here(px: float, py: float) -> bool:
	var p := Vector2(px, py)
	for spot in DIRT_SPOTS:
		if p.distance_to(Vector2(spot[0], spot[1])) <= spot[2]:
			return true
	return false

var _dirt_cells: Array[Dictionary] = []

func _draw_dirt_patches() -> void:
	if r.dirt_tile_texture == null:
		return
	if r.lite_draw:
		_draw_dirt_spots_lite()
		return
	_ensure_dirt_cells()
	var atlas: Texture2D = r.dirt_tile_texture
	var use_atlas := atlas.get_width() >= 128
	for cell in _dirt_cells:
		_draw_dirt_cell(float(cell.x), float(cell.y), 96.0, atlas, use_atlas)

func _ensure_dirt_cells() -> void:
	if not _dirt_cells.is_empty():
		return
	var cell := 96.0
	var y := 480.0
	while y < 4440.0:
		_collect_dirt_row(y, cell)
		y += cell

func _collect_dirt_row(y: float, cell: float) -> void:
	var x := 360.0
	while x < 7440.0:
		if _dirt_here(x + cell * 0.5, y + cell * 0.5):
			_dirt_cells.append({"x": x, "y": y})
		x += cell

func _draw_dirt_spots_lite() -> void:
	var atlas: Texture2D = r.dirt_tile_texture
	var src := Rect2(Vector2.ZERO, Vector2(32, 32))
	if atlas.get_width() >= 128:
		src = Rect2(Vector2(32, 32), Vector2(32, 32))
	for spot in DIRT_SPOTS:
		var rad: float = float(spot[2])
		var pos := Vector2(float(spot[0]) - rad, float(spot[1]) - rad)
		r.draw_texture_rect_region(atlas, Rect2(pos, Vector2(rad * 2.0, rad * 2.0)), src)

func _draw_dirt_cell(x: float, y: float, cell: float, atlas: Texture2D, use_atlas: bool) -> void:
	var n := 1 if _dirt_here(x + cell * 0.5, y - cell * 0.5) else 0
	var e := 2 if _dirt_here(x + cell * 1.5, y + cell * 0.5) else 0
	var s := 4 if _dirt_here(x + cell * 0.5, y + cell * 1.5) else 0
	var w := 8 if _dirt_here(x - cell * 0.5, y + cell * 0.5) else 0
	var mask := n + e + s + w
	var src := Rect2(Vector2.ZERO, Vector2(32, 32))
	if use_atlas:
		src = Rect2(Vector2(float(mask % 4) * 32.0, float(int(mask / 4)) * 32.0), Vector2(32, 32))
	r.draw_texture_rect_region(atlas, Rect2(Vector2(x, y), Vector2(cell, cell)), src)

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
	_draw_tree_spots(spots)
	r.texture_filter = prev_filter

func _draw_tree_spots(spots: Array[Vector3]) -> void:
	var dw := 48.0 * 3.2
	var dh := 64.0 * 3.2
	for spot in spots:
		var feet := Vector2(spot.x, spot.y)
		r.draw_circle(feet + Vector2(0, 4), 22.0, Color(0.05, 0.04, 0.03, 0.28))
		var src := Rect2(Vector2(spot.z * 48.0, 0.0), Vector2(48, 64))
		r.draw_texture_rect_region(r.tree_atlas, Rect2(feet - Vector2(dw * 0.5, dh - 10.0), Vector2(dw, dh)), src)

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
	_draw_zone_bands(center, radius, ring, pulse)
	r.draw_arc(center, radius, 0.0, TAU, 64, Color(ring, 0.22), pulse * 2.5)
	_draw_zone_bolts(center, radius, shrinking, ring)
	if shrinking or absf(target_radius - radius) > 4.0:
		r._draw_dashed_circle(center, target_radius, Color(0.90, 0.76, 1.0, 0.55), 3.0, 0.075, 0.075)

func _draw_zone_bands(center: Vector2, radius: float, ring: Color, pulse: float) -> void:
	var band_count := 10 if r.lite_draw else 48
	var shrinking := bool(world.safe_zone_shrinking)
	var phase := float(world.tick) * (0.026 if shrinking else 0.007)
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

func _draw_zone_bolts(center: Vector2, radius: float, shrinking: bool, ring: Color) -> void:
	if r.lite_draw:
		return
	var bolt_count := 12 if shrinking else 7
	var bolt_step := int(world.tick / (2 if shrinking else 5))
	for bolt_index in range(bolt_count):
		_draw_one_zone_bolt(center, radius, shrinking, ring, bolt_index, bolt_step)

func _draw_one_zone_bolt(center: Vector2, radius: float, shrinking: bool, ring: Color, bolt_index: int, bolt_step: int) -> void:
	var bolt_life := fmod(float(world.tick) * (0.052 if shrinking else 0.025) + float(bolt_index) * 0.173, 1.0)
	if bolt_life > 0.64:
		return
	var seed := bolt_index * 37 + bolt_step * 17
	var bolt_angle := TAU * float(posmod(seed, 997)) / 997.0
	var tangent := Vector2.RIGHT.rotated(bolt_angle + PI * 0.5)
	var radial := Vector2.RIGHT.rotated(bolt_angle)
	var bolt_center := center + radial * radius
	var bolt_alpha := (0.98 if shrinking else 0.82) * sin(bolt_life / 0.64 * PI)
	if r.zone_lightning_atlas != null:
		var frame := posmod(seed + bolt_step, 8)
		var bolt_size := Vector2(54.0, 92.0) * (1.10 if shrinking else 0.92)
		r.draw_set_transform(bolt_center, tangent.angle() + PI * 0.5, Vector2.ONE)
		r.draw_texture_rect_region(r.zone_lightning_atlas, Rect2(-bolt_size * 0.5, bolt_size), r._zone_lightning_src_rect(frame), Color(1.0, 1.0, 1.0, bolt_alpha))
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var bolt_length := 34.0 + float(posmod(seed * 11, 32))
	var bolt_points := PackedVector2Array()
	for point_index in range(5):
		var along := (float(point_index) / 4.0 - 0.5) * bolt_length
		var jitter := float(posmod(seed + point_index * 23, 9) - 4) * (2.2 if shrinking else 1.5)
		bolt_points.append(bolt_center + tangent * along + radial * jitter)
	r.draw_polyline(bolt_points, Color(ring, bolt_alpha * 0.42), 6.0)
	r.draw_polyline(bolt_points, Color("#f1d9ff", bolt_alpha), 2.0)

func draw_covers() -> void:
	for cover_index in range(world.covers.size()):
		var cover: Dictionary = world.covers[cover_index]
		var rect: Rect2 = cover["rect"]
		var c := rect.get_center()
		var base := minf(rect.size.x, rect.size.y) * 0.5
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
		_draw_pickup(pickup)

func _draw_pickup(pickup: Dictionary) -> void:
	var pickup_pos: Vector2 = pickup["pos"]
	var pulse := 1.0 + sin(float(world.tick) * 0.10 + float(pickup["id"])) * 0.10
	var gun_name := str(pickup.get("gun_name", ""))
	if gun_name != "":
		_draw_gun_pickup(pickup, pickup_pos, pulse, gun_name)
		return
	_draw_item_pickup(pickup, pickup_pos, pulse)

func _draw_gun_pickup(pickup: Dictionary, pickup_pos: Vector2, pulse: float, gun_name: String) -> void:
	r.draw_circle(pickup_pos, 24.0 * pulse, Color(1.0, 0.82, 0.25, 0.16))
	r.draw_arc(pickup_pos, 27.0, 0.0, TAU, 28, Color("#ffd166"), 3.5)
	var pickup_equip := str(pickup.get("equipment", pickup.get("gun_id", "")))
	if r.gun_atlas != null and pickup_equip != "":
		var vis: Dictionary = r.GunSig.visual_for_equipment(pickup_equip)
		r.draw_texture_rect_region(r.gun_atlas, Rect2(pickup_pos - Vector2(26.0, 14.0) * pulse, Vector2(52.0, 28.0) * pulse), r._gun_src_rect(int(vis.get("frame", 0))))
	elif r.gun_texture != null:
		r.draw_texture_rect(r.gun_texture, Rect2(pickup_pos - Vector2(24.0, 14.0) * pulse, Vector2(48.0, 28.0) * pulse), false)
	r.draw_string(GameFont.get_font(), pickup_pos + Vector2(-60.0, 44.0), gun_name, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Color("#ffd166"))

func _draw_item_pickup(pickup: Dictionary, pickup_pos: Vector2, pulse: float) -> void:
	var show_kind := _item_display_kind(pickup)
	var tint: Color = _item_tint(show_kind)
	var magnet_slot := int(pickup.get("magnet_slot", -1))
	if magnet_slot >= 0 and magnet_slot < world.heroes.size():
		var magnet_dir := pickup_pos.direction_to(Vector2(world.heroes[magnet_slot]["pos"]))
		_draw_magnet_trails(pickup_pos, magnet_dir, tint)
		r.draw_arc(pickup_pos, 25.0, magnet_dir.angle() - 1.1, magnet_dir.angle() + 1.1, 18, Color(tint, 0.95), 5.0)
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

func _draw_magnet_trails(pickup_pos: Vector2, magnet_dir: Vector2, tint: Color) -> void:
	for trail_index in range(3):
		var side := magnet_dir.orthogonal() * (float(trail_index) - 1.0) * 7.0
		r.draw_line(pickup_pos - magnet_dir * (20.0 + float(trail_index) * 9.0) + side, pickup_pos - magnet_dir * (48.0 + float(trail_index) * 12.0) + side, Color(tint, 0.72), 4.0)

func draw_cores() -> void:
	for core in world.cores:
		var slot := int(core["slot"])
		var pos: Vector2 = core["pos"]
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
		var pulse := 1.0 + sin(float(world.tick) * 0.18) * 0.12
		var tint := Color("#ff4f4f") if bool(orb.get("red", true)) else Color("#4f8cff")
		if r.crate_orb_atlas != null:
			var cell := Vector2(float(r.crate_orb_atlas.get_width()) / 4.0, float(r.crate_orb_atlas.get_height()) / 2.0)
			var frame := posmod(int(world.tick / 4), 8)
			var src := Rect2(Vector2(float(frame % 4), float(frame / 4)) * cell, cell)
			var size := Vector2(36.0, 36.0) * pulse
			r.draw_texture_rect_region(r.crate_orb_atlas, Rect2(pos - size * 0.5, size), src, tint)
			continue
		r.draw_circle(pos, 18.0 * pulse, Color(tint, 0.18))
		r.draw_circle(pos, 11.0 * pulse, Color(tint, 0.92))
		r.draw_arc(pos, 16.0 * pulse, 0.0, TAU, 22, Color.WHITE, 2.0)

func draw_mid_tower() -> void:
	if world == null or not bool(world.mid_tower.get("alive", false)):
		return
	var pos: Vector2 = world.mid_tower["pos"]
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
