class_name RoomBuilder
extends RefCounted

static func build(callbacks: Dictionary) -> Dictionary:
	var root := UiTheme.full(Control.new())
	var header := _build_header(callbacks)
	root.add_child(header["node"])
	var mode_refs := _build_mode_row(callbacks)
	root.add_child(mode_refs["node"])
	var slot_host := _build_slots(callbacks)
	root.add_child(slot_host)
	var center := _build_center()
	root.add_child(center["node"])
	var footer_refs := _build_footer(callbacks)
	root.add_child(footer_refs["node"])
	return {
		"root": root,
		"slot_host": slot_host,
		"count_label": center["count_label"],
		"ready_label": center["ready_label"],
		"wait_mode_label": header["wait_mode_label"],
		"wait_mode_buttons": mode_refs["buttons"],
		"chat_log": footer_refs["chat_log"],
		"start_button": footer_refs["start_button"],
		"start_hint": footer_refs["start_hint"],
	}

static func _build_header(callbacks: Dictionary) -> Dictionary:
	var header := HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 36
	header.offset_right = -36
	header.offset_top = 18
	header.offset_bottom = 92
	var back := UiTheme.icon_btn("뒤로")
	back.pressed.connect(callbacks["on_back"])
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UiTheme.lbl("대기실", 14, UiTheme.MUTED))
	titles.add_child(UiTheme.lbl("멤버를 모으세요", 30, UiTheme.INK))
	var wait_mode_label := UiTheme.lbl("", 15, UiTheme.MUTED)
	titles.add_child(wait_mode_label)
	header.add_child(titles)
	var sound := UiTheme.icon_btn("소리")
	sound.pressed.connect(callbacks["on_sound"])
	var gear := UiTheme.icon_btn("설정")
	gear.pressed.connect(callbacks["on_settings"])
	header.add_child(sound)
	header.add_child(gear)
	return {"node": header, "wait_mode_label": wait_mode_label}

static func _build_mode_row(_callbacks: Dictionary) -> Dictionary:
	var mode_row := Control.new()
	mode_row.visible = false
	return {"node": mode_row, "buttons": [] as Array[Button]}

static func _build_slots(callbacks: Dictionary) -> Control:
	var slot_host := Control.new()
	slot_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_host.offset_top = 96
	slot_host.offset_bottom = -150
	slot_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in UiTheme.SLOT_COUNT:
		slot_host.add_child(_make_slot_card(i, callbacks.get("on_kick", Callable())))
	return slot_host

