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
var _dash = null
var _ult = null

var move: Vector2:
    get:
        return _move_stick.output if _move_stick != null else Vector2.ZERO
var aim_dir: Vector2:
    get:
        return _aim_stick.output if _aim_stick != null else Vector2.ZERO
var aiming: bool:
    get:
        return _aim_stick != null and _aim_stick.active and _aim_stick.output.length() > AIM_DEADZONE
## 손을 뗀 뒤에도 남는 마지막 조준 방향. 탭 발사와 바라보는 방향이 이걸 쓴다.
var aim_last: Vector2:
    get:
        return _aim_stick.last_dir if _aim_stick != null else Vector2.RIGHT
## 조준 스틱을 밀고 있으면 그게 곧 발사다. 공격 버튼은 없앴다.
var fire: bool:
    get:
        return _aim_stick != null and _aim_stick.output.length() > AIM_DEADZONE
var dash_held: bool:
    get:
        return _dash != null and _dash.held
var ult_held: bool:
    get:
        return _ult != null and _ult.held
## 스킬·약 버튼은 뺐다. 이 패드를 함께 쓰는 다른 앱이 읽으므로 이름은 남긴다.
var skill: bool:
    get:
        return false
var medkit_held: bool:
    get:
        return false

const TouchPolicy := preload("res://core/contract/touch_policy.gd")

func _ready() -> void:
    layer = 2
    _platform_ok = TouchPolicy.wants_overlay(
        OS.has_feature("mobile"),
        OS.has_feature("web"),
        _pointer_is_coarse(),
    )
    _build()
    _apply_visibility()

func _pointer_is_coarse() -> bool:
    if OS.has_feature("web"):
        var raw := str(JavaScriptBridge.eval(
            "window.matchMedia && window.matchMedia('(pointer: coarse)').matches ? '1' : '0'",
            true))
        return raw == "1"
    return DisplayServer.is_touchscreen_available()

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

func consume_ult() -> bool:
    return _ult != null and _ult.consume_press()

## 조준 스틱을 밀지 않고 툭 치면 마지막 방향으로 한 발.
func consume_aim_tap() -> bool:
    return _aim_stick != null and _aim_stick.consume_tap()

func consume_medkit() -> bool:
    return false

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
    for node in [_move_stick, _aim_stick, _dash, _ult]:
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
    _aim_stick.show_aim_indicator = true
    # 대시·궁은 조준 스틱(좌측 경계 x≈1246) 바깥에 둬서 엄지가 짧게 닿되 히트박스는 안 겹치게.
    _dash = _make_button("대시", Vector2(1130.0, 762.0), 54.0, Color("#66e09a"), font)
    _ult = _make_button("궁", Vector2(1096.0, 606.0), 58.0, Color("#ff5d91"), font)

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
