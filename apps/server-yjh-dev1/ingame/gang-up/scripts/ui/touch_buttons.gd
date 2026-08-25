class_name TouchButtons
extends RefCounted

static func make_button(text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.visible = false
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, 0.92)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

static func build(hud_node: Node, on_exit: Callable, on_rematch: Callable) -> Dictionary:
	var layer := CanvasLayer.new()
	layer.name = "TouchMenu"
	layer.layer = 3
	hud_node.add_child(layer)
	var exit_btn := make_button(tr("TOUCH_EXIT"), UiTheme.BTN_DARK)
	exit_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	exit_btn.offset_left = -120
	exit_btn.offset_right = -16
	exit_btn.offset_top = 14
	exit_btn.offset_bottom = 58
	exit_btn.pressed.connect(on_exit)
	layer.add_child(exit_btn)
	var rematch_btn := make_button(tr("TOUCH_REMATCH"), UiTheme.BLUE)
	rematch_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	rematch_btn.offset_left = -110
	rematch_btn.offset_right = 110
	rematch_btn.offset_top = -160
	rematch_btn.offset_bottom = -104
	rematch_btn.pressed.connect(on_rematch)
	layer.add_child(rematch_btn)
	return {"exit": exit_btn, "rematch": rematch_btn}

static func sync(exit_btn: Button, rematch_btn: Button, touch, phase: StringName, world, net_active: bool) -> void:
	if exit_btn == null:
		return
	var playing: bool = phase == &"play"
	var touch_on: bool = touch != null and touch.has_method("is_enabled") and bool(touch.is_enabled())
	var finished: bool = world != null and world.get("result") != null and world.result != &"playing"
	exit_btn.visible = playing and (touch_on or finished)
	exit_btn.text = tr("TOUCH_TO_LOBBY") if finished else tr("TOUCH_EXIT")
	rematch_btn.visible = playing and finished and not net_active
	if touch != null and touch.has_method("set_playing"):
		touch.set_playing(playing and not finished)
