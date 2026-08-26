class_name SettingsStore
extends RefCounted

const PATH := "user://settings.cfg"
const SECTION := "input"
const HELP_SECTION := "help"
const ONBOARDING_HIDE_KEY := "onboarding_hide"
const WEB_TUTORIAL_KEY := "dagul_tutorial_done"
const LEGACY_TUTORIAL_PATH := "user://tutorial_done.txt"
const MODE_AUTO := "auto"
const MODE_KEYBOARD := "keyboard"
const MODE_TOUCH := "touch"
const MODES := [MODE_AUTO, MODE_KEYBOARD, MODE_TOUCH]

static func normalize_mode(mode: String) -> String:
    return mode if mode in MODES else MODE_AUTO


static func load_control_mode() -> String:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK:
        return MODE_AUTO
    return normalize_mode(str(cfg.get_value(SECTION, "control_mode", MODE_AUTO)))

static func load_sound_on() -> bool:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK:
        return true
    return bool(cfg.get_value("audio", "sound_on", true))

static func save(control_mode: String, sound_on: bool) -> void:
    var cfg := ConfigFile.new()
    cfg.load(PATH)
    cfg.set_value(SECTION, "control_mode", normalize_mode(control_mode))
    cfg.set_value("audio", "sound_on", sound_on)
    cfg.save(PATH)


static func load_onboarding_hide() -> bool:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) == OK and cfg.has_section_key(HELP_SECTION, ONBOARDING_HIDE_KEY):
        return bool(cfg.get_value(HELP_SECTION, ONBOARDING_HIDE_KEY, false))
    return _legacy_onboarding_done()


static func save_onboarding_hide(hide: bool) -> void:
    var cfg := ConfigFile.new()
    cfg.load(PATH)
    cfg.set_value(HELP_SECTION, ONBOARDING_HIDE_KEY, hide)
    cfg.save(PATH)
    _write_legacy_onboarding(hide)


static func _legacy_onboarding_done() -> bool:
    if OS.has_feature("web"):
        var val = JavaScriptBridge.eval("try{localStorage.getItem('%s')||''}catch(e){''}" % WEB_TUTORIAL_KEY, true)
        var raw := str(val).strip_edges()
        return raw != "" and raw != "null" and raw != "<null>"
    return FileAccess.file_exists(LEGACY_TUTORIAL_PATH)


static func _write_legacy_onboarding(hide: bool) -> void:
    if OS.has_feature("web"):
        if hide:
            JavaScriptBridge.eval("try{localStorage.setItem('%s','1')}catch(e){}" % WEB_TUTORIAL_KEY)
        else:
            JavaScriptBridge.eval("try{localStorage.removeItem('%s')}catch(e){}" % WEB_TUTORIAL_KEY)
        return
    if hide:
        var f := FileAccess.open(LEGACY_TUTORIAL_PATH, FileAccess.WRITE)
        if f != null:
            f.store_string("1")
        return
    var folder := DirAccess.open("user://")
    if folder != null and folder.file_exists("tutorial_done.txt"):
        folder.remove("tutorial_done.txt")

static func mode_title(mode: String) -> String:
    match mode:
        MODE_KEYBOARD:
            return "PC 키보드형"
        MODE_TOUCH:
            return "모바일형"
        _:
            return "자동"

static func mode_desc(mode: String) -> String:
    match mode:
        MODE_KEYBOARD:
            return "WASD 이동 · 마우스 조준 · 가상 스틱/버튼 숨김"
        MODE_TOUCH:
            return "화면 스틱/버튼 항상 표시 · 키보드도 함께 사용 가능"
        _:
            return "기기에 맞춰 결정 (모바일·거친 포인터면 모바일형)"
