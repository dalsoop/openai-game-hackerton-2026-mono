extends Control

signal start_match
signal request_quit_to_intro
signal request_resume
signal control_mode_changed(mode: String)

var page := &"lobby"
var selected_mode := "classic"
var sound_on := true
var control_mode := SettingsStore.MODE_AUTO
var hub = null
var _select: Control
var _intro: Control
var _how: Control
var _lobby: Control
var _wait: Control
var _settings: Control
var _slot_host: Control
var _count_label: Label
var _ready_label: Label
var _wait_mode_label: Label
var _chat_log: RichTextLabel
var _name_edit: LineEdit
var _start_button: Button
var _start_hint: Label
var _room_list: VBoxContainer
var _lobby_status: Label
var _lobby_error: Label
var _local_button: Button
var _retry_button: Button
var _wait_mode_buttons: Array[Button] = []
var _how_return: StringName = &"lobby"
var _settings_return: StringName = &"lobby"
var _settings_mode_buttons: Dictionary = {}
var _settings_mode_desc: Label
var _settings_sound: CheckButton
var _pending_create := false

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var t := Theme.new()
	t.default_font = GameFont.get_font()
	theme = t
	control_mode = SettingsStore.load_control_mode()
	sound_on = SettingsStore.load_sound_on()
	AudioServer.set_bus_mute(0, not sound_on)
	_build()
	_sync_settings_ui()
	_name_edit.text = tr("FLOW_DEFAULT_NAME") % (randi() % 90 + 10)
	show_page(&"lobby")

func show_page(which: StringName) -> void:
	page = which
	_select.visible = which == &"select"
	_intro.visible = which == &"intro"
	_how.visible = which == &"how"
	_lobby.visible = which == &"lobby"
	_wait.visible = which == &"wait"
	_settings.visible = which == &"settings"
	if which == &"lobby":
		_enter_lobby()
	if which == &"wait":
		if hub == null or not hub.in_room:
			if _chat_log != null:
				_chat_log.clear()
		_fill_wait()
		call_deferred("_layout_slots")

func pop_page() -> void:
	match page:
		&"how":
			show_page(_how_return)
		&"select":
			show_page(&"lobby")
		&"lobby":
			return
		&"wait":
			if hub != null and hub.in_room:
				hub.leave_room()
			else:
				show_page(&"lobby")
		&"settings":
			show_page(_settings_return)
		_:
			show_page(&"lobby")

func apply_roster(world) -> void:
	if world == null:
		return
	_fill_wait()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	_select = UiTheme.full(Control.new())
	_intro = UiTheme.full(Control.new())
	_how = HowToPlayPopup.build(func(): pop_page())
	var lobby_refs := LobbyBuilder.build({
		"on_how": func():
			_how_return = &"lobby"
			show_page(&"how"),
		"on_refresh": _on_lobby_refresh,
		"on_settings": func(): open_settings(&"lobby"),
		"on_name_changed": func(_t): _push_identity(),
		"on_create": _on_create_pressed,
		"on_retry": func(): if hub != null: hub.reconnect_now(),
		"on_local": func(): show_page(&"wait"),
	})
	_lobby = lobby_refs["root"]
	_name_edit = lobby_refs["name_edit"]
	_lobby_status = lobby_refs["lobby_status"]
	_lobby_error = lobby_refs["lobby_error"]
	_room_list = lobby_refs["room_list"]
	_retry_button = lobby_refs["retry_button"]
	_local_button = lobby_refs["local_button"]
	var room_refs := RoomBuilder.build({
		"on_back": func(): pop_page(),
		"on_sound": _toggle_sound,
		"on_settings": func(): open_settings(&"wait"),
		"on_mode": _on_wait_mode_pressed,
		"on_kick": func(idx): if hub != null and hub.in_room: hub.kick_player(idx),
		"on_start": _on_start_pressed,
	})
	_wait = room_refs["root"]
	_slot_host = room_refs["slot_host"]
	_count_label = room_refs["count_label"]
	_ready_label = room_refs["ready_label"]
	_wait_mode_label = room_refs["wait_mode_label"]
	_wait_mode_buttons = room_refs["wait_mode_buttons"]
	_chat_log = room_refs["chat_log"]
	_start_button = room_refs["start_button"]
	_start_hint = room_refs["start_hint"]
	_settings = _build_settings()
	add_child(_select)
	add_child(_intro)
	add_child(_how)
	add_child(_lobby)
	add_child(_wait)
	add_child(_settings)

