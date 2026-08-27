extends Control
## 마우스 조준점 전용 오버레이. HUD 본체는 상태 해시 + 0.2초 스로틀로만 다시 그려서
## 마우스만 움직일 때 조준점이 5Hz 로 끊긴다 — 조준점만 여기서 매 프레임 다시 그린다.

var world

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if world == null or world.heroes.is_empty():
		return
	var me: Dictionary = world.heroes[clampi(int(world.local_slot), 0, world.heroes.size() - 1)]
	if me.is_empty():
		return
	var spray_i := float(me.get("spray_index", 0.0))
	var c: Vector2 = get_local_mouse_position()
	var climb := spray_i * 3.2
	var gap := 8.0 + climb * 0.10
	var arm := 11.0
	var ink := Color(0.12, 0.07, 0.04, 0.92)
	var fill := Color(1.0, 0.96, 0.86, 0.96)
	var accent := Color(1.0, 0.55, 0.22, 0.95)
	for thick in [3.4, 1.6]:
		var col := ink if thick > 2.0 else fill
		draw_circle(c, 2.6 if thick > 2.0 else 1.7, col if thick > 2.0 else accent)
		draw_line(c + Vector2(0, -gap - arm), c + Vector2(0, -gap), col, thick)
		draw_line(c + Vector2(0, gap), c + Vector2(0, gap + arm), col, thick)
		draw_line(c + Vector2(-gap - arm, 0), c + Vector2(-gap, 0), col, thick)
		draw_line(c + Vector2(gap, 0), c + Vector2(gap + arm, 0), col, thick)
	draw_arc(c, 5.0 + climb * 0.04, 0.0, TAU, 28, Color(accent, 0.45), 1.4)
