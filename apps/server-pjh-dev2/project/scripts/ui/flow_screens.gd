extends Control

signal start_match
signal request_quit_to_intro
signal request_resume

const BG := Color("F5F2EA")
const INK := Color("1C2430")
const MUTED := Color("6B7380")
const CARD := Color("FFFDF8")
const LINE := Color("E4DDD2")
const BLUE := Color("2F6BFF")
const GREEN := Color("1F9D55")
const SLOT_COUNT := 8
const ANIMALS := ["토끼", "쥐", "호랑이", "황소", "용", "말", "닭", "돼지"]
const NICKS := ["토토", "찍찍", "호랑", "황소", "용용", "말말", "꼬끼오", "꿀꿀"]
const SLOT_COLORS := [
    Color("5bc0eb"), Color("9bc53d"), Color("e55934"), Color("fa7921"),
    Color("b084cc"), Color("70e7ff"), Color("ffd166"), Color("ff8dac")
]
const MODES := [
    {"id":"classic", "title":"클래식", "desc":"시작부터 각자 다른 총. 필드 힐만.", "art":"mode_classic.png"},
    {"id":"gun-semi", "title":"단발", "desc":"모두 단발 권총 시작. 처치 시 총 업그레이드.", "art":"mode_gun_semi.png"},
    {"id":"gun-auto", "title":"연발", "desc":"모두 연발 권총 시작. 처치 시 총 업그레이드.", "art":"mode_gun_auto.png"},
    {"id":"item", "title":"아이템", "desc":"같은 총 고정. 메드킷을 주워 E로 사용.", "art":"mode_item.png"},
    {"id":"full", "title":"풀", "desc":"랜덤 총 + 메드킷 루팅 + 처치 시 총 업그레이드.", "art":"mode_full.png"},
]

var page := &"lobby"
var selected_mode := "classic"
var sound_on := true
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
var _mode_buttons: Array[Button] = []
var _wait_mode_buttons: Array[Button] = []
var _how_return: StringName = &"lobby"
var _pending_create := false

func _ready() -> void:
    set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    mouse_filter = MOUSE_FILTER_STOP
    var t := Theme.new()
    t.default_font = GameFont.get_font()
    theme = t
    _build()
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
            show_page(&"wait")
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

func _full(node: Control) -> Control:
    node.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    return node

func _lbl(text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = align
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l

func _btn(text: String, bg: Color, min_size: Vector2) -> Button:
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

func _icon_btn(caption: String) -> Button:
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

func _card_box() -> StyleBoxFlat:
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

func _load_png(filename: String) -> Texture2D:
    var res_path := "res://assets/ui/%s" % filename
    if ResourceLoader.exists(res_path):
        return load(res_path)
    var abs_path := ProjectSettings.globalize_path(res_path)
    if FileAccess.file_exists(abs_path):
        var img := Image.load_from_file(abs_path)
        if img != null:
            return ImageTexture.create_from_image(img)
    return null

func _mode_title(mode_id: String) -> String:
    for mode in MODES:
        if str(mode["id"]) == mode_id:
            return str(mode["title"])
    return mode_id

func _build_select() -> Control:
    var root := _full(Control.new())
    var col := VBoxContainer.new()
    col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 28)
    col.add_theme_constant_override("separation", 14)
    var head := HBoxContainer.new()
    var titles := VBoxContainer.new()
    titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    titles.add_child(_lbl("모드 선택", 14, MUTED))
    titles.add_child(_lbl("다굴", 32, INK))
    titles.add_child(_lbl("방 안에서 게임을 고를 수 있습니다.", 15, MUTED))
    head.add_child(titles)
    var how := _icon_btn("?")
    how.pressed.connect(func(): show_page(&"how"))
    head.add_child(how)
    col.add_child(head)
    var banner := TextureRect.new()
    banner.custom_minimum_size = Vector2(0, 160)
    banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    var banner_tex := _load_png("banner_select.png")
    if banner_tex != null:
        banner.texture = banner_tex
    else:
        var fallback := ColorRect.new()
        fallback.custom_minimum_size = Vector2(0, 160)
        fallback.color = Color("E8E0D2")
        col.add_child(fallback)
    if banner_tex != null:
        col.add_child(banner)
    var grid := HBoxContainer.new()
    grid.add_theme_constant_override("separation", 12)
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _mode_buttons.clear()
    var group := ButtonGroup.new()
    for mode in MODES:
        var card := _make_mode_card(mode)
        card.button_group = group
        grid.add_child(card)
    col.add_child(grid)
    var go := _btn("이 모드로 로비 입장", BLUE, Vector2(280, 58))
    go.pressed.connect(func(): show_page(&"lobby"))
    col.add_child(go)
    root.add_child(col)
    return root

