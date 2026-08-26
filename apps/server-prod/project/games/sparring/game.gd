extends GameModule
## 스파링(데모) — 유즈맵 추가 경로 증명용 최소 게임.
## 월드 없이: 호스트가 경과 시간 스냅을 0.5초맏 보내고 게스트는 수신만 한다.
## 새 게임 추가에 필요한 것은 이 폴더뿐 (+웹 카탈로그 1줄).

const SNAP_INTERVAL := 0.5

var _elapsed := 0.0
var _since_snap := 0.0
var _is_host := false

func id() -> String:
	return "sparring"

func start(payload: Dictionary, _ctx: Dictionary) -> void:
	_is_host = bool(payload.get("host", false))
	_elapsed = 0.0
	_since_snap = 0.0

func tick(delta: float, ctx: Dictionary) -> void:
	_elapsed += delta
	_since_snap += delta
	var hub: Node = ctx.get("hub")
	if hub != null and hub.has_method("send_input"):
		hub.send_input({"mx": 0, "my": 0, "seq": int(_elapsed * 60.0)})

func become_host(_ctx: Dictionary) -> void:
	_is_host = true

func become_guest(_ctx: Dictionary) -> void:
	_is_host = false

func push_snap(snap: Dictionary) -> void:
	# 게스트 미러 — 데모는 수신 로그만.
	print("sparring snap t=%s" % str(snap.get("t")))

func stop() -> void:
	pass
