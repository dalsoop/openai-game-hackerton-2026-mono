class_name SettingsPopup
extends RefCounted

static func build(close_callback: Callable, quit_callback: Callable, control_mode: String, sound_on: bool, on_mode_changed: Callable, on_sound_changed: Callable) -> Dictionary:
	var root := UiTheme.full(Control.new())
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.28)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			close_callback.call()
	)
	root.add_child(dim)
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -270
	panel.offset_right = 270
	panel.offset_top = -165
	panel.offset_bottom = 165
	panel.add_theme_stylebox_override("panel", UiTheme.card_box())
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	col.add_theme_constant_override("separation", 12)
	col.add_child(UiTheme.lbl("설정", 24, UiTheme.INK))
	col.add_child(UiTheme.lbl("조작 방식", 15, UiTheme.INK))
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	var mode_group := ButtonGroup.new()
	var mode_buttons: Dictionary = {}
	for mode in SettingsStore.MODES:
		var chip := UiTheme.chip(SettingsStore.mode_title(mode), mode_group)
		var mode_id := str(mode)
		chip.pressed.connect(func(): on_mode_changed.call(mode_id))
		mode_buttons[mode_id] = chip
		mode_row.add_child(chip)
	col.add_child(mode_row)
	var mode_desc := UiTheme.lbl("", 13, UiTheme.MUTED)
	mode_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(mode_desc)
	col.add_child(UiTheme.lbl("소리", 15, UiTheme.INK))
	var sound_check := CheckButton.new()
	sound_check.text = "효과음 켜기"
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		sound_check.add_theme_color_override(state, UiTheme.INK)
	sound_check.button_pressed = sound_on
	sound_check.toggled.connect(func(on): on_sound_changed.call(on))
	col.add_child(sound_check)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	var back := UiTheme.btn("닫기", UiTheme.BTN_DARK, Vector2(160, 44))
	back.pressed.connect(close_callback)
	var intro := UiTheme.btn("로비로 나가기", UiTheme.BTN_MUTED, Vector2(160, 44))
	intro.pressed.connect(quit_callback)
	actions.add_child(back)
	actions.add_child(intro)
	col.add_child(actions)
	panel.add_child(col)
	root.add_child(panel)

	# Sync initial state
	for m in mode_buttons.keys():
		var b: Button = mode_buttons[m]
		b.set_pressed_no_signal(m == control_mode)
	mode_desc.text = SettingsStore.mode_desc(control_mode)

	return {"root": root, "mode_buttons": mode_buttons, "mode_desc": mode_desc, "sound_check": sound_check}
