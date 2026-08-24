extends Control

signal start_match
signal request_quit_to_intro
signal request_resume
signal control_mode_changed(mode: String)

# Constants and factory functions are in UiTheme (class_name)
const BG := UiTheme.BG
const INK := UiTheme.INK
const MUTED := UiTheme.MUTED
const CARD := UiTheme.CARD
const LINE := UiTheme.LINE
const BLUE := UiTheme.BLUE
const GREEN := UiTheme.GREEN
const SLOT_COUNT := UiTheme.SLOT_COUNT
const ANIMALS := UiTheme.ANIMALS
const LOBBY_ANIMAL_FRAME := UiTheme.LOBBY_ANIMAL_FRAME
const NICKS := UiTheme.NICKS
const SLOT_COLORS := UiTheme.SLOT_COLORS
const MODES := UiTheme.MODES

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
    _name_edit.text = "플레이어%02d" % (randi() % 90 + 10)
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
    bg.color = BG
    bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    bg.mouse_filter = MOUSE_FILTER_IGNORE
    add_child(bg)
    _select = _build_select()
    _intro = _build_intro()
    _how = _build_how()
    _lobby = _build_lobby()
    _wait = _build_wait()
    _settings = _build_settings()
    add_child(_select)
    add_child(_intro)
    add_child(_how)
    add_child(_lobby)
    add_child(_wait)
    add_child(_settings)

# Delegate factory functions to UiTheme
func _full(node: Control) -> Control: return UiTheme.full(node)
func _lbl(text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label: return UiTheme.lbl(text, size, color, align)
func _btn(text: String, bg: Color, min_size: Vector2) -> Button: return UiTheme.btn(text, bg, min_size)
func _chip(text: String, group: ButtonGroup) -> Button: return UiTheme.chip(text, group)
func _icon_btn(caption: String) -> Button: return UiTheme.icon_btn(caption)
func _card_box() -> StyleBoxFlat: return UiTheme.card_box()
func _load_png(filename: String) -> Texture2D: return UiTheme.load_png(filename)
func _mode_title(mode_id: String) -> String: return UiTheme.mode_title(mode_id)

# Select and Intro screens removed — web hub handles lobby entry
func _build_select() -> Control:
    return _full(Control.new())

func _build_intro() -> Control:
    return _full(Control.new())

func _build_how() -> Control:
    return HowToPlayPopup.build(func(): pop_page())

func _build_lobby() -> Control:
    var root := _full(Control.new())
    var bg_tex := _load_png("lobby_bg.png")
    if bg_tex != null:
        var art := TextureRect.new()
        art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        art.texture = bg_tex
        art.mouse_filter = MOUSE_FILTER_IGNORE
        root.add_child(art)
    var col := VBoxContainer.new()
    col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 32)
    col.add_theme_constant_override("separation", 16)
    var head := HBoxContainer.new()
    head.add_theme_constant_override("separation", 12)
    var how := _icon_btn("조작")
    how.pressed.connect(func():
        _how_return = &"lobby"
        show_page(&"how")
    )
    head.add_child(how)
    var titles := VBoxContainer.new()
    titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    titles.add_child(_lbl("1 / 2  로비", 14, MUTED))
    titles.add_child(_lbl("방을 만들거나 들어갑니다", 30, INK))
    _lobby_status = _lbl("", 15, MUTED)
    titles.add_child(_lobby_status)
    head.add_child(titles)
    var refresh := _icon_btn("새로고침")
    refresh.custom_minimum_size = Vector2(110, 52)
    refresh.pressed.connect(_on_lobby_refresh)
    head.add_child(refresh)
    var lobby_gear := _icon_btn("설정")
    lobby_gear.pressed.connect(func(): open_settings(&"lobby"))
    head.add_child(lobby_gear)
    col.add_child(head)
    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 18)
    var side := VBoxContainer.new()
    side.custom_minimum_size = Vector2(320, 0)
    side.add_theme_constant_override("separation", 12)
    side.add_child(_lbl("닉네임", 15, INK))
    _name_edit = LineEdit.new()
    _name_edit.max_length = 12
    _name_edit.custom_minimum_size = Vector2(0, 44)
    _name_edit.text_changed.connect(func(_t): _push_identity())
    side.add_child(_name_edit)
    var create := _btn("방 만들기", BLUE, Vector2(0, 60))
    var create_tex := _load_png("lobby_create.png")
    if create_tex != null:
        var create_sb := StyleBoxTexture.new()
        create_sb.texture = create_tex
        create_sb.content_margin_left = 18
        create_sb.content_margin_right = 18
        create.add_theme_stylebox_override("normal", create_sb)
    create.pressed.connect(_on_create_pressed)
    side.add_child(create)
    _retry_button = _btn("다시 연결", Color("3D4654"), Vector2(0, 48))
    _retry_button.pressed.connect(func(): if hub != null: hub.reconnect_now())
    _retry_button.visible = false
    side.add_child(_retry_button)
    _local_button = _btn("연습하기 (로컬)", GREEN, Vector2(0, 52))
    _local_button.pressed.connect(func(): show_page(&"wait"))
    side.add_child(_local_button)
    _lobby_error = _lbl("", 14, Color("C0392B"))
    _lobby_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    side.add_child(_lobby_error)
    body.add_child(side)
    var list_panel := Panel.new()
    list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_panel.add_theme_stylebox_override("panel", _card_box())
    var list_col := VBoxContainer.new()
    list_col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 16)
    list_col.add_theme_constant_override("separation", 10)
    list_col.add_child(_lbl("열린 방", 18, INK))
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _room_list = VBoxContainer.new()
    _room_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _room_list.add_theme_constant_override("separation", 10)
    scroll.add_child(_room_list)
    list_col.add_child(scroll)
    list_panel.add_child(list_col)
    body.add_child(list_panel)
    col.add_child(body)
    root.add_child(col)
    return root

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
        _lobby_error.text = "허브 클라이언트가 없습니다."
        return
    _push_identity()
    if hub.is_open():
        _pending_create = false
        hub.create_room()
        return
    _pending_create = true
    _lobby_error.text = "허브에 연결하는 중입니다."
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
        var offline_note := _lbl("허브 연결을 기다리는 중입니다.", 15, MUTED)
        _room_list.add_child(offline_note)
        return
    if hub.rooms.is_empty():
        var empty := _lbl("열린 방이 없습니다. 방을 만들어 시작하세요!", 16, MUTED)
        empty.custom_minimum_size = Vector2(0, 60)
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _room_list.add_child(empty)
        return
    for room in hub.rooms:
        _room_list.add_child(_make_room_row(room))

