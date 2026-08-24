extends Node2D

const SNAKE_COLORS := [
	Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"),
	Color("#b084cc"), Color("#70e7ff"), Color("#ffd166"), Color("#ff8dac"),
	Color("#4ecdc4"), Color("#ff6b6b"), Color("#c8b6ff"), Color("#bee1e6"),
]
const BG_COLOR := Color("#1a1a2e")
const GRID_COLOR := Color("#16213e")
const FOOD_GLOW := Color("#ffd700")
const MAP_SIZE := 4000.0
const MINIMAP_SIZE := 140.0
const MINIMAP_MARGIN := 16.0

var world
var camera_pos := Vector2(2000, 2000)
var camera_smooth := 8.0

func _process(delta: float) -> void:
	if world == null:
		return
	var ps: Dictionary = world.player_snake()
	if ps.is_empty() or not bool(ps["alive"]):
		queue_redraw()
		return
	var head := Vector2(ps["segments"][0]["x"], ps["segments"][0]["y"])
	camera_pos = camera_pos.lerp(head, camera_smooth * delta)
	queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var vp := get_viewport_rect().size
	var offset := vp * 0.5 - camera_pos
	_draw_background(offset, vp)
	_draw_foods(offset)
	_draw_snakes(offset)
	_draw_minimap(vp)

func _draw_background(offset: Vector2, vp: Vector2) -> void:
	draw_rect(Rect2(-offset, Vector2(MAP_SIZE, MAP_SIZE) + vp), BG_COLOR)
	var grid := 100.0
	var start_x := floorf((camera_pos.x - vp.x * 0.5) / grid) * grid
	var start_y := floorf((camera_pos.y - vp.y * 0.5) / grid) * grid
	var end_x := camera_pos.x + vp.x * 0.5
	var end_y := camera_pos.y + vp.y * 0.5
	var x := start_x
	while x <= end_x:
		draw_line(Vector2(x, start_y) + offset, Vector2(x, end_y) + offset, GRID_COLOR, 1.0)
		x += grid
	var y := start_y
	while y <= end_y:
		draw_line(Vector2(start_x, y) + offset, Vector2(end_x, y) + offset, GRID_COLOR, 1.0)
		y += grid
	draw_rect(Rect2(Vector2.ZERO + offset, Vector2(MAP_SIZE, MAP_SIZE)), Color.WHITE, false, 3.0)

func _draw_foods(offset: Vector2) -> void:
	for f in world.foods:
		var pos := Vector2(f["x"], f["y"]) + offset
		var color := Color.from_hsv(float(f["hue"]), 0.7, 1.0, 0.85)
		draw_circle(pos, 5.0, color)
		draw_circle(pos, 3.0, Color.WHITE.lerp(color, 0.5))

func _draw_snakes(offset: Vector2) -> void:
	for s in world.snakes:
		if not bool(s["alive"]):
			continue
		var color: Color = SNAKE_COLORS[int(s["color_index"]) % SNAKE_COLORS.size()]
		var segs: Array = s["segments"]
		var seg_count := segs.size()
		for i in range(seg_count - 1, -1, -1):
			var pos := Vector2(segs[i]["x"], segs[i]["y"]) + offset
			var t := 1.0 - float(i) / maxf(float(seg_count), 1.0)
			var radius := 6.0 + t * 6.0
			var seg_color := color.darkened(float(i) / maxf(float(seg_count), 1.0) * 0.4)
			draw_circle(pos, radius, seg_color)
		var head_pos := Vector2(segs[0]["x"], segs[0]["y"]) + offset
		draw_circle(head_pos, 13.0, color)
		draw_circle(head_pos, 10.0, color.lightened(0.3))
		var angle := float(s["angle"])
		var eye_offset := 5.0
		var left_eye := head_pos + Vector2(cos(angle - 0.5), sin(angle - 0.5)) * eye_offset
		var right_eye := head_pos + Vector2(cos(angle + 0.5), sin(angle + 0.5)) * eye_offset
		draw_circle(left_eye, 3.5, Color.WHITE)
		draw_circle(right_eye, 3.5, Color.WHITE)
		var pupil_dir := Vector2(cos(angle), sin(angle)) * 1.5
		draw_circle(left_eye + pupil_dir, 2.0, Color.BLACK)
		draw_circle(right_eye + pupil_dir, 2.0, Color.BLACK)
		if bool(s["boost"]):
			var trail_pos := head_pos - Vector2(cos(angle), sin(angle)) * 18.0
			draw_circle(trail_pos, 4.0, Color(1, 0.8, 0.2, 0.6))
			draw_circle(trail_pos - Vector2(cos(angle), sin(angle)) * 8, 3.0, Color(1, 0.5, 0.1, 0.4))
		var name_str: String = str(s["name"])
		var name_pos := head_pos + Vector2(-30, -22)
		draw_string(ThemeDB.fallback_font, name_pos, name_str, HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Color.WHITE)

func _draw_minimap(vp: Vector2) -> void:
	var mm_pos := Vector2(vp.x - MINIMAP_SIZE - MINIMAP_MARGIN, vp.y - MINIMAP_SIZE - MINIMAP_MARGIN)
	draw_rect(Rect2(mm_pos, Vector2(MINIMAP_SIZE, MINIMAP_SIZE)), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(mm_pos, Vector2(MINIMAP_SIZE, MINIMAP_SIZE)), Color.WHITE, false, 1.0)
	var scale := MINIMAP_SIZE / MAP_SIZE
	for s in world.snakes:
		if not bool(s["alive"]):
			continue
		var head := Vector2(s["segments"][0]["x"], s["segments"][0]["y"])
		var dot := mm_pos + head * scale
		var color: Color = SNAKE_COLORS[int(s["color_index"]) % SNAKE_COLORS.size()]
		var r := 3.0 if int(s["id"]) == 1 else 2.0
		draw_circle(dot, r, color)
	var cam_dot := mm_pos + camera_pos * scale
	draw_rect(Rect2(cam_dot - Vector2(2, 2), Vector2(4, 4)), Color.YELLOW, false, 1.0)
