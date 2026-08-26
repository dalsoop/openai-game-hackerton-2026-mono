class_name TutorialOverlay
extends Control

const LayoutKeysScript := preload("res://core/input/layout_keys.gd")

const HINTS := {
	"hit": "피격! Shift로 대시해서 벗어나세요",
	"down": "다운! WASD로 기어가세요. 곧 부활합니다",
	"outside_zone": "세이프존 밖! 안쪽으로 이동하세요",
	"ultimate_ready": "궁극기 준비! Q를 누르세요",
}

var _hints_shown: Dictionary = {}
var _hint_text: String = ""
var _hint_time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

func show_hint(hint_id: String) -> void:
	if _hints_shown.has(hint_id):
		return
	if not HINTS.has(hint_id):
		return
	_hints_shown[hint_id] = true
	if hint_id == "down":
		_hint_text = "다운! %s%s%s%s 자리로 기어가세요. 곧 부활합니다" % [
			LayoutKeysScript.seat_label(KEY_W), LayoutKeysScript.seat_label(KEY_A),
			LayoutKeysScript.seat_label(KEY_S), LayoutKeysScript.seat_label(KEY_D),
		]
	elif hint_id == "ultimate_ready":
		_hint_text = "궁극기 준비! %s를 누르세요" % LayoutKeysScript.seat_label(KEY_Q)
	else:
		_hint_text = HINTS[hint_id]
	_hint_time = 4.0

func _process(delta: float) -> void:
	if _hint_time > 0.0:
		_hint_time -= delta
	queue_redraw()

func _draw() -> void:
	if _hint_time <= 0.0 or _hint_text == "":
		return
	var alpha := clampf(_hint_time, 0.0, 1.0)
	var cx := size.x * 0.5
	var w := 400.0
	draw_rect(Rect2(cx - w * 0.5, 16, w, 36), Color(0.0, 0.0, 0.0, 0.7 * alpha))
	var font = get_theme_default_font()
	if font != null:
		draw_string(font, Vector2(cx - w * 0.5 + 12, 40), _hint_text, HORIZONTAL_ALIGNMENT_CENTER, w - 24, 15, Color(1.0, 1.0, 1.0, alpha))