func _make_room_row(room: Dictionary) -> Control:
    var row := Panel.new()
    row.custom_minimum_size = Vector2(0, 64)
    var row_tex := _load_png("lobby_row.png")
    if row_tex != null:
        var sb := StyleBoxTexture.new()
        sb.texture = row_tex
        row.add_theme_stylebox_override("panel", sb)
    else:
        row.add_theme_stylebox_override("panel", _card_box())
    var line := HBoxContainer.new()
    line.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 12)
    line.add_theme_constant_override("separation", 14)
    var title := _lbl(str(room.get("title", "방")), 18, INK)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.clip_text = true
    line.add_child(title)
    var mode_lbl := _lbl(_mode_title(str(room.get("mode", ""))), 14, MUTED)
    mode_lbl.custom_minimum_size = Vector2(110, 0)
    line.add_child(mode_lbl)
    var count_lbl := _lbl("%d/%d" % [int(room.get("count", 0)), int(room.get("max", 8))], 16, INK, HORIZONTAL_ALIGNMENT_CENTER)
    count_lbl.custom_minimum_size = Vector2(70, 0)
    line.add_child(count_lbl)
    var join := _btn("참가", BLUE, Vector2(96, 44))
    join.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    var room_id := str(room.get("id", ""))
    join.pressed.connect(func(): _on_join_pressed(room_id))
    line.add_child(join)
    row.add_child(line)
    return row

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
        _chat_log.append_text("[color=#C47B17][시스템] %s[/color]\n" % message)
    elif _lobby_error != null and page == &"lobby":
        _lobby_error.text = message

func _on_hub_status(next: String) -> void:
    if _lobby_status != null:
        var mode_text := _mode_title(selected_mode)
        _lobby_status.text = "%s  |  %s" % [mode_text, next]
        var status_color := MUTED
        if next == "로비":
            status_color = GREEN
        elif next == "오프라인 로컬" or next == "끊김":
            status_color = Color("C0392B")
        elif next == "다시 연결 중" or next == "연결 중":
            status_color = Color("C47B17")
        _lobby_status.add_theme_color_override("font_color", status_color)
    if _local_button != null:
        _local_button.visible = true
    if _retry_button != null:
        _retry_button.visible = next == "오프라인 로컬" or next == "끊김"
    if page == &"lobby" and next == "로비" and hub != null:
        hub.request_rooms()
        if _pending_create:
            _pending_create = false
            _lobby_error.text = ""
            _push_identity()
            hub.create_room()
    elif next == "오프라인 로컬" and _pending_create:
        _pending_create = false
        if _lobby_error != null:
            _lobby_error.text = "허브에 연결하지 못했습니다. 다시 연결을 눌러 주세요."
    if page == &"wait":
        _fill_wait()

