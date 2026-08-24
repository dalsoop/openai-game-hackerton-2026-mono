class_name HowToPlayPopup
extends RefCounted

static func build(close_callback: Callable) -> Control:
	var root := UiTheme.full(Control.new())
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -460
	panel.offset_right = 460
	panel.offset_top = -280
	panel.offset_bottom = 280
	panel.add_theme_stylebox_override("panel", UiTheme.card_box())
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	col.add_theme_constant_override("separation", 10)
	col.add_child(UiTheme.lbl(tr("HOW_BREADCRUMB"), 14, UiTheme.MUTED))
	col.add_child(UiTheme.lbl(tr("HOW_TITLE"), 28, UiTheme.INK))
	for line in [
		tr("HOW_LINE1"),
		tr("HOW_LINE2"),
		tr("HOW_LINE3"),
		tr("HOW_LINE4"),
		"SHIFT / dash button flash  ·  SPACE hop  ·  Q / ult button  ·  E / item button",
		tr("HOW_LINE5"),
	]:
		col.add_child(UiTheme.lbl(line, 18, UiTheme.MUTED))
	var back := UiTheme.btn(tr("HOW_BACK"), Color("3D4654"), Vector2(140, 48))
	back.pressed.connect(close_callback)
	col.add_child(back)
	panel.add_child(col)
	root.add_child(panel)
	return root
