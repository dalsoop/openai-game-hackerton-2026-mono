class_name RenderFxLayer
extends RefCounted

var r: Node2D
var world

func _init(renderer: Node2D) -> void:
	r = renderer

func impact_src_rect(row: int, col: int) -> Rect2:
	if r.impact_atlas == null:
		return Rect2()
	var cell: Vector2 = Vector2(float(r.impact_atlas.get_width()) / 4.0, float(r.impact_atlas.get_height()) / 3.0)
	return Rect2(Vector2(float(posmod(col, 4)), float(posmod(row, 3))) * cell, cell)

func horizontal_fx_src_rect(texture: Texture2D, columns: int, frame: int) -> Rect2:
	var cell := Vector2(float(texture.get_width()) / float(columns), float(texture.get_height()))
	return Rect2(Vector2(float(clampi(frame, 0, columns - 1)) * cell.x, 0.0), cell)

func mobility_fx_texture(kind: StringName, label: String) -> Texture2D:
	if kind == &"guard" and label not in ["IRON MARCH", "BRACE STEP"]:
		return null
	if kind == &"drain" and label != "+8 SHADOW PULL":
		return null
	if kind == &"fuse" and label != "BLAST ROLL":
		return null
	return r.mobility_fx_atlases.get(str(kind)) as Texture2D

func zone_lightning_src_rect(frame: int) -> Rect2:
	if r.zone_lightning_atlas == null:
		return Rect2()
	var cell := Vector2(float(r.zone_lightning_atlas.get_width()) / 4.0, float(r.zone_lightning_atlas.get_height()) / 2.0)
	var safe_frame := posmod(frame, 8)
	return Rect2(Vector2(float(safe_frame % 4), float(safe_frame / 4)) * cell, cell)

func ultimate_src_rect(texture: Texture2D, frame: int, row: int = 0) -> Rect2:
	if texture == null:
		return Rect2()
	var cell := Vector2(float(texture.get_width()) / 4.0, float(texture.get_height()) / 2.0)
	return Rect2(Vector2(float(clampi(frame, 0, 3)), float(clampi(row, 0, 1))) * cell, cell)

func draw_ultimate_frame(animal: int, pos: Vector2, size: Vector2, frame: int, row: int = 0, rotation: float = 0.0, alpha: float = 1.0) -> bool:
	var texture: Texture2D = r.ultimate_fx_atlases.get(posmod(animal, 12), null)
	if texture == null:
		return false
	r.draw_set_transform(pos, rotation, Vector2.ONE)
	r.draw_texture_rect_region(texture, Rect2(-size * 0.5, size), ultimate_src_rect(texture, frame, row), Color(1.0, 1.0, 1.0, alpha))
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func bullet_src_rect(kind: String, tick: int) -> Rect2:
	var row := 1
	match kind:
		"pellet": row = 0
		"burst", "bolt": row = 1
		"shell": row = 2
		"seeker": row = 3
		_: row = 1
	var col: int = posmod(tick / 3, int(r.BULLET_COLS))
	var cell := Vector2(float(r.bullet_atlas.get_width()) / float(r.BULLET_COLS), float(r.bullet_atlas.get_height()) / float(r.BULLET_ROWS))
	return Rect2(Vector2(float(col), float(row)) * cell, cell)

func draw_lhj_bullet(projectile_pos: Vector2, direction: Vector2, kind: String, scale: float = 1.0) -> void:
	if r.bullet_atlas == null:
		return
	var dir := direction if direction.length_squared() > 0.0001 else Vector2.RIGHT
	var src := bullet_src_rect(kind, int(r.world.tick))
	var dest := Rect2(Vector2(-28.0, -10.0) * scale, Vector2(56.0, 20.0) * scale)
	r.draw_set_transform(projectile_pos, dir.angle(), Vector2.ONE)
	r.draw_texture_rect_region(r.bullet_atlas, dest, src)
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func projectile_color(projectile: Dictionary) -> Color:
	match str(projectile.get("kind", "bolt")):
		"pellet": return Color("#ffae57")
		"beam": return Color("#70e7ff")
		"shell": return Color("#ff665a")
		"tether": return Color("#db6cff")
		"hammer": return Color("#ffe066")
		"seeker": return Color("#ff5ca8")
		"burst": return Color("#8bffde")
		"slash": return Color("#b9f3ff")
		"fist": return Color("#ff9466")
		"bomb": return Color("#ff554a")
		"spear": return Color("#ffe27a")
		"chain": return Color("#b78cff")
		"shield": return Color("#8de1ff")
		_: return r._slot_color(int(projectile["owner"]))

func draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float = 3.0, dash: float = 0.10, gap: float = 0.08) -> void:
	var angle := 0.0
	while angle < TAU:
		r.draw_arc(center, radius, angle, minf(angle + dash, TAU), 4, color, width)
		angle += dash + gap

func draw_dashed_tracer(pos: Vector2, dir: Vector2, color: Color, width: float = 5.0) -> void:
	var cursor := 12.0
	for index in range(3):
		r.draw_line(pos - dir * (cursor + 15.0), pos - dir * cursor, color, width, true)
		cursor += 15.0 + 9.0

func draw_motion_trail(trail: Array, color: Color, width: float, opacity: float = 1.0) -> void:
	if r.lite_draw or trail.size() < 2 or opacity <= 0.001:
		return
	var last_index := trail.size() - 1
	for segment_index in range(1, trail.size()):
		var age_ratio := float(segment_index) / float(last_index)
		var fade := pow(age_ratio, 1.65) * opacity
		var segment_width := width * lerpf(0.22, 1.0, age_ratio)
		var from: Vector2 = trail[segment_index - 1]
		var to: Vector2 = trail[segment_index]
		r.draw_line(from, to, Color(color, fade * 0.16), segment_width * 1.75, true)
		r.draw_line(from, to, Color(color, fade * 0.76), segment_width, true)

func draw_projectile_texture(pos: Vector2, direction: Vector2, kind: String, size_scale: float = 1.0) -> bool:
	var texture: Texture2D = r.projectile_textures.get(kind) as Texture2D
	if texture == null or not r.PROJECTILE_TEXTURE_SIZES.has(kind):
		return false
	var draw_size: Vector2 = Vector2(r.PROJECTILE_TEXTURE_SIZES[kind]) * size_scale
	r.draw_set_transform(pos, direction.angle(), Vector2.ONE)
	r.draw_texture_rect(texture, Rect2(Vector2(-draw_size.x * 0.72, -draw_size.y * 0.5), draw_size), false)
	r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func sync_roar_fx() -> void:
	if r.world == null:
		return
	var roars: Array = r.world.tiger_roars
	while r.roar_fx.size() < roars.size():
		_spawn_roar_rect()
	for i in range(r.roar_fx.size()):
		_sync_one_roar(i, roars)

func _spawn_roar_rect() -> void:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(1160, 1160)
	rect.pivot_offset = rect.size * 0.5
	if r.roar_shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = r.roar_shader
		rect.material = mat
	r.add_child(rect)
	r.roar_fx.append(rect)

func _sync_one_roar(i: int, roars: Array) -> void:
	var node: ColorRect = r.roar_fx[i]
	if i >= roars.size():
		node.visible = false
		return
	var roar: Dictionary = roars[i]
	var life := maxf(0.01, float(roar.get("life", 1.15)))
	var progress := clampf(float(roar.get("age", 0.0)) / life, 0.0, 1.0)
	var pos: Vector2 = roar.get("pos", Vector2.ZERO)
	node.visible = true
	var rad := float(roar.get("radius", 300.0))
	node.size = Vector2(rad * 2.0 + 80.0, rad * 2.0 + 80.0)
	node.pivot_offset = node.size * 0.5
	node.position = pos - node.size * 0.5
	node.z_index = 40
	var mat2 = node.material
	if mat2 is ShaderMaterial:
		mat2.set_shader_parameter("progress", progress)
		mat2.set_shader_parameter("strength", 0.10)