func _on_hub_error(message: String) -> void:
    if _lobby_error != null:
        _lobby_error.text = message
    if _chat_log != null and page == &"wait":
        _chat_log.append_text("[color=#C0392B][시스템] %s[/color]\n" % message)

func _build_wait() -> Control:
    var root := _full(Control.new())
    var header := HBoxContainer.new()
    header.set_anchors_preset(PRESET_TOP_WIDE)
    header.offset_left = 36
    header.offset_right = -36
    header.offset_top = 18
    header.offset_bottom = 92
    var back := _icon_btn("뒤로")
    back.pressed.connect(func(): pop_page())
    header.add_child(back)
    var titles := VBoxContainer.new()
    titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    titles.add_child(_lbl("2 / 2  로비  >  방", 14, MUTED))
    titles.add_child(_lbl("멤버와 게임을 고르세요", 30, INK))
    _wait_mode_label = _lbl("", 15, MUTED)
    titles.add_child(_wait_mode_label)
    header.add_child(titles)
    var sound := _icon_btn("소리")
    sound.pressed.connect(_toggle_sound)
    var gear := _icon_btn("설정")
    gear.pressed.connect(func(): open_settings(&"wait"))
    header.add_child(sound)
    header.add_child(gear)
    root.add_child(header)

    var mode_row := HBoxContainer.new()
    mode_row.set_anchors_preset(PRESET_TOP_WIDE)
    mode_row.offset_left = 36
    mode_row.offset_right = -36
    mode_row.offset_top = 96
    mode_row.offset_bottom = 148
    mode_row.add_theme_constant_override("separation", 8)
    _wait_mode_buttons.clear()
    var wait_group := ButtonGroup.new()
    for mode in MODES:
        var chip := _chip(str(mode["title"]), wait_group)
        var mode_id := str(mode["id"])
        chip.pressed.connect(func(): _on_wait_mode_pressed(mode_id))
        _wait_mode_buttons.append(chip)
        mode_row.add_child(chip)
    root.add_child(mode_row)

    _slot_host = Control.new()
    _slot_host.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    _slot_host.offset_top = 150
    _slot_host.offset_bottom = -150
    _slot_host.mouse_filter = MOUSE_FILTER_IGNORE
    root.add_child(_slot_host)
    for i in SLOT_COUNT:
        _slot_host.add_child(_make_slot_card(i))

    var hub := VBoxContainer.new()
    hub.set_anchors_preset(PRESET_CENTER)
    hub.offset_left = -160
    hub.offset_right = 160
    hub.offset_top = -90
    hub.offset_bottom = 90
    hub.add_theme_constant_override("separation", 8)
    _count_label = _lbl("1 / 8", 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
    _ready_label = _lbl("빈 자리는 시작 시 CPU가 채웁니다", 13, GREEN, HORIZONTAL_ALIGNMENT_CENTER)
    var bot := Panel.new()
    bot.custom_minimum_size = Vector2(200, 52)
    bot.add_theme_stylebox_override("panel", _card_box())
    var bot_row := HBoxContainer.new()
    bot_row.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 10)
    bot_row.add_child(_lbl("CPU  자동 참여", 16, INK, HORIZONTAL_ALIGNMENT_CENTER))
    bot.add_child(bot_row)
    hub.add_child(_count_label)
    hub.add_child(_ready_label)
    hub.add_child(bot)
    root.add_child(hub)

    var footer := HBoxContainer.new()
    footer.set_anchors_preset(PRESET_BOTTOM_WIDE)
    footer.offset_left = 28
    footer.offset_right = -28
    footer.offset_top = -138
    footer.offset_bottom = -18
    footer.add_theme_constant_override("separation", 16)
    footer.add_child(_build_chat())
    var start_box := VBoxContainer.new()
    start_box.add_theme_constant_override("separation", 6)
    _start_button = _btn("게임 시작", BLUE, Vector2(280, 72))
    _start_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    _start_button.pressed.connect(_on_start_pressed)
    _start_hint = _lbl("호스트가 시작하면 출발합니다", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    _start_hint.visible = false
    start_box.add_child(_start_button)
    start_box.add_child(_start_hint)
    footer.add_child(start_box)
    footer.add_child(_build_tip())
    root.add_child(footer)
    return root

func _build_chat() -> Control:
    var panel := Panel.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.custom_minimum_size = Vector2(360, 110)
    panel.add_theme_stylebox_override("panel", _card_box())
    var col := VBoxContainer.new()
    col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 10)
    col.add_child(_lbl("채팅", 14, INK))
    _chat_log = RichTextLabel.new()
    _chat_log.bbcode_enabled = true
    _chat_log.fit_content = true
    _chat_log.scroll_active = true
    _chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _chat_log.add_theme_color_override("default_color", MUTED)
    col.add_child(_chat_log)
    var row := HBoxContainer.new()
    var edit := LineEdit.new()
    edit.placeholder_text = "메시지를 입력하세요..."
    edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    edit.text_submitted.connect(func(t): _send_chat(t); edit.text = "")
    var send := Button.new()
    send.text = "전송"
    send.pressed.connect(func(): _send_chat(edit.text); edit.text = "")
    row.add_child(edit)
    row.add_child(send)
    col.add_child(row)
    panel.add_child(col)
    return panel

