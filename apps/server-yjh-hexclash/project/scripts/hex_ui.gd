extends Control

var world: HexWorld = null
var local_player := 0
var phase := &"intro"

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw() -> void:
	if phase == &"intro":
		_draw_intro()
		return
	if world == null:
		return
	_draw_energy_bar()
	_draw_timer()
	_draw_leaderboard()
	_draw_help()
	if phase == &"result":
		_draw_result()

func _draw_intro() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.06, 0.08))
	var font := ThemeDB.fallback_font
	var cx := vp.x / 2.0
	draw_string(font, Vector2(cx - 120, vp.y * 0.3), "HEX CLASH", HORIZONTAL_ALIGNMENT_CENTER, 240, 48, Color("d4a843"))
	draw_string(font, Vector2(cx - 100, vp.y * 0.3 + 40), "6인 실시간 영토 전쟁", HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color(0.7, 0.7, 0.7))
	draw_string(font, Vector2(cx - 120, vp.y * 0.5), "인접한 헥스를 클릭해서 영토를 넓히세요", HORIZONTAL_ALIGNMENT_CENTER, 240, 15, Color(0.5, 0.5, 0.5))
	draw_string(font, Vector2(cx - 120, vp.y * 0.5 + 24), "에너지를 써서 점령 · 요새화 가능", HORIZONTAL_ALIGNMENT_CENTER, 240, 15, Color(0.5, 0.5, 0.5))
	draw_string(font, Vector2(cx - 120, vp.y * 0.5 + 48), "3분 후 영토가 가장 많은 사람이 승리!", HORIZONTAL_ALIGNMENT_CENTER, 240, 15, Color(0.5, 0.5, 0.5))
	var pulse := absf(sin(float(Time.get_ticks_msec()) * 0.003))
	draw_string(font, Vector2(cx - 80, vp.y * 0.7), "클릭하여 시작", HORIZONTAL_ALIGNMENT_CENTER, 160, 22, Color(1, 1, 1, 0.5 + pulse * 0.5))

func _draw_energy_bar() -> void:
	var p: Dictionary = world.players[local_player]
	var energy := float(p["energy"])
	var ratio := energy / HexWorld.MAX_ENERGY
	var bar_w := 220.0
	var bar_h := 22.0
	var pos := Vector2(20, 20)
	draw_rect(Rect2(pos, Vector2(bar_w, bar_h)), Color(0.12, 0.12, 0.12))
	draw_rect(Rect2(pos, Vector2(bar_w * ratio, bar_h)), p["color"])
	draw_rect(Rect2(pos, Vector2(bar_w, bar_h)), Color.WHITE, false, 1.5)
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(bar_w + 10, 17), "에너지 %.0f / %.0f" % [energy, HexWorld.MAX_ENERGY], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

func _draw_timer() -> void:
	var remaining := world.time_remaining()
	var minutes := int(remaining) / 60
	var seconds := int(remaining) % 60
	var text := "%d:%02d" % [minutes, seconds]
	var font := ThemeDB.fallback_font
	var vp := get_viewport_rect().size
	var color := Color.WHITE if remaining > 30.0 else Color("e55934")
	draw_string(font, Vector2(vp.x / 2.0 - 40, 38), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 28, color)

func _draw_leaderboard() -> void:
	var board := world.leaderboard()
	var font := ThemeDB.fallback_font
	var vp := get_viewport_rect().size
	var x := vp.x - 200.0
	var y := 20.0
	draw_rect(Rect2(Vector2(x - 10, y - 5), Vector2(195, 24.0 + 22.0 * board.size())), Color(0, 0, 0, 0.4), true, -1.0)
	draw_string(font, Vector2(x, y + 14), "영토 순위", HORIZONTAL_ALIGNMENT_LEFT, 160, 14, Color(1, 1, 1, 0.7))
	y += 24.0
	for i in board.size():
		var entry: Dictionary = board[i]
		var label := "P%d" % (int(entry["id"]) + 1)
		if int(entry["id"]) == local_player:
			label += " (나)"
		var color: Color = entry["color"]
		draw_rect(Rect2(Vector2(x, y + 2), Vector2(14, 14)), color)
		draw_string(font, Vector2(x + 20, y + 14), "%s  %d칸" % [label, entry["territory"]], HORIZONTAL_ALIGNMENT_LEFT, 160, 14, Color.WHITE)
		y += 22.0

func _draw_help() -> void:
	var font := ThemeDB.fallback_font
	var vp := get_viewport_rect().size
	draw_string(font, Vector2(20, vp.y - 16), "좌클릭: 점령/요새화  |  내 영토 옆만 가능", HORIZONTAL_ALIGNMENT_LEFT, 400, 12, Color(1, 1, 1, 0.4))

func _draw_result() -> void:
	var vp := get_viewport_rect().size
	var cx := vp.x / 2.0
	var cy := vp.y / 2.0
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.65))
	var font := ThemeDB.fallback_font
	var win_text: String
	var win_color: Color
	if world.winner == local_player:
		win_text = "승리!"
		win_color = Color("d4a843")
	else:
		win_text = "P%d 승리" % (world.winner + 1)
		win_color = world.players[world.winner]["color"] if world.winner >= 0 else Color.WHITE
	draw_string(font, Vector2(cx - 80, cy - 20), win_text, HORIZONTAL_ALIGNMENT_CENTER, 160, 42, win_color)
	var board := world.leaderboard()
	var y := cy + 20.0
	for entry in board:
		var me := " ← 나" if int(entry["id"]) == local_player else ""
		var label := "P%d: %d칸%s" % [int(entry["id"]) + 1, entry["territory"], me]
		draw_string(font, Vector2(cx - 80, y), label, HORIZONTAL_ALIGNMENT_CENTER, 160, 16, entry["color"])
		y += 24.0
	y += 16.0
	var pulse := absf(sin(float(Time.get_ticks_msec()) * 0.003))
	draw_string(font, Vector2(cx - 80, y), "클릭하여 다시 시작", HORIZONTAL_ALIGNMENT_CENTER, 160, 18, Color(1, 1, 1, 0.4 + pulse * 0.6))
