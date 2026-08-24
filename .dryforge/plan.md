# plan.md — 멀티플레이어 마이그레이션 실행 계획

## 단계 개요

Phase 0~4를 7개 태스크로 나눈다. 관전 모드와 리플레이는 서버 권위가 확립된 후 추가한다. 모든 dev 슬롯(yjh-dev1, pjh-dev1, fig-dev1)에 동시 적용하므로 yjh-dev1에서 먼저 구현하고 project/ 폴더를 복사하는 방식으로 전파한다.

## T1 — Godot 헤드리스 서버 골격

**목표:** WebSocketMultiplayerPeer로 연결을 받고 에코 응답을 보내는 최소 서버를 만든다.

**작업 대상:**
- `apps/server-yjh-dev1/project/scripts/net/game_server.gd` (신규)
- `apps/server-yjh-dev1/project/scripts/net/server_match.gd` (신규)
- `apps/server-yjh-dev1/project/project.godot` (서버 메인씬 등록)

**동작 계약:** 서버가 `--headless` 모드로 기동되고, WebSocketMultiplayerPeer로 클라이언트 연결을 수용하며, peer_connected/peer_disconnected 시그널이 정상 발화한다.

**검증:** `godot --headless --main-pack server.pck -- --port 9121` 실행 후 WebSocket 연결 성공.

**사고 근거:** `WebSocketMultiplayerPeer`는 웹 내보내기에서 동작하는 유일한 공식 MultiplayerPeer. 서버 포트(9121)를 허브(9120)와 분리해야 같은 머신에서 공존 가능.

---

## T2 — hub_client.gd 분리 + game_client.gd 작성 + 허브 코드 수정

**목표:** 현재 `hub_client.gd`에서 게임 통신(스냅샷/입력)을 분리하고, `game_client.gd`를 작성하며, Node.js 허브에서 스냅샷/입력 중계를 제거하고 매치 시작 신호를 추가한다.

**작업 대상:**
- `apps/server-yjh-dev1/project/scripts/net/game_client.gd` (신규)
- `apps/server-yjh-dev1/project/scripts/net/hub_client.gd` (게임 관련 메시지 제거)
- `apps/server-yjh-dev1/src/relay.ts` (host_snap/peer_input 중계 제거)
- `apps/server-yjh-dev1/src/index.ts` (매치 시작 시 Godot 서버에 HTTP POST 추가)

**동작 계약:**
- `game_client.gd`는 WebSocketMultiplayerPeer로 게임 서버에 연결한다.
- RPC로 입력을 전송하고 스냅샷을 수신한다.
- `hub_client.gd`는 로비 통신(방 관리, 채팅)만 유지한다.
- 매치 시작 시 `hub_client`가 게임 서버 URL을 클라이언트에 전달하고, `game_client`가 해당 서버에 연결한다.

**검증:** 로비에서 방 입장 → 매치 시작 → game_client가 서버에 연결되어 스냅샷 수신 확인.

---

## T3 — 서버 시뮬레이션 이전

**목표:** `GangGameWorld` 시뮬레이션을 서버로 이전한다. 클라이언트는 입력 전송 + 보간/예측만 수행한다.

**작업 대상:**
- `apps/server-yjh-dev1/project/scripts/net/server_match.gd` (시뮬레이션 실행 로직)
- `apps/server-yjh-dev1/project/scripts/net/game_server.gd` (입력 수집 + 스냅샷 브로드캐스트)
- `apps/server-yjh-dev1/project/scripts/game_root.gd` (호스트/클라이언트 분기 제거)
- `apps/server-yjh-dev1/project/scripts/net/network_host.gd` (서버로 이동, 클라이언트에서 제거)

**동작 계약:**
- 서버가 60Hz로 `GangGameWorld.step_tick()`을 실행한다.
- 서버가 20Hz로 `NetworkHost.build_snapshot()`을 호출하여 모든 클라이언트에 브로드캐스트한다.
- 클라이언트는 `game_root.gd`에서 호스트/클라이언트 분기가 사라지고, 네트워크 모드에서는 항상 보간/예측만 수행한다.
- 로컬 모드(허브 없이 인간 1 + CPU 7)는 기존과 동일하게 동작한다.

**검증:** 8인 온라인 매치에서 서버가 시뮬레이션을 실행하고 모든 클라이언트가 동기화된 상태를 표시한다. 로컬 매치도 정상 동작한다.

**사고 근거:** `game_root.gd`의 `_tick_world()`에서 `GameState.net_host` 분기를 제거하는 것이 핵심. 클라이언트는 `net_world.gd`의 기존 보간 코드를 그대로 사용한다.

---

## T4 — 히트 판정 래그 보상 + 서버 입력 검증

**목표:** 서버에서 래그 보상 히트 판정을 구현하고, 기본 입력 검증을 추가한다.

**작업 대상:**
- `apps/server-yjh-dev1/project/scripts/net/server_match.gd` (래그 보상 로직)
- `apps/server-yjh-dev1/project/scripts/sim/game_world.gd` (히트박스 되감기 인터페이스)

**동작 계약:**
- 클라이언트가 발사 시 추정 서버 시간을 포함하여 입력을 전송한다.
- 서버가 `현재 서버 시간 - RTT/2`를 계산하고 히트박스를 과거 위치로 되감아 판정한다.
- 250ms를 초과하는 보상 요청은 현재 시점으로 판정한다.
- 이동 속도 검증: 허용 최대 속도 초과 입력 거부.
- 발사 속도 검증: 무기별 쿨다운보다 빠른 발사 거부.

