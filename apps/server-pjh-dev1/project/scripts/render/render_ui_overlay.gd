class_name RenderUiOverlay
extends RefCounted

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer

func draw_head_roulette(body_pos: Vector2, hero: Dictionary) -> void:
	if int(hero.get("slot", -1)) != int(world.local_slot):
		return
	var phase := str(hero.get("roulette_phase", ""))
	if phase == "":
		return
	var slice_ids: Array = ["atk", "spd", "def", "hp", "rate", "range", "giant", "shield", "berserk", "sniper", "double_giant", "turtle"]
	var count := slice_ids.size()
	var spin_id := str(hero.get("roulette_spin_id", ""))
	var current := 0
	if spin_id != "":
		for i in range(count):
			if str(slice_ids[i]) == spin_id:
				current = i
				break
	var wheel_pos: Vector2 = body_pos + Vector2(0.0, -88.0)
	var radius := 54.0
	var slice := TAU / float(count)
	var rot := 0.0
	if phase == "spin":
		var dur := maxf(0.001, float(hero.get("roulette_spin_dur", 0.9)))
		var u := clampf(1.0 - float(hero.get("roulette_time", 0.0)) / dur, 0.0, 1.0)
		var eased := 1.0 - (1.0 - u) * (1.0 - u)
		rot = TAU * 1.65 * eased
	elif phase == "land":
		rot = -float(current) * slice
	var rank := str(hero.get("roulette_rank", "kill"))
	var cols: Array = _roulette_slice_palette(rank)
	var rim: Color = _roulette_rank_color(rank)
	for i in range(count):
		var a0 := -PI * 0.5 + rot + float(i) * slice - slice * 0.5
		var a1 := a0 + slice
		var pts := PackedVector2Array()
		pts.append(wheel_pos)
		for s in range(7):
			var a := lerpf(a0, a1, float(s) / 6.0)
			pts.append(wheel_pos + Vector2(cos(a), sin(a)) * radius)
		r.draw_colored_polygon(pts, cols[i % cols.size()])
		r.draw_line(wheel_pos, wheel_pos + Vector2(cos(a0), sin(a0)) * radius, Color(1.0, 1.0, 1.0, 0.88), 1.6)
	r.draw_arc(wheel_pos, radius, 0.0, TAU, 48, rim.darkened(0.25), 5.0)
	r.draw_circle(wheel_pos, 7.5, Color(0.96, 0.93, 0.86, 1.0))
	r.draw_arc(wheel_pos, 7.5, 0.0, TAU, 20, rim.darkened(0.15), 1.6)
	for i in range(count):
		var mid := -PI * 0.5 + rot + float(i) * slice
		var face_id := str(slice_ids[i])
		var icon_pos: Vector2 = wheel_pos + Vector2(cos(mid), sin(mid)) * (radius * 0.58)
		var icon_tex: Texture2D = r.roulette_icons.get(face_id, null)
		var glow := phase == "land" and i == current
		var sz := 24.0 if glow else 20.0
		if icon_tex != null:
			r.draw_texture_rect(icon_tex, Rect2(icon_pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), false)
		else:
			r.draw_circle(icon_pos, 5.0, Color.WHITE)
	r.draw_colored_polygon(PackedVector2Array([
		wheel_pos + Vector2(0.0, -radius - 7.0),
		wheel_pos + Vector2(-7.0, -radius + 6.0),
		wheel_pos + Vector2(7.0, -radius + 6.0)
	]), Color(0.98, 0.98, 0.98, 1.0))

func _roulette_slice_palette(rank: String) -> Array:
	if rank == "assist":
		return [Color("#2f6fff"), Color("#7eb6ff"), Color("#163a8a")]
	if rank == "wanted":
		return [Color("#e11d2e"), Color("#ff6b6b"), Color("#7a121c")]
	return [Color("#8b3dff"), Color("#c89bff"), Color("#4a1d86")]

func _roulette_rank_color(rank: String) -> Color:
	if rank == "assist":
		return Color("#4da3ff")
	if rank == "wanted":
		return Color("#ff3349")
	return Color("#b84dff")

