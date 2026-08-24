# Gang-Up 멀티플레이어 아키텍처 마이그레이션 설계서

## 1. 아키텍처 개요

### 현재 (AS-IS)

```
┌──────────────┐         WebSocket (JSON)         ┌──────────────┐
│  Node.js Hub │◄────────────────────────────────►│ Godot Client │
│              │   hello/rooms/join/create/start   │              │
│  - 방 관리    │   snap/input/chat/peers/leave     │  - 로비 UI    │
│  - 채팅 중계  │                                   │  - 시뮬레이션  │
│  - 스냅샷 중계│                                   │  - 렌더링     │
└──────────────┘                                   └──────────────┘
     ▲                                                   │
     │  host_snap (호스트 클라→허브→다른 클라)               │
     └───────────────────────────────────────────────────┘

호스트 클라이언트가 GangGameWorld를 돌리고 스냅샷을 허브에 보냄
허브는 그 스냅샷을 다른 클라이언트에게 중계
비호스트 클라이언트는 NetWorld로 스냅샷을 보간+예측
```

### 목표 (TO-BE)

```
┌──────────────┐     WebSocket      ┌────────────────────┐
│  Node.js Hub │◄──────────────────►│  Godot 헤드리스 서버  │
│              │  방 관리 API만      │                    │
│  - 매칭/방    │                    │  - GangGameWorld    │
│  - 인증(선택) │                    │  - 입력 수집        │
└──────────────┘                    │  - 스냅샷 발행      │
                                    │  - 판정 권위        │
                                    └────────┬───────────┘
                                             │
                                    WebSocketMultiplayerPeer
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    │                        │                        │
             ┌──────┴──────┐          ┌──────┴──────┐          ┌──────┴──────┐
             │ Godot Client│          │ Godot Client│          │ Godot Client│
             │  - 입력 전송 │          │  - 입력 전송 │          │  - 입력 전송 │
             │  - 보간/예측 │          │  - 보간/예측 │          │  - 보간/예측 │
             │  - 렌더링    │          │  - 렌더링    │          │  - 렌더링    │
             └─────────────┘          └─────────────┘          └─────────────┘
```

핵심 변경점:
- **시뮬레이션 권위를 Godot 헤드리스 서버로 이전** (현재는 호스트 클라이언트가 담당)
- **Node.js 허브는 방 관리/매칭만** (시뮬레이션과 분리)
- **Godot MultiplayerPeer 체계 위에서 동작** (Netfox, Synchronizer 활용 가능)


## 2. 전송 계층 (Transport Layer)

### WebSocketMultiplayerPeer

Godot 4에 내장된 `WebSocketMultiplayerPeer`가 웹 내보내기에서 동작하는 유일한 공식 MultiplayerPeer입니다.

```gdscript
# 서버 측
var server := WebSocketMultiplayerPeer.new()
server.create_server(9120)
multiplayer.multiplayer_peer = server

# 클라이언트 측
var client := WebSocketMultiplayerPeer.new()
client.create_client("wss://server-fig-dev1.external.kr/ws")
multiplayer.multiplayer_peer = client
```

#### 웹 내보내기 주의사항