**검증:** 인위적 지연(100ms, 200ms) 환경에서 히트 판정이 합리적으로 동작한다.

---

## T5 — 재접속 + 델타 압축

**목표:** 서버 권위 모델에서의 재접속 처리와 델타 압축을 구현한다.

**작업 대상:**
- `apps/server-yjh-dev1/project/scripts/net/game_server.gd` (재접속 토큰 매핑)
- `apps/server-yjh-dev1/project/scripts/net/game_client.gd` (자동 재연결)
- `apps/server-yjh-dev1/project/scripts/net/server_match.gd` (풀/델타 스냅샷 분기)

**동작 계약:**
- 클라이언트 끊김 시 서버가 30초간 슬롯을 보존하고 CPU가 대행한다.
- `resume_token`으로 재연결 시 풀 스냅샷을 전송하고 같은 슬롯에 복귀한다.
- 평상시 델타 스냅샷(변경된 필드만) 전송. JSON diff 기반.

**검증:** 매치 중 브라우저 새로고침 → 30초 이내 재접속 시 같은 슬롯으로 복귀. 델타 스냅샷 크기가 풀 스냅샷의 50% 이하.

---

## T6 — 관전 모드

**목표:** 읽기 전용 관전자가 매치를 실시간으로 볼 수 있게 한다.

**작업 대상:**
- `apps/server-yjh-dev1/project/scripts/net/game_server.gd` (관전자 연결 처리)
- `apps/server-yjh-dev1/project/scripts/ui/flow_screens.gd` (관전 버튼 추가)
- `apps/server-yjh-dev1/project/scripts/net/game_client.gd` (관전 모드 플래그)

**동작 계약:**
- 로비에서 진행 중인 방에 "관전" 버튼으로 진입한다.
- 관전자는 플레이어 수(8명)에 포함되지 않는다.
- 관전자는 입력을 보내지 않고 스냅샷만 수신한다.
- 관전자에게는 전체 맵 뷰가 표시된다.

**검증:** 진행 중인 매치에 관전자가 접속하여 실시간 화면을 볼 수 있다.

---

## T7 — 리플레이 저장 + Netfox 틱 동기화

**목표:** 매치 리플레이 데이터를 저장하고, Netfox 틱 동기화를 도입한다.

**작업 대상:**
- `apps/server-yjh-dev1/project/scripts/net/server_match.gd` (입력 기록)
- `apps/server-yjh-dev1/project/scripts/net/replay_recorder.gd` (신규)
- `apps/server-yjh-dev1/project/addons/netfox/` (Netfox 설치)
- `apps/server-yjh-dev1/project/project.godot` (Netfox autoload)

**동작 계약:**
- 서버가 매치 중 모든 입력을 `{tick, slot, input}` 형태로 기록한다.
- 매치 종료 시 `{seed, mode, player_names, commands}` JSON으로 저장한다.
- Netfox `NetworkTime` + `NetworkTimeSynchronizer`가 서버-클라이언트 틱 drift를 보정한다.

**검증:** 저장된 리플레이를 로드하여 `GangGameWorld`를 재시뮬레이션하면 동일한 최종 상태가 나온다. Netfox 틱 동기화 후 보간 품질이 개선된다.

---

## T8 — 전체 슬롯 전파 + 배포

**목표:** fig-dev1에서 완성한 project/를 다른 슬롯에 복사하고, 배포한다.

**작업 대상:**
- `apps/server-yjh-dev1/project/` (복사)
- `apps/server-pjh-dev1/project/` (복사)
- `apps/server-prod/project/` (복사)
- `deploy/` (Helm 차트에 게임 서버 포트 추가)
- 각 슬롯의 `Dockerfile` (Godot 헤드리스 서버 빌드 추가)

**동작 계약:**
- 모든 슬롯에서 동일한 게임플레이가 동작한다.
- `Apps ship` GitHub Actions가 허브 + Godot 웹 + Godot 서버를 모두 빌드/배포한다.
- 각 `https://<슬롯>.external.kr/`에서 8인 매치가 가능하다.

**검증:** `python3 deploy/scripts/status.py`가 모든 슬롯을 healthy로 표시한다. 보드(`server-board.external.kr`)에서 확인 가능하다.

---

## 공유 파일 주의

- `game_world.gd`는 서버와 클라이언트 양쪽에서 사용한다. 서버 전용 수정은 하지 않는다.
- `network_host.gd`의 `build_snapshot()` 로직은 서버 전용이 된다. 클라이언트에서는 더 이상 호출하지 않는다.
- `project.godot`는 T1(서버 씬 등록)과 T7(Netfox autoload)이 모두 수정한다. T7은 T1 이후에 실행.

---

## Execution Graph

```yaml
tasks:
  - id: T1
    depends: []
    risk: RISKY
  - id: T2
    depends: []
    risk: RISKY
  - id: T3
    depends: [T1, T2]
    risk: RISKY
  - id: T4
    depends: [T3]
    risk: RISKY
  - id: T5
    depends: [T3]
    risk: RISKY
  - id: T6
    depends: [T3]
    risk: MECHANICAL
  - id: T7
    depends: [T3]
    risk: MECHANICAL
  - id: T8
    depends: [T3, T4, T5, T6, T7]
    risk: MECHANICAL
```

Wave 1: T1, T2 (병렬)
Wave 2: T3
Wave 3: T4, T5, T6, T7 (병렬)
Wave 4: T8
