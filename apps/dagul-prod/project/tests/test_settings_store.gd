extends RefCounted
## SettingsStore 정규화 — 모르는 모드는 자동으로 떨어진다.

const Store := preload("res://core/ui/settings_store.gd")
const Ui := preload("res://core/ui/ui_theme.gd")

func run(t) -> void:
	t.check("자동은 유지", Store.normalize_mode("auto") == Store.MODE_AUTO)
	t.check("키보드는 유지", Store.normalize_mode("keyboard") == Store.MODE_KEYBOARD)
	t.check("터치는 유지", Store.normalize_mode("touch") == Store.MODE_TOUCH)
	t.check("빈 값은 자동", Store.normalize_mode("") == Store.MODE_AUTO)
	t.check("모르는 값은 자동", Store.normalize_mode("pad") == Store.MODE_AUTO)
	t.check("제목은 한국어", Store.mode_title("keyboard") == "PC 키보드형")
	t.check("효과음 기본은 켜짐", Store.load_sound_on() == true)
	Store.save_onboarding_hide(true)
	t.check("온보딩 숨김을 기록한다", Store.load_onboarding_hide() == true)
	Store.save_onboarding_hide(false)
	t.check("온보딩을 다시 켠다", Store.load_onboarding_hide() == false)
	var tex := Ui.gear_texture(40)
	t.check("설정 아이콘 텍스처", tex != null and tex.get_width() == 40)
	var gear := Ui.flat_icon_btn(tex, Vector2(40, 40))
	t.check("설정은 글자 없는 아이콘", gear.text == "" and gear.icon != null)
