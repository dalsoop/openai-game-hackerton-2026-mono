class_name EngineInputChannel
extends RefCounted
## defineInput 프레임 하나를 room.input() 핸들에 태워 보낸다.
## Predict·직결 접속 수명주기는 다루지 않는다 — engine_socket.gd 가 그쪽을 맡는다.
## 이 클래스 하나만 보면 defineInput 전송 로직 전부를 볼 수 있다(디버깅 경계).

var _pending: Dictionary = {}

## 다음 flush() 에서 보낼 프레임을 예약한다.
func stage(msg: Dictionary) -> void:
	_pending = msg.duplicate()

## 예약된 프레임을 room 에 보낸다. 보낼 게 없거나 room 이 준비 안 됐으면 false.
func flush(room) -> bool:
	if _pending.is_empty():
		return false
	return _send(room, _pending)

func _send(room, msg: Dictionary) -> bool:
	if room == null or not room.has_method("input"):
		return false
	var handle = room.input()
	if handle == null:
		return false
	var data = handle.data
	# 칸 이름은 서버 defineInput(MatchInputSchema). seq 는 프레임 번호라 스키마에 없다.
	for key in msg:
		if str(key) == "seq":
			continue
		var v: Variant = msg[key]
		match typeof(v):
			TYPE_BOOL:
				data.set(str(key), 1.0 if bool(v) else 0.0)
			TYPE_INT, TYPE_FLOAT:
				data.set(str(key), float(v))
	handle.send()
	return true