func _build_tip() -> Control:
    var panel := Panel.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.custom_minimum_size = Vector2(320, 110)
    panel.add_theme_stylebox_override("panel", _card_box())
    var col := VBoxContainer.new()
    col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 12)
    col.add_child(_lbl("참고", 14, INK))
    var tip := _lbl("안전 구역은 시간이 지날수록 줄어듭니다. 마지막까지 생존하세요!", 14, MUTED)
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    col.add_child(tip)
    panel.add_child(col)
    return panel

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

var _animal_atlas: Texture2D = null

func _animal_portrait(index: int) -> Texture2D:
    if _animal_atlas == null and ResourceLoader.exists("res://assets/lhj/Tex_Animal_4x3.png"):
        _animal_atlas = load("res://assets/lhj/Tex_Animal_4x3.png")
    if _animal_atlas == null:
        return null
    var frame := int(LOBBY_ANIMAL_FRAME[posmod(index, LOBBY_ANIMAL_FRAME.size())])
    var cell := Vector2(float(_animal_atlas.get_width()) / 4.0, float(_animal_atlas.get_height()) / 3.0)
    var atlas := AtlasTexture.new()
    atlas.atlas = _animal_atlas
    atlas.region = Rect2(Vector2(float(frame % 4), float(int(frame / 4))) * cell, cell)
    return atlas


