class_name GameModule
extends RefCounted
## 게임 폴더(games/<id>/game.gd)가 구현하는 계약.
## 셸(core/shell/match_shell.gd)은 이 인터페이스만 알고, 어떤 게임인지 모른다.
## 씬(main.tscn)은 게임이 소유한다 — 루트에 match_shell 을 부착하고
## WorldView(Node2D)·HUD(CanvasLayer)·HUD/Overlay(Control) 노드를 제공한다.
## 멀티 수송(방·릴레이·재접속)은 core+서버 소유 — 게임은 월드만 소유한다.
##
## ctx (셸이 만들어 넘기는 공유 자원):
##   hub: Node          — NetworkManager (send_input/send_snap/players/rtt_ms)
##   world_view: Node2D — 렌더 루트 (게임 씬 소유)
##   camera: Camera2D
##   hud: Control       — 인게임 HUD 오버레이 (게임 씬 소유)
##   hud_layer: CanvasLayer
##   touch: CanvasLayer — 터치 컨트롤 (없으면 null)
##   leave: Callable    — 매치 이탈 요청 (셸이 처리)

func id() -> String:
	return ""

## 매치 시작. payload: {you:int, host:bool, seed:int, mode:String, seats:Array}
func start(_payload: Dictionary, _ctx: Dictionary) -> void:
	pass

## 매 물리 틱의 게임 루프 (입력 조립 → 시뮬/예측 → 카메라·SFX).
func tick(_delta: float, _ctx: Dictionary) -> void:
	pass

## 게스트 미러 월드에 스냅 반영.
func push_snap(_snap: Dictionary) -> void:
	pass

## 매치 종료·이탈 시 정리.
func stop() -> void:
	pass

## 데디케이티드 서버 모드 (--server) — 지원 게임만 구현.
func start_dedicated(_root: Node) -> void:
	pass
