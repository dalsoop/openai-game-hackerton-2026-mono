# 5명 병렬 실행팀 구성 — 다굴(Gang-Up) 완성 계획

## 현재 상태 요약

- game_world.gd 모듈화: 13개 모듈 추출 완료 (파사드 1176줄, 500줄 초과 4개 잔존)
- 코드 퀄리티: game_root(488), net/(388+192+495), UI(500+145+248+198) 정리 완료
- debug_renderer: 모듈 파일 4개 생성, 파사드 통합 미적용 (1721줄)
- 모드: full 1종으로 단순화 완료
- Godot 파싱 에러: 0건
- 멀티플레이어: dryforge spec/plan 작성 완료, 구현 미착수

## 5명 에이전트 배정

### 에이전트 A — 서버 코어 (멀티플레이어 핵심)

**담당**: 헤드리스 서버 구축 + 시뮬레이션 이전

**작업 파일 (신규 생성)**:
- `scripts/net/game_server.gd` — 서버 메인 루프, 피어 관리, HTTPServer(:9122)
- `scripts/net/server_match.gd` — 매치 인스턴스, step_tick 호출, 스냅샷 발행(20Hz)
- `scripts/net/game_client.gd` — WebSocketMultiplayerPeer 클라이언트, RPC 입력/스냅샷

**작업 파일 (수정)**:
- `scripts/game_root.gd` — `--server` 분기 추가, 호스트/클라이언트 분기 제거
- `project.godot` — 서버 autoload 등록

**작업 내용 (dryforge T1+T2+T3)**:
1. WebSocketMultiplayerPeer 서버 골격 (에코 → 매치 시작)
2. game_client.gd 작성 (입력 RPC 전송, 스냅샷 RPC 수신)
3. server_match.gd에서 GangGameWorld.step_tick() 실행 + build_snapshot() 브로드캐스트
4. game_root.gd에서 `--server` 감지 시 UI/렌더 생략, game_server.gd 기동
5. 로컬 모드(GameState.net_active == false) 코드 경로 보존

**파일 충돌**: game_root.gd를 수정하므로 에이전트 D(밸런스)와 겹칠 수 있음 → game_root.gd 수정은 A가 전담

**검증**:
- `godot --headless -- --server --port 9121` 기동 후 클라이언트 연결 성공
- 로컬 매치(인간 1+CPU 7) 정상 동작
- 8인 온라인 매치 동기화

---

### 에이전트 B — 네트워크 기능 (재접속/관전/리플레이/래그보상)

**담당**: 서버 위에 올라가는 네트워크 기능 전체

**작업 파일 (신규 생성)**:
- `scripts/net/replay_recorder.gd` — 입력 시퀀스 기록 + JSON 저장
- `scripts/net/lag_compensator.gd` — 히트박스 되감기 + RTT 기반 판정

**작업 파일 (수정)**:
- `scripts/net/game_server.gd` — 관전자 피어 처리, 재접속 토큰 매핑, 래그 보상 호출
- `scripts/net/game_client.gd` — 관전 모드 플래그, 자동 재연결
- `scripts/net/server_match.gd` — 풀/델타 스냅샷 분기, 리플레이 기록 호출
- `scripts/ui/flow_screens.gd` — 관전 버튼 추가

**의존**: **에이전트 A의 서버 골격이 완성된 후 시작** (game_server.gd, game_client.gd, server_match.gd가 존재해야 함)

**작업 내용 (dryforge T4+T5+T6+T7)**:
1. 재접속: resume_token→slot 매핑, 30초 타임아웃, 풀 스냅샷 재전송
2. 델타 압축: 이전 스냅샷과 diff만 전송
3. 관전 모드: 읽기 전용 피어, 입력 없이 스냅샷만 수신
4. 리플레이: replay_recorder.gd가 매치 중 입력 기록, 종료 시 JSON 저장
5. 래그 보상: lag_compensator.gd에서 히트박스 되감기 (250ms 임계값)
6. 입력 검증: 이동 속도/발사 속도 서버측 검증

**파일 충돌**: flow_screens.gd를 수정하므로 에이전트 C(사운드)와 겹칠 수 있음 → flow_screens.gd의 관전 버튼은 B가 전담, C는 flow_screens.gd를 건드리지 않음

**검증**:
- 매치 중 브라우저 새로고침 → 30초 이내 재접속
- 관전자가 매치를 실시간으로 볼 수 있음
- 리플레이 JSON 저장 + 재시뮬레이션 동일 결과
- 인위적 지연 100ms/200ms에서 히트 판정 정상

---

### 에이전트 C — 사운드 + 에셋

**담당**: 오디오 시스템 구축 + 시각 에셋 기반 마련

**작업 파일 (신규 생성)**:
- `addons/sound_manager/` — Sound Manager 패키지 설치 (또는 자체 구현)
- `scripts/audio/game_audio.gd` — 효과음 풀링, 음악 크로스페이드
- `assets/sfx/` — 효과음 파일 배치 (총소리, 스킬, 피격, UI)
- `assets/sprites/` — 캐릭터/무기/환경 스프라이트 (있다면 배치)

