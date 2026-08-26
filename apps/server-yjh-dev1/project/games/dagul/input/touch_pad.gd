class_name TouchPad
extends RefCounted
## 가상 패드 CanvasLayer 의 읽기 창. 켜져 있을 때만 발사·스킬을 인정한다.

var _layer: CanvasLayer = null


func bind(layer: CanvasLayer) -> void:
	_layer = layer


func is_on() -> bool:
	return _layer != null and _layer.has_method("is_enabled") and bool(_layer.is_enabled())


func move() -> Vector2:
	if _layer == null:
		return Vector2.ZERO
	return Vector2(_layer.move)


func aiming() -> bool:
	return is_on() and bool(_layer.aiming)


func aim_dir() -> Vector2:
	if _layer == null:
		return Vector2.ZERO
	return Vector2(_layer.aim_dir)


func fire() -> bool:
	return is_on() and bool(_layer.fire)


func skill() -> bool:
	return is_on() and bool(_layer.skill)


func consume_dash() -> bool:
	return _layer != null and bool(_layer.consume_dash())


func consume_medkit() -> bool:
	return _layer != null and bool(_layer.consume_medkit())


func consume_ult() -> bool:
	return _layer != null and bool(_layer.consume_ult())