func draw_reload_bubble(body_pos: Vector2, hero: Dictionary) -> void:
	if not bool(hero.get("alive", false)):
		return
	var mag_now := int(hero.get("mag", 1))
	var reloading := float(hero.get("reload_left", 0.0)) > 0.0
	var flash := float(hero.get("reload_flash", 0.0)) > 0.0
	var mode := ""
	if reloading:
		mode = "RELOADING"
	elif flash:
		mode = "RELOADED"
	elif mag_now <= 0:
		mode = "NEED"
	if mode == "":
		return
	if r.reload_bubble_atlas != null:
		var frame := 8
		if mode == "RELOADING":
			frame = int(world.tick / 3) % 8
		elif mode == "RELOADED":
			var complete_progress := 1.0 - clampf(float(hero.get("reload_flash", 0.0)) / 0.55, 0.0, 1.0)
			frame = 10 + mini(1, int(complete_progress * 2.0))
		var frame_size := Vector2(384.0, 384.0)
		var source := Rect2(Vector2(frame % 4, floori(float(frame) / 4.0)) * frame_size, frame_size)
		var display_size := Vector2(58.0, 58.0)
		var display_rect := Rect2(body_pos + Vector2(-display_size.x * 0.5, -150.0), display_size)
		r.draw_texture_rect_region(r.reload_bubble_atlas, display_rect, source)
		return
	var bw := 36.0
	var bh := 28.0
	var origin: Vector2 = body_pos + Vector2(-bw * 0.5, -122.0)
	r.draw_rect(Rect2(origin, Vector2(bw, bh)), Color(1.0, 1.0, 1.0, 0.96))
	r.draw_rect(Rect2(origin, Vector2(bw, bh)), Color(0.05, 0.05, 0.07, 1.0), false, 1.0)
	var tail: PackedVector2Array = PackedVector2Array([
		body_pos + Vector2(-4.0, -60.0),
		origin + Vector2(bw * 0.5 - 5.0, bh),
		origin + Vector2(bw * 0.5 + 5.0, bh)
	])
	r.draw_colored_polygon(tail, Color(1.0, 1.0, 1.0, 0.96))
	r.draw_line(tail[0], tail[1], Color(0.05, 0.05, 0.07, 1.0), 1.0)
	r.draw_line(tail[0], tail[2], Color(0.05, 0.05, 0.07, 1.0), 1.0)
	var c: Vector2 = origin + Vector2(bw * 0.5, bh * 0.5 - 1.0)
	if mode == "NEED":
		r.draw_rect(Rect2(c + Vector2(-7.0, -8.0), Vector2(14.0, 16.0)), Color(0.12, 0.12, 0.14, 1.0), false, 1.5)
		r.draw_rect(Rect2(c + Vector2(-4.0, -4.0), Vector2(8.0, 9.0)), Color(0.22, 0.22, 0.24, 1.0))
		r.draw_rect(Rect2(c + Vector2(8.0, -9.0), Vector2(3.0, 10.0)), Color(0.92, 0.18, 0.22, 1.0))
		r.draw_rect(Rect2(c + Vector2(8.0, 3.0), Vector2(3.0, 3.0)), Color(0.92, 0.18, 0.22, 1.0))
	elif mode == "RELOADING":
		var p := int(world.tick / 4) % 8
		for i in range(8):
			var ang := float(i) * TAU / 8.0
			var p0: Vector2 = c + Vector2(cos(ang), sin(ang)) * 5.0
			var p1: Vector2 = c + Vector2(cos(ang), sin(ang)) * 10.0
			var col := Color(0.18, 0.18, 0.2, 1.0)
			if i == p:
				col = Color(0.12, 0.45, 0.95, 1.0)
			r.draw_line(p0, p1, col, 2.0)
	else:
		r.draw_line(c + Vector2(-7.0, 1.0), c + Vector2(-2.0, 6.0), Color(0.12, 0.72, 0.28, 1.0), 2.4)
		r.draw_line(c + Vector2(-2.0, 6.0), c + Vector2(8.0, -6.0), Color(0.12, 0.72, 0.28, 1.0), 2.4)

func draw_pocket_bubbles() -> void:
	for hero in world.heroes:
		if not bool(hero.get("alive", false)):
			continue
		if float(hero.get("pocket_time", 0.0)) <= 0.0:
			continue
		var bubble_pos: Vector2 = hero["pos"]
		var pulse := 150.0 + sin(float(world.tick) * 0.14 + float(hero.get("slot", 0))) * 4.0
		r.draw_circle(bubble_pos, pulse, Color(0.92, 0.95, 1.0, 0.10))
		r.draw_arc(bubble_pos, pulse, 0.0, TAU, 48, Color(0.90, 0.94, 1.0, 0.55), 3.0)
		r.draw_arc(bubble_pos, pulse * 0.70, 0.0, TAU, 32, Color(0.78, 0.86, 1.0, 0.22), 2.0)

