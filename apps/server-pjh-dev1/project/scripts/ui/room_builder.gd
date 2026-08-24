class_name RoomBuilder
extends RefCounted

static func build(callbacks: Dictionary) -> Dictionary:
	var root := UiTheme.full(Control.new())
	var header := HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 36
	header.offset_right = -36
	header.offset_top = 18
	header.offset_bottom = 92
	var back := UiTheme.icon_btn(tr("ROOM_BACK"))
	back.pressed.connect(callbacks["on_back"])
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UiTheme.lbl(tr("ROOM_STEP"), 14, UiTheme.MUTED))
	titles.add_child(UiTheme.lbl(tr("ROOM_SUBTITLE"), 30, UiTheme.INK))
	var wait_mode_label := UiTheme.lbl("", 15, UiTheme.MUTED)
	titles.add_child(wait_mode_label)
	header.add_child(titles)
	var sound := UiTheme.icon_btn(tr("ROOM_SOUND"))
	sound.pressed.connect(callbacks["on_sound"])
	var gear := UiTheme.icon_btn(tr("ROOM_SETTINGS"))
	gear.pressed.connect(callbacks["on_settings"])
	header.add_child(sound)
	header.add_child(gear)
	root.add_child(header)

	var mode_row := HBoxContainer.new()
	mode_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	mode_row.offset_left = 36
	mode_row.offset_right = -36
	mode_row.offset_top = 96
	mode_row.offset_bottom = 148
	mode_row.add_theme_constant_override("separation", 8)
	var wait_mode_buttons: Array[Button] = []
	var wait_group := ButtonGroup.new()
	for mode in UiTheme.MODES:
		var chip := UiTheme.chip(str(mode["title"]), wait_group)
		var mode_id := str(mode["id"])
		chip.pressed.connect(func(): callbacks["on_mode"].call(mode_id))
		wait_mode_buttons.append(chip)
		mode_row.add_child(chip)
	root.add_child(mode_row)

	var slot_host := Control.new()
	slot_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_host.offset_top = 150
	slot_host.offset_bottom = -150
	slot_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(slot_host)
	for i in UiTheme.SLOT_COUNT:
		slot_host.add_child(_make_slot_card(i, callbacks.get("on_kick", Callable())))

	var center_box := VBoxContainer.new()
	center_box.set_anchors_preset(Control.PRESET_CENTER)
	center_box.offset_left = -160
	center_box.offset_right = 160
	center_box.offset_top = -90
	center_box.offset_bottom = 90
	center_box.add_theme_constant_override("separation", 8)
	var count_label := UiTheme.lbl("1 / 8", 22, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var ready_label := UiTheme.lbl(tr("ROOM_EMPTY_HINT"), 13, UiTheme.GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	var bot := Panel.new()
	bot.custom_minimum_size = Vector2(200, 52)
	bot.add_theme_stylebox_override("panel", UiTheme.card_box())
	var bot_row := HBoxContainer.new()
	bot_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	bot_row.add_child(UiTheme.lbl(tr("ROOM_CPU_AUTO"), 16, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER))
	bot.add_child(bot_row)
	center_box.add_child(count_label)
	center_box.add_child(ready_label)
	center_box.add_child(bot)
	root.add_child(center_box)

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
	var start_button := UiTheme.btn(tr("ROOM_START_GAME"), UiTheme.BLUE, Vector2(280, 72))
	start_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(callbacks["on_start"])
	var start_hint := UiTheme.lbl(tr("ROOM_HOST_HINT"), 14, UiTheme.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	start_hint.visible = false
	start_box.add_child(start_button)
	start_box.add_child(start_hint)
	footer.add_child(start_box)
	footer.add_child(_build_tip())
	root.add_child(footer)
	return {
		"root": root,
		"slot_host": slot_host,
		"count_label": count_label,
		"ready_label": ready_label,
		"wait_mode_label": wait_mode_label,
		"wait_mode_buttons": wait_mode_buttons,
		"chat_log": chat_refs["chat_log"],
		"start_button": start_button,
		"start_hint": start_hint,
	}

static func _build_chat() -> Dictionary:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(360, 110)
	panel.add_theme_stylebox_override("panel", UiTheme.card_box())
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	col.add_child(UiTheme.lbl(tr("ROOM_CHAT"), 14, UiTheme.INK))
	var chat_log := RichTextLabel.new()
	chat_log.bbcode_enabled = true
	chat_log.fit_content = true
	chat_log.scroll_active = true
	chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_log.add_theme_color_override("default_color", UiTheme.MUTED)
	col.add_child(chat_log)
	var row := HBoxContainer.new()
	var edit := LineEdit.new()
	edit.placeholder_text = tr("ROOM_CHAT_PLACEHOLDER")
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var send := Button.new()
	send.text = tr("ROOM_CHAT_SEND")
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
	col.add_child(UiTheme.lbl(tr("ROOM_NOTE"), 14, UiTheme.INK))
	var tip := UiTheme.lbl(tr("ROOM_TIP"), 14, UiTheme.MUTED)
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
	var badge := ColorRect.new()
	badge.custom_minimum_size = Vector2(22, 22)
	badge.color = UiTheme.SLOT_COLORS[index]
	var num := UiTheme.lbl(str(index + 1), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	num.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.add_child(num)
	var nick := UiTheme.lbl(UiTheme.NICKS[index], 15, UiTheme.INK)
	nick.name = "Nick"
	row.add_child(badge)
	row.add_child(nick)
	var ready := UiTheme.lbl(tr("ROOM_READY"), 13, UiTheme.GREEN)
	ready.name = "Ready"
	var portrait := _animal_portrait(index)
	var art: Control
	if portrait != null:
		var pic := TextureRect.new()
		pic.texture = portrait
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(88, 88)
		pic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art = pic
	else:
		art = UiTheme.lbl(UiTheme.ANIMALS[index], 28, UiTheme.SLOT_COLORS[index], HORIZONTAL_ALIGNMENT_CENTER)
	art.name = "Art"
	var kick := Button.new()
	kick.name = "Kick"
	kick.text = tr("ROOM_KICK")
	kick.visible = false
	kick.custom_minimum_size = Vector2(0, 26)
	kick.add_theme_font_size_override("font_size", 12)
	kick.add_theme_color_override("font_color", Color("C0392B"))
	kick.add_theme_color_override("font_hover_color", Color("C0392B"))
	kick.add_theme_color_override("font_pressed_color", Color("C0392B"))
	kick.add_theme_stylebox_override("normal", UiTheme.card_box())
	kick.add_theme_stylebox_override("hover", UiTheme.card_box())
	kick.add_theme_stylebox_override("pressed", UiTheme.card_box())
	kick.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if on_kick.is_valid():
		var idx := index
		kick.pressed.connect(func(): on_kick.call(idx))
	col.add_child(row)
	col.add_child(ready)
	col.add_child(art)
	col.add_child(kick)
	card.add_child(col)
	return card
