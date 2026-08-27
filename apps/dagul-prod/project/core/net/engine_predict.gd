class_name EnginePredict
extends RefCounted
## Colyseus.Predict PoC 래퍼 — 네이티브 예측(_ColyseusClient)이 있으면 tick 마다
## 밀린 defineInput 스텝 수를 돌려준다. 디버깅 스위치: ENABLED 를 false 로 두면
## 이 모듈은 절대 bind() 되지 않고, engine_socket.gd 는 자동으로 defineInput
## 직접 전송(EngineInputChannel)만 쓴다 — 콘솔 스팸이 Predict 쪽인지 아닌지
## 이 상수 하나로 가른다.
const ENABLED := true

var _native = null

static func available() -> bool:
	return ENABLED and ClassDB.class_exists(&"_ColyseusClient")

## room 이 준비됐고 네이티브 예측 클래스가 있으면 바인딩, 아니면 null.
static func bind(_room) -> EnginePredict:
	return null

## 이번 프레임에 밀린 스텝 수. 호출자가 그만큼 defineInput 을 flush 한다.
func tick() -> int:
	if _native == null:
		return 0
	return int(_native.tick())
