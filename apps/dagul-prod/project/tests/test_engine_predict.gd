extends RefCounted
## EnginePredict — 네이티브 예측 클래스 부재 시 항상 안전하게 비활성화되는지만 본다.
## 실제 _ColyseusClient 네이티브 예측 동작 자체는 여기서 재현하지 않는다(엔진 의존).

const Predict := preload("res://core/net/engine_predict.gd")

func run(t) -> void:
	_available_reflects_enabled_and_native(t)
	_bind_room_null(t)
	_bind_room_without_get_state(t)
	_tick_without_native_is_zero(t)

func _available_reflects_enabled_and_native(t) -> void:
	# available() 은 ENABLED 상수와 네이티브 클래스 존재 여부의 AND — 어느 쪽이든 헤드리스
	# 테스트 환경의 실제 값을 그대로 반영해야 한다(고정값을 기대하지 않는다).
	var expect := Predict.ENABLED and ClassDB.class_exists(&"_ColyseusClient")
	t.check("available() 은 ENABLED and 네이티브 존재", Predict.available() == expect)

func _bind_room_null(t) -> void:
	var p: Variant = Predict.bind(null)
	t.check("room null 이면 bind 는 null", p == null)

class FakeRoomNoState extends RefCounted:
	pass # has_method("get_state") == false

func _bind_room_without_get_state(t) -> void:
	var room := FakeRoomNoState.new()
	var p: Variant = Predict.bind(room)
	t.check("get_state 없는 room 은 bind 실패", p == null)

func _tick_without_native_is_zero(t) -> void:
	var p := Predict.new()
	t.check("바인딩 전 tick() 은 0", p.tick() == 0)