func _make_mode_card(mode: Dictionary) -> Button:
    var card := Button.new()
    card.toggle_mode = true
    card.button_pressed = str(mode["id"]) == selected_mode
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.custom_minimum_size = Vector2(180, 260)
    var sb := _card_box()
    card.add_theme_stylebox_override("normal", sb)
    var on := sb.duplicate()
    on.border_color = BLUE
    on.border_width_left = 3
    on.border_width_top = 3
    on.border_width_right = 3
    on.border_width_bottom = 3
    card.add_theme_stylebox_override("pressed", on)
    card.add_theme_stylebox_override("hover", on)
    card.add_theme_color_override("font_color", Color(0, 0, 0, 0))
    var inner := VBoxContainer.new()
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inner.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 12)
    inner.add_theme_constant_override("separation", 8)
    var art := TextureRect.new()
    art.custom_minimum_size = Vector2(0, 140)
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var tex := _load_png(str(mode["art"]))
    if tex != null:
        art.texture = tex
    inner.add_child(art)
    inner.add_child(_lbl(str(mode["title"]), 20, INK, HORIZONTAL_ALIGNMENT_CENTER))
    var desc := _lbl(str(mode["desc"]), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inner.add_child(desc)
    card.add_child(inner)
    var mode_id := str(mode["id"])
    card.pressed.connect(func(): _pick_mode(mode_id))
    _mode_buttons.append(card)
    return card

func _pick_mode(mode_id: String) -> void:
    selected_mode = mode_id
    for i in _mode_buttons.size():
        _mode_buttons[i].button_pressed = str(MODES[i]["id"]) == selected_mode

func _build_intro() -> Control:
    var root := _full(Control.new())
    var col := VBoxContainer.new()
    col.set_anchors_preset(PRESET_CENTER)
    col.offset_left = -420
    col.offset_right = 420
    col.offset_top = -220
    col.offset_bottom = 220
    col.add_theme_constant_override("separation", 16)
    var kicker := _lbl("최대 8인 난전 서바이벌", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    var title := _lbl("다굴", 72, INK, HORIZONTAL_ALIGNMENT_CENTER)
    var tag := _lbl("강해 보이는 순간, 모두의 적이 된다", 22, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 14)
    var play := _btn("로비 입장", BLUE, Vector2(240, 64))
    play.pressed.connect(func(): show_page(&"lobby"))
    var how := _btn("조작 설명", Color("3D4654"), Vector2(180, 64))
    how.pressed.connect(func(): show_page(&"how"))
    row.add_child(play)
    row.add_child(how)
    col.add_child(kicker)
    col.add_child(title)
    col.add_child(tag)
    col.add_child(row)
    root.add_child(col)
    return root

func _build_how() -> Control:
    var root := _full(Control.new())
    var panel := Panel.new()
    panel.set_anchors_preset(PRESET_CENTER)
    panel.offset_left = -460
    panel.offset_right = 460
    panel.offset_top = -280
    panel.offset_bottom = 280
    panel.add_theme_stylebox_override("panel", _card_box())
    var col := VBoxContainer.new()
    col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 28)
    col.add_theme_constant_override("separation", 10)
    col.add_child(_lbl("로비  >  조작", 14, MUTED))
    col.add_child(_lbl("조작", 28, INK))
    for line in [
        "가로 화면 기준입니다.",
        "키보드: WASD 이동  ·  마우스 조준",
        "터치: 왼쪽 스틱 이동  ·  오른쪽 스틱 조준",
        "LMB / 공격 버튼 기본 공격  ·  RMB / 스킬 버튼",
        "SPACE / 대시 버튼 이동기  ·  Q / 궁 버튼 궁극기  ·  E / 약 버튼 메드킷",
        "최후의 1인이 이깁니다. 안전 구역은 줄어듭니다.",
    ]:
        col.add_child(_lbl(line, 18, MUTED))
    var back := _btn("뒤로", Color("3D4654"), Vector2(140, 48))
    back.pressed.connect(func(): pop_page())
    col.add_child(back)
    panel.add_child(col)
    root.add_child(panel)
    return root

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
    gear.pressed.connect(func(): show_page(&"settings"))
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
        var chip := Button.new()
        chip.toggle_mode = true
        chip.button_group = wait_group
        chip.text = str(mode["title"])
        chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        chip.custom_minimum_size = Vector2(0, 46)
        chip.add_theme_color_override("font_color", INK)
        var chip_off := _card_box()
        chip.add_theme_stylebox_override("normal", chip_off)
        var chip_on := chip_off.duplicate()
        chip_on.border_color = BLUE
        chip_on.border_width_left = 3
        chip_on.border_width_top = 3
        chip_on.border_width_right = 3
        chip_on.border_width_bottom = 3
        chip.add_theme_stylebox_override("pressed", chip_on)
        chip.add_theme_stylebox_override("hover", chip_on)
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

func _build_settings() -> Control:
    var root := _full(Control.new())
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.28)
    dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
    dim.gui_input.connect(func(ev):
        if ev is InputEventMouseButton and ev.pressed:
            show_page(&"wait")
    )
    root.add_child(dim)
    var panel := Panel.new()
    panel.set_anchors_preset(PRESET_CENTER)
    panel.offset_left = -220
    panel.offset_right = 220
    panel.offset_top = -120
    panel.offset_bottom = 120
    panel.add_theme_stylebox_override("panel", _card_box())
    var col := VBoxContainer.new()
    col.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 24)
    col.add_theme_constant_override("separation", 14)
    col.add_child(_lbl("로비  >  방  >  설정", 13, MUTED))
    col.add_child(_lbl("설정", 24, INK))
    var sound := CheckButton.new()
    sound.text = "소리"
    sound.button_pressed = true
    sound.toggled.connect(func(on): sound_on = on; AudioServer.set_bus_mute(0, not on))
    col.add_child(sound)
    var back := _btn("대기실로", Color("3D4654"), Vector2(160, 44))
    back.pressed.connect(func(): show_page(&"wait"))
    var intro := Button.new()
    intro.text = "로비로"
    intro.pressed.connect(func(): _quit_to_select())
    col.add_child(back)
    col.add_child(intro)
    panel.add_child(col)
    root.add_child(panel)
    return root

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
    var art := _lbl(ANIMALS[index], 28, SLOT_COLORS[index], HORIZONTAL_ALIGNMENT_CENTER)
    art.name = "Art"
    col.add_child(row)
    col.add_child(ready)
    col.add_child(art)
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
    for i in SLOT_COUNT:
        var card: Panel = _slot_host.get_node("Slot%d" % i)
        var nick: Label = card.find_child("Nick", true, false)
        var ready: Label = card.find_child("Ready", true, false)
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

func _quit_to_select() -> void:
    if hub != null and hub.in_room:
        hub.leave_room()
    show_page(&"lobby")
    request_quit_to_intro.emit()

func _send_chat(text: String) -> void:
    var t := text.strip_edges()
    if t.is_empty():
        return
    _chat_log.append_text("%s: %s\n" % [_display_name(), t])