**작업 파일 (수정)**:
- `scripts/sfx_manager.gd` — 기존 SfxManager를 Sound Manager 기반으로 교체
- `scripts/render/debug_renderer.gd` — 스프라이트 렌더링으로 전환 준비 (에셋이 있는 경우에만)
- `scripts/render/render_heroes.gd` — 히어로 스프라이트 적용
- `scripts/render/render_environment.gd` — 환경 스프라이트 적용
- `project.godot` — Sound Manager autoload 등록

**파일 충돌 없음**: render/ 모듈 파일과 audio/ 디렉터리는 C만 접근

**작업 내용**:
1. Sound Manager(또는 자체 AudioPool) 설치
2. 효과음 매핑: 총 발사, 피격, 스킬 사용, 다운, 제거, UI 클릭
3. sfx_manager.gd를 오디오 풀링 기반으로 교체
4. 에셋이 있다면 debug_renderer의 도형 → 스프라이트 전환 시작

**검증**:
- 총 발사/피격 시 효과음 재생
- 동시 8명 발사 시 오디오 겹침 없음
- 웹 내보내기에서 오디오 정상 재생

---

### 에이전트 D — 밸런스 + 테스트

**담당**: 게임 밸런스 조정 + 자동화 테스트 구축

**작업 파일 (신규 생성)**:
- `project/tests/gut/` — GUT 테스트 디렉터리
- `project/tests/gut/test_game_world.gd` — 시뮬레이션 단위 테스트
- `project/tests/gut/test_equipment.gd` — 장비 데이터 테스트
- `project/tests/gut/test_determinism.gd` — 결정론 검증 (같은 시드 → 같은 결과)
- `project/addons/gut/` — GUT 플러그인 설치

**작업 파일 (수정)**:
- `scripts/sim/equipment_registry.gd` — 밸런스 수치 조정
- `scripts/sim/damage_system.gd` — 데미지 공식 튜닝
- `scripts/sim/roulette_buff.gd` — 버프 수치 조정
- `docs/FEEL-TUNING.md` — 변경된 수치 기록
- `project.godot` — GUT autoload/설정

**파일 충돌**: sim/ 모듈 파일의 수치만 변경하므로 A(서버)와 겹치지 않음. game_root.gd는 건드리지 않음.

**작업 내용**:
1. GUT 설치 + 프로젝트 설정
2. 시뮬레이션 단위 테스트: reset → step_tick 100틱 → 상태 검증
3. 결정론 테스트: 같은 시드+입력 → 같은 최종 상태
4. 장비 밸런스: DPS, TTK(Time To Kill) 분석 + 조정
5. 버프/룰렛 밸런스 검토
6. FEEL-TUNING.md 갱신

**검증**:
- GUT 테스트 전체 통과
- 결정론 테스트: 100회 반복 동일 결과
- full 모드에서 무기 간 TTK 편차 ±15% 이내

---

### 에이전트 E — 배포 + 허브 + 코드 품질

**담당**: Node.js 허브 수정 + 슬롯 전파 + 배포 + 잔여 린트

**작업 파일 (수정)**:
- `src/relay.ts` — host_snap/peer_input 중계 제거
- `src/index.ts` — 매치 시작 시 Godot 서버에 HTTP POST 추가
- `src/state.ts` — 매치 상태 관리 축소
- `Dockerfile` — Godot 헤드리스 서버 빌드 단계 추가
- `deploy/` — Helm 차트에 게임 서버 포트(9121, 9122) 추가
- `hackertone.yaml` — 서버 설정 업데이트

**작업 내용**:
1. Node.js 허브 수정: 스냅샷/입력 중계 제거, match_started에 서버 URL 포함
2. Dockerfile에 Godot 헤드리스 서버 빌드 추가
3. Helm 차트에 게임 서버 서비스/포트 추가
4. yjh-dev1 project/ → pjh-dev1, fig-dev1, prod 복사
5. gdlint + 커스텀 린터 최종 실행 → 잔여 경고 수정
6. `python3 deploy/scripts/status.py` 확인

**파일 충돌 없음**: src/, deploy/, Dockerfile은 E만 접근

**검증**:
- 모든 슬롯에서 `https://<슬롯>.external.kr/` 접속 가능
- 보드(`server-board.external.kr`)에서 전체 상태 healthy
- `deploy/usability && node cli.mjs smoke` 통과
- gdlint 에러 0건

---

## 에이전트 간 의존성

```
Wave 1 (병렬):  A(서버 코어)  |  C(사운드)  |  D(밸런스+테스트)  |  E(허브+배포 준비)
                     ↓
Wave 2 (A 완료 후): B(네트워크 기능) — A의 서버 골격에 의존
                     ↓
Wave 3 (전부 완료 후): E(슬롯 전파 + 최종 배포)
```

