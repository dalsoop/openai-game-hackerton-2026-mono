extends Control

var world: HexWorld = null
var local_player := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw() -> void:
	if world == null:
		return
	_draw_energy_bar()
	_draw_timer()
	_draw_leaderboard()
	if world.result == &"finished":
		_draw_result()

func _draw_energy_bar() -> void:
	var p: Dictionary = world.players[local_player]
	var energy := float(p["energy"])
	var ratio := energy / HexWorld.MAX_ENERGY
	var bar_w := 200.0
	var bar_h := 18.0
	var pos := Vector2(20, 20)
	draw_rect(Rect2(pos, Vector2(bar_w, bar_h)), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(pos, Vector2(bar_w * ratio, bar_h)), p["color"])
	draw_rect(Rect2(pos, Vector2(bar_w, bar_h)), Color.WHITE, false, 1.5)
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(bar_w + 10, 14), "에너지 %.0f" % energy, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _draw_timer() -> void:
	var remaining := world.time_remaining()
	var minutes := int(remaining) / 60
	var seconds := int(remaining) % 60
	var text := "%d:%02d" % [minutes, seconds]
	var font := ThemeDB.fallback_font
	var vp := get_viewport_rect().size
	draw_string(font, Vector2(vp.x / 2.0 - 30, 34), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 24, Color.WHITE)

func _draw_leaderboard() -> void:
	var board := world.leaderboard()
	var font := ThemeDB.fallback_font
	var vp := get_viewport_rect().size
	var x := vp.x - 180.0
	var y := 20.0
	draw_string(font, Vector2(x, y + 14), "영토 순위", HORIZONTAL_ALIGNMENT_LEFT, 160, 14, Color(1, 1, 1, 0.7))
	y += 24.0
	for i in board.size():
		var entry: Dictionary = board[i]
		var label := "P%d" % (int(entry["id"]) + 1)
		if int(entry["id"]) == local_player:
			label += " (나)"
		var color: Color = entry["color"]
		draw_rect(Rect2(Vector2(x, y + 2), Vector2(12, 12)), color)
		draw_string(font, Vector2(x + 18, y + 13), "%s  %d칸" % [label, entry["territory"]], HORIZONTAL_ALIGNMENT_LEFT, 140, 13, Color.WHITE)
		y += 20.0

func _draw_result() -> void:
	var vp := get_viewport_rect().size
	var cx := vp.x / 2.0
	var cy := vp.y / 2.0
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
	var font := ThemeDB.fallback_font
	var win_text: String
	if world.winner == local_player:
		win_text = "승리!"
	else:
		win_text = "P%d 승리" % (world.winner + 1)
	draw_string(font, Vector2(cx - 60, cy - 10), win_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 36, Color.WHITE)
	var board := world.leaderboard()
	var y := cy + 30.0
	for entry in board:
		var label := "P%d: %d칸" % [int(entry["id"]) + 1, entry["territory"]]
		draw_string(font, Vector2(cx - 60, y), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 16, entry["color"])
		y += 22.0