| 항목 | 상태 | 대응 |
|---|---|---|
| WebSocket | 작동 | 브라우저 네이티브 API 사용 |
| ENet | 불가 | UDP 없음 — WebSocket만 사용 |
| WebRTC | 제한적 | STUN/TURN 서버 필요, 복잡도 대비 이점 적음 |
| TLS (wss://) | 필수 | HTTPS 페이지에서 ws:// 차단됨 |

#### 현재 `hub_client.gd`의 `_resolve_url()` 활용

현재 코드가 이미 origin 기반 URL 해석을 하고 있으므로, 같은 로직을 WebSocketMultiplayerPeer에 적용합니다:

```gdscript
# 현재 hub_client.gd:69-82의 로직을 재활용
func _resolve_game_url() -> String:
    if OS.has_feature("web"):
        var origin := _js_text("String(window.location.origin)")
        if origin.begins_with("https://"):
            return "wss://%s/game-ws" % origin.substr(8)
        # ...
    return "ws://127.0.0.1:9121"  # 게임 서버 포트 (허브 9120과 분리)
```


## 3. 서버 모델: 하이브리드

### Node.js 허브 (유지, 축소)

역할을 **방 관리와 매칭**으로 한정합니다:

| 유지 | 제거 |
|---|---|
| 방 생성/참가/퇴장 | 스냅샷 중계 (`host_snap` 메시지) |
| 플레이어 목록/채팅 | 입력 중계 (`peer_input` 메시지) |
| 재접속 토큰 발급 | 매치 상태 관리 |
| Godot 서버에 매치 시작 신호 | |

매치가 시작되면 허브는 Godot 헤드리스 서버에 "이 방의 플레이어 N명으로 매치를 시작하라"는 메시지를 보내고, 이후 게임 트래픽은 Godot 서버와 클라이언트가 직접 주고받습니다.

### Godot 헤드리스 서버 (신규)

```bash
# 서버 실행 (리눅스/도커)
godot --headless --main-pack gang_up_server.pck -- --port 9121
```

서버가 담당하는 것:
- `GangGameWorld` 시뮬레이션 실행 (현재 호스트 클라이언트가 하던 것)
- 입력 수집 및 적용
- 스냅샷 브로드캐스트 (현재 `NetworkHost.build_snapshot()` 로직)
- 판정 권위 (데미지, 사망, 승리 판정)

```gdscript
# game_server.gd (신규)
extends Node

var world: GangGameWorld
var _snap_timer := 0.0

func _ready() -> void:
    var server := WebSocketMultiplayerPeer.new()
    server.create_server(9121)
    multiplayer.multiplayer_peer = server
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func start_match(player_ids: Array[int], mode: String, seed_val: int) -> void:
    world = GangGameWorld.new(seed_val)
    world.set_mode(mode)
    world.reset()
    # 플레이어 슬롯 매핑
    for i in player_ids.size():
        world.human_slots[i] = true

func _physics_process(delta: float) -> void:
    if world == null:
        return
    world.step_tick(_merged_command(), 1.0 / 60.0)
    _snap_timer += delta
    if _snap_timer >= 1.0 / 20.0:  # 20Hz 스냅샷
        _snap_timer -= 1.0 / 20.0
        _broadcast_snapshot.rpc(NetworkHost.new(null, world).build_snapshot())

@rpc("any_peer", "unreliable")
func submit_input(input_data: Dictionary) -> void:
    var sender := multiplayer.get_remote_sender_id()
    var slot := _peer_to_slot(sender)
    if slot >= 0:
        world.peer_commands[slot] = input_data
```


## 4. 상태 동기화 전략

### 현재 방식 분석

현재 시스템은 이미 **서버 권위 + 스냅샷 보간 + 클라이언트 예측**을 구현하고 있습니다:

| 기능 | 현재 구현 위치 | 상태 |
|---|---|---|
| 서버 권위 시뮬레이션 | `game_root.gd` 호스트 분기 | 호스트 클라이언트에서 실행 |
| 스냅샷 직렬화 | `network_host.gd` `build_snapshot()` | 20Hz JSON |
| 스냅샷 보간 | `net_world.gd` `_lerp_motion()` | 2-3프레임 버퍼, 선형 보간 |
| 클라이언트 예측 | `net_world.gd` `predict_local()` | 이동+조준만 예측 |
| 서버 재조정 | `net_world.gd` `_reconcile()` | seq 기반 ack, pending 재적용 |
| 외삽 | `net_world.gd` `_extrapolate()` | 속도 기반 0.08초 이내 |

이 구조는 **이미 잘 동작하고 있으므로** 완전히 교체하지 않습니다.

### Netfox 도입 여부 판단

Netfox이 제공하는 것:
- 롤백 넷코드 (`NetworkRollback`)
- 틱 동기화 (`NetworkTimeSynchronizer`)
- 입력 관리 (`RollbackSynchronizer`)

**평가:**

| Netfox 기능 | 이 게임에 필요한가 | 이유 |
|---|---|---|
| 롤백 | **부분적** | 이동 예측은 이미 있음. 발사 판정 롤백까지는 과함 |
| 틱 동기화 | **유용** | 현재 서버 틱과 클라이언트 틱 간의 drift 보정이 없음 |
| 입력 버퍼링 | **유용** | 현재 `_pending` 배열이 이 역할을 하고 있지만 정교하지 않음 |

**권장: Netfox의 틱 동기화만 선택적으로 도입하고, 롤백은 이후 단계로 미룸**

### 권장 동기화 전략: 개선된 스냅샷 보간

```
서버 (60Hz 시뮬레이션, 20Hz 스냅샷)
  │
  ├─ 전체 스냅샷 (최초 접속/재접속 시)
  │
  └─ 델타 스냅샷 (평상시)
       │
       ▼
클라이언트
  ├─ 스냅샷 보간 버퍼 (현재 net_world.gd 유지)
  ├─ 로컬 입력 예측 (현재 predict_local 유지)
  ├─ 서버 재조정 (현재 _reconcile 유지)
  └─ [신규] 틱 동기화 (Netfox NetworkTimeSynchronizer)
```


## 5. 마이그레이션 경로 (Phase별)

### Phase 0: 준비 (1일)

변경 없이 인프라만 준비합니다.

- [ ] Godot 헤드리스 서버용 프로젝트 구조 생성
- [ ] `WebSocketMultiplayerPeer` 연결 PoC (에코 서버)
- [ ] 배포 파이프라인에 서버 빌드 추가

### Phase 1: 전송 계층 교체 (2-3일)

**목표:** `hub_client.gd`의 raw WebSocketPeer를 WebSocketMultiplayerPeer로 교체

현재 `hub_client.gd`는 두 가지 역할을 합니다:
1. 로비 통신 (방 관리, 채팅) — JSON 메시지
2. 게임 통신 (스냅샷, 입력) — JSON 메시지

이 두 역할을 분리합니다:

```
hub_client.gd (로비 전용, WebSocketPeer 유지)
  └─ 방 관리, 채팅, 매치 시작 신호

game_client.gd (게임 전용, 신규, WebSocketMultiplayerPeer)
  └─ 입력 전송, 스냅샷 수신, RPC 기반
```

```gdscript
# game_client.gd (신규)
extends Node

var peer := WebSocketMultiplayerPeer.new()

func connect_to_server(url: String) -> void:
    peer.create_client(url)
    multiplayer.multiplayer_peer = peer

@rpc("authority", "unreliable")
func receive_snapshot(snap: Dictionary) -> void:
    # 현재 hub_client.gd의 snapshot_received.emit(snap) 대체
    snapshot_received.emit(snap)

func send_input(input_data: Dictionary) -> void:
    # 현재 hub_client.gd의 send_input() 대체
    submit_input.rpc_id(1, input_data)

@rpc("any_peer", "unreliable")
func submit_input(input_data: Dictionary) -> void:
    pass  # 서버 측에서만 처리
```

### Phase 2: 서버 권위 이전 (3-4일)

**목표:** 시뮬레이션을 호스트 클라이언트에서 Godot 헤드리스 서버로 이전

현재 `game_root.gd:301-332`의 `_tick_world()`:

```gdscript
# 현재: 호스트 클라이언트가 시뮬레이션 실행
if GameState.net_active and GameState.net_host:
    world.step_tick(command, 1.0 / 60.0)
    _host_ctrl.tick(1.0 / 60.0)  # 스냅샷 전송
```

이 로직을 서버로 옮깁니다:

```gdscript
# 이후: 모든 클라이언트가 동일하게 동작
if GameState.net_active:
    game_client.send_input(_build_input())
    world.present(1.0 / 60.0)      # 보간+예측만
```

이 단계에서 `NetworkHost` 클래스는 서버 프로젝트로 이동합니다.

### Phase 3: MultiplayerSynchronizer 도입 (2-3일)

**목표:** 로비/방 상태를 Scene Replication으로 동기화

현재 로비 상태(플레이어 목록, 방 정보)는 JSON 메시지로 수동 동기화됩니다.
MultiplayerSynchronizer를 도입하면:

```gdscript
# lobby_state.gd (서버에서 관리, 자동 동기화)
extends Node

@export var players: Array[Dictionary] = []
@export var room: Dictionary = {}
@export var match_running := false

# MultiplayerSynchronizer가 이 프로퍼티를 자동으로 클라이언트에 동기화
```

하지만 **이 단계는 선택적**입니다. 현재 JSON 방식이 잘 동작하고 있고, 로비 통신량은 적습니다.

### Phase 4: 클라이언트 예측 개선 (선택, 2-3일)

**목표:** Netfox 틱 동기화 도입, 발사 판정 예측 추가

현재 `net_world.gd`의 예측은 이동만 합니다. 발사 판정까지 예측하면 반응성이 올라갑니다:

```gdscript
# 현재: 이동만 예측
func predict_local(move, dash, aim, dt):
    _step_pred(mx, my, dash, aim, dt)  # 위치만 업데이트

# 개선: 발사 이펙트도 즉시 표시
func predict_local(move, dash, aim, fire, dt):
    _step_pred(mx, my, dash, aim, dt)
    if fire:
        _add_predicted_muzzle_flash(aim)  # 즉시 시각 피드백
        # 실제 데미지 판정은 서버에서
```


## 6. 파일별 영향도

### 변경이 큰 파일

| 파일 | 변경 내용 | 영향도 |
|---|---|---|
| `hub_client.gd` | 게임 통신 제거, 로비 전용으로 축소. 395→~200줄 | **높음** |
| `game_root.gd` | `_tick_world()`에서 호스트/클라이언트 분기 제거. 모든 네트워크 클라이언트가 동일 코드 경로 | **높음** |
| `network_host.gd` | 서버 프로젝트로 이동. 클라이언트에서 삭제 | **높음** |

### 변경이 적은 파일

| 파일 | 변경 내용 | 영향도 |
|---|---|---|
| `net_world.gd` | `push_snap()` 입력 형식만 변경 (JSON Dict → RPC Dict). 보간/예측 로직은 그대로 | **낮음** |
| `net_snap_parser.gd` | 변경 없음 (스냅샷 파싱 로직은 형식과 무관) | **없음** |
| `flow_screens.gd` | `bind_hub()` 인터페이스 유지. 내부적으로 game_client 추가 바인딩 | **낮음** |
| `game_world.gd` | 변경 없음 (시뮬레이션 로직은 서버로 그대로 복사) | **없음** |

### 신규 파일

| 파일 | 역할 |
|---|---|
| `game_client.gd` | WebSocketMultiplayerPeer 기반 게임 서버 연결 |
| `game_server.gd` (서버 프로젝트) | 헤드리스 서버 메인 루프 |
| `server_match.gd` (서버 프로젝트) | 매치 관리 (시뮬레이션 + 스냅샷 발행) |


## 7. 위험 평가

### 높은 위험

| 위험 | 영향 | 완화 |
|---|---|---|
| 웹 내보내기에서 WebSocketMultiplayerPeer 불안정 | 게임 불가 | Phase 0에서 PoC 검증. 실패 시 현재 방식 유지 |
| 헤드리스 서버 배포 복잡도 | 운영 부담 | Docker 이미지로 패키징. 현재 Node.js 허브와 같은 서버에 배치 |
| 호스트 마이그레이션 상실 | 서버 다운 시 매치 중단 | 허브가 서버 헬스체크, 3초 무응답 시 매치 종료 알림 |

### 중간 위험

| 위험 | 영향 | 완화 |
|---|---|---|
| 두 개 WebSocket 연결 (허브+서버) | 웹에서 연결 제한 | 브라우저별 6-256개 제한 — 2개는 안전 |
| 스냅샷 크기 증가 | 대역폭 | 델타 압축 도입 (Phase 2에서) |
| 기존 재접속 로직 깨짐 | UX 저하 | `resume_token` 메커니즘을 서버에도 적용 |

### 낮은 위험

| 위험 | 영향 | 완화 |
|---|---|---|
| Netfox 웹 호환성 | 기능 제한 | Netfox는 순수 GDScript — 웹 문제 없음 |
| 결정론적 시뮬레이션 깨짐 | 판정 불일치 | 서버만 판정하므로 클라이언트 결정론성은 필요 없어짐 |


## 8. 패키지 통합 상세

### WebSocketMultiplayerPeer (Godot 내장)

```gdscript
# 서버
var ws_server := WebSocketMultiplayerPeer.new()
ws_server.create_server(9121, "*", TLSOptions.server(key, cert))
multiplayer.multiplayer_peer = ws_server

# 시그널
multiplayer.peer_connected.connect(_on_player_joined)
multiplayer.peer_disconnected.connect(_on_player_left)
```

### Netfox (선택적, Phase 4)

```
addons/
└── netfox/
    ├── NetworkTime          ← 틱 동기화 (사용)
    ├── NetworkTimeSynchronizer  ← 서버-클라이언트 시간 맞춤 (사용)
    └── RollbackSynchronizer ← 롤백 (Phase 4 이후)
```

설치: `gd-plug` 또는 수동 복사

```gdscript
# project.godot
[autoload]
NetworkTime="*res://addons/netfox/NetworkTime.gd"
NetworkTimeSynchronizer="*res://addons/netfox/NetworkTimeSynchronizer.gd"
```

### MultiplayerSynchronizer (Godot 내장, Phase 3)

현재 코드가 씬 트리 없이 전부 코드 기반이므로, MultiplayerSynchronizer를 코드로 생성합니다:

```gdscript
var sync := MultiplayerSynchronizer.new()
sync.replication_config = SceneReplicationConfig.new()
# 동기화할 프로퍼티 등록
sync.replication_config.add_property(NodePath(".:players"))
sync.replication_config.add_property(NodePath(".:room"))
add_child(sync)
```


## 9. 재접속 설계

### 현재 재접속 흐름

```
클라이언트 끊김
  → hub_client.gd: holding_seat = true, 24회까지 재시도
  → 재연결 시: resume_token으로 hello 전송
  → 허브: 같은 슬롯에 복귀, 현재 스냅샷 전송
  → 클라이언트: match_resumed 시그널로 게임 복귀
```

### 개선된 재접속 흐름

```
클라이언트 끊김
  ├─ 허브 연결 재시도 (로비용, 현재와 동일)
  └─ 게임 서버 연결 재시도 (게임용, 신규)
       → peer_id가 바뀌므로 resume_token으로 슬롯 매핑
       → 서버: 풀 스냅샷 + 최근 이벤트 전송
       → 클라이언트: net_world.reset() 후 새 스냅샷으로 시작
```

```gdscript
# game_server.gd
var _slot_tokens: Dictionary = {}  # resume_token → slot

@rpc("any_peer", "reliable")
func request_resume(token: String) -> void:
    var sender := multiplayer.get_remote_sender_id()
    if _slot_tokens.has(token):
        var slot: int = _slot_tokens[token]
        _peer_slot_map[sender] = slot
        world.human_slots[slot] = true
        # 풀 스냅샷 전송
        receive_full_snapshot.rpc_id(sender, _build_full_snapshot())
```

### 끊김 감지

```gdscript
# 서버 측
func _on_peer_disconnected(id: int) -> void:
    var slot := _peer_to_slot(id)
    if slot < 0:
        return
    # 즉시 제거하지 않고 30초 대기
    _disconnected_slots[slot] = Time.get_ticks_msec()
    # CPU가 대신 조종 (현재 peer_parked와 동일)
    world.human_slots.erase(slot)

func _check_reconnect_timeout() -> void:
    var now := Time.get_ticks_msec()
    for slot in _disconnected_slots.keys():
        if now - _disconnected_slots[slot] > 30000:
            _disconnected_slots.erase(slot)
            # 영구 이탈 처리
```


## 10. 성능 추정

### 대역폭

현재 스냅샷 크기 (JSON):

```
players: 8명 × ~200바이트 = 1,600바이트
bullets: ~10개 × ~40바이트 = 400바이트
zones/deployables/etc: ~500바이트
오버헤드 (JSON 키 이름): ~800바이트
─────────────────────────────────
합계: ~3,300바이트/스냅샷
× 20Hz = 66KB/s (서버→클라이언트, 단방향)
× 8명 = 528KB/s (서버 총 송신)
```

### 최적화 방안

#### 1단계: 바이너리 직렬화 (JSON → PackedByteArray)

```gdscript
# JSON 대신 바이너리
func _snap_to_bytes(snap: Dictionary) -> PackedByteArray:
    var buf := StreamPeerBuffer.new()
    buf.put_32(snap["tick"])
    buf.put_float(snap["time"])
    for p in snap["players"]:
        buf.put_8(p["slot"])
        buf.put_float(p["x"])
        buf.put_float(p["y"])
        # ...
    return buf.data_array
```

예상 절감: JSON 3,300바이트 → 바이너리 ~1,200바이트 (64% 절감)

#### 2단계: 델타 압축

변경된 필드만 전송:

```gdscript
func _delta_snap(prev: Dictionary, current: Dictionary) -> Dictionary:
    var delta := {"tick": current["tick"]}
    # 플레이어: 위치가 1.0 이상 변했을 때만 포함
    var changed_players := []
    for i in current["players"].size():
        var cp = current["players"][i]
        var pp = prev["players"][i] if i < prev["players"].size() else {}
        if _player_changed(pp, cp):
            changed_players.append(cp)
    if not changed_players.is_empty():
        delta["players"] = changed_players
    return delta
```

예상 절감: 평균 50-70% 추가 절감 (정지 캐릭터가 많을 때)

#### 최종 대역폭 추정

| 단계 | 스냅샷 크기 | 서버 송신 (8명) |
|---|---|---|
| 현재 (JSON) | 3,300B | 528 KB/s |
| 바이너리 | 1,200B | 192 KB/s |
| 바이너리 + 델타 | ~500B 평균 | 80 KB/s |

입력 (클라이언트→서버): ~50바이트 × 60Hz × 8명 = 24 KB/s

**총 서버 대역폭: ~100-200 KB/s** — 일반 VPS에서 충분히 처리 가능


## 부록: 해커톤 일정용 최소 실행 계획

시간이 제한되어 있다면 **Phase 0 + Phase 1 + Phase 2**만 실행합니다:

| 일차 | 작업 | 산출물 |
|---|---|---|
| 1일차 | WebSocketMultiplayerPeer PoC + 헤드리스 서버 골격 | 에코 서버 동작 확인 |
| 2일차 | `hub_client.gd` 분리 + `game_client.gd` 작성 | 로비는 허브, 게임은 서버 |
| 3일차 | `NetworkHost` 로직을 서버로 이전 | 서버가 시뮬레이션 실행 |
| 4일차 | 재접속 + 테스트 | 8인 매치 동작 확인 |

Phase 3(MultiplayerSynchronizer)와 Phase 4(Netfox 틱 동기화)는 해커톤 이후에 진행합니다.
