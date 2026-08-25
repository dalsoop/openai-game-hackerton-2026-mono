# handoff.md — 멀티플레이어 마이그레이션

## 문서 역할

| 문서 | 역할 | 충돌 시 |
|---|---|---|
| `spec.md` | 동작 정의 (정본) | spec이 이긴다. spec 오류는 사용자 승인 후에만 수정 |
| `plan.md` | 작업 순서 + 파일 대상 (잠정) | 자유롭게 수정 가능 |
| `handoff.md` | 실행 맥락 + 제약 | 프로젝트 전체 제약을 기록 |

기존 코드는 HOW 참조이지 WHAT의 정본이 아니다.

## 파일 위치

- `.dryforge/spec.md` — 동작 명세
- `.dryforge/plan.md` — 실행 계획 + Execution Graph
- `.dryforge/handoff.md` — 이 문서

## 실행 형태

8개 태스크, 4개 wave. Wave 1(T1+T2 병렬: 서버 골격 + 클라이언트 분리) → Wave 2(T3: 서버 시뮬레이션 이전) → Wave 3(T4+T5+T6+T7 병렬: 래그 보상, 재접속, 관전, 리플레이) → Wave 4(T8: 전체 슬롯 전파).

## 제약 (코드에서 도출할 수 없는 것)

- 해커톤 마감이 내일이다. 속도 우선이지만 로컬 플레이가 깨지면 안 된다.
- 모든 dev 슬롯(yjh, pjh, fig)에 동시 적용한다. fig-dev1에서 먼저 구현하고 project/ 폴더를 복사한다.
- `game-pjh-gang-up`은 원본이므로 절대 수정하지 않는다.
- `wss://`가 HTTPS 페이지에서 필수이다. 배포 시 TLS 인증서가 이미 있는 `*.external.kr` 도메인을 사용한다.
- Godot 헤드리스 서버는 기존 허브와 같은 서버 머신에서 실행한다. 포트를 분리한다(허브 9120, 게임 9121).
- Node.js 허브의 방 관리 코드(`src/`)는 유지한다. 스냅샷/입력 중계 메시지만 제거한다.

## 설계 결정 (채택한 것과 이유)

- **호스트 클라이언트 대신 전용 서버를 선택한 이유:** 호스트 어드밴티지(0ms 레이턴시), 치팅 취약성, 호스트 이탈 시 매치 중단 — 경쟁 게임에서 공정성이 결정적이므로.
- **Godot 헤드리스를 선택한 이유:** `GangGameWorld`가 `RefCounted` 기반 순수 연산이라 씬 트리에 의존하지 않으므로 `--headless`로 그대로 실행 가능. Dome Keeper가 프로덕션 사례를 확립(GodotCon 2025).
- **프로세스 내 다중 매치를 선택한 이유:** 8인 규모에서 CPU 부하가 낮아 Docker per 매치 오버헤드가 불필요. 하나의 프로세스로 10~20개 동시 매치 가능.
- **롤백을 도입하지 않는 이유:** 8인 배틀로얄에서 전체 상태 롤백 비용이 높고, 현재 스냅샷 보간 + 클라이언트 예측이 이미 충분히 동작. Netfox 틱 동기화만 선택 도입.
- **입력 기록 방식 리플레이를 선택한 이유:** `SeededRng`로 결정적 시뮬레이션이 이미 보장되어 있어서 입력만 저장하면 정확한 재현이 가능. 스냅샷 기록보다 용량이 작고 구현이 간단.

## 참고 자료

- `docs/multiplayer-migration-design.md` — Fable이 작성한 마이그레이션 설계서 (AS-IS/TO-BE, 코드 예시, 파일별 영향도)
- `docs/multiplayer-architecture-research.md` — 업계 사례 연구 (surviv.io, Dome Keeper, Gabriel Gambetta, 래그 보상 임계값)

---

## Project Foundation (첫 사이클 프로젝트 맥락 — 실행 대상이 아님)