static func _build_center() -> Dictionary:
	var center_box := VBoxContainer.new()
	center_box.set_anchors_preset(Control.PRESET_CENTER)
	center_box.offset_left = -160
	center_box.offset_right = 160
	center_box.offset_top = -90
	center_box.offset_bottom = 90
	center_box.add_theme_constant_override("separation", 8)
	var count_label := UiTheme.lbl("1 / 8", 22, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var ready_label := UiTheme.lbl("빈 자리는 시작 시 CPU가 채웁니다", 13, UiTheme.GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	var bot := Panel.new()
	bot.custom_minimum_size = Vector2(200, 52)
	bot.add_theme_stylebox_override("panel", UiTheme.card_box())
	var bot_row := HBoxContainer.new()
	bot_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	bot_row.add_child(UiTheme.lbl("CPU  자동 참여", 16, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER))
	bot.add_child(bot_row)
	center_box.add_child(count_label)
	center_box.add_child(ready_label)
	center_box.add_child(bot)
	return {"node": center_box, "count_label": count_label, "ready_label": ready_label}

static func _build_footer(callbacks: Dictionary) -> Dictionary:
	var footer := HBoxContainer.new()
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 28
	footer.offset_right = -28
	footer.offset_top = -138
	footer.offset_bottom = -18
	footer.add_theme_constant_override("separation", 16)
	var chat_refs := _build_chat()
	footer.add_child(chat_refs["root"])
	var start_box := VBoxContainer.new()
	start_box.add_theme_constant_override("separation", 6)
	var start_button := UiTheme.btn("게임 시작", UiTheme.BLUE, Vector2(280, 72))
	start_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(callbacks["on_start"])
	var start_hint := UiTheme.lbl("호스트가 시작하면 출발합니다", 14, UiTheme.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	start_hint.visible = false
	start_box.add_child(start_button)
	start_box.add_child(start_hint)
	footer.add_child(start_box)
	footer.add_child(_build_tip())
	return {"node": footer, "chat_log": chat_refs["chat_log"], "start_button": start_button, "start_hint": start_hint}

static func _build_chat() -> Dictionary:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(360, 110)
	panel.add_theme_stylebox_override("panel", UiTheme.card_box())
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	col.add_child(UiTheme.lbl("채팅", 14, UiTheme.INK))
	var chat_log := RichTextLabel.new()
	chat_log.bbcode_enabled = true
	chat_log.fit_content = true
	chat_log.scroll_active = true
	chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_log.add_theme_color_override("default_color", UiTheme.MUTED)
	col.add_child(chat_log)
	var row := HBoxContainer.new()
	var edit := LineEdit.new()
	edit.placeholder_text = "메시지를 입력하세요..."
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var send := Button.new()
	send.text = "전송"
	row.add_child(edit)
	row.add_child(send)
	col.add_child(row)
	panel.add_child(col)
	return {"root": panel, "chat_log": chat_log, "edit": edit, "send": send}

static func _build_tip() -> Control:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(320, 110)
	panel.add_theme_stylebox_override("panel", UiTheme.card_box())
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	col.add_child(UiTheme.lbl("참고", 14, UiTheme.INK))
	var tip := UiTheme.lbl("안전 구역은 시간이 지날수록 줄어듭니다. 마지막까지 생존하세요!", 14, UiTheme.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(tip)
	panel.add_child(col)
	return panel

static var _animal_atlas: Texture2D = null

static func _animal_portrait(index: int) -> Texture2D:
	if _animal_atlas == null and ResourceLoader.exists("res://assets/lhj/Tex_Animal_4x3.png"):
		_animal_atlas = load("res://assets/lhj/Tex_Animal_4x3.png")
	if _animal_atlas == null:
		return null
	var frame := int(UiTheme.LOBBY_ANIMAL_FRAME[posmod(index, UiTheme.LOBBY_ANIMAL_FRAME.size())])
	var cell := Vector2(float(_animal_atlas.get_width()) / 4.0, float(_animal_atlas.get_height()) / 3.0)
	var atlas := AtlasTexture.new()
	atlas.atlas = _animal_atlas
	atlas.region = Rect2(Vector2(float(frame % 4), float(int(frame / 4))) * cell, cell)
	return atlas

static func _make_slot_card(index: int, on_kick: Callable) -> Panel:
	var card := Panel.new()
	card.name = "Slot%d" % index
	card.custom_minimum_size = Vector2(168, 156)
	card.size = Vector2(168, 156)
	card.add_theme_stylebox_override("panel", UiTheme.card_box())
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	col.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	var badge := _make_slot_badge(index)
	var nick := UiTheme.lbl(UiTheme.NICKS[index], 15, UiTheme.INK)
	nick.name = "Nick"
	row.add_child(badge)
	row.add_child(nick)
	var ready := UiTheme.lbl("준비 완료", 13, UiTheme.GREEN)
	ready.name = "Ready"
	var art := _make_slot_art(index)
	var kick := _make_kick_button(index, on_kick)
	col.add_child(row)
	col.add_child(ready)
	col.add_child(art)
	col.add_child(kick)
	card.add_child(col)
	return card

static func _make_slot_badge(index: int) -> ColorRect:
	var badge := ColorRect.new()
	badge.custom_minimum_size = Vector2(22, 22)
	badge.color = UiTheme.SLOT_COLORS[index]
	var num := UiTheme.lbl(str(index + 1), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	num.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.add_child(num)
	return badge

static func _make_slot_art(index: int) -> Control:
	var portrait := _animal_portrait(index)
	if portrait != null:
		var pic := TextureRect.new()
		pic.texture = portrait
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(88, 88)
		pic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pic.name = "Art"
		return pic
	var art := UiTheme.lbl(UiTheme.ANIMALS[index], 28, UiTheme.SLOT_COLORS[index], HORIZONTAL_ALIGNMENT_CENTER)
	art.name = "Art"
	return art

static func _make_kick_button(index: int, on_kick: Callable) -> Button:
	var kick := Button.new()
	kick.name = "Kick"
	kick.text = "내보내기"
	kick.visible = false
	kick.custom_minimum_size = Vector2(0, 26)
	kick.add_theme_font_size_override("font_size", 12)
	kick.add_theme_color_override("font_color", UiTheme.ERROR)
	kick.add_theme_color_override("font_hover_color", UiTheme.ERROR)
	kick.add_theme_color_override("font_pressed_color", UiTheme.ERROR)
	kick.add_theme_stylebox_override("normal", UiTheme.card_box())
	kick.add_theme_stylebox_override("hover", UiTheme.card_box())
	kick.add_theme_stylebox_override("pressed", UiTheme.card_box())
	kick.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if on_kick.is_valid():
		var idx := index
		kick.pressed.connect(func(): on_kick.call(idx))
	return kick
