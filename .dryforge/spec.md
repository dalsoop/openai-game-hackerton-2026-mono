# spec.md — Next.js 게임 플랫폼

## 목표

기존 Node.js 허브 + Godot WASM 3종(다굴/Snake Arena/Hex Clash)을 Next.js App Router 기반 통합 플랫폼으로 재구성한다. React가 로비/방/매칭/채팅을 즉시 제공하고, Godot WASM은 인게임 렌더링만 담당한다.

## 동기

- Godot WASM 66MB 로딩이 브라우저를 프리즈시켜서 로비조차 못 쓰는 문제 해소
- custom_shell.html에 HTML 로비를 넣는 우회책이 상태 꼬임과 코드 이중 관리를 유발
- 게임 추가 시 허브/로비/배포를 매번 복제해야 하는 구조 개선

## 아키텍처

```
Next.js App Router (단일 서버)
├── / (게임 선택 홈)
├── /dagul (다굴 로비/방/게임)
├── /snake (Snake Arena 로비/방/게임)
├── /hex (Hex Clash 로비/방/게임)
├── /api/ws (WebSocket 허브 — 방 관리/매칭/채팅)
└── /api/auth (간단한 세션 — 쿠키 기반)
```

## 동작 명세

### 페이지 흐름

1. `/` — 게임 선택 홈. 3개 게임 카드. 닉네임 입력.
2. `/dagul` — 다굴 로비. 방 목록, 방 만들기, 참가, 관전.
3. `/dagul/room/[id]` — 대기실. 8인 슬롯, 채팅, 게임 시작.
4. `/dagul/play` — 인게임. Godot 캔버스가 전체 화면. 매치 종료 시 결과 오버레이.

Snake, Hex도 동일한 `/snake/...`, `/hex/...` 경로.

### WebSocket 허브 (API Route)

기존 src/relay.ts + state.ts 로직을 Next.js Custom Server의 WebSocket 핸들러로 이전한다.

- 경로: 게임별 `/api/ws/dagul`, `/api/ws/snake`, `/api/ws/hex`
- 프로토콜: 기존과 동일 (hello, rooms, create, join, start, peers, chat, leave, kick, snap, input)
- 각 게임이 독립된 방 풀을 가진다.

### 세션

- 쿠키 기반 세션. 서버에서 `crypto.randomUUID()`로 세션 ID 발급.
- 세션에 저장: 닉네임, 현재 방 ID, 전적(킬/승리 수).
- 세션 만료: 24시간 비활동 시.
- 로그인 없이 닉네임만 입력하면 세션 시작.

### Godot WASM 백그라운드 프리로드

- 게임 선택 또는 로비 진입 시 해당 게임의 WASM+PCK를 `fetch()`로 백그라운드 다운로드 시작.
- 다운로드 진행률을 로비 하단에 표시 (바이트 단위).
- `WebAssembly.compileStreaming()`으로 다운로드와 컴파일을 동시 진행.
- 매치 시작 시 이미 컴파일된 WASM 모듈을 사용해서 Godot Engine을 즉시 시작.
- 아직 다운로드 중이면 "게임 로딩 중..." 표시하며 완료 대기.

### Godot 캔버스 컴포넌트

- React 컴포넌트 `<GodotCanvas game="dagul" matchInfo={...} />`
- 매치 시작 시 canvas를 표시하고 Godot Engine을 프로그래매틱하게 시작.
- 매치 정보(방 ID, 닉네임, 슬롯, 허브 URL)를 localStorage로 전달.
- Godot 측에서 `JavaScriptBridge.eval()`로 React에 매치 종료를 알림.
- 매치 종료 시 canvas를 숨기고 React 결과 화면 표시.

### Godot 측 컷오프

- flow_screens.gd의 인트로/로비/대기실 → **비활성화(분기 처리)**. `GameState.hub_launched`가 true이면 건너뛴다. false이면 기존 Godot 로비가 동작한다 (개발 시 에디터에서 직접 테스트용).
- custom_shell.html → 최소화 (Godot 엔진 로더만, UI 없음).
- game_root.gd에서 `GameState.hub_launched = true`일 때 바로 게임 시작하는 기존 로직 활용.

### 게임 플러그인 구조

게임을 추가할 때 필요한 것:
1. Godot 프로젝트 (`apps/server-yjh-<name>/project/`)
2. 게임 설정 파일 (`games/<name>/config.ts` — 이름, 설명, 플레이어 수, 모드, 아이콘)
3. WebSocket 핸들러 (기본 방 관리는 공통, 게임별 커스텀 메시지만 추가)

