extends CanvasLayer

const VirtualStickScript = preload("res://addons/godot-touch-controls/virtual_stick.gd")
const ActionButtonScript = preload("res://addons/godot-touch-controls/action_button.gd")

const AIM_RANGE := 400.0
const STICK_RADIUS := 125.0
const AIM_DEADZONE := 0.12

var _playing := false
var _platform_ok := false
var _control_mode := "auto"
var _root: Control = null
var _move_stick = null
var _aim_stick = null
var _fire = null
var _skill = null
var _dash = null
var _ult = null
var _medkit = null

var move: Vector2:
    get:
        return _move_stick.output if _move_stick != null else Vector2.ZERO
var aim_dir: Vector2:
    get:
        return _aim_stick.output if _aim_stick != null else Vector2.ZERO
var aiming: bool:
    get:
        return _aim_stick != null and _aim_stick.active and _aim_stick.output.length() > AIM_DEADZONE
var fire: bool:
    get:
        return _fire != null and _fire.held
var skill: bool:
    get:
        return _skill != null and _skill.held
var dash_held: bool:
    get:
        return _dash != null and _dash.held
var medkit_held: bool:
    get:
        return _medkit != null and _medkit.held
var ult_held: bool:
    get:
        return _ult != null and _ult.held

func _ready() -> void:
    layer = 2
    _platform_ok = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or OS.has_feature("web")
    _build()
    _apply_visibility()

func set_playing(playing: bool) -> void:
    _playing = playing
    _apply_visibility()

func set_control_mode(mode: String) -> void:
    _control_mode = mode
    _apply_visibility()

func is_enabled() -> bool:
    match _control_mode:
        "keyboard":
            return false
        "touch":
            return true
        _:
            return _platform_ok

func consume_dash() -> bool:
    return _dash != null and _dash.consume_press()

func consume_medkit() -> bool:
    return _medkit != null and _medkit.consume_press()

func consume_ult() -> bool:
    return _ult != null and _ult.consume_press()

static func resolve_font() -> Font:
    for entry in ProjectSettings.get_global_class_list():
        if str(entry.get("class", "")) == "GameFont":
            var script: Script = load(str(entry.get("path", "")))
            if script != null:
                var font: Variant = script.call("get_font")
                if font is Font:
                    return font
    var custom := str(ProjectSettings.get_setting("gui/theme/custom_font", ""))
    if custom != "" and ResourceLoader.exists(custom):
        var loaded: Variant = load(custom)
        if loaded is Font:
            return loaded
    return ThemeDB.fallback_font

func _apply_visibility() -> void:
    var show := _playing and is_enabled()
    visible = show
    if not show:
        _release_all()

func _release_all() -> void:
    for node in [_move_stick, _aim_stick, _fire, _skill, _dash, _ult, _medkit]:
        if node != null:
            node.reset()

func _build() -> void:
    _root = Control.new()
    _root.name = "TouchRoot"
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_root)
    var font := resolve_font()
    _move_stick = _make_stick(Vector2(215.0, 695.0))
    _aim_stick = _make_stick(Vector2(1385.0, 695.0))
    _fire = _make_button("공격", Vector2(1150.0, 680.0), 66.0, Color("#ffd166"), font)
    _skill = _make_button("스킬", Vector2(1220.0, 530.0), 48.0, Color("#fa7921"), font)
    _dash = _make_button("대시", Vector2(1050.0, 525.0), 50.0, Color("#66e09a"), font)
    _ult = _make_button("궁", Vector2(918.0, 700.0), 48.0, Color("#ff5d91"), font)
    _medkit = _make_button("약", Vector2(918.0, 560.0), 44.0, Color("#6ef3a5"), font)

func _make_stick(center: Vector2) -> Control:
    var stick: Control = VirtualStickScript.new()
    stick.base_radius = STICK_RADIUS
    var side := (STICK_RADIUS + 14.0) * 2.0
    _root.add_child(stick)
    stick.position = center - Vector2(side, side) * 0.5
    stick.size = Vector2(side, side)
    return stick

func _make_button(caption: String, center: Vector2, radius: float, accent: Color, font: Font) -> Control:
    var button: Control = ActionButtonScript.new()
    button.caption = caption
    button.accent = accent
    _root.add_child(button)
    var side := radius * 2.0
    button.position = center - Vector2(side, side) * 0.5
    button.size = Vector2(side, side)
    button.set_font(font)
    return button