> 이 섹션은 실행 가능한 명세가 아니라 프로젝트 전체 맥락이다. `go`는 이 섹션을 참고로 읽되 구현 대상으로 삼지 않는다.

### 1. 프로젝트 정체성

다굴(Gang-Up)은 OpenAI 게임 해커톤 파티 엔트리로, 8인 탑다운 배틀로얄 게임이다. Godot 4 + GDScript + 웹 내보내기(HTML5)로 제작하고, Node.js WebSocket 허브로 멀티플레이를 지원한다. 3명의 개발자(정한/크리엘/Figix)가 각자 dev 슬롯에서 작업하며 project/ 폴더를 공유한다. 조작감이 제품이고, 기본값은 빡셈.

### 2. 도메인 모델

**게임 구조:**
- 8인 개인전. 마지막 생존이 승리. 로컬은 인간 1 + CPU 7.
- 12종 동물 캐릭터: 쥐(물결), 뱀(허물), 용(연기), 호랑이(포효), 토끼(굴), 말(발차기), 닭(알), 돼지(진흙), 개(돌진), 황소(돌진). 각자 고유 궁극기.
- 모드 5종: 클래식, 단발, 연발, 아이템, 풀. 한 Godot 앱 로비에서 선택.
- 결정론적 시뮬레이션: `SeededRng`, 고정 타임스텝 1/60, `EventLog`.
- 아레나: 7840×4760, 엄폐물(타일링), 세이프존(5단계 수축), 중앙 타워(75초에 스폰).
- 체력/힐: 체력 픽업(30% 회복, 16초 리스폰), 크레이트(파괴 시 오브 드롭).
- 다운/부활: 다운 시 5초 출혈, 최대 3회 부활, 부활 시간은 순위에 비례.

**네트워크 구조 (현재):**
- `hub_client.gd`: 원시 WebSocketPeer로 허브에 연결. hello/rooms/join/create/start/snap/input/chat 메시지.
- `network_host.gd`: 호스트 클라이언트가 `build_snapshot()`으로 스냅샷을 허브에 전송, 허브가 다른 클라이언트에 중계.
- `net_world.gd`: 비호스트 클라이언트가 스냅샷을 보간(`_lerp_motion`), 예측(`predict_local`), 재조정(`_reconcile`), 외삽(`_extrapolate`).
- `game_root.gd`: 호스트/클라이언트/로컬 3분기로 `_tick_world()` 실행.

**UI 구조:**
- 코드 전용 UI (.tscn 없음). `flow_screens.gd`가 로비/방/설정 화면을 코드로 구성.
- `debug_renderer.gd`가 모든 시각 요소를 `_draw()`로 렌더링 (스프라이트 없음).

### 3. 기술 결정

- **엔진:** Godot 4, GDScript, 웹 내보내기(HTML5).
- **허브:** Node.js + ws 라이브러리 + prom-client(메트릭). TypeScript(`src/`).
- **배포:** GitHub Actions `Apps ship` → Helm → `*.external.kr`. wasm/pck는 git에 넣지 않음.
- **시뮬레이션:** `GangGameWorld`는 `RefCounted` 기반 순수 연산. 씬 트리에 의존하지 않음.
- **검증:** `deploy/usability && node cli.mjs smoke`.

### 4. 향후 범위 (이번 작업 범위 밖)

- 리플레이 뷰어 UI (재생 컨트롤, 속도 조절, 플레이어 시점 전환)
- 관전자 시점 전환 (특정 플레이어 따라가기)
- 고급 안티치트 (행동 패턴 분석, 리포트 시스템)
- 바이너리 프로토콜 최적화 (`StreamPeerBuffer` 완전 전환)
- MultiplayerSynchronizer를 로비 상태 동기화에 적용
- 매치메이킹 (레이팅 기반 자동 매칭)
- 서버 수평 확장 (매치별 컨테이너 분리)
