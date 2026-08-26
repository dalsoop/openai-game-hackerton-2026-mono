class_name TextCache
extends RefCounted
## draw_string 매 호출 셰이핑을 TextLine 캐시로 대체한다. 키 = 문자열+폰트+크기+폭+정렬.

const MAX := 256

static var _lines: Dictionary = {}
static var _order: Array[String] = []


static func clear() -> void:
	_lines.clear()
	_order.clear()


static func count() -> int:
	return _lines.size()


static func get_line(text: String, font: Font, font_size: int, width: float = -1.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> TextLine:
	if font == null:
		return null
	var key := _key(text, font, font_size, width, alignment)
	if _lines.has(key):
		return _lines[key]
	var line := _make_line(text, font, font_size, width, alignment)
	_insert(key, line)
	return line


static func draw(ci: CanvasItem, pos: Vector2, text: String, font: Font, font_size: int, color: Color, width: float = -1.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if ci == null or font == null or text.is_empty():
		return
	var line := get_line(text, font, font_size, width, alignment)
	if line == null:
		return
	# TextLine.draw 원점은 상단, CanvasItem.draw_string 은 베이스라인.
	line.draw(ci.get_canvas_item(), pos - Vector2(0.0, line.get_line_ascent()), color)


static func _key(text: String, font: Font, font_size: int, width: float, alignment: HorizontalAlignment) -> String:
	return "%s\u001f%d\u001f%d\u001f%.4f\u001f%d" % [text, font.get_instance_id(), font_size, width, int(alignment)]


static func _make_line(text: String, font: Font, font_size: int, width: float, alignment: HorizontalAlignment) -> TextLine:
	var line := TextLine.new()
	line.alignment = alignment
	if width > 0.0:
		line.width = width
	line.add_string(text, font, font_size)
	return line


static func _insert(key: String, line: TextLine) -> void:
	if _order.size() >= MAX:
		var old: String = _order[0]
		_order.remove_at(0)
		_lines.erase(old)
	_lines[key] = line
	_order.append(key)