### 상세 의존 관계

| 에이전트 | 선행 조건 | 이유 |
|---|---|---|
| A (서버 코어) | 없음 | 독립적으로 시작 가능 |
| B (네트워크 기능) | **A 완료** | game_server.gd, game_client.gd, server_match.gd가 존재해야 함 |
| C (사운드) | 없음 | render/, audio/ 파일만 작업, 서버와 독립 |
| D (밸런스+테스트) | 없음 | sim/ 모듈의 수치만 변경, 서버와 독립 |
| E (허브+배포) | **A+B+C+D 모두 완료** (슬롯 전파 단계에서) | 최종 project/를 복사해야 하므로. 허브 수정(src/)은 Wave 1에서 선행 가능 |

## 파일 충돌 검증

| 파일/디렉터리 | 접근 에이전트 | 충돌 여부 |
|---|---|---|
| `scripts/net/game_server.gd` | A(생성) → B(수정) | 순차(Wave 1→2), 충돌 없음 |
| `scripts/net/game_client.gd` | A(생성) → B(수정) | 순차, 충돌 없음 |
| `scripts/net/server_match.gd` | A(생성) → B(수정) | 순차, 충돌 없음 |
| `scripts/game_root.gd` | A만 | 충돌 없음 |
| `scripts/net/hub_client.gd` | A만 (분리) | 충돌 없음 |
| `scripts/ui/flow_screens.gd` | B만 (관전 버튼) | 충돌 없음 |
| `scripts/render/*` | C만 | 충돌 없음 |
| `scripts/sfx_manager.gd` | C만 | 충돌 없음 |
| `scripts/sim/*.gd` | D만 (수치 변경) | 충돌 없음 |
| `src/*.ts` | E만 | 충돌 없음 |
| `deploy/`, `Dockerfile` | E만 | 충돌 없음 |
| `project.godot` | A(서버 등록) + D(GUT) + C(사운드) | **잠재적 충돌** → 각자 다른 섹션([autoload])을 수정하므로 실제 충돌 가능성 낮음. 단, Wave 1에서 동시에 건드리면 merge 필요. A가 먼저 수정하고, C와 D는 A 이후에 autoload 추가 권장 |
| `docs/FEEL-TUNING.md` | D만 | 충돌 없음 |

### 유일한 잠재 충돌: `project.godot`

project.godot을 A, C, D가 모두 수정할 수 있다. 완화 방법:
- A가 Wave 1에서 `[autoload]` 섹션에 서버 관련 항목을 추가한다
- C와 D는 A가 project.godot 수정을 마친 후에 각자 autoload를 추가한다
- 또는 E가 Wave 3에서 project.godot의 autoload를 통합 정리한다

## Wave별 실행 일정

### Wave 1 (동시 4명)

| 에이전트 | 작업 | 산출물 |
|---|---|---|
| A | 서버 골격 + 시뮬 이전 + 클라이언트 분리 | game_server.gd, server_match.gd, game_client.gd, game_root.gd 수정 |
| C | Sound Manager + 효과음 배치 | game_audio.gd, sfx_manager.gd 교체 |
| D | GUT 설치 + 시뮬 테스트 + 밸런스 | test_*.gd, 수치 조정 |
| E | 허브 수정 + Dockerfile + Helm | relay.ts, index.ts, Dockerfile, deploy/ |

**Wave 1 검증**: 각 에이전트가 자체 Godot 파싱 테스트 통과

### Wave 2 (A 완료 후, 1명)

| 에이전트 | 작업 | 산출물 |
|---|---|---|
| B | 재접속 + 관전 + 리플레이 + 래그보상 | replay_recorder.gd, lag_compensator.gd, 서버 파일 확장 |

**Wave 2 검증**: 재접속, 관전, 리플레이, 래그보상 개별 동작 확인

### Wave 3 (전부 완료 후, 1명)

| 에이전트 | 작업 | 산출물 |
|---|---|---|
| E | 슬롯 전파 + 최종 배포 + 린트 | pjh, fig, prod 복사, 배포, gdlint |

**Wave 3 검증**: 모든 슬롯 healthy + smoke 테스트 통과

## 최종 검증 체크리스트

- [ ] 로컬 매치(인간 1+CPU 7) 정상 동작
- [ ] 8인 온라인 매치 서버 권위로 동작
- [ ] 관전자가 매치를 실시간으로 볼 수 있음
- [ ] 매치 중 재접속 → 같은 슬롯 복귀
- [ ] 리플레이 저장 + 재시뮬레이션 동일 결과
- [ ] 효과음 정상 재생 (겹침 없음)
- [ ] GUT 테스트 전체 통과
- [ ] 결정론 테스트 통과
- [ ] 모든 슬롯에서 웹 접속 가능
- [ ] gdlint 에러 0건
- [ ] smoke 테스트 통과
