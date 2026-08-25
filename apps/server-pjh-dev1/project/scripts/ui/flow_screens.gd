extends Control

signal start_match
signal request_quit_to_intro
signal request_resume
signal control_mode_changed(mode: String)

const _STATUS_COLORS := {
	"로비": UiTheme.GREEN,
	"오프라인 로컬": UiTheme.ERROR,
	"끊김": UiTheme.ERROR,
	"다시 연결 중": UiTheme.WARN,
	"연결 중": UiTheme.WARN,
}

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
var _intro_name_edit: LineEdit

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
	var default_name := "플레이어%02d" % (randi() % 90 + 10)
	_intro_name_edit.text = default_name
	_name_edit.text = default_name
	show_page(&"intro")

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
		if (hub == null or not hub.in_room) and _chat_log != null:
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
			show_page(&"intro")
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
	_intro = _build_intro()
	_how = HowToPlayPopup.build(func(): pop_page())
	_build_lobby()
	_build_room()
	_settings = _build_settings()
	for node in [_select, _intro, _how, _lobby, _wait, _settings]:
		add_child(node)

func _build_intro() -> Control:
	var root := UiTheme.full(Control.new())
	var bg := ColorRect.new()
	bg.color = UiTheme.INTRO_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var title := Label.new()
	title.text = "다굴"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", UiTheme.INTRO_TITLE)
	title.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	title.offset_top = 120
	title.offset_bottom = 240
	title.offset_left = -300
	title.offset_right = 300
	root.add_child(title)
	var subtitle := UiTheme.lbl("8인 배틀로얄", 18, UiTheme.INTRO_SUB, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	subtitle.offset_top = 230
	subtitle.offset_bottom = 260
	subtitle.offset_left = -300
	subtitle.offset_right = 300
	root.add_child(subtitle)
	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_CENTER)
	center.offset_left = -180
	center.offset_right = 180
	center.offset_top = 20
	center.offset_bottom = 260
	center.add_theme_constant_override("separation", 12)
	_intro_name_edit = LineEdit.new()
	_intro_name_edit.max_length = 12
	_intro_name_edit.custom_minimum_size = Vector2(0, 48)
	_intro_name_edit.placeholder_text = "닉네임을 입력하세요"
	_intro_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_name_edit.add_theme_font_size_override("font_size", 18)
	var name_sb := StyleBoxFlat.new()
	name_sb.bg_color = Color(1, 1, 1, 0.08)
	name_sb.border_color = Color(1, 1, 1, 0.15)
	name_sb.border_width_bottom = 2
	name_sb.corner_radius_top_left = 8
	name_sb.corner_radius_top_right = 8
	name_sb.corner_radius_bottom_left = 8
	name_sb.corner_radius_bottom_right = 8
	name_sb.content_margin_left = 16
	name_sb.content_margin_right = 16
	_intro_name_edit.add_theme_stylebox_override("normal", name_sb)
	_intro_name_edit.add_theme_color_override("font_color", Color.WHITE)
	_intro_name_edit.add_theme_color_override("font_placeholder_color", UiTheme.INTRO_SUB)
	center.add_child(_intro_name_edit)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	center.add_child(spacer)
	var play_btn := UiTheme.btn("바로 시작", UiTheme.BLUE, Vector2(0, 64))
	play_btn.add_theme_font_size_override("font_size", 26)
	play_btn.pressed.connect(_on_intro_play)
	center.add_child(play_btn)
	var find_btn := UiTheme.btn("방 찾기", Color(0.12, 0.6, 0.35), Vector2(0, 54))
	find_btn.pressed.connect(_on_intro_find)
	center.add_child(find_btn)
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	var how_btn := UiTheme.btn("조작법", Color(0.22, 0.26, 0.34), Vector2(0, 44))
	how_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	how_btn.pressed.connect(func():
		_how_return = &"intro"
		show_page(&"how"))
	btn_row.add_child(how_btn)
	var rules_btn := UiTheme.btn("규칙", Color(0.22, 0.26, 0.34), Vector2(0, 44))
	rules_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_btn.pressed.connect(_show_rules_card)
	btn_row.add_child(rules_btn)
	center.add_child(btn_row)
	root.add_child(center)
	var hint := UiTheme.lbl("WASD 이동 · 마우스 조준 · 좌클릭 공격", 12, UiTheme.INTRO_SUB, HORIZONTAL_ALIGNMENT_CENTER)
	hint.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	hint.offset_top = -40
	hint.offset_bottom = -16
	root.add_child(hint)
	return root

func _on_intro_play() -> void:
	_sync_intro_name()
	start_match.emit()

func _on_intro_find() -> void:
	_sync_intro_name()
	show_page(&"lobby")

func _sync_intro_name() -> void:
	var name := _intro_name_edit.text.strip_edges()
	if name != "":
		_name_edit.text = name
	_push_identity()

