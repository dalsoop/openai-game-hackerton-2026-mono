extends Control

const PANEL_BG := Color(0.08, 0.06, 0.12, 0.75)
const TEXT_COLOR := Color.WHITE
const ACCENT := Color("#ffd166")
const DEAD_BG := Color(0.05, 0.03, 0.08, 0.88)

var world
var _score_label: Label
var _length_label: Label
var _leaderboard: VBoxContainer
var _death_panel: Panel
var _death_score: Label
var _restart_btn: Button
var _name_edit: LineEdit
var _intro_panel: Panel
var _start_btn: Button

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_hud()
	_build_death_screen()
	_build_intro()
	_show_intro()

func _process(_delta: float) -> void:
	if world == null:
		return
	var ps: Dictionary = world.player_snake()
	if ps.is_empty():
		return
	_score_label.text = "SCORE: %d" % int(ps["score"])
	_length_label.text = "LENGTH: %d" % ps["segments"].size()
	_update_leaderboard()
	_death_panel.visible = not bool(ps["alive"])
	if _death_panel.visible:
		_death_score.text = "Score: %d  |  Length: %d" % [int(ps["score"]), ps["segments"].size()]

func _build_hud() -> void:
	var hud := VBoxContainer.new()
	hud.set_anchors_preset(PRESET_TOP_LEFT)
	hud.offset_left = 16
	hud.offset_top = 16
	hud.mouse_filter = MOUSE_FILTER_IGNORE
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.add_theme_color_override("font_color", ACCENT)
	hud.add_child(_score_label)
	_length_label = Label.new()
	_length_label.add_theme_font_size_override("font_size", 16)
	_length_label.add_theme_color_override("font_color", TEXT_COLOR)
	hud.add_child(_length_label)
	add_child(hud)
	var lb_panel := Panel.new()
	lb_panel.set_anchors_preset(PRESET_TOP_RIGHT)
	lb_panel.offset_left = -200
	lb_panel.offset_right = -12
	lb_panel.offset_top = 12
	lb_panel.offset_bottom = 180
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	lb_panel.add_theme_stylebox_override("panel", sb)
	lb_panel.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(lb_panel)
	var lb_title := Label.new()
	lb_title.text = "LEADERBOARD"
	lb_title.add_theme_font_size_override("font_size", 14)
	lb_title.add_theme_color_override("font_color", ACCENT)
	lb_title.set_anchors_preset(PRESET_TOP_WIDE)
	lb_title.offset_left = 10
	lb_title.offset_top = 8
	lb_panel.add_child(lb_title)
	_leaderboard = VBoxContainer.new()
	_leaderboard.set_anchors_preset(PRESET_FULL_RECT)
	_leaderboard.offset_left = 10
	_leaderboard.offset_top = 28
	_leaderboard.offset_right = -10
	_leaderboard.mouse_filter = MOUSE_FILTER_IGNORE
	lb_panel.add_child(_leaderboard)

func _build_death_screen() -> void:
	_death_panel = Panel.new()
	_death_panel.set_anchors_preset(PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DEAD_BG
	_death_panel.add_theme_stylebox_override("panel", sb)
	_death_panel.visible = false
	add_child(_death_panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_CENTER)
	vbox.offset_left = -150
	vbox.offset_right = 150
	vbox.offset_top = -60
	vbox.offset_bottom = 60
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_death_panel.add_child(vbox)
	var title := Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#ff6b6b"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	_death_score = Label.new()
	_death_score.add_theme_font_size_override("font_size", 18)
	_death_score.add_theme_color_override("font_color", TEXT_COLOR)
	_death_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_death_score)
	_restart_btn = Button.new()
	_restart_btn.text = "다시 시작"
	_restart_btn.custom_minimum_size = Vector2(200, 50)
	_restart_btn.add_theme_font_size_override("font_size", 20)
	_restart_btn.pressed.connect(_on_restart)
	vbox.add_child(_restart_btn)

func _build_intro() -> void:
	_intro_panel = Panel.new()
	_intro_panel.set_anchors_preset(PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.04, 0.1, 0.95)
	_intro_panel.add_theme_stylebox_override("panel", sb)
	add_child(_intro_panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_CENTER)
	vbox.offset_left = -180
	vbox.offset_right = 180
	vbox.offset_top = -100
	vbox.offset_bottom = 100
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	_intro_panel.add_child(vbox)
	var title := Label.new()
	title.text = "SNAKE ARENA"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#5bc0eb"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = "먹고 키우고 살아남아라"
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color("#aaaaaa"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "닉네임"
	_name_edit.custom_minimum_size = Vector2(0, 44)
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.add_theme_font_size_override("font_size", 18)
	_name_edit.text = "Player"
	vbox.add_child(_name_edit)
	_start_btn = Button.new()
	_start_btn.text = "시작하기"
	_start_btn.custom_minimum_size = Vector2(200, 54)
	_start_btn.add_theme_font_size_override("font_size", 22)
	_start_btn.pressed.connect(_on_start)
	vbox.add_child(_start_btn)

func _show_intro() -> void:
	_intro_panel.visible = true
	_death_panel.visible = false

func _on_start() -> void:
	_intro_panel.visible = false
	if world != null:
		var ps: Dictionary = world.player_snake()
		if not ps.is_empty():
			ps["name"] = _name_edit.text.strip_edges() if _name_edit.text.strip_edges() != "" else "Player"

func _on_restart() -> void:
	if world != null:
		world._respawn_snake(0)
		var ps: Dictionary = world.player_snake()
		if not ps.is_empty():
			ps["name"] = _name_edit.text.strip_edges() if _name_edit.text.strip_edges() != "" else "Player"

func _update_leaderboard() -> void:
	if world == null:
		return
	var lb = world.leaderboard(5)
	for child in _leaderboard.get_children():
		child.queue_free()
	for i in lb.size():
		var entry: Dictionary = lb[i]
		var lbl := Label.new()
		lbl.text = "%d. %s  %d" % [i + 1, str(entry["name"]), int(entry["score"])]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", TEXT_COLOR)
		lbl.mouse_filter = MOUSE_FILTER_IGNORE
		_leaderboard.add_child(lbl)
