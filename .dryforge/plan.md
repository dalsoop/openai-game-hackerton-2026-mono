# plan.md — Next.js 게임 플랫폼 실행 계획

## T1 — Next.js 프로젝트 골격

**목표:** Next.js App Router 프로젝트를 생성하고 기본 라우팅을 구성한다.

**작업 대상:**
- `web/` (신규 — Next.js 프로젝트 루트)
- `web/app/layout.tsx`, `web/app/page.tsx`
- `web/app/dagul/page.tsx`, `web/app/snake/page.tsx`, `web/app/hex/page.tsx`
- `web/package.json`, `web/tsconfig.json`, `web/next.config.ts`

**동작 계약:** `next dev`로 실행하면 `/`에서 게임 선택 홈이 뜨고, `/dagul`, `/snake`, `/hex`로 각 게임 로비가 뜬다.

**검증:** `next build` 성공, 3개 경로 접속 가능.

---

## T2 — WebSocket 허브 이전

**목표:** 기존 src/*.ts의 방 관리/매칭/채팅 로직을 Next.js Custom Server WebSocket으로 이전한다.

**작업 대상:**
- `web/server.ts` (Custom Server — WebSocket 핸들링)
- `web/lib/hub/room-manager.ts` (방 생성/참가/퇴장 — src/state.ts에서 이전)
- `web/lib/hub/relay.ts` (메시지 라우팅 — src/relay.ts에서 이전)
- `web/lib/hub/types.ts` (Client, Room 타입)

**동작 계약:** 기존 WebSocket 프로토콜(hello/rooms/create/join/start/peers/chat)이 Next.js 서버에서 동일하게 동작한다. 기존 Godot 클라이언트(network_manager.gd)로도 접속 가능하다.

**검증:** WebSocket 연결 → hello → rooms → create → joined 흐름 동작.

**사고 근거:** Next.js App Router는 WebSocket을 네이티브 지원하지 않으므로 Custom Server(server.ts)가 필요하다. `ws` 라이브러리로 HTTP Upgrade를 처리한다.

---

## T3 — React 로비/방/대기실 UI

**목표:** React 컴포넌트로 로비, 방, 대기실 UI를 구현한다.

**작업 대상:**
- `web/components/Lobby.tsx` (방 목록, 방 만들기, 새로고침)
- `web/components/Room.tsx` (대기실 — 슬롯, 채팅, 시작)
- `web/components/GameSelect.tsx` (홈 — 3게임 카드)
- `web/components/NicknameInput.tsx` (닉네임 입력)
- `web/hooks/useHub.ts` (WebSocket 연결 + 메시지 훅)
- `web/hooks/useSession.ts` (세션 관리)

**동작 계약:** 로비에서 방 목록이 실시간 업데이트되고, 방 만들기/참가/채팅이 동작한다. 대기실에서 플레이어 슬롯이 업데이트되고, 호스트가 시작을 누르면 게임으로 전환된다.

---

## T4 — Godot WASM 프리로더 + 캔버스

**목표:** Godot WASM을 백그라운드로 프리로드하고, 매치 시작 시 캔버스를 표시한다.

**작업 대상:**
- `web/components/GodotCanvas.tsx` (Godot 캔버스 래퍼)
- `web/hooks/useGodotLoader.ts` (WASM 프리로드 + compileStreaming)
- `web/lib/godot/engine-loader.ts` (Godot Engine API 래퍼)

**동작 계약:** 로비 진입 시 WASM+PCK 다운로드가 백그라운드로 시작된다. 진행률이 UI에 표시된다. 매치 시작 시 캔버스가 나타나고 Godot가 즉시 시작된다. 매치 종료 시 캔버스가 사라지고 React 결과 화면이 뜬다.

---

## T5 — 세션 + 전적

**목표:** 쿠키 기반 세션으로 닉네임과 간단한 전적을 유지한다.

**작업 대상:**
- `web/lib/session/session-store.ts` (인메모리 세션 저장소)
- `web/app/api/session/route.ts` (세션 API — 생성/조회)

**동작 계약:** 닉네임 입력 시 세션이 생성되고, 같은 브라우저에서 재방문하면 닉네임이 유지된다. 매치 결과(킬/승리)가 세션에 누적된다.

---

## T6 — Godot 측 컷오프

**목표:** Godot에서 인트로/로비/대기실 UI를 제거하고 인게임만 남긴다.

**작업 대상:**
- `project/scripts/ui/flow_screens.gd` (인트로/로비 제거, 게임 화면만)
- `project/scripts/game_root.gd` (`hub_launched` 분기 강화)
- `project/custom_shell.html` (최소화 — UI 없이 엔진 로더만)

**동작 계약:** Godot가 시작되면 바로 게임 화면으로 진입한다. 로비/방은 React가 처리하므로 Godot에서는 불필요하다.

---

## T7 — Docker + Helm 배포

**목표:** Next.js 서버 + Godot 정적 파일을 Docker로 패키징하고 K3s에 배포한다.

**작업 대상:**
- `web/Dockerfile` (Next.js 빌드 + 서빙)
- `deploy/chart/` (Helm 차트 확장 — Next.js 서비스 추가)

**동작 계약:** `*.external.kr`에서 Next.js 앱이 서빙되고, `/godot/<game>/` 경로에서 WASM 파일이 제공된다.

---

## T8 — 게임 플러그인 구조

**목표:** 게임 추가를 쉽게 만드는 설정 기반 구조를 구현한다.

**작업 대상:**
- `web/games/dagul/config.ts`
- `web/games/snake/config.ts`
- `web/games/hex/config.ts`
- `web/lib/game-registry.ts` (게임 목록 자동 수집)

**동작 계약:** `games/<name>/config.ts`를 추가하면 홈 화면에 게임 카드가 자동으로 나타나고, 해당 게임의 로비/방/게임 경로가 생성된다.

---

## Execution Graph

```yaml
tasks:
  - id: T1
    depends: []
    risk: MECHANICAL
  - id: T2
    depends: [T1]
    risk: RISKY
  - id: T3
    depends: [T1]
    risk: RISKY
  - id: T4
    depends: [T1]
    risk: RISKY
  - id: T5
    depends: [T1]
    risk: MECHANICAL
  - id: T6
    depends: [T4]
    risk: RISKY
  - id: T7
    depends: [T2, T3, T4, T5, T6]
    risk: MECHANICAL
  - id: T8
    depends: [T2, T3, T4]
    risk: MECHANICAL
```

Wave 1: T1
Wave 2: T2, T3, T4, T5 (병렬)
Wave 3: T6, T8 (병렬)
Wave 4: T7
