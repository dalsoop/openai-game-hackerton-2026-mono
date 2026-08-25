extends Control
## 스파링 최소 HUD — 셸 계약(ctx.hud: Control)을 만족하는 오버레이.

var world = null
var mode_id := ""
var spectate_slot := 0
var hud_mode := 0
var net_rtt_ms := 0
var net_connected := false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if net_rtt_ms <= 0:
		return
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(16.0, 28.0), "%dms" % net_rtt_ms, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#70e7ff"))
