class_name SettingsStore
extends RefCounted

const PATH := "user://settings.cfg"
const SECTION := "input"
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

static func mode_title(mode: String) -> String:
    match mode:
        MODE_KEYBOARD:
            return HudStrings.t("mode_keyboard")
        MODE_TOUCH:
            return HudStrings.t("mode_touch")
        _:
            return HudStrings.t("mode_auto")

static func mode_desc(mode: String) -> String:
    match mode:
        MODE_KEYBOARD:
            return HudStrings.t("mode_keyboard_desc")
        MODE_TOUCH:
            return HudStrings.t("mode_touch_desc")
        _:
            return HudStrings.t("mode_auto_desc")
