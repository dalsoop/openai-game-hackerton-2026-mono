---
name: godot-party-game
description: Godot 4 멀티플레이어 파티게임을 이 모노레포 패턴에 맞춰 생성·검수하는 스킬. 트리거 — "게임 만들어", "새 미니게임", "파티게임 추가", "godot game", "멀티 게임 추가".
---

# Godot Party Game Maker

이 모노레포(`openai-game-hackerton-2026-mono`)에 새 멀티플레이어 파티게임을 추가한다.

## 불변 규칙

1. **디렉터리**: `apps/game-yjh-{YYMMDD}-{게임명}` (날짜 + kebab-case 게임명)
2. **파일 5개 고정**: `main.gd`, `main.tscn`, `project.godot`, `export_presets.cfg`, `README.md`
3. **Dual-entry**: `--headless` = WebSocket 서버, 브라우저(웹 export) = 클라이언트
4. **서버 권위**: 클라이언트는 입력만 전송. 게임 로직은 서버에서만 실행
5. **포트**: CLAUDE.md 카탈로그의 다음 번호 사용 (현재 다음: 9111)
6. **렌더링**: `_draw()` 코드 드로잉만. 씬 노드로 UI 구성 금지. HUD는 Label 1개
7. **한국어 UI**: 모든 플레이어 대면 텍스트는 한국어
8. **엔진**: Godot 4.7, `gl_compatibility`, 1280×720, `canvas_items` stretch

## main.tscn 템플릿 (고정)

```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://main.gd" id="1"]
[node name="Main" type="Node2D"]
script = ExtResource("1")
```

## project.godot 템플릿

```ini
config_version=5
[application]
config/name="게임 표시명"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.7")
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

## export_presets.cfg (고정)

bomb-pass의 것을 그대로 복사.

## main.gd 구조 패턴

```gdscript
extends Node2D

const WS_PORT := NNNN
var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

# --- server state ---
var players := {}  # id -> {...}

# --- client state ---
var snap := {}
var hud: Label

func _ready() -> void:
    rng.randomize()
    is_server = DisplayServer.get_name() == "headless"
    if is_server: _start_server()
    else: _start_client()

# 서버: create_server, peer_connected/disconnected
# 클라: create_client, Label HUD

# @rpc("any_peer", ...) srv_* — 클라→서버 입력
# @rpc("authority", ...) cl_state — 서버→클라 스냅샷 (TICK 간격)

# _draw() 에서 모든 비주얼 렌더링
# 원탁 배치: 플레이어를 원형으로 배치 (_seat_positions 패턴)
```

## 생성 절차

1. CLAUDE.md 카탈로그에서 다음 포트 번호 확인
2. `apps/game-yjh-{YYMMDD}-{이름}/` 디렉터리 생성
3. 5개 파일 작성 (main.gd는 200~600줄, 완전히 플레이 가능한 수준)
4. CLAUDE.md 카탈로그 테이블에 새 게임 행 추가
5. 포트 번호 갱신 ("새 멀티 게임 포트는 :NNNN 부터")

## 검수 기준 (90점 이상 필수)

- [ ] 최소 인원으로 전체 게임 루프 완주 가능
- [ ] 플레이어 접속/퇴장 중 크래시 없음
- [ ] 죽은/탈락 플레이어가 행동 불가
- [ ] RPC 서명 올바름 (any_peer/authority, reliable/unreliable)
- [ ] 위상 전환 엣지케이스 처리 (동점, 전원 행동 완료 시 조기 전환)
- [ ] _draw()에서 시각 피드백 충분 (현재 페이즈, 타이머, 내 역할/상태)
- [ ] 한국어 텍스트 오타 없음
- [ ] Godot 4.7 GDScript 문법 오류 없음
