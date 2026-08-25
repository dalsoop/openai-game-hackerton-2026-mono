class_name SettingsStore
extends RefCounted

const PATH := "user://settings.cfg"
const SECTION := "input"
const MODE_AUTO := "auto"
const MODE_KEYBOARD := "keyboard"
const MODE_TOUCH := "touch"
const MODES := [MODE_AUTO, MODE_KEYBOARD, MODE_TOUCH]

static func load_control_mode() -> String:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK:
        return MODE_AUTO
    var mode := str(cfg.get_value(SECTION, "control_mode", MODE_AUTO))
    return mode if mode in MODES else MODE_AUTO

static func load_sound_on() -> bool:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK:
        return true
    return bool(cfg.get_value("audio", "sound_on", true))

static func save(control_mode: String, sound_on: bool) -> void:
    var cfg := ConfigFile.new()
    cfg.load(PATH)
    cfg.set_value(SECTION, "control_mode", control_mode)
    cfg.set_value("audio", "sound_on", sound_on)
    cfg.save(PATH)

static func mode_title(mode: String) -> String:
    match mode:
        MODE_KEYBOARD:
            return tr("CONTROL_PC")
        MODE_TOUCH:
            return tr("CONTROL_MOBILE")
        _:
            return tr("CONTROL_AUTO")

static func mode_desc(mode: String) -> String:
    match mode:
        MODE_KEYBOARD:
            return tr("CONTROL_PC_DESC")
        MODE_TOUCH:
            return tr("CONTROL_MOBILE_DESC")
        _:
            return tr("CONTROL_AUTO_DESC")
