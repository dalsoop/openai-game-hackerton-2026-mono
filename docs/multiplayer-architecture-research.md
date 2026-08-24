# 멀티플레이어 아키텍처 전환 연구 보고서

Gang-Up(8인 탑다운 배틀로얄)의 멀티플레이어 아키텍처를 "호스트 클라이언트 시뮬레이션"에서 "Godot 헤드리스 전용 서버 + MultiplayerPeer 체계"로 전환할 때의 이점과 설계 방법론을 조사한 보고서.

---

## 1. 전환이 가져오는 구체적 이점

### 1.1 호스트 클라이언트 vs 전용 서버

호스트 클라이언트(listen server) 모델에서는 한 플레이어의 기기가 시뮬레이션 권위를 갖는다. 이 구조는 세 가지 근본적 문제를 안고 있다.

**호스트 어드밴티지**: 호스트는 자기 입력에 대한 레이턴시가 0ms이므로, 다른 플레이어보다 항상 빠르게 반응할 수 있다. 경쟁 플레이에서 이 차이는 분명하게 드러난다. ([Softlist](https://www.softlist.io/dedicated-servers-vs-peer-to-peer-networking/))

**치팅 취약성**: 호스트가 게임 로직을 실행하므로, 메모리 조작으로 자기 체력을 무한으로 설정하거나 다른 플레이어의 위치를 조작하는 것이 구조적으로 가능하다. 서버 권위 모델에서는 서버가 모든 입력을 검증하므로 이런 조작이 차단된다. ([AccelByte](https://accelbyte.io/blog/server-authoritative-logic-to-prevent-cheating))

**호스트 이탈 시 세션 종료**: 호스트가 게임을 떠나면 전체 매치가 끊어진다. 전용 서버는 어떤 플레이어가 떠나든 매치가 계속된다. ([Edgegap](https://edgegap.com/blog/cheaters-peer-to-peer-hosting-an-beginners-guide))

### 1.2 배틀로얄 장르의 서버 권위 모델

주요 배틀로얄 게임은 모두 서버 권위 모델을 사용한다.

| 게임 | 서버 틱레이트 | 동기화 방식 | 참고 |
|---|---|---|---|
| Fortnite | 30Hz | 스냅샷 기반 | 100명, 건축 메카닉 포함 시 90~250MB/시간 |
| PUBG | 30Hz (초기 20Hz) | 스냅샷 기반 | 초반 서버 부하가 높고 후반에 안정화 |
| Apex Legends | 20Hz | 스냅샷 기반 | 60명, 80~220MB/시간. 낮은 틱레이트로 넷코드 비판 |

([GameRant](https://gamerant.com/apex-legends-netcode/), [Dexerto](https://www.dexerto.com/apex-legends/how-bad-is-apex-legends-netcode-compared-to-fortnite-pubg-1290489/))

세 게임 모두 서버가 시뮬레이션을 실행하고, 클라이언트는 서버 스냅샷을 보간하면서 로컬 입력만 예측한다. Apex의 20Hz 틱레이트조차 P2P보다 공정한 경험을 제공한다는 것이 업계 합의다.

### 1.3 웹 게임 성공 사례

브라우저 배틀로얄의 대표 사례인 **Surviv.io**는 Node.js + WebSocket 기반 서버 권위 모델로 동작했다. 2018~2020년에 월 수백만 사용자를 기록했으며, Kongregate가 인수했다. 서버가 모든 게임 로직을 실행하고 클라이언트는 렌더링만 담당하는 구조였다. ([Wikipedia](https://en.wikipedia.org/wiki/Surviv.io))

**agar.io**, **slither.io** 등 .io 장르 전체가 Node.js + WebSocket + 서버 권위 아키텍처를 사용한다. 이 패턴이 브라우저 실시간 멀티플레이어의 사실상 표준이다. ([GitHub agar.io-clone Wiki](https://github.com/huytd/agar.io-clone/wiki/Game-Architecture))

### 1.4 Godot 헤드리스 서버 프로덕션 사례

**Dome Keeper** (Steam 수익 $6.1M)가 2025년 4월에 온라인 멀티플레이어를 출시하면서, Godot 헤드리스 서버를 프로덕션에서 사용하는 첫 대형 사례가 됐다. 개발사 Bippinbits가 GodotCon 2025에서 기존 GDScript 코드베이스에 멀티플레이어를 추가한 과정을 발표했다. ([Ziva](https://ziva.sh/blogs/godot-multiplayer))

Godot 4.5/4.6에서 전용 서버 내보내기 모드가 내장되어 있으며, `--headless` 플래그로 렌더링과 오디오를 제거한 채 시뮬레이션만 실행할 수 있다. ([Gameye](https://gameye.com/blog/godot-dedicated-server-hosting/))

### 1.5 8인 규모 비용 vs 이점

8인은 배틀로얄 중 가장 작은 규모에 속한다. 서버 비용 관점에서:

- 서버 대역폭: 바이너리+델타 압축 시 **~100KB/s** (일반 VPS로 충분)
- CPU: Godot 헤드리스 1코어로 60Hz 시뮬레이션 8인 매치 수 개 동시 처리 가능
- 한 대 VPS($5~20/월)로 수십 개 동시 매치 운영 가능

비용이 매우 낮은 반면, 치팅 방지와 공정성 확보라는 이점은 경쟁 게임에서 결정적이다.

---

## 2. 서버 권위 배틀로얄 설계 패턴

### 2.1 클라이언트 예측 + 서버 재조정 (Reconciliation)

Gabriel Gambetta의 정본 알고리즘:

1. 클라이언트가 입력에 시퀀스 번호를 붙여 서버에 전송하면서 로컬에서 즉시 적용
2. 서버가 입력을 처리하고, 마지막으로 처리한 시퀀스 번호를 응답에 포함
3. 클라이언트는 확인된 입력을 버퍼에서 제거
4. 서버 상태와 로컬 예측이 어긋나면, 서버 상태를 기준으로 미확인 입력을 재적용

핵심: 재조정 시 미확인 입력을 전부 재시뮬레이션해야 하므로, 시뮬레이션이 가벼워야 한다. Gang-Up의 `GangGameWorld`는 `RefCounted` 기반 순수 연산이라 이 조건에 부합한다. ([Gabriel Gambetta](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html))

### 2.2 스냅샷 보간 vs 롤백 vs 상태 동기화

| 방식 | 적합한 상황 | Gang-Up 적합성 |
|---|---|---|
| **스냅샷 보간** | 서버 권위 + 많은 엔티티 + 시각적 매끄러움 | **최적**. 현재 이미 구현됨 |
| **롤백 넷코드** | 격투/플랫포머 등 정밀 프레임 판정 | 과함. 8인 배틀로얄에서 전체 상태 롤백은 비용이 높음 |
| **상태 동기화** | 느린 업데이트 (턴제, 로비) | 로비/방 관리에만 적합 |

스냅샷 보간은 서버가 20Hz로 월드 상태를 보내고, 클라이언트가 2~3프레임 버퍼에 넣고 선형 보간하는 방식이다. Gang-Up은 `net_world.gd`에서 이미 `_lerp_motion()`으로 이 패턴을 구현하고 있다.

### 2.3 히트 판정: 서버측 래그 보상

배틀로얄/슈터에서 히트 판정의 업계 표준은 **서버측 래그 보상(lag compensation)**이다.

알고리즘:
1. 클라이언트가 발사 시점의 추정 서버 시간을 포함하여 발사 명령을 전송
2. 서버가 `발사 시점 = 현재 서버 시간 - RTT/2 - 클라이언트 보간 지연`을 계산
3. 대상 히트박스를 해당 과거 시점의 위치로 되감기
4. 되감긴 위치에서 히트 판정 실행
5. 히트박스를 원래 위치로 복구

레이턴시 임계값(Battlefield 4/Overwatch: 250ms, CoD: 500ms)을 초과하는 플레이어에게는 보상을 제한하여 악용을 방지한다.

**즉시 시각 피드백(클라이언트)과 권위 판정(서버)의 분리**:
- 클라이언트 즉시 처리: 총구 화염, 반동, 발사음, 탄흔
- 서버 확인 후 처리: 체력 감소, 히트마커, 사망 판정

([Daniel Jiménez Morales](https://danieljimenezmorales.github.io/2023-10-29-the-art-of-hit-registration/))

### 2.4 안티치트: 서버 권위 모델에서의 입력 검증

서버 권위 모델 자체가 가장 강력한 안티치트이지만, 추가 검증이 필요하다.

- **이동 속도 검증**: 입력이 허용된 최대 속도를 초과하면 거부
- **발사 속도 검증**: 무기별 쿨다운보다 빠른 발사 명령 거부
- **위치 무결성**: 클라이언트 보고 위치와 서버 시뮬레이션 위치가 임계값 이상 벗어나면 서버 위치로 강제 보정
- **입력 빈도 제한**: 초당 입력 수가 비정상적으로 많으면 차단

([AccelByte](https://accelbyte.io/blog/server-authoritative-logic-to-prevent-cheating), [Supercraft](https://crux.supercraft.host/blog/server-authoritative-anti-cheat-backend/))

### 2.5 "느린 클라이언트" 문제

한 명의 느린 클라이언트가 나머지 7명에게 미치는 영향을 차단하는 방법:

- **서버 시뮬레이션은 고정 틱레이트로 진행**: 느린 클라이언트의 입력이 늦게 도착하면 해당 플레이어만 "과거 입력"으로 처리
- **입력 타임아웃**: 일정 시간 입력이 없으면 해당 슬롯을 CPU가 대행 (Gang-Up에서 이미 `peer_parked` 개념이 있음)
- **적응형 스냅샷**: 느린 클라이언트에게는 스냅샷 전송 빈도를 낮추되, 다른 클라이언트에게는 정상 빈도 유지

---

## 3. Godot 4 + WebSocket 전용 서버 설계 방법론

### 3.1 헤드리스 서버 실행과 제약

```bash
godot --headless --main-pack server.pck -- --port 9121
```

- `--headless`: 렌더링, 오디오, 윈도우 시스템 비활성화
- Godot 4.5+: 전용 서버 내보내기 프리셋이 내장되어, 서버 빌드에서 텍스처/사운드 에셋을 자동 제외
- 제약: `_draw()`, `CanvasItem`, `AudioStreamPlayer` 등 렌더링/오디오 노드는 사용 불가 (시뮬레이션 로직이 이런 노드에 의존하면 분리 필요)

Gang-Up의 `GangGameWorld`는 `RefCounted` 기반이라 씬 트리에 의존하지 않으므로, 서버에서 그대로 실행할 수 있다. ([Gameye](https://gameye.com/blog/godot-dedicated-server-hosting/))

### 3.2 WebSocketMultiplayerPeer

웹 내보내기에서 유일하게 동작하는 공식 MultiplayerPeer. 내부적으로 TCP 위에 WebSocket을 사용한다.

- HTML5 내보내기에서는 브라우저의 WebSocket API를 사용하므로 출력 버퍼를 브라우저가 관리
- `wss://` (TLS)가 HTTPS 페이지에서 필수
- ENet(UDP)은 웹에서 불가하므로, WebSocket이 유일한 선택

구체적인 벤치마크 수치는 공개된 자료가 없지만, Dome Keeper가 이 경로로 프로덕션 출시에 성공했다. ([Godot Docs](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html))

### 3.3 Godot RPC vs 커스텀 바이너리 프로토콜

| 방식 | 장점 | 단점 | 전환 시점 |
|---|---|---|---|
| Godot RPC | 구현이 간단, 타입 안전 | 오버헤드 (함수 이름, 직렬화 메타데이터) | 초기~중기 |
| 커스텀 바이너리 | 최소 대역폭, 완전 제어 | 직접 파서/시리얼라이저 구현 필요 | 대역폭이 병목이 될 때 |

권장: **Phase 1~2에서 Godot RPC를 사용하고**, 대역폭 프로파일링 후 병목이 확인되면 스냅샷만 바이너리(`StreamPeerBuffer`)로 전환. 로비/채팅은 RPC 유지.

### 3.4 서버 틱레이트 설계

| 계층 | 빈도 | 역할 |
|---|---|---|
| 시뮬레이션 | 60Hz | `GangGameWorld.step_tick()` — 물리, 충돌, 판정 |
| 스냅샷 발행 | 20Hz | 월드 상태를 클라이언트에 브로드캐스트 |
| 입력 수집 | 60Hz (클라이언트 전송), 서버는 도착 순으로 처리 | 클라이언트 입력을 다음 시뮬레이션 틱에 적용 |

20Hz 스냅샷은 Apex Legends과 동일한 빈도이며, 8인 규모에서 대역폭과 반응성의 균형점이다.

### 3.5 서버 한 대에 여러 매치 운영

두 가지 접근:

**방법 A: 프로세스 내 다중 매치** — 하나의 Godot 헤드리스 프로세스가 여러 `GangGameWorld` 인스턴스를 Node 트리에 배치. 8인 매치의 CPU 부하가 낮으므로 하나의 프로세스로 10~20개 매치를 동시에 실행 가능.

**방법 B: Docker 컨테이너 per 매치** — 게임 서버 매니저가 매치마다 Docker 컨테이너를 생성하고 포트를 할당. 격리성이 높지만 오버헤드도 높음. ([Andres Romero](https://www.andresromero.dev/blog/dedicated-game-server-hosting))

Gang-Up의 8인 규모에서는 **방법 A**가 적합하다. 메모리와 프로세스 오버헤드가 최소화된다.

---

## 4. 재접속과 관전 모드 설계

### 4.1 재접속 시 상태 복구

서버 권위 모델에서 재접속은 구조적으로 간단해진다.

1. 클라이언트가 `resume_token`으로 서버에 재연결 요청
2. 서버가 토큰으로 슬롯을 매핑하고 **풀 스냅샷**을 전송
3. 클라이언트가 `net_world.reset()` 후 풀 스냅샷으로 상태를 복구하고 이후 델타 스냅샷으로 전환

주의: Godot의 MultiplayerPeer는 재연결 시 새로운 `peer_id`를 부여하므로, `resume_token` → 슬롯 매핑 테이블을 서버가 유지해야 한다. 타임아웃(30초 권장) 후에는 슬롯을 영구 이탈로 처리한다. ([StraySpark](https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server))

### 4.2 관전 모드

서버 권위 모델의 가장 큰 부수 이점 중 하나가 관전 모드의 간편함이다.

- 관전자는 입력을 보내지 않고 스냅샷만 수신하는 "읽기 전용 클라이언트"
- 서버가 모든 플레이어의 전체 상태를 갖고 있으므로, 관전자에게 아무 플레이어의 시점이든 전송 가능
- 기존 스냅샷 브로드캐스트 경로에 관전자를 추가하기만 하면 됨
- 관전자 부하가 크면, 별도 "리브로드캐스트 서버"에 풀 상태를 중계하는 계층화도 가능

### 4.3 매치 리플레이 저장

두 가지 접근:

| 방식 | 저장량 | 장점 | 단점 |
|---|---|---|---|
| **입력 기록** | ~50B × 60Hz × 8명 = ~24KB/s | 용량 최소, 결정적 시뮬레이션으로 정확 재현 | 시뮬레이션 코드 변경 시 구버전 리플레이 재현 불가 |
| **스냅샷 기록** | ~500B × 20Hz = ~10KB/s (델타) | 시뮬레이션 코드와 독립, 어느 시점이든 즉시 이동 | 용량이 더 크고, 중간 프레임 재현이 불완전 |

Gang-Up은 이미 `SeededRng` + `EventLog`로 결정적 시뮬레이션을 갖추고 있어서 **입력 기록 방식**이 자연스럽다. 3.5분(210초) 매치 기준 입력 기록은 약 **5MB** 이하.

---

## 5. 비슷한 규모의 실제 구현 사례

### 5.1 Godot 멀티플레이어 프로덕션

| 게임 | 규모 | 기술 스택 | 비고 |
|---|---|---|---|
| Dome Keeper | 2~4인 co-op | Godot 4, ENet, 전용 서버 | Steam $6.1M 수익. GodotCon 2025 발표 |
| Relay Zero | 오픈소스 데모 | Godot 4, WebSocket, Docker | 클라이언트/서버 분리, 권위 고정 틱 루프 |

### 5.2 .io 게임 아키텍처

| 게임 | 플레이어 수 | 서버 | 프로토콜 | 비고 |
|---|---|---|---|---|
| agar.io | ~100/방 | Node.js | WebSocket | 서버 권위, 원형 충돌만 |
| slither.io | ~500/방 | Go | WebSocket | 매우 최적화된 바이너리 프로토콜 |
| surviv.io | ~80/방 | Node.js | WebSocket | 브라우저 배틀로얄, Kongregate 인수 |
| diep.io | ~50/방 | Node.js | WebSocket | 서버 권위, 바이너리 직렬화 |

이 게임들의 공통점: **서버가 모든 게임 로직을 실행하고, 클라이언트는 렌더링만 담당**. WebSocket 위에서 자체 바이너리 프로토콜을 사용하되, 초기에는 JSON으로 시작한 경우가 많다. ([GitHub io-game topic](https://github.com/topics/io-game), [Dataconomy](https://dataconomy.com/2025/11/04/step-by-step-guide-building-a-multiplayer-browser-game-using-node-js/))

### 5.3 Gang-Up과의 대응

Gang-Up(8인, 탑다운 슈터, 웹 내보내기)은 surviv.io와 가장 유사한 프로필이다. 차이점은 Godot를 사용한다는 점과, surviv.io보다 더 적은 플레이어 수(8 vs 80)라는 점이다. 이 규모에서는 서버 비용이 사실상 무시할 수 있으며, 전용 서버의 공정성/안티치트 이점만 온전히 취할 수 있다.

---

## 참고 출처

- [Softlist — Dedicated Servers vs P2P](https://www.softlist.io/dedicated-servers-vs-peer-to-peer-networking/)
- [AccelByte — Server-Authoritative Logic](https://accelbyte.io/blog/server-authoritative-logic-to-prevent-cheating)
- [AccelByte — P2P vs Relay vs Dedicated](https://accelbyte.io/blog/p2p-vs-relay-vs-dedicated-servers)
- [Edgegap — Cheaters & P2P](https://edgegap.com/blog/cheaters-peer-to-peer-hosting-an-beginners-guide)
- [Supercraft — Server-Authoritative Anti-Cheat](https://crux.supercraft.host/blog/server-authoritative-anti-cheat-backend/)
- [Gabriel Gambetta — Client-Side Prediction](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html)
- [Daniel Jiménez Morales — Hit Registration](https://danieljimenezmorales.github.io/2023-10-29-the-art-of-hit-registration/)
- [Ziva — Godot 4 Multiplayer Best Practices](https://ziva.sh/blogs/godot-multiplayer)
- [Gameye — Godot Dedicated Server Hosting](https://gameye.com/blog/godot-dedicated-server-hosting/)
- [Supercraft — Godot Dedicated Server Setup](https://crux.supercraft.host/blog/godot-multiplayer-dedicated-server-backend/)
- [Godot Docs — WebSocket](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html)
- [StraySpark — Godot 4 Authoritative Server](https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server)
- [Andres Romero — Dedicated Game Server Hosting](https://www.andresromero.dev/blog/dedicated-game-server-hosting)
- [GameRant — Apex Legends Netcode](https://gamerant.com/apex-legends-netcode/)
- [Dexerto — BR Netcode Comparison](https://www.dexerto.com/apex-legends/how-bad-is-apex-legends-netcode-compared-to-fortnite-pubg-1290489/)
- [SDE Ray — Fortnite/PUBG Architecture](https://sderay.com/how-do-multiplayer-games-like-fortnite-and-pubg-handle-millions-of-concurrent-players/)
- [GitHub — agar.io-clone Architecture](https://github.com/huytd/agar.io-clone/wiki/Game-Architecture)
- [Wikipedia — Surviv.io](https://en.wikipedia.org/wiki/Surviv.io)
- [Dataconomy — Multiplayer Browser Game](https://dataconomy.com/2025/11/04/step-by-step-guide-building-a-multiplayer-browser-game-using-node-js/)
- [Web Game Dev — Prediction & Reconciliation](https://www.webgamedev.com/backend/prediction-reconciliation)