공통 모듈:
- `lib/hub/` — 방 관리, 매칭, 채팅 (게임 무관 공통 로직)
- `lib/session/` — 세션 관리
- `lib/godot/` — WASM 로더, 캔버스 컴포넌트

### Custom Server 실행

Next.js App Router는 WebSocket을 네이티브 지원하지 않으므로 Custom Server로 실행한다:
- 진입점: `web/server.ts` — `http.createServer` + `next()` + `ws` WebSocket 핸들러
- 실행: `node dist/server.js` (tsc 빌드 후), `next dev`는 개발 시에만
- `web/package.json` scripts: `"dev": "tsx server.ts"`, `"build": "next build && tsc --project tsconfig.server.json"`, `"start": "node dist/server.js"`

### Godot Engine 로더 API (4.7 기준)

Godot 웹 내보내기가 생성하는 `index.js`는 전역 `Engine` 클래스를 노출한다:
```typescript
// web/lib/godot/engine-loader.ts
const engine = new (window as any).Engine({
  args: ['--main-pack', `/godot/${game}/index.pck`],
  canvasResizePolicy: 2,
  canvas: canvasElement,
  executable: `/godot/${game}/index`,
});
await engine.startGame();
// 종료: engine.requestQuit()
```
- WASM 파일: `/godot/<game>/index.wasm`
- PCK 파일: `/godot/<game>/index.pck`
- JS 로더: `/godot/<game>/index.js` — `<script>` 태그로 로드하면 `window.Engine` 등록

### React ↔ Godot 통신 계약

**React → Godot (매치 시작 시, localStorage 키):**
- `gangup_from_hub`: `"1"` — Godot가 읽으면 로비를 건너뛰고 바로 게임 진입
- `gangup_name`: 닉네임 문자열
- `gangup_room_id`: 방 ID
- `gangup_you`: 슬롯 번호 문자열
- `gangup_game_url`: 게임 서버 WebSocket URL (있으면)
- 타이밍: React가 쓴 직후 Godot Engine.startGame() 호출. Godot는 `_ready()`에서 한 번 읽음.

**Godot → React (매치 종료 시):**
- Godot: `JavaScriptBridge.eval("window.dispatchEvent(new CustomEvent('godot-match-end', {detail: {result: 'win', slot: 0}}))")`
- React: `window.addEventListener('godot-match-end', handler)`

### 배포 단위

**하나의 Next.js 서버가 3개 게임을 모두 서빙한다.** 기존 `server-*`별 독립 배포 구조에서 단일 서버로 전환. `*.external.kr` 도메인은 하나의 서비스를 가리키고, URL 경로(`/dagul`, `/snake`, `/hex`)로 게임을 분기한다.

### 빌드 파이프라인

1. Next.js 빌드: `next build` → `.next/`
2. Godot 웹 내보내기: CI에서 각 게임 WASM+PCK 생성 → `apps/server-yjh-<game>/project/web/`
3. **WASM 복사 단계**: CI가 각 게임의 `project/web/*`를 `web/public/godot/<game>/`로 복사
4. Docker 이미지: Next.js 서버 + Godot 정적 파일
5. K3s 배포: 기존 Helm 차트 확장

## 불변

- Godot 시뮬레이션 코드(game_world.gd 등)는 건드리지 않는다.
- 기존 게임플레이가 유지된다.
- 웹 내보내기(HTML5)가 동작한다.
- 멀티플레이어 WebSocket 프로토콜이 호환된다.

## 범위 경계

- 포함: Next.js 앱, WebSocket 허브 이전, React 로비/방/게임선택, Godot 캔버스 래퍼, 세션, 프리로더, Godot 컷오프, Docker/Helm 배포.
- 제외: OAuth 인증, 리더보드 DB, 관전 모드 UI (기본 구조만), 결제, 모바일 네이티브.

## 검증

- Next.js `next build` 성공.
- 3개 게임 로비/방 만들기/참가/매치 시작이 동작.
- Godot WASM이 백그라운드 프리로드 후 매치 시 즉시 시작.
- 기존 WebSocket 프로토콜 호환 (기존 Godot 클라이언트로도 접속 가능).
- K3s 배포 후 `*.external.kr` 접속 가능.
