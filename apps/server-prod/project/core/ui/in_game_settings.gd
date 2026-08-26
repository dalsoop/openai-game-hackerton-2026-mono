class_name InGameSettings
extends CanvasLayer
## 매치 중 설정. 조작 모드·효과음·온보딩·나가기를 다룬다. 허브 소켓은 모른다.

const Store := preload("res://core/ui/settings_store.gd")
const Ui := preload("res://core/ui/ui_theme.gd")

signal open_changed(open: bool)
signal mode_picked(mode: String)
signal sound_changed(on: bool)
signal onboarding_requested
signal leave_requested

var is_open := false

var _playing := false
var _gear: Button
var _dimmer: ColorRect
var _panel: PanelContainer
var _desc: Label
var _group: ButtonGroup
var _mode_btns: Dictionary = {}
var _onboard_check: CheckButton
var _onboard_guard := false


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	set_playing(false)


func set_playing(playing: bool) -> void:
	_playing = playing
	if _gear != null:
		_gear.visible = playing
	if not playing:
		set_open(false)


func set_open(open: bool) -> void:
	if is_open == open:
		return
	is_open = open
	if _dimmer != null:
		_dimmer.visible = open
	if _panel != null:
		_panel.visible = open
	if open:
		_sync_onboard_check()
	open_changed.emit(open)


func select_mode(mode: String) -> void:
	var normalized := Store.normalize_mode(mode)
	var btn: Button = _mode_btns.get(normalized)
	if btn != null:
		btn.button_pressed = true
	_refresh_desc(normalized)


func _unhandled_input(event: InputEvent) -> void:
	if not _playing:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_ESCAPE:
		set_open(not is_open)
		get_viewport().set_input_as_handled()


func _build() -> void:
	_build_gear()
	_build_dimmer()
	_build_panel()


func _build_gear() -> void:
	_gear = Ui.btn("설정", Ui.BTN_DARK, Vector2(88, 44))
	_gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gear.offset_left = -112
	_gear.offset_right = -16
	_gear.offset_top = 14
	_gear.offset_bottom = 58
	_gear.pressed.connect(func() -> void: set_open(not is_open))
	add_child(_gear)


func _build_dimmer() -> void:
	_dimmer = ColorRect.new()
	_dimmer.color = Color(0, 0, 0, 0.55)
	Ui.full(_dimmer)
	_dimmer.visible = false
	_dimmer.gui_input.connect(_on_dimmer)
	add_child(_dimmer)


func _build_panel() -> void:
	var center := CenterContainer.new()
	Ui.full(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.custom_minimum_size = Vector2(420, 0)
	_panel.add_theme_stylebox_override("panel", Ui.card_box())
	center.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_panel.add_child(col)
	col.add_child(Ui.lbl("설정", 22, Ui.INK, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(Ui.lbl("조작 방식", 14, Ui.MUTED))
	_fill_mode_row(col)
	_desc = Ui.lbl("", 13, Ui.MUTED)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_desc)
	_fill_sound_and_leave(col)


func _fill_mode_row(col: VBoxContainer) -> void:
	_group = ButtonGroup.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	for mode in Store.MODES:
		var chip := Ui.chip(Store.mode_title(mode), _group)
		chip.pressed.connect(_on_mode_pressed.bind(mode))
		_mode_btns[mode] = chip
		row.add_child(chip)


func _fill_sound_and_leave(col: VBoxContainer) -> void:
	col.add_child(Ui.lbl("소리", 14, Ui.MUTED))
	var sound_check := CheckButton.new()
	sound_check.text = "효과음 켜기"
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		sound_check.add_theme_color_override(state, Ui.INK)
	sound_check.button_pressed = Store.load_sound_on()
	sound_check.toggled.connect(func(on: bool) -> void: sound_changed.emit(on))
	col.add_child(sound_check)
	col.add_child(Ui.lbl("조작 안내", 14, Ui.MUTED))
	_onboard_check = CheckButton.new()
	_onboard_check.text = "매치 시작 시 다시 보기"
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		_onboard_check.add_theme_color_override(state, Ui.INK)
	_onboard_check.toggled.connect(_on_onboard_toggled)
	col.add_child(_onboard_check)
	var show_btn := Ui.btn("지금 보기", Ui.BTN_MUTED, Vector2(0, 44))
	show_btn.pressed.connect(_on_show_onboarding)
	col.add_child(show_btn)
	var leave_btn := Ui.btn("나가기", Ui.ERROR, Vector2(0, 48))
	leave_btn.pressed.connect(func() -> void: leave_requested.emit())
	col.add_child(leave_btn)
	var keep_btn := Ui.btn("계속하기", Ui.BTN_MUTED, Vector2(0, 44))
	keep_btn.pressed.connect(func() -> void: set_open(false))
	col.add_child(keep_btn)


func _on_dimmer(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		set_open(false)


func _sync_onboard_check() -> void:
	if _onboard_check == null:
		return
	_onboard_guard = true
	_onboard_check.button_pressed = not Store.load_onboarding_hide()
	_onboard_guard = false


func _on_onboard_toggled(on: bool) -> void:
	if _onboard_guard:
		return
	Store.save_onboarding_hide(not on)
	if on:
		_on_show_onboarding()


func _on_show_onboarding() -> void:
	set_open(false)
	onboarding_requested.emit()


func _on_mode_pressed(mode: String) -> void:
	var normalized := Store.normalize_mode(mode)
	_refresh_desc(normalized)
	mode_picked.emit(normalized)


func _refresh_desc(mode: String) -> void:
	if _desc != null:
		_desc.text = Store.mode_desc(mode)
