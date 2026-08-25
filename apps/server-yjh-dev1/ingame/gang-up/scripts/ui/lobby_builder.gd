class_name LobbyBuilder
extends RefCounted

static func build(callbacks: Dictionary) -> Dictionary:
	var root := UiTheme.full(Control.new())
	_add_background(root)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 32)
	col.add_theme_constant_override("separation", 16)
	var head := _build_header(callbacks)
	var lobby_status: Label = head["status"]
	col.add_child(head["node"])
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	var side_refs := _build_side(callbacks)
	body.add_child(side_refs["node"])
	var list_refs := _build_room_list()
	body.add_child(list_refs["node"])
	col.add_child(body)
	root.add_child(col)
	return {
		"root": root,
		"name_edit": side_refs["name_edit"],
		"lobby_status": lobby_status,
		"lobby_error": side_refs["lobby_error"],
		"room_list": list_refs["room_list"],
		"retry_button": side_refs["retry_button"],
		"local_button": side_refs["local_button"],
	}

static func _add_background(root: Control) -> void:
	var bg_tex := UiTheme.load_png("lobby_bg.png")
	if bg_tex == null:
		return
	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = bg_tex
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art)

static func _build_header(callbacks: Dictionary) -> Dictionary:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var how := UiTheme.icon_btn(tr("LOBBY_HOW_TO_PLAY"))
	how.pressed.connect(callbacks["on_how"])
	head.add_child(how)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UiTheme.lbl(tr("LOBBY_TITLE"), 14, UiTheme.MUTED))
	titles.add_child(UiTheme.lbl(tr("LOBBY_SUBTITLE"), 30, UiTheme.INK))
	var lobby_status := UiTheme.lbl("", 15, UiTheme.MUTED)
	titles.add_child(lobby_status)
	head.add_child(titles)
	var refresh := UiTheme.icon_btn(tr("LOBBY_REFRESH"))
	refresh.custom_minimum_size = Vector2(110, 52)
	refresh.pressed.connect(callbacks["on_refresh"])
	head.add_child(refresh)
	var lobby_gear := UiTheme.icon_btn(tr("LOBBY_SETTINGS"))
	lobby_gear.pressed.connect(callbacks["on_settings"])
	head.add_child(lobby_gear)
	return {"node": head, "status": lobby_status}

static func _build_side(callbacks: Dictionary) -> Dictionary:
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(320, 0)
	side.add_theme_constant_override("separation", 12)
	side.add_child(UiTheme.lbl(tr("LOBBY_NICKNAME"), 15, UiTheme.INK))
	var name_edit := LineEdit.new()
	name_edit.max_length = 12
	name_edit.custom_minimum_size = Vector2(0, 44)
	name_edit.text_changed.connect(callbacks["on_name_changed"])
	side.add_child(name_edit)
	var create := UiTheme.btn(tr("LOBBY_CREATE_ROOM"), UiTheme.BLUE, Vector2(0, 60))
	var create_tex := UiTheme.load_png("lobby_create.png")
	if create_tex != null:
		var create_sb := StyleBoxTexture.new()
		create_sb.texture = create_tex
		create_sb.content_margin_left = 18
		create_sb.content_margin_right = 18
		create.add_theme_stylebox_override("normal", create_sb)
	create.pressed.connect(callbacks["on_create"])
	side.add_child(create)
	var retry_button := UiTheme.btn(tr("LOBBY_RETRY"), UiTheme.BTN_DARK, Vector2(0, 48))
	retry_button.pressed.connect(callbacks["on_retry"])
	retry_button.visible = false
	side.add_child(retry_button)
	var local_button := UiTheme.btn(tr("LOBBY_PRACTICE"), UiTheme.GREEN, Vector2(0, 52))
	local_button.pressed.connect(callbacks["on_local"])
	side.add_child(local_button)
	var lobby_error := UiTheme.lbl("", 14, UiTheme.ERROR)
	lobby_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(lobby_error)
	return {"node": side, "name_edit": name_edit, "lobby_error": lobby_error, "retry_button": retry_button, "local_button": local_button}

static func _build_room_list() -> Dictionary:
	var list_panel := Panel.new()
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", UiTheme.card_box())
	var list_col := VBoxContainer.new()
	list_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	list_col.add_theme_constant_override("separation", 10)
	list_col.add_child(UiTheme.lbl(tr("LOBBY_OPEN_ROOMS"), 18, UiTheme.INK))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var room_list := VBoxContainer.new()
	room_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_list.add_theme_constant_override("separation", 10)
	scroll.add_child(room_list)
	list_col.add_child(scroll)
	list_panel.add_child(list_col)
	return {"node": list_panel, "room_list": room_list}

static func make_room_row(room: Dictionary, on_join: Callable, on_spectate: Callable = Callable()) -> Control:
	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, 64)
	var row_tex := UiTheme.load_png("lobby_row.png")
	if row_tex != null:
		var sb := StyleBoxTexture.new()
		sb.texture = row_tex
		row.add_theme_stylebox_override("panel", sb)
	else:
		row.add_theme_stylebox_override("panel", UiTheme.card_box())
	var line := HBoxContainer.new()
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	line.add_theme_constant_override("separation", 14)
	var title := UiTheme.lbl(str(room.get("title", tr("LOBBY_ROOM_DEFAULT"))), 18, UiTheme.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	line.add_child(title)
	var mode_lbl := UiTheme.lbl(UiTheme.mode_title(str(room.get("mode", ""))), 14, UiTheme.MUTED)
	mode_lbl.custom_minimum_size = Vector2(110, 0)
	line.add_child(mode_lbl)
	var count_lbl := UiTheme.lbl("%d/%d" % [int(room.get("count", 0)), int(room.get("max", 8))], 16, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER)
	count_lbl.custom_minimum_size = Vector2(70, 0)
	line.add_child(count_lbl)
	var room_id := str(room.get("id", ""))
	if on_spectate.is_valid() and bool(room.get("playing", false)):
		var spectate := UiTheme.btn(tr("LOBBY_SPECTATE"), UiTheme.MUTED, Vector2(80, 44))
		spectate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		spectate.pressed.connect(func(): on_spectate.call(room_id))
		line.add_child(spectate)
	var join := UiTheme.btn(tr("LOBBY_JOIN"), UiTheme.BLUE, Vector2(96, 44))
	join.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	join.pressed.connect(func(): on_join.call(room_id))
	line.add_child(join)
	row.add_child(line)
	return row