func _build_lobby() -> void:
	var lobby_refs = LobbyBuilder.build({
		"on_how": func():
			_how_return = &"lobby"
			show_page(&"how"),
		"on_refresh": _on_lobby_refresh,
		"on_settings": func(): open_settings(&"lobby"),
		"on_name_changed": func(_t): _push_identity(),
		"on_create": _on_create_pressed,
		"on_retry": _on_retry_pressed,
		"on_local": func(): show_page(&"wait"),
	})
	_lobby = lobby_refs["root"]
	_name_edit = lobby_refs["name_edit"]
	_lobby_status = lobby_refs["lobby_status"]
	_lobby_error = lobby_refs["lobby_error"]
	_room_list = lobby_refs["room_list"]
	_retry_button = lobby_refs["retry_button"]
	_local_button = lobby_refs["local_button"]

func _on_retry_pressed() -> void:
	if hub != null:
		hub.reconnect_now()

func _build_room() -> void:
	var room_refs = RoomBuilder.build({
		"on_back": func(): pop_page(),
		"on_sound": _toggle_sound,
		"on_settings": func(): open_settings(&"wait"),
		"on_mode": _on_wait_mode_pressed,
		"on_kick": _on_kick_pressed,
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

func _on_kick_pressed(idx: int) -> void:
	if hub != null and hub.in_room:
		hub.kick_player(idx)

func _display_name() -> String:
	var typed := _name_edit.text.strip_edges() if _name_edit != null else ""
	return typed if typed != "" else "플레이어"

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
		_lobby_error.text = "서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요."
		return
	_push_identity()
	if hub.is_open():
		_pending_create = false
		hub.create_room()
		return
	_pending_create = true
	_lobby_error.text = "서버에 연결하는 중입니다."
	if hub.status == "오프라인 로컬" or hub.status == "끊김":
		hub.reconnect_now()
	else:
		hub.ensure_connected()

func _rebuild_room_list() -> void:
	if _room_list == null:
		return
	for child in _room_list.get_children():
		child.queue_free()
	if hub == null or not hub.is_open():
		_room_list.add_child(UiTheme.lbl("서버에 연결하는 중입니다.", 15, UiTheme.MUTED))
		return
	if hub.rooms.is_empty():
		var empty := UiTheme.lbl("열린 방이 없습니다. 방을 만들어 시작하세요!", 16, UiTheme.MUTED)
		empty.custom_minimum_size = Vector2(0, 60)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_room_list.add_child(empty)
		return
	for room in hub.rooms:
		_room_list.add_child(LobbyBuilder.make_room_row(room, _on_join_pressed, _on_spectate_pressed))

func _on_join_pressed(room_id: String) -> void:
	if hub == null or not hub.is_open():
		return
	_push_identity()
	hub.join_room(room_id)

func _on_spectate_pressed(room_id: String) -> void:
	if hub == null or not hub.is_open():
		return
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
		_chat_log.append_text("[color=#%s][시스템] %s[/color]\n" % [UiTheme.WARN.to_html(false), message])
	elif _lobby_error != null and page == &"lobby":
		_lobby_error.text = message

func _on_hub_status(next: String) -> void:
	if _lobby_status != null:
		var mode_text := UiTheme.mode_title(selected_mode)
		_lobby_status.text = "%s  |  %s" % [mode_text, next]
		_lobby_status.add_theme_color_override("font_color", _STATUS_COLORS.get(next, UiTheme.MUTED))
	if _local_button != null:
		_local_button.visible = true
	if _retry_button != null:
		_retry_button.visible = next == "오프라인 로컬" or next == "끊김"
	_try_pending_create(next)
	if page == &"wait":
		_fill_wait()

func _try_pending_create(status: String) -> void:
	if page == &"lobby" and status == "로비" and hub != null:
		hub.request_rooms()
		if not _pending_create:
			return
		_pending_create = false
		_lobby_error.text = ""
		_push_identity()
		hub.create_room()
		return
	if status != "오프라인 로컬" or not _pending_create:
		return
	_pending_create = false
	if _lobby_error != null:
		_lobby_error.text = "연결에 실패했습니다. 다시 연결을 눌러 주세요."

func _on_hub_error(message: String) -> void:
	if _lobby_error != null:
		_lobby_error.text = message
	if _chat_log != null and page == &"wait":
		_chat_log.append_text("[color=#%s][시스템] %s[/color]\n" % [UiTheme.ERROR.to_html(false), message])

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
	var result = SettingsPopup.build(
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
	_update_wait_mode_label(mode_id)

func _update_wait_mode_label(_mode_id: String) -> void:
	if _wait_mode_label == null:
		return
	if hub != null and hub.in_room:
		_wait_mode_label.text = "%s  |  최후의 1인이 승리합니다!" % str(hub.room.get("title", "방"))
	else:
		_wait_mode_label.text = "오프라인 연습  |  최후의 1인이 승리합니다!"

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
		_fill_slot(i, online, me_host)
	_count_label.text = "%d / 8" % count
	_update_wait_mode_label(str(hub.room.get("mode", selected_mode)) if online else selected_mode)
	_sync_wait_modes()
	_fill_wait_chat(online, count)
	_update_start_button()

func _fill_slot(i: int, online: bool, me_host: bool) -> void:
	var card: Panel = _slot_host.get_node("Slot%d" % i)
	var nick: Label = card.find_child("Nick", true, false)
	var ready: Label = card.find_child("Ready", true, false)
	var kick: Button = card.find_child("Kick", true, false)
	if kick != null:
		kick.visible = me_host and i < hub.players.size() and i != hub.you
	if online and i < hub.players.size():
		_fill_slot_online(i, nick, ready)
	elif not online and i == 0:
		nick.text = "%s (나)" % _display_name()
		ready.text = "호스트"
		ready.add_theme_color_override("font_color", UiTheme.BLUE)
	else:
		nick.text = "CPU"
		ready.text = "시작 시 참여"
		ready.add_theme_color_override("font_color", UiTheme.MUTED)

func _fill_slot_online(i: int, nick: Label, ready: Label) -> void:
	var peer: Dictionary = hub.players[i]
	var peer_name := str(peer.get("name", "?"))
	if i == hub.you:
		peer_name = "%s (나)" % peer_name
	nick.text = peer_name
	if bool(peer.get("dropped", false)):
		ready.text = "재접속 대기"
		ready.add_theme_color_override("font_color", UiTheme.ERROR)
	elif bool(peer.get("host", false)):
		ready.text = "호스트"
		ready.add_theme_color_override("font_color", UiTheme.BLUE)
	else:
		ready.text = "대기 중"
		ready.add_theme_color_override("font_color", UiTheme.GREEN)

func _fill_wait_chat(online: bool, count: int) -> void:
	if _chat_log == null or _chat_log.get_total_character_count() > 0:
		return
	if online:
		_chat_log.append_text("[color=#%s][시스템] 방에 입장했습니다. %d/8명.[/color]\n" % [UiTheme.GREEN.to_html(false), count])
		_chat_log.append_text("[color=#%s][시스템] 호스트가 게임을 바꿀 수 있습니다. 빈 자리는 시작 시 CPU가 채웁니다.[/color]\n" % UiTheme.MUTED.to_html(false))
	else:
		_chat_log.append_text("[color=#%s][시스템] 오프라인 로컬 매치입니다. CPU 7명과 시작합니다.[/color]\n" % UiTheme.MUTED.to_html(false))

func _update_start_button() -> void:
	if _start_button == null:
		return
	var online: bool = hub != null and hub.in_room
	var show_start: bool = not online or hub.match_running or hub.you == 0
	_start_button.visible = show_start
	_start_hint.visible = not show_start
	if show_start:
		_start_button.text = "게임으로 돌아가기" if (online and hub.match_running) else "게임 시작"

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
	show_page(&"intro")
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
	var shown := from_name + " (나)" if mine else from_name
	_chat_log.append_text("[color=#%s][b]%s[/b][/color]: %s\n" % [color.to_html(false), shown, text.replace("[", "[lb]")])

func _show_rules_card() -> void:
	var popup := Control.new()
	popup.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	popup.mouse_filter = MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_STOP
	popup.add_child(dim)
	var card := Panel.new()
	card.set_anchors_preset(PRESET_CENTER)
	card.offset_left = -260
	card.offset_right = 260
	card.offset_top = -220
	card.offset_bottom = 220
	var sb := UiTheme.card_box()
	sb.bg_color = UiTheme.CARD
	card.add_theme_stylebox_override("panel", sb)
	popup.add_child(card)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vbox.offset_left = 24
	vbox.offset_right = -24
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(UiTheme.lbl("게임 규칙", 28, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER))
	var rules := [
		"목표: 8명 중 최후의 1인이 승리합니다",
		"체력이 0이 되면 다운됩니다 (부활 3회)",
		"적을 처치하면 킬 룰렛이 돌아갑니다 (버프 획득)",
		"세이프존이 점점 좁아집니다 — 밖에 있으면 데미지!",
		"75초에 중앙 타워가 등장합니다",
		"WASD 이동 · 마우스 조준 · 좌클릭 공격",
		"Shift 대시 · 우클릭(홀드) 장비 스킬",
		"Q 궁극기 · E 아이템 사용 · R 장전",
	]
	for r in rules:
		vbox.add_child(UiTheme.lbl(r, 16, UiTheme.INK))
	card.add_child(vbox)
	var close_btn := UiTheme.btn("닫기", UiTheme.BLUE, Vector2(120, 44))
	close_btn.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	close_btn.offset_left = -140
	close_btn.offset_top = -56
	close_btn.offset_right = -20
	close_btn.offset_bottom = -12
	close_btn.pressed.connect(func(): popup.queue_free())
	card.add_child(close_btn)
	dim.gui_input.connect(func(_ev): popup.queue_free())
	add_child(popup)
