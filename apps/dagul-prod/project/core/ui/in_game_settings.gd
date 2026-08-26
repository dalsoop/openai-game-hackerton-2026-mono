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
var _panel: Panel
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
	_gear = Ui.flat_icon_btn(Ui.gear_texture(40), Vector2(40, 40))
	_gear.tooltip_text = "설정"
	_gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# 미니맵 중심 x=1486 위에 맞춤 (1600 뷰포트).
	_gear.offset_left = -134
	_gear.offset_right = -94
	_gear.offset_top = 10
	_gear.offset_bottom = 50
	_gear.pressed.connect(func() -> void: set_open(not is_open))
	add_child(_gear)


func _build_dimmer() -> void:
	_dimmer = ColorRect.new()
	_dimmer.color = Color(0, 0, 0, 0.28)
	Ui.full(_dimmer)
	_dimmer.visible = false
	_dimmer.gui_input.connect(_on_dimmer)
	add_child(_dimmer)


func _build_panel() -> void:
	_panel = Panel.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -270
	_panel.offset_right = 270
	_panel.offset_top = -210
	_panel.offset_bottom = 210
	_panel.add_theme_stylebox_override("panel", Ui.card_box())
	add_child(_panel)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	col.add_theme_constant_override("separation", 12)
	_panel.add_child(col)
	col.add_child(Ui.lbl("설정", 24, Ui.INK))
	col.add_child(Ui.lbl("조작 방식", 15, Ui.INK))
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
	col.add_child(Ui.lbl("소리", 15, Ui.INK))
	var sound_check := CheckButton.new()
	sound_check.text = "효과음 켜기"
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		sound_check.add_theme_color_override(state, Ui.INK)
	sound_check.button_pressed = Store.load_sound_on()
	sound_check.toggled.connect(func(on: bool) -> void: sound_changed.emit(on))
	col.add_child(sound_check)
	col.add_child(Ui.lbl("조작 안내", 15, Ui.INK))
	_onboard_check = CheckButton.new()
	_onboard_check.text = "매치 시작 시 다시 보기"
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		_onboard_check.add_theme_color_override(state, Ui.INK)
	_onboard_check.toggled.connect(_on_onboard_toggled)
	col.add_child(_onboard_check)
	var show_btn := Ui.btn("지금 보기", Ui.BTN_MUTED, Vector2(160, 44))
	show_btn.pressed.connect(_on_show_onboarding)
	col.add_child(show_btn)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	var back := Ui.btn("닫기", Ui.BTN_DARK, Vector2(160, 44))
	back.pressed.connect(func() -> void: set_open(false))
	var leave := Ui.btn("로비로 나가기", Ui.BTN_MUTED, Vector2(160, 44))
	leave.pressed.connect(func() -> void: leave_requested.emit())
	actions.add_child(back)
	actions.add_child(leave)
	col.add_child(actions)


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
