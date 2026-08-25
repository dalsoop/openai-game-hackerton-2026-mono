class_name RenderEnvironment
extends RefCounted

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer

func draw_island() -> void:
	var arena := Rect2(Vector2.ZERO, world.ARENA_SIZE)
	r.draw_rect(arena.grow(900.0), Color("#17456f"))
	if r.island_texture != null:
		var tex_size = r.island_texture.get_size()
		var arena_aspect: float = world.ARENA_SIZE.x / world.ARENA_SIZE.y
		var tex_aspect: float = tex_size.x / tex_size.y
		var src := Rect2(Vector2.ZERO, tex_size)
		if tex_aspect > arena_aspect:
			var w: float = tex_size.y * arena_aspect
			src = Rect2(Vector2((tex_size.x - w) * 0.5, 0.0), Vector2(w, tex_size.y))
		else:
			var h: float = tex_size.x / arena_aspect
			src = Rect2(Vector2(0.0, (tex_size.y - h) * 0.5), Vector2(tex_size.x, h))
		r.draw_texture_rect_region(r.island_texture, arena, src)
	else:
		r.draw_rect(arena, Color("#cbb37a"))
		r.draw_circle(Vector2(world.ARENA_CENTER), world.ARENA_SIZE.y * 0.48, Color("#d9c088"))

func draw_safe_zone() -> void:
	var center: Vector2 = world.safe_zone_center
	var radius: float = maxf(8.0, float(world.safe_zone_radius))
	var target_radius: float = maxf(8.0, float(world.safe_zone_target_radius))
	var outer := maxf(world.ARENA_SIZE.x, world.ARENA_SIZE.y)
	var mid := (radius + outer) * 0.5
	var width := maxf(12.0, outer - radius)
	var seg := 32 if r.lite_draw else 96
	r.draw_arc(center, mid, 0.0, TAU, seg, Color(0.45, 0.10, 0.78, 0.30), width)
	if not r.lite_draw:
		r.draw_arc(center, mid, 0.0, TAU, seg, Color(0.30, 0.02, 0.50, 0.22), width * 0.55)
	var shrinking := bool(world.safe_zone_shrinking)
	var ring: Color = r.ZONE_RING_HOT if shrinking else r.ZONE_RING
	var pulse := 7.0 + (3.0 if shrinking else 0.0) + sin(float(world.tick) * 0.12) * 1.4
	r.draw_arc(center, radius, 0.0, TAU, 96, Color(ring, 0.28), pulse * 2.8)
	r.draw_arc(center, radius, 0.0, TAU, 96, ring, pulse)
	r.draw_arc(center, radius, 0.0, TAU, 96, Color("#f4e2ff"), 2.0)
	if shrinking or absf(target_radius - radius) > 4.0:
		r._draw_dashed_circle(center, target_radius, Color(1.0, 1.0, 1.0, 0.62), 3.0)

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
		var pickup_pos: Vector2 = pickup["pos"]
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