func _display_name() -> String:
	var typed := _name_edit.text.strip_edges() if _name_edit != null else ""
	return typed if typed != "" else tr("FLOW_FALLBACK_NAME")

func _push_identity() -> void:
	if hub == null:
		return
	hub.player_name = _display_name()
	hub.mode = selected_mode
	if hub.is_open():
		hub.send_hello()

func _enter_lobby() -> void:
	if hub != null:
		_push_identity()
		hub.ensure_connected()
		if hub.is_open():
			hub.request_rooms()
		_on_hub_status(hub.status)
	_rebuild_room_list()

func _on_lobby_refresh() -> void:
	if hub == null:
		return
	_push_identity()
	if hub.is_open():
		hub.request_rooms()
	else:
		hub.reconnect_now()

func _on_create_pressed() -> void:
	if hub == null:
		_lobby_error.text = tr("FLOW_NO_HUB")
		return
	_push_identity()
	if hub.is_open():
		_pending_create = false
		hub.create_room()
		return
	_pending_create = true
	_lobby_error.text = tr("FLOW_CONNECTING")
	if hub.status == NetworkManager.STATUS_OFFLINE or hub.status == NetworkManager.STATUS_CLOSED:
		hub.reconnect_now()
	else:
		hub.ensure_connected()

func _rebuild_room_list() -> void:
	if _room_list == null:
		return
	for child in _room_list.get_children():
		child.queue_free()
	if hub == null or not hub.is_open():
		_room_list.add_child(UiTheme.lbl(tr("FLOW_WAITING_HUB"), 15, UiTheme.MUTED))
		return
	if hub.rooms.is_empty():
		var empty := UiTheme.lbl(tr("FLOW_NO_ROOMS"), 16, UiTheme.MUTED)
		empty.custom_minimum_size = Vector2(0, 60)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_room_list.add_child(empty)
		return
	for room in hub.rooms:
		_room_list.add_child(LobbyBuilder.make_room_row(room, _on_join_pressed))

func _on_join_pressed(room_id: String) -> void:
	if hub == null or not hub.is_open():
		return
	_push_identity()
	hub.join_room(room_id)

func bind_hub(client) -> void:
	hub = client
	hub.rooms_updated.connect(_on_hub_rooms)
	hub.joined_room.connect(_on_hub_joined)
	hub.peers_updated.connect(_on_hub_peers)
	hub.left_room.connect(_on_hub_left)
	hub.status_changed.connect(_on_hub_status)
	hub.hub_error.connect(_on_hub_error)
	hub.hub_notice.connect(_on_hub_notice)
	hub.chat_received.connect(_on_hub_chat)
	_on_hub_status(hub.status)

func _on_hub_rooms(_rooms: Array) -> void:
	if page == &"lobby":
		_rebuild_room_list()

func _on_hub_joined(_room: Dictionary, _players: Array, _you: int) -> void:
	_lobby_error.text = ""
	if _chat_log != null:
		_chat_log.clear()
	show_page(&"wait")

func _on_hub_peers(_players: Array, _room: Dictionary) -> void:
	if page == &"wait":
		_fill_wait()

func _on_hub_left() -> void:
	if hub != null and hub.holding_seat:
		return
	if page == &"wait":
		show_page(&"lobby")

func _on_hub_notice(message: String) -> void:
	if _chat_log != null and page == &"wait":
		_chat_log.append_text("[color=#C47B17][%s] %s[/color]\n" % [tr("FLOW_SYSTEM"), message])
	elif _lobby_error != null and page == &"lobby":
		_lobby_error.text = message

func _on_hub_status(next: String) -> void:
	if _lobby_status != null:
		var mode_text := UiTheme.mode_title(selected_mode)
		_lobby_status.text = "%s  |  %s" % [mode_text, next]
		var status_color := UiTheme.MUTED
		if next == NetworkManager.STATUS_LOBBY:
			status_color = UiTheme.GREEN
		elif next == NetworkManager.STATUS_OFFLINE or next == NetworkManager.STATUS_CLOSED:
			status_color = Color("C0392B")
		elif next == NetworkManager.STATUS_RECONNECTING or next == NetworkManager.STATUS_CONNECTING:
			status_color = Color("C47B17")
		_lobby_status.add_theme_color_override("font_color", status_color)
	if _local_button != null:
		_local_button.visible = true
	if _retry_button != null:
		_retry_button.visible = next == NetworkManager.STATUS_OFFLINE or next == NetworkManager.STATUS_CLOSED
	if page == &"lobby" and next == NetworkManager.STATUS_LOBBY and hub != null:
		hub.request_rooms()
		if _pending_create:
			_pending_create = false
			_lobby_error.text = ""
			_push_identity()
			hub.create_room()
	elif next == NetworkManager.STATUS_OFFLINE and _pending_create:
		_pending_create = false
		if _lobby_error != null:
			_lobby_error.text = tr("FLOW_HUB_FAIL")
	if page == &"wait":
		_fill_wait()

