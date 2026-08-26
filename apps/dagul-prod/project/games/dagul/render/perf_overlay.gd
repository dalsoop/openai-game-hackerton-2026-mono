class_name PerfOverlay
extends Control
## 인게임 프레임 프로파일. F3 토글, 기본 꺼짐. 텍스트는 0.25초마다만 갱신.

const TextCacheScript = preload("res://games/dagul/render/text_cache.gd")
const SAMPLE_N := 120
const REFRESH_SEC := 0.25
const LS_KEY := "dagul.perf"

var enabled := false
var _samples: PackedFloat32Array = PackedFloat32Array()
var _sample_i := 0
var _sample_filled := 0
var _refresh_left := 0.0
var _line1 := ""
var _line2 := ""
var _dpr := 1.0
var _backing := "0x0"


static func boot_on_from_ls(raw: String) -> bool:
	return raw.strip_edges() == "1"


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_samples.resize(SAMPLE_N)
	_query_display_once()
	set_enabled(boot_on_from_ls(_read_ls(LS_KEY)))


func toggle() -> void:
	set_enabled(not enabled)


func set_enabled(on: bool) -> void:
	enabled = on
	visible = on
	set_process(on)
	if on:
		_refresh_left = 0.0


func _process(delta: float) -> void:
	if not enabled:
		return
	_push_ms(delta * 1000.0)
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = REFRESH_SEC
	_rebuild_text()


func _draw() -> void:
	if not enabled or _line1.is_empty():
		return
	var font := GameFont.get_font()
	if font == null:
		return
	draw_rect(Rect2(8.0, 8.0, 780.0, 44.0), Color(UiTheme.INTRO_BG, 0.78))
	TextCacheScript.draw(self, Vector2(16.0, 26.0), _line1, font, 13, UiTheme.BANNER_TEXT)
	TextCacheScript.draw(self, Vector2(16.0, 44.0), _line2, font, 13, UiTheme.BANNER_TEXT)


func _push_ms(ms: float) -> void:
	if _samples.size() != SAMPLE_N:
		_samples.resize(SAMPLE_N)
	_samples[_sample_i] = ms
	_sample_i = (_sample_i + 1) % SAMPLE_N
	if _sample_filled < SAMPLE_N:
		_sample_filled += 1


func _rebuild_text() -> void:
	var stats := _sample_stats()
	var proc_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_line1 = "%.1fms avg  %.1fms max  proc %.1f  phys %.1f  dpr %.2f  %s" % [
		stats.x, stats.y, proc_ms, phys_ms, _dpr, _backing]
	_line2 = "draws %d  prim %d  nodes %d" % [draws, prims, nodes]
	queue_redraw()


func _sample_stats() -> Vector2:
	if _sample_filled <= 0:
		return Vector2.ZERO
	var total := 0.0
	var mx := 0.0
	for i in range(_sample_filled):
		var ms: float = _samples[i]
		total += ms
		if ms > mx:
			mx = ms
	return Vector2(total / float(_sample_filled), mx)


func _query_display_once() -> void:
	if OS.has_feature("web"):
		_parse_web_metrics(_eval_js(_web_metrics_js()))
		return
	_dpr = DisplayServer.screen_get_scale()
	var sz := DisplayServer.window_get_size()
	_backing = "%dx%d" % [sz.x, sz.y]


func _web_metrics_js() -> String:
	return "try{var c=document.querySelector('canvas');(window.devicePixelRatio||1)+' '+(c?(c.width+'x'+c.height):'0x0')}catch(e){'1 0x0'}"


func _parse_web_metrics(raw: String) -> void:
	var text := raw.strip_edges()
	if text == "" or text == "<null>" or text == "null" or text == "undefined":
		_dpr = 1.0
		_backing = "0x0"
		return
	var parts := text.split(" ", false)
	_dpr = float(parts[0])
	_backing = parts[1] if parts.size() > 1 else "0x0"


func _read_ls(key: String) -> String:
	if not OS.has_feature("web"):
		return ""
	var text := _eval_js("try{sessionStorage.getItem('%s')||''}catch(e){''}" % key)
	if text == "<null>" or text == "null" or text == "undefined":
		return ""
	return text


func _eval_js(expr: String) -> String:
	return str(JavaScriptBridge.eval(expr, true)).strip_edges()
