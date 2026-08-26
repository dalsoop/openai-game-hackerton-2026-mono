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
	col.add_child(UiTheme.lbl("도움말", 28, UiTheme.INK))
	for line in [
		"WASD  이동   ·   마우스  조준",
		"좌클릭  기본 공격   ·   우클릭  장비 스킬",
		"SHIFT  대시   ·   SPACE  점프   ·   Q  궁극기   ·   E  아이템",
		"터치: 왼쪽 스틱 이동  ·  오른쪽 스틱 조준  ·  버튼 공격",
		"최후의 1인이 승리합니다. 안전 구역은 시간이 지나면 줄어듭니다.",
	]:
		col.add_child(UiTheme.lbl(line, 18, UiTheme.MUTED))
	var back := UiTheme.btn("뒤로", UiTheme.BTN_DARK, Vector2(140, 48))
	back.pressed.connect(close_callback)
	col.add_child(back)
	panel.add_child(col)
	root.add_child(panel)
	return root
