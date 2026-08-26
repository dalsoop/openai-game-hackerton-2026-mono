extends RefCounted
## SettingsStore 정규화 — 모르는 모드는 자동으로 떨어진다.

const Store := preload("res://core/ui/settings_store.gd")

func run(t) -> void:
	t.check("자동은 유지", Store.normalize_mode("auto") == Store.MODE_AUTO)
	t.check("키보드는 유지", Store.normalize_mode("keyboard") == Store.MODE_KEYBOARD)
	t.check("터치는 유지", Store.normalize_mode("touch") == Store.MODE_TOUCH)
	t.check("빈 값은 자동", Store.normalize_mode("") == Store.MODE_AUTO)
	t.check("모르는 값은 자동", Store.normalize_mode("pad") == Store.MODE_AUTO)
	t.check("제목은 한국어", Store.mode_title("keyboard") == "PC 키보드형")
	t.check("효과음 기본은 켜짐", Store.load_sound_on() == true)