func _on_hub_error(message: String) -> void:
	if _lobby_error != null:
		_lobby_error.text = message
	if _chat_log != null and page == &"wait":
		_chat_log.append_text("[color=#C0392B][%s] %s[/color]\n" % [tr("FLOW_SYSTEM"), message])

func open_settings(return_to: StringName) -> void:
	_settings_return = return_to
	_sync_settings_ui()
	show_page(&"settings")

func set_control_mode(mode: String) -> void:
	if not mode in SettingsStore.MODES:
		mode = SettingsStore.MODE_AUTO
	control_mode = mode
	SettingsStore.save(control_mode, sound_on)
	_sync_settings_ui()
	control_mode_changed.emit(control_mode)

func _sync_settings_ui() -> void:
	for mode in _settings_mode_buttons.keys():
		var b: Button = _settings_mode_buttons[mode]
		b.set_pressed_no_signal(mode == control_mode)
	if _settings_mode_desc != null:
		_settings_mode_desc.text = SettingsStore.mode_desc(control_mode)
	if _settings_sound != null:
		_settings_sound.set_pressed_no_signal(sound_on)

func _build_settings() -> Control:
	var result := SettingsPopup.build(
		func(): pop_page(),
		func(): _quit_to_select(),
		control_mode,
		sound_on,
		func(mode_id): set_control_mode(mode_id),
		func(on):
			sound_on = on
			AudioServer.set_bus_mute(0, not on)
			SettingsStore.save(control_mode, sound_on)
	)
	_settings_mode_buttons = result["mode_buttons"]
	_settings_mode_desc = result["mode_desc"]
	_settings_sound = result["sound_check"]
	return result["root"]

func _on_wait_mode_pressed(mode_id: String) -> void:
	selected_mode = mode_id
	if hub != null:
		hub.mode = mode_id
		if hub.in_room and hub.you == 0:
			hub.set_room_mode(mode_id)
	_sync_wait_modes()
	if _wait_mode_label != null:
		if hub != null and hub.in_room:
			_wait_mode_label.text = "%s  |  %s  |  %s" % [str(hub.room.get("title", "")), UiTheme.mode_title(mode_id), tr("FLOW_LAST_STANDING")]
		else:
			_wait_mode_label.text = "%s  |  %s  |  %s" % [UiTheme.mode_title(mode_id), tr("FLOW_OFFLINE_LOCAL"), tr("FLOW_LAST_STANDING")]

func _host_can_change_mode() -> bool:
	if hub == null:
		return true
	if not hub.in_room:
		return true
	return int(hub.you) == 0

func _sync_wait_modes() -> void:
	var current: String = selected_mode
	if hub != null and hub.in_room:
		current = str(hub.room.get("mode", selected_mode))
		selected_mode = current
		hub.mode = current
	var guest_locked: bool = not _host_can_change_mode()
	for i in _wait_mode_buttons.size():
		var chip: Button = _wait_mode_buttons[i]
		var id := str(UiTheme.MODES[i]["id"])
		chip.disabled = guest_locked
		chip.set_pressed_no_signal(id == current)