func draw_keycap(center: Vector2, letter: String) -> void:
	var box := Rect2(center + Vector2(-16.0, -18.0), Vector2(32.0, 32.0))
	r.draw_rect(box.grow(2.0), Color(0.10, 0.08, 0.06, 0.55))
	r.draw_rect(box, Color("#f4efe4"))
	r.draw_rect(Rect2(box.position + Vector2(2.0, 2.0), Vector2(box.size.x - 4.0, box.size.y - 5.0)), Color("#fffaf2"))
	r.draw_rect(box, Color("#c8bba8"), false, 2.0)
	r.draw_string(GameFont.get_font(), box.position + Vector2(0.0, 23.0), letter, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 16, Color("#2a2218"))

func draw_finish_prompts() -> void:
	if world == null:
		return
	if not world.finish_cine.is_empty() and bool(world.finish_cine.get("on", false)):
		return
	var me := int(world.local_slot)
	if me < 0 or me >= world.heroes.size():
		me = 0
	var me_pos: Vector2 = world.heroes[me]["pos"]
	if bool(world.heroes[me].get("downed", false)) or not bool(world.heroes[me].get("alive", false)):
		return
	for hero in world.heroes:
		var slot := int(hero.get("slot", -1))
		if slot == me:
			continue
		if not bool(hero.get("downed", false)) or not bool(hero.get("alive", false)):
			continue
		var pos: Vector2 = hero["pos"]
		if me_pos.distance_to(pos) > 180.0:
			continue
		var bob := sin(float(world.tick) * 0.18) * 3.0
		var cap := pos + Vector2(0.0, -78.0 + bob)
		draw_keycap(cap, "F")