func _make_slot_card(index: int) -> Panel:
    var card := Panel.new()
    card.name = "Slot%d" % index
    card.custom_minimum_size = Vector2(168, 156)
    card.size = Vector2(168, 156)
    card.add_theme_stylebox_override("panel", _card_box())
    var col := VBoxContainer.new()
    col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 10)
    col.add_theme_constant_override("separation", 4)
    var row := HBoxContainer.new()
    var badge := ColorRect.new()
    badge.custom_minimum_size = Vector2(22, 22)
    badge.color = SLOT_COLORS[index]
    var num := _lbl(str(index + 1), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
    num.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    badge.add_child(num)
    var nick := _lbl(NICKS[index], 15, INK)
    nick.name = "Nick"
    row.add_child(badge)
    row.add_child(nick)
    var ready := _lbl("준비 완료", 13, GREEN)
    ready.name = "Ready"
    var portrait := _animal_portrait(index)
    var art: Control
    if portrait != null:
        var pic := TextureRect.new()
        pic.texture = portrait
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        pic.custom_minimum_size = Vector2(88, 88)
        pic.size_flags_horizontal = SIZE_EXPAND_FILL
        art = pic
    else:
        art = _lbl(ANIMALS[index], 28, SLOT_COLORS[index], HORIZONTAL_ALIGNMENT_CENTER)
    art.name = "Art"
    var kick := Button.new()
    kick.name = "Kick"
    kick.text = "내보내기"
    kick.visible = false
    kick.custom_minimum_size = Vector2(0, 26)
    kick.add_theme_font_size_override("font_size", 12)
    kick.add_theme_color_override("font_color", Color("C0392B"))
    kick.add_theme_color_override("font_hover_color", Color("C0392B"))
    kick.add_theme_color_override("font_pressed_color", Color("C0392B"))
    kick.add_theme_stylebox_override("normal", _card_box())
    kick.add_theme_stylebox_override("hover", _card_box())
    kick.add_theme_stylebox_override("pressed", _card_box())
    kick.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    kick.pressed.connect(func():
        if hub != null and hub.in_room:
            hub.kick_player(index)
    )
    col.add_child(row)
    col.add_child(ready)
    col.add_child(art)
    col.add_child(kick)
    card.add_child(col)
    return card

func _on_wait_mode_pressed(mode_id: String) -> void:
    selected_mode = mode_id
    if hub != null:
        hub.mode = mode_id
        if hub.in_room and hub.you == 0:
            hub.set_room_mode(mode_id)
    _sync_wait_modes()
    if _wait_mode_label != null:
        if hub != null and hub.in_room:
            _wait_mode_label.text = "%s  |  %s  |  최후의 1인이 승리합니다!" % [str(hub.room.get("title", "")), _mode_title(mode_id)]
        else:
            _wait_mode_label.text = "%s  |  오프라인 로컬  |  최후의 1인이 승리합니다!" % _mode_title(mode_id)

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
        var id := str(MODES[i]["id"])
        chip.disabled = guest_locked
        chip.set_pressed_no_signal(id == current)

func _fill_wait() -> void:
    var online: bool = hub != null and hub.in_room
    var count := 1
    if online:
        count = hub.players.size()
    var me_host: bool = online and hub.you >= 0 and hub.you < hub.players.size() and bool(hub.players[hub.you].get("host", false))
    for i in SLOT_COUNT:
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
                peer_name = "%s (나)" % peer_name
            nick.text = peer_name
            if bool(peer.get("dropped", false)):
                ready.text = "재접속 대기"
                ready.add_theme_color_override("font_color", Color("C0392B"))
            elif bool(peer.get("host", false)):
                ready.text = "호스트"
                ready.add_theme_color_override("font_color", BLUE)
            else:
                ready.text = "대기 중"
                ready.add_theme_color_override("font_color", GREEN)
        elif not online and i == 0:
            nick.text = "%s (나)" % _display_name()
            ready.text = "호스트"
            ready.add_theme_color_override("font_color", BLUE)
        else:
            nick.text = "CPU"
            ready.text = "시작 시 참여"
            ready.add_theme_color_override("font_color", MUTED)
    _count_label.text = "%d / 8" % count
    if _wait_mode_label != null:
        if online:
            _wait_mode_label.text = "%s  |  %s  |  최후의 1인이 승리합니다!" % [str(hub.room.get("title", "")), _mode_title(str(hub.room.get("mode", selected_mode)))]
        else:
            _wait_mode_label.text = "%s  |  오프라인 로컬  |  최후의 1인이 승리합니다!" % _mode_title(selected_mode)
    _sync_wait_modes()
    if _chat_log != null and _chat_log.get_total_character_count() == 0:
        if online:
            _chat_log.append_text("[color=#1F9D55][시스템] 방에 입장했습니다. %d/8명.[/color]\n" % count)
            _chat_log.append_text("[color=#6B7380][시스템] 호스트가 게임을 바꿀 수 있습니다. 빈 자리는 시작 시 CPU가 채웁니다.[/color]\n")
        else:
            _chat_log.append_text("[color=#6B7380][시스템] 오프라인 로컬 매치입니다. CPU 7명과 시작합니다.[/color]\n")
    _update_start_button()

func _update_start_button() -> void:
    if _start_button == null:
        return
    var online: bool = hub != null and hub.in_room
    if not online:
        _start_button.visible = true
        _start_button.text = "게임 시작"
        _start_hint.visible = false
    elif hub.match_running:
        _start_button.visible = true
        _start_button.text = "게임으로 돌아가기"
        _start_hint.visible = false
    elif hub.you == 0:
        _start_button.visible = true
        _start_button.text = "게임 시작"
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
    for i in SLOT_COUNT:
        var card: Control = _slot_host.get_node("Slot%d" % i)
        var ang := -PI * 0.5 + TAU * float(i) / float(SLOT_COUNT)
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
    var color: Color = SLOT_COLORS[slot] if slot >= 0 and slot < SLOT_COLORS.size() else INK
    var mine: bool = hub != null and slot == hub.you
    var shown := from_name + " (나)" if mine else from_name
    _chat_log.append_text("[color=#%s][b]%s[/b][/color]: %s\n" % [color.to_html(false), shown, text.replace("[", "[lb]")])
