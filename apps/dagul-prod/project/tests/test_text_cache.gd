extends RefCounted
## 텍스트 셰이핑 캐시 — 같은 키 재사용, 상한 256, 전량 비우기.

const TextCacheScript := preload("res://games/dagul/render/text_cache.gd")


func run(t) -> void:
	TextCacheScript.clear()
	var font := ThemeDB.fallback_font
	t.check("clear starts empty", TextCacheScript.count() == 0)
	var line_a: TextLine = TextCacheScript.get_line("P1 쥐", font, 14, 144.0, HORIZONTAL_ALIGNMENT_CENTER)
	var line_b: TextLine = TextCacheScript.get_line("P1 쥐", font, 14, 144.0, HORIZONTAL_ALIGNMENT_CENTER)
	t.check("same key returns same object", line_a != null and line_a == line_b)
	var line_size: TextLine = TextCacheScript.get_line("P1 쥐", font, 16, 144.0, HORIZONTAL_ALIGNMENT_CENTER)
	t.check("font size is part of key", line_size != null and line_size != line_a)
	t.check("distinct keys counted", TextCacheScript.count() == 2)
	_fill_to_cap(font)
	t.check("cap stays at 256", TextCacheScript.count() == TextCacheScript.MAX)
	var after: TextLine = TextCacheScript.get_line("P1 쥐", font, 14, 144.0, HORIZONTAL_ALIGNMENT_CENTER)
	t.check("evicted key is a new object", after != null and after != line_a)
	t.check("cap holds after reinsert", TextCacheScript.count() == TextCacheScript.MAX)
	TextCacheScript.clear()
	t.check("clear empties cache", TextCacheScript.count() == 0)
	var again: TextLine = TextCacheScript.get_line("P1 쥐", font, 14, 144.0, HORIZONTAL_ALIGNMENT_CENTER)
	t.check("after clear still shapes", again != null)
	TextCacheScript.clear()


func _fill_to_cap(font: Font) -> void:
	for index in range(TextCacheScript.MAX + 8):
		TextCacheScript.get_line("n%d" % index, font, 12, -1.0, HORIZONTAL_ALIGNMENT_LEFT)
