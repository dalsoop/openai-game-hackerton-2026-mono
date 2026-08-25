class_name UiTheme
extends RefCounted

const BG := Color("F5F2EA")
const INK := Color("1C2430")
const MUTED := Color("6B7380")
const CARD := Color("FFFDF8")
const LINE := Color("E4DDD2")
const BLUE := Color("2F6BFF")
const GREEN := Color("1F9D55")
const ERROR := Color("C0392B")
const WARN := Color("C47B17")
const BANNER_TEXT := Color("FFF6E5")
const BTN_DARK := Color("3D4654")
const BTN_MUTED := Color("8A93A3")
const INTRO_BG := Color("0b0e14")
const INTRO_TITLE := Color("ffd23e")
const INTRO_SUB := Color("67728a")
const SLOT_COUNT := 8
const SLOT_COLORS := [
	Color("5bc0eb"), Color("9bc53d"), Color("e55934"), Color("fa7921"),
	Color("b084cc"), Color("70e7ff"), Color("ffd166"), Color("ff8dac")
]

static func full(node: Control) -> Control:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return node

static func lbl(text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func btn(text: String, bg: Color, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = bg.lightened(0.08)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	return b

static func chip(text: String, group: ButtonGroup) -> Button:
	var c := Button.new()
	c.toggle_mode = true
	c.button_group = group
	c.text = text
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size = Vector2(0, 46)
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		c.add_theme_color_override(state, INK)
	var chip_off := card_box()
	c.add_theme_stylebox_override("normal", chip_off)
	var chip_on := chip_off.duplicate()
	chip_on.border_color = BLUE
	chip_on.border_width_left = 3
	chip_on.border_width_top = 3
	chip_on.border_width_right = 3
	chip_on.border_width_bottom = 3
	c.add_theme_stylebox_override("pressed", chip_on)
	c.add_theme_stylebox_override("hover", chip_on)
	c.add_theme_stylebox_override("hover_pressed", chip_on)
	c.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return c

static func icon_btn(caption: String) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(72, 52)
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD
	sb.border_color = LINE
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", INK)
	return b

static func card_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD
	sb.border_color = LINE
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18
	sb.corner_radius_bottom_right = 18
	return sb
