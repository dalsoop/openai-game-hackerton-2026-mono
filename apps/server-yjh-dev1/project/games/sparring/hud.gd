extends Control
## 스파링 최소 HUD — 셸 계약(ctx.hud: Control)을 만족하는 빈 오버레이.
## 셸·게임이 참조 가능한 필드만 갖춘다 (렌더 없음).

var world = null
var mode_id := ""
var spectate_slot := 0
var hud_mode := 0
var net_rtt_ms := 0
var net_connected := false
