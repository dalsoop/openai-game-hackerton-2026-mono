
---

## 추가 발견 (2026-08-24 후반 세션)

### Godot WebSocket 연결 실패
- Godot `hub_client.gd:73-78`이 `wss://<host>/gang-up/ws`로 연결하지만, 서버+Caddy+Cloudflare 경로에서 `/gang-up/ws`가 404 반환
- 웹 허브는 `wss://<host>/gang-up`(ws 없이)으로 잘 동작
- 원인: Caddy가 `/gang-up*` 패턴으로 프록시하지만 `/gang-up/ws`는 별도 매칭 필요, 또는 Cloudflare HTTP/2가 WS 업그레이드 차단
- 수정: hub_client.gd의 URL에서 `/ws` 제거 → `/gang-up`으로 변경 → web export 재빌드

### 닉네임 전달 미동작
- goToGame()에서 `gangup_name`을 localStorage에 저장하지만, Godot이 "플레이어82"로 표시 → consume_hub_launch 후 닉네임이 적용되기 전에 hello가 먼저 나갔을 가능성
- hub_client.gd의 player_name 설정 타이밍 확인 필요

### 스켈레톤 로딩 동작 확인
- /gang-up/ 로비 즉시 로드 ✔
- 프리페치 진행률 바 ✔ ("게임 다운로드 88%" → "게임 준비 완료")
- "게임으로 이동" 클릭 → / 이동 ✔
- Godot 로딩 + 캐시 히트 빠른 로드 ✔
- 서버 연결 실패 ✖ (WS URL 문제)

### 배포 큐 상태 (세션 종료 시점)
- `refactor: 서버 모듈화 + 로비 분리 1단계` — in_progress 28분+ (비정상)
- `fix: game_root.gd hub_name 타입 추론 에러 수정` — pending (위 배포 완료 대기)
- 수정된 pck(타입 에러 수정 + WS URL /gang-up)가 아직 배포되지 않음
- 배포 완료 후 `/gang-up/` → "게임으로 이동" → Godot 서버 연결 테스트 필요

### 다음 세션 체크리스트
1. 배포는 로컬 `apply-apps.py ship` / `helm`. Actions 빌드 큐는 보지 않는다.
2. Godot 콘솔에서 Parse Error 없는지 확인
3. `/gang-up/` → 방 만들기 → "게임으로 이동" → Godot 서버 연결 → 방 복귀 테스트
4. 닉네임 "웹XX" 대신 허브에서 정한 이름이 Godot에 표시되는지 확인
5. 게임 종료/ESC 시 `/gang-up/`으로 복귀되는지 확인 (hub_launched=true일 때)

### i18n 분리 계획
- Godot: `project/locale/ko.csv` + `tr()` 함수. 상태 비교도 키 기반으로 변경.
- 허브 HTML: JS 상단에 `const I18N = {}` 객체
- 서버 TS: `src/messages.ts`에 에러/알림 메시지 상수
- 현재 한국어 하드코딩 위치: game_root, network_manager, flow_screens, index.html, state.ts
