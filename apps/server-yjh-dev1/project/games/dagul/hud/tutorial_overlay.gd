class_name TutorialOverlay
extends Control

const LayoutKeysScript := preload("res://core/input/layout_keys.gd")

signal tutorial_finished

const STEPS := [
	{"key": "move", "text": "WASD로 이동해 보세요", "sub": "W 위 · A 왼 · S 아래 · D 오른"},
	{"key": "fire", "text": "마우스로 조준하고 좌클릭으로 공격!", "sub": "적에게 데미지를 줍니다"},
	{"key": "dash", "text": "Shift를 눌러 대시하세요", "sub": "짧은 거리를 빠르게 이동합니다"},
	{"key": "skill", "text": "우클릭을 꾹 눌러 장비 스킬!", "sub": "캐릭터마다 고유 스킬이 있습니다"},
	{"key": "done", "text": "준비 완료!", "sub": "최후의 1인이 되세요"},
]

const HINTS := {
	"hit": "피격! Shift로 대시해서 벗어나세요",
	"down": "다운! WASD로 기어가세요. 곧 부활합니다",
	"outside_zone": "세이프존 밖! 안쪽으로 이동하세요",
	"ultimate_ready": "궁극기 준비! Q를 누르세요",
}

var _step: int = 0
var _active: bool = false
var _done_time: float = 0.0
var _skip_btn: Button
var _label: Label
var _sub_label: Label
var _panel: Panel
var _hints_shown: Dictionary = {}
var _hint_text: String = ""
var _hint_time: float = 0.0

static func is_first_play() -> bool:
	if OS.has_feature("web"):
		var val = JavaScriptBridge.eval("try{localStorage.getItem('dagul_tutorial_done')||''}catch(e){''}", true)
		return str(val).strip_edges() == "" or str(val) == "null" or str(val) == "<null>"
	return not FileAccess.file_exists("user://tutorial_done.txt")

static func mark_done() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try{localStorage.setItem('dagul_tutorial_done','1')}catch(e){}")
		return
	var f := FileAccess.open("user://tutorial_done.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("1")

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_ui()
	visible = false

func start_tutorial() -> void:
	_step = 0
	_active = true
	_done_time = 0.0
	visible = true
	_update_display()

func _build_ui() -> void:
	_build_ui_panel()
	_build_ui_labels()
	_build_ui_skip_button()

func _build_ui_panel() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_panel.offset_top = -120
	_panel.offset_left = 200
	_panel.offset_right = -200
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.02, 0.88)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

func _build_ui_labels() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	_label.offset_top = 20
	_label.offset_left = -200
	_label.offset_right = 200
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(_label)

	_sub_label = Label.new()
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	_sub_label.offset_top = 56
	_sub_label.offset_left = -200
	_sub_label.offset_right = 200
	_sub_label.add_theme_font_size_override("font_size", 15)
	_sub_label.add_theme_color_override("font_color", UiTheme.MUTED)
	_panel.add_child(_sub_label)

func _build_ui_skip_button() -> void:
	_skip_btn = Button.new()
	_skip_btn.text = "건너뛰기"
	_skip_btn.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	_skip_btn.offset_left = -100
	_skip_btn.offset_top = -40
	_skip_btn.offset_right = -10
	_skip_btn.offset_bottom = -10
	_skip_btn.add_theme_font_size_override("font_size", 13)
	_skip_btn.pressed.connect(_on_skip)
	_panel.add_child(_skip_btn)

func _update_display() -> void:
	if _step >= STEPS.size():
		return
	var step_data: Dictionary = STEPS[_step]
	_label.text = step_data["text"]
	_sub_label.text = step_data["sub"]
	if step_data["key"] == "done":
		_skip_btn.visible = false
	else:
		_skip_btn.visible = true

func _process(delta: float) -> void:
	if not _active:
		_tick_hints(delta)
		return
	if _step >= STEPS.size():
		return
	var step_key: String = STEPS[_step]["key"]
	var advance := false
	match step_key:
		"move":
			advance = LayoutKeysScript.held(KEY_W) or LayoutKeysScript.held(KEY_A) or LayoutKeysScript.held(KEY_S) or LayoutKeysScript.held(KEY_D)
		"fire":
			advance = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		"dash":
			advance = LayoutKeysScript.held(KEY_SHIFT)
		"skill":
			advance = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		"done":
			_tick_done_step(delta)
			return
	if advance:
		_step += 1
		if _step < STEPS.size():
			_update_display()
		else:
			_finish()

func _tick_done_step(delta: float) -> void:
	_done_time += delta
	if _done_time >= 3.0:
		_finish()

func _on_skip() -> void:
	_finish()

func _finish() -> void:
	_active = false
	visible = false
	mark_done()
	tutorial_finished.emit()

func show_hint(hint_id: String) -> void:
	if _hints_shown.has(hint_id):
		return
	if not HINTS.has(hint_id):
		return
	_hints_shown[hint_id] = true
	_hint_text = HINTS[hint_id]
	_hint_time = 4.0

func _tick_hints(delta: float) -> void:
	if _hint_time > 0.0:
		_hint_time -= delta
	queue_redraw()

func _draw() -> void:
	if _hint_time <= 0.0 or _hint_text == "":
		return
	var alpha := clampf(_hint_time, 0.0, 1.0)
	var cx := size.x * 0.5
	var w := 400.0
	draw_rect(Rect2(cx - w * 0.5, 16, w, 36), Color(0.0, 0.0, 0.0, 0.7 * alpha))
	var font = get_theme_default_font()
	if font != null:
		draw_string(font, Vector2(cx - w * 0.5 + 12, 40), _hint_text, HORIZONTAL_ALIGNMENT_CENTER, w - 24, 15, Color(1.0, 1.0, 1.0, alpha))
