class_name TutorialOverlay
extends Control

const LayoutKeysScript := preload("res://core/input/layout_keys.gd")
const Store := preload("res://core/ui/settings_store.gd")
const Ui := preload("res://core/ui/ui_theme.gd")

signal tutorial_finished

const HINTS := {
	"hit": "피격! Shift로 대시해서 벗어나세요",
	"down": "다운! WASD로 기어가세요. 곧 부활합니다",
	"outside_zone": "세이프존 밖! 안쪽으로 이동하세요",
	"ultimate_ready": "궁극기 준비! Q를 누르세요",
}

var _active: bool = false
var _dimmer: ColorRect
var _panel: PanelContainer
var _body: Label
var _hide_check: CheckButton
var _hints_shown: Dictionary = {}
var _hint_text: String = ""
var _hint_time: float = 0.0

func should_show() -> bool:
	return not Store.load_onboarding_hide()

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_ui()
	visible = false

func start_tutorial() -> void:
	_active = true
	visible = true
	mouse_filter = MOUSE_FILTER_STOP
	if _hide_check != null:
		_hide_check.button_pressed = false
	_refresh_body()
	if _dimmer != null:
		_dimmer.visible = true
	if _panel != null:
		_panel.visible = true

func _build_ui() -> void:
	_dimmer = ColorRect.new()
	_dimmer.color = Color(0, 0, 0, 0.55)
	Ui.full(_dimmer)
	_dimmer.gui_input.connect(_on_dimmer)
	add_child(_dimmer)
	var center := CenterContainer.new()
	Ui.full(center)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(440, 0)
	_panel.add_theme_stylebox_override("panel", Ui.card_box())
	center.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_panel.add_child(col)
	col.add_child(Ui.lbl("조작 안내", 22, Ui.INK, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(Ui.lbl("한 판을 시작하기 전에 조작을 확인하세요", 14, Ui.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_body = Ui.lbl("", 16, Ui.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_body)
	_hide_check = CheckButton.new()
	_hide_check.text = "다시 보지 않기"
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		_hide_check.add_theme_color_override(state, Ui.INK)
	col.add_child(_hide_check)
	var ok := Ui.btn("확인", Ui.BLUE, Vector2(0, 48))
	ok.pressed.connect(_on_confirm)
	col.add_child(ok)

func _refresh_body() -> void:
	if _body == null:
		return
	var w := LayoutKeysScript.seat_label(KEY_W)
	var a := LayoutKeysScript.seat_label(KEY_A)
	var s := LayoutKeysScript.seat_label(KEY_S)
	var d := LayoutKeysScript.seat_label(KEY_D)
	var shift := LayoutKeysScript.seat_label(KEY_SHIFT)
	var q := LayoutKeysScript.seat_label(KEY_Q)
	_body.text = "\n".join([
		"%s%s%s%s  이동" % [w, a, s, d],
		"마우스  조준",
		"좌클릭  공격",
		"우클릭(홀드)  장비 스킬",
		"%s  대시" % shift,
		"%s  궁극기" % q,
	])

func _on_dimmer(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close(_hide_check != null and _hide_check.button_pressed)

func _on_confirm() -> void:
	_close(_hide_check != null and _hide_check.button_pressed)

func _close(persist_hide: bool) -> void:
	if persist_hide:
		Store.save_onboarding_hide(true)
	_active = false
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	if _dimmer != null:
		_dimmer.visible = false
	if _panel != null:
		_panel.visible = false
	tutorial_finished.emit()

func show_hint(hint_id: String) -> void:
	if _hints_shown.has(hint_id):
		return
	if not HINTS.has(hint_id):
		return
	_hints_shown[hint_id] = true
	if hint_id == "down":
		_hint_text = "다운! %s%s%s%s 자리로 기어가세요. 곧 부활합니다" % [
			LayoutKeysScript.seat_label(KEY_W), LayoutKeysScript.seat_label(KEY_A),
			LayoutKeysScript.seat_label(KEY_S), LayoutKeysScript.seat_label(KEY_D),
		]
	elif hint_id == "ultimate_ready":
		_hint_text = "궁극기 준비! %s를 누르세요" % LayoutKeysScript.seat_label(KEY_Q)
	else:
		_hint_text = HINTS[hint_id]
	_hint_time = 4.0

func _process(delta: float) -> void:
	if _active:
		return
	if _hint_time > 0.0:
		_hint_time -= delta
	queue_redraw()

func _draw() -> void:
	if _active or _hint_time <= 0.0 or _hint_text == "":
		return
	var alpha := clampf(_hint_time, 0.0, 1.0)
	var cx := size.x * 0.5
	var w := 400.0
	draw_rect(Rect2(cx - w * 0.5, 16, w, 36), Color(0.0, 0.0, 0.0, 0.7 * alpha))
	var font = get_theme_default_font()
	if font != null:
		draw_string(font, Vector2(cx - w * 0.5 + 12, 40), _hint_text, HORIZONTAL_ALIGNMENT_CENTER, w - 24, 15, Color(1.0, 1.0, 1.0, alpha))
