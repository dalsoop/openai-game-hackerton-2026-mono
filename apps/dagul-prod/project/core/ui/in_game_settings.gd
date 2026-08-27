class_name InGameSettings
extends CanvasLayer
## 매치 중 설정. 조작 모드·효과음·나가기를 다룬다. 허브 소켓은 모른다.

const Store := preload("res://core/ui/settings_store.gd")
const Ui := preload("res://core/ui/ui_theme.gd")

signal open_changed(open: bool)
signal mode_picked(mode: String)
signal sound_changed(on: bool)
signal leave_requested

var is_open := false

var _playing := false
var _gear: Button
var _dimmer: ColorRect
var _panel: Panel
var _desc: Label
var _group: ButtonGroup
var _mode_btns: Dictionary = {}


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
	_gear.tooltip_text = HudStrings.t("settings_title")
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
	_panel.offset_top = -150
	_panel.offset_bottom = 150
	_panel.add_theme_stylebox_override("panel", Ui.card_box())
	add_child(_panel)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	col.add_theme_constant_override("separation", 12)
	_panel.add_child(col)
	col.add_child(Ui.lbl(HudStrings.t("settings_title"), 24, Ui.INK))
	col.add_child(Ui.lbl(HudStrings.t("settings_controls"), 15, Ui.INK))
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
	col.add_child(Ui.lbl(HudStrings.t("settings_sound"), 15, Ui.INK))
	var sound_check := CheckButton.new()
	sound_check.text = HudStrings.t("settings_sound_on")
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		sound_check.add_theme_color_override(state, Ui.INK)
	sound_check.button_pressed = Store.load_sound_on()
	sound_check.toggled.connect(func(on: bool) -> void: sound_changed.emit(on))
	col.add_child(sound_check)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	var back := Ui.btn(HudStrings.t("settings_close"), Ui.BTN_DARK, Vector2(160, 44))
	back.pressed.connect(func() -> void: set_open(false))
	var leave := Ui.btn(HudStrings.t("settings_leave"), Ui.BTN_MUTED, Vector2(160, 44))
	leave.pressed.connect(func() -> void: leave_requested.emit())
	actions.add_child(back)
	actions.add_child(leave)
	col.add_child(actions)


func _on_dimmer(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		set_open(false)


func _on_mode_pressed(mode: String) -> void:
	var normalized := Store.normalize_mode(mode)
	_refresh_desc(normalized)
	mode_picked.emit(normalized)


func _refresh_desc(mode: String) -> void:
	if _desc != null:
		_desc.text = Store.mode_desc(mode)
