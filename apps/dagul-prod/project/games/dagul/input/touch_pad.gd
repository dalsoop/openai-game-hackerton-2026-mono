class_name TouchPad
extends RefCounted
## 가상 패드 CanvasLayer 의 읽기 창. 켜져 있을 때만 조준·발사를 인정한다.

var _layer: CanvasLayer = null


func bind(layer: CanvasLayer) -> void:
	_layer = layer


func is_on() -> bool:
	return _layer != null and _layer.has_method("is_enabled") and bool(_layer.is_enabled())


func move() -> Vector2:
	if not is_on():
		return Vector2.ZERO
	return Vector2(_layer.move)


func aiming() -> bool:
	return is_on() and bool(_layer.aiming)


func aim_dir() -> Vector2:
	if not is_on():
		return Vector2.ZERO
	return Vector2(_layer.aim_dir)


## 손을 뗀 뒤에도 남는 방향. 패드가 꺼져 있으면 쓰이지 않는다.
func aim_last() -> Vector2:
	if not is_on():
		return Vector2.RIGHT
	return Vector2(_layer.aim_last)


## 조준 스틱을 밀고 있으면 그게 발사다.
func fire() -> bool:
	return is_on() and bool(_layer.fire)


## 스틱을 툭 친 한 번. 엣지라 틱당 한 번만 읽어야 한다.
func consume_aim_tap() -> bool:
	return is_on() and bool(_layer.consume_aim_tap())


func consume_dash() -> bool:
	return is_on() and bool(_layer.consume_dash())


func consume_ult() -> bool:
	return is_on() and bool(_layer.consume_ult())
