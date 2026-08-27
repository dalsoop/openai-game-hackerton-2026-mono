extends RefCounted
## EngineInputChannel — defineInput 프레임 전송 계약만 격리 검증.
## Predict·접속 수명주기는 test_engine_socket_fallback.gd 가 맡는다.

const Channel := preload("res://core/net/engine_input_channel.gd")

class FakeData extends RefCounted:
	var values: Dictionary = {}
	## Object.set() 를 직접 오버라이드하면 네이티브 시그니처 경고가 오류로 취급된다 —
	## 대신 엔진이 set() 내부에서 위임하는 _set 가상 메서드를 쓴다.
	func _set(property: StringName, value: Variant) -> bool:
		values[property] = value
		return true

class FakeHandle extends RefCounted:
	var data := FakeData.new()
	var sent := 0
	func send() -> void:
		sent += 1

class FakeRoom extends RefCounted:
	var handle: FakeHandle = null # null 이면 input() 이 미지원인 room 흉내
	var handle_returns_null := false
	func input() -> Variant:
		if handle_returns_null:
			return null
		return handle

func run(t) -> void:
	_stage_then_flush(t)
	_flush_without_stage_is_noop(t)
	_room_without_input_method(t)
	_handle_null(t)
	_bool_and_number_mapping(t)
	_seq_excluded(t)

func _stage_then_flush(t) -> void:
	var ch := Channel.new()
	var room := FakeRoom.new()
	room.handle = FakeHandle.new()
	ch.stage({"mx": 1.0, "seq": 5})
	var ok: bool = ch.flush(room)
	t.check("stage 후 flush 는 true", ok == true)
	t.check("handle.send() 한 번", room.handle.sent == 1)

func _flush_without_stage_is_noop(t) -> void:
	var ch := Channel.new()
	var room := FakeRoom.new()
	room.handle = FakeHandle.new()
	var ok: bool = ch.flush(room)
	t.check("stage 없이 flush 는 false", ok == false)
	t.check("handle.send() 호출 안 됨", room.handle.sent == 0)

func _room_without_input_method(t) -> void:
	var ch := Channel.new()
	ch.stage({"mx": 1.0})
	var not_a_room: RefCounted = RefCounted.new() # has_method("input") == false
	var ok: bool = ch.flush(not_a_room)
	t.check("input() 없는 room 은 false — 크래시 없음", ok == false)

func _handle_null(t) -> void:
	var ch := Channel.new()
	ch.stage({"mx": 1.0})
	var room := FakeRoom.new()
	room.handle_returns_null = true
	var ok: bool = ch.flush(room)
	t.check("handle null 이면 false", ok == false)

func _bool_and_number_mapping(t) -> void:
	var ch := Channel.new()
	var room := FakeRoom.new()
	room.handle = FakeHandle.new()
	ch.stage({"dash": true, "firePressed": false, "mx": -1, "aimX": 12.5})
	ch.flush(room)
	var v := room.handle.data.values
	t.check("bool true → 1.0", float(v.get("dash", 0)) == 1.0)
	t.check("bool false → 0.0", float(v.get("firePressed", 1)) == 0.0)
	t.check("int → float", v.get("mx") is float and float(v["mx"]) == -1.0)
	t.check("float 그대로", float(v.get("aimX", 0)) == 12.5)

func _seq_excluded(t) -> void:
	var ch := Channel.new()
	var room := FakeRoom.new()
	room.handle = FakeHandle.new()
	ch.stage({"seq": 99, "mx": 1.0})
	ch.flush(room)
	t.check("seq 는 defineInput 스키마에 없어 제외된다", not room.handle.data.values.has("seq"))