func _fill_wait() -> void:
	var online: bool = hub != null and hub.in_room
	var count := 1
	if online:
		count = hub.players.size()
	var me_host: bool = online and hub.you >= 0 and hub.you < hub.players.size() and bool(hub.players[hub.you].get("host", false))
	for i in UiTheme.SLOT_COUNT:
		var card: Panel = _slot_host.get_node("Slot%d" % i)
		var nick: Label = card.find_child("Nick", true, false)
		var ready: Label = card.find_child("Ready", true, false)
		var kick: Button = card.find_child("Kick", true, false)
		if kick != null:
			kick.visible = me_host and i < hub.players.size() and i != hub.you
		if online and i < hub.players.size():
			var peer: Dictionary = hub.players[i]
			var peer_name := str(peer.get("name", "?"))
			if i == hub.you:
				peer_name = "%s %s" % [peer_name, tr("FLOW_PEER_ME")]
			nick.text = peer_name
			if bool(peer.get("dropped", false)):
				ready.text = tr("FLOW_RECONNECT_WAIT")
				ready.add_theme_color_override("font_color", Color("C0392B"))
			elif bool(peer.get("host", false)):
				ready.text = tr("FLOW_HOST")
				ready.add_theme_color_override("font_color", UiTheme.BLUE)
			else:
				ready.text = tr("FLOW_WAITING")
				ready.add_theme_color_override("font_color", UiTheme.GREEN)
		elif not online and i == 0:
			nick.text = "%s %s" % [_display_name(), tr("FLOW_PEER_ME")]
			ready.text = tr("FLOW_HOST")
			ready.add_theme_color_override("font_color", UiTheme.BLUE)
		else:
			nick.text = "CPU"
			ready.text = tr("FLOW_JOIN_ON_START")
			ready.add_theme_color_override("font_color", UiTheme.MUTED)
	_count_label.text = "%d / 8" % count
	if _wait_mode_label != null:
		if online:
			_wait_mode_label.text = "%s  |  %s  |  %s" % [str(hub.room.get("title", "")), UiTheme.mode_title(str(hub.room.get("mode", selected_mode))), tr("FLOW_LAST_STANDING")]
		else:
			_wait_mode_label.text = "%s  |  %s  |  %s" % [UiTheme.mode_title(selected_mode), tr("FLOW_OFFLINE_LOCAL"), tr("FLOW_LAST_STANDING")]
	_sync_wait_modes()
	if _chat_log != null and _chat_log.get_total_character_count() == 0:
		if online:
			_chat_log.append_text("[color=#1F9D55][%s] %s[/color]\n" % [tr("FLOW_SYSTEM"), tr("FLOW_ENTERED_ROOM") % count])
			_chat_log.append_text("[color=#6B7380][%s] %s[/color]\n" % [tr("FLOW_SYSTEM"), tr("FLOW_HOST_CAN_CHANGE")])
		else:
			_chat_log.append_text("[color=#6B7380][%s] %s[/color]\n" % [tr("FLOW_SYSTEM"), tr("FLOW_OFFLINE_MATCH")])
	_update_start_button()

func _update_start_button() -> void:
	if _start_button == null:
		return
	var online: bool = hub != null and hub.in_room
	if not online:
		_start_button.visible = true
		_start_button.text = tr("FLOW_START_GAME")
		_start_hint.visible = false
	elif hub.match_running:
		_start_button.visible = true
		_start_button.text = tr("FLOW_RETURN_GAME")
		_start_hint.visible = false
	elif hub.you == 0:
		_start_button.visible = true
		_start_button.text = tr("FLOW_START_GAME")
		_start_hint.visible = false
	else:
		_start_button.visible = false
		_start_hint.visible = true

func _on_start_pressed() -> void:
	if hub != null and hub.in_room:
		if hub.match_running:
			request_resume.emit()
		elif hub.you == 0:
			hub.start_match()
	else:
		start_match.emit()

func _layout_slots() -> void:
	if _slot_host == null:
		return
	var area := _slot_host.size
	if area.x < 8.0 or area.y < 8.0:
		return
	var center := area * 0.5
	var radius := minf(area.x * 0.32, area.y * 0.38)
	for i in UiTheme.SLOT_COUNT:
		var card: Control = _slot_host.get_node("Slot%d" % i)
		var ang := -PI * 0.5 + TAU * float(i) / float(UiTheme.SLOT_COUNT)
		var pos := center + Vector2(cos(ang), sin(ang)) * radius - card.size * 0.5
		card.position = pos

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_slots()

func _toggle_sound() -> void:
	sound_on = not sound_on
	AudioServer.set_bus_mute(0, not sound_on)
	SettingsStore.save(control_mode, sound_on)
	_sync_settings_ui()

func _quit_to_select() -> void:
	if hub != null and hub.in_room:
		hub.leave_room()
	show_page(&"lobby")
	request_quit_to_intro.emit()

func _send_chat(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty():
		return
	if hub != null and hub.in_room:
		hub.send_chat(t)
		return
	_chat_log.append_text("%s: %s\n" % [_display_name(), t])

func _on_hub_chat(from_name: String, slot: int, text: String) -> void:
	if _chat_log == null:
		return
	var color: Color = UiTheme.SLOT_COLORS[slot] if slot >= 0 and slot < UiTheme.SLOT_COLORS.size() else UiTheme.INK
	var mine: bool = hub != null and slot == hub.you
	var shown := from_name + " " + tr("FLOW_PEER_ME") if mine else from_name
	_chat_log.append_text("[color=#%s][b]%s[/b][/color]: %s\n" % [color.to_html(false), shown, text.replace("[", "[lb]")])
