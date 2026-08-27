extends RefCounted
## HudStrings 번역 테이블의 완전성과 i18n 동작을 검증한다.

func run(t) -> void:
	_locales_exist(t)
	_keys_match(t)
	_no_empty_values(t)
	_fallback_returns_key(t)
	_en_locale_works(t)
	_unknown_locale_falls_back(t)
	_zodiac_count(t)

func _locales_exist(t) -> void:
	t.check("ko locale 존재", HudStrings.STRINGS.has("ko"))
	t.check("en locale 존재", HudStrings.STRINGS.has("en"))

func _keys_match(t) -> void:
	var ko_keys: Array = HudStrings.STRINGS["ko"].keys()
	var en_keys: Array = HudStrings.STRINGS["en"].keys()
	ko_keys.sort()
	en_keys.sort()
	var missing_en: Array = []
	for key in ko_keys:
		if not HudStrings.STRINGS["en"].has(key):
			missing_en.append(key)
	var missing_ko: Array = []
	for key in en_keys:
		if not HudStrings.STRINGS["ko"].has(key):
			missing_ko.append(key)
	t.check("en 에 누락 키 없음: %s" % str(missing_en), missing_en.is_empty())
	t.check("ko 에 누락 키 없음: %s" % str(missing_ko), missing_ko.is_empty())

func _no_empty_values(t) -> void:
	for locale in ["ko", "en"]:
		var table: Dictionary = HudStrings.STRINGS[locale]
		for key in table.keys():
			var val := str(table[key]).strip_edges()
			t.check("%s.%s 빈 값 아님" % [locale, key], val != "")

func _fallback_returns_key(t) -> void:
	t.check("없는 키는 키 자체를 반환", HudStrings.t("_nonexistent_key_") == "_nonexistent_key_")

func _en_locale_works(t) -> void:
	HudStrings.set_locale("en")
	var rat := HudStrings.zodiac(0)
	t.check("en zodiac(0) = Rat", rat == "Rat")
	HudStrings.set_locale("ko")
	var rat_ko := HudStrings.zodiac(0)
	t.check("ko zodiac(0) = 쥐", rat_ko == "쥐") # lint-gd: i18n-ok

func _unknown_locale_falls_back(t) -> void:
	HudStrings.set_locale("xx")
	var val := HudStrings.t("default_name")
	HudStrings.set_locale("ko")
	var ko_val := HudStrings.t("default_name")
	t.check("미지원 locale 은 ko 폴백", val == ko_val)

func _zodiac_count(t) -> void:
	for locale in ["ko", "en"]:
		var count := 0
		var table: Dictionary = HudStrings.STRINGS[locale]
		for key in table.keys():
			if str(key).begins_with("zodiac_"):
				count += 1
		t.check("%s zodiac 12개" % locale, count == 12)