func _draw_finish_actor(pos: Vector2, animal: int, face_right: bool, scale: float, spin: float, opacity: float, flash: float) -> void:
	var tint := Color(3.2, 3.2, 3.2, opacity) if flash > 0.0 else Color(1.0, 1.0, 1.0, opacity)
	var flip := 1.0 if face_right else -1.0
	r.draw_set_transform(pos, spin, Vector2(flip * scale, scale))
	if r.animal_atlas != null:
		r.draw_texture_rect_region(r.animal_atlas, Rect2(Vector2(-40.0, -40.0), Vector2(80.0, 80.0)), r._animal_src_rect(animal), tint)
	else:
		r.draw_circle(Vector2.ZERO, 28.0, Color(r._slot_color(animal), opacity))
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_finish_cine() -> void:
	if world == null:
		return
	var cine: Dictionary = world.finish_cine
	if cine.is_empty() or not bool(cine.get("on", false)):
		return
	var atk := int(cine.get("atk", 0))
	var vic := int(cine.get("vic", -1))
	if atk < 0 or vic < 0 or atk >= world.heroes.size() or vic >= world.heroes.size():
		return
	if r.finish_bg_tex == null:
		r.finish_bg_tex = r._load_tex("res://assets/fx/finish-bg.png")
	var mid := Vector2.ZERO
	var cam := r.get_viewport().get_camera_2d()
	if cam != null:
		mid = cam.get_screen_center_position()
	elif cine.has("mid"):
		mid = Vector2(cine["mid"])
	if r.finish_bg_tex != null:
		r.draw_texture_rect(r.finish_bg_tex, Rect2(mid + Vector2(-520.0, -260.0), Vector2(1040.0, 520.0)), false)
	else:
		r.draw_circle(mid, 220.0, Color(1.0, 0.32, 0.28, 0.6))
	var atk_h: Dictionary = world.heroes[atk]
	var vic_h: Dictionary = world.heroes[vic]
	var atk_an := int(atk_h.get("animal", atk))
	var vic_an := int(vic_h.get("animal", vic))
	var cine_t := float(cine.get("t", 0.0))
	var prep_t := clampf(cine_t / 0.35, 0.0, 1.0)
	var hop_wave := absf(sin(TAU * prep_t)) if cine_t < 0.35 else 0.0
	var hop_lift := hop_wave * 22.0
	var atk_scale := 1.55
	if cine_t < 0.35:
		atk_scale *= 1.0 + 0.07 * hop_wave
	var atk_pos := mid + Vector2(-150.0 + float(cine.get("atk_x", 0.0)), 28.0 - hop_lift)
	var hit_age := float(cine.get("hit_age", 0.0))
	var shake := Vector2.ZERO
	if bool(cine.get("hit", false)) and hit_age <= 0.40:
		shake = Vector2(sin(hit_age * 117.0), cos(hit_age * 153.0)) * 3.0
	var vic_pos := mid + Vector2(150.0, 36.0) + Vector2(float(cine.get("vic_x", 0.0)), float(cine.get("vic_y", 0.0))) + shake
	var impact_pos := mid + Vector2(76.0, 34.0)
	if bool(cine.get("hit", false)) and hit_age < 0.80:
		var impact_t := clampf(hit_age / 0.80, 0.0, 1.0)
		var impact_frame := clampi(int(impact_t * 4.0), 0, 3)
		var impact_size := Vector2.ONE * lerpf(230.0, 340.0, impact_t)
		r.draw_ultimate_frame(6, impact_pos, impact_size, impact_frame, 1, 0.0, (1.0 - impact_t) * 0.58)
		var ring_radius := lerpf(34.0, 174.0, impact_t)
		r.draw_arc(impact_pos, ring_radius, 0.0, TAU, 40, Color(1.0, 0.84, 0.34, (1.0 - impact_t) * 0.82), lerpf(12.0, 3.0, impact_t))
	if bool(cine.get("hit", false)) and hit_age < 0.30 and r.explosion_fx_atlas != null:
		var burst_t := clampf(hit_age / 0.30, 0.0, 1.0)
		var burst_frame := clampi(int(burst_t * 6.0), 0, 5)
		var burst_size := Vector2.ONE * lerpf(184.0, 310.0, burst_t)
		r.draw_texture_rect_region(r.explosion_fx_atlas, Rect2(impact_pos - burst_size * 0.5, burst_size), r._horizontal_fx_src_rect(r.explosion_fx_atlas, 6, burst_frame), Color(1.0, 1.0, 1.0, 1.0 - burst_t * 0.42))
	if bool(cine.get("hit", false)) and hit_age < 0.22 and r.hit_spark_fx_atlas != null:
		var spark_t := clampf(hit_age / 0.22, 0.0, 1.0)
		var spark_frame := clampi(int(spark_t * 4.0), 0, 3)
		var spark_size := Vector2(260.0, 176.0) * lerpf(0.72, 1.18, spark_t)
		for spark_angle in [-0.18, PI + 0.18]:
			r.draw_set_transform(impact_pos, spark_angle, Vector2.ONE)
			r.draw_texture_rect_region(r.hit_spark_fx_atlas, Rect2(-spark_size * 0.5, spark_size), r._horizontal_fx_src_rect(r.hit_spark_fx_atlas, 4, spark_frame), Color(1.0, 0.94, 0.72, 1.0 - spark_t * 0.55))
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if bool(cine.get("hit", false)) and hit_age < 0.12 and r.impact_atlas != null:
		var core_t := clampf(hit_age / 0.12, 0.0, 1.0)
		var core_size := Vector2.ONE * lerpf(116.0, 196.0, core_t)
		r.draw_texture_rect_region(r.impact_atlas, Rect2(impact_pos - core_size * 0.5, core_size), r._impact_src_rect(1, clampi(int(core_t * 4.0), 0, 3)), Color(1.0, 1.0, 1.0, 1.0 - core_t))
	_draw_finish_actor(atk_pos, atk_an, true, atk_scale, 0.0, 1.0, 0.0)
	var cine_spin := float(cine.get("vic_spin", 0.0))
	if not bool(cine.get("hit", false)):
		cine_spin = 0.85
	var fade := 1.0
	if bool(cine.get("hit", false)):
		fade = clampf(1.0 - float(cine.get("fly", 0.0)) / 0.591, 0.15, 1.0)
	_draw_finish_actor(vic_pos, vic_an, false, 1.45, cine_spin, fade, 0.4 if bool(cine.get("hit", false)) else 0.0)
	if not bool(cine.get("hit", false)):
		r.draw_string(GameFont.get_font(), mid + Vector2(-110.0, -176.0), "F / ESC", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, Color("#fff4d2"))
