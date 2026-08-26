# React + Godot 이중 구조 설계서

다굴(Gang-Up), Snake Arena, Hex Clash 3개 게임의 프론트엔드를 React(TypeScript) SPA + Godot(WASM) 렌더러로 분리한다.

## 1. 왜 이중 구조인가

### 현재 문제
- Godot WASM 38MB + PCK 28MB = 66MB를 받아야 로비가 뜸
- WASM 컴파일이 메인 스레드를 블로킹해서 브라우저 프리즈
- custom_shell.html에 HTML 로비를 넣는 우회책은 코드 이중 관리 + 상태 꼬임 유발
- Godot의 코드 전용 UI는 웹 표준 UX와 거리가 있음

### 해결
- **React SPA가 즉시 로드**(번들 ~200KB) → 로비/방/매칭/채팅을 웹 표준 UI로 처리
- **Godot WASM은 백그라운드 프리로드** → 매칭이 잡히면 그때 캔버스 표시
- 두 세계의 통신은 [ReactBridge](https://godotengine.org/asset-library/asset/4980) 또는 [jsgdbridge](https://github.com/KronbergerSpiele/jsgdbridge) 패턴 사용
- 참고: [React + WebGL/WASM 게임 통합 발표](https://gitnation.com/contents/marrying-wasmwebgl-games-with-react-ui)

## 2. 아키텍처 개요

```
브라우저
┌─────────────────────────────────────────────────┐
│  React SPA (Vite + TypeScript)                  │
│  ├─ 로비: 방 목록, 생성, 참가                      │
│  ├─ 대기실: 슬롯, 채팅, 시작                       │
│  ├─ 게임 선택: 다굴 / Snake / Hex                 │
│  ├─ 결과 화면                                     │
│  └─ GodotCanvas: <canvas> 래퍼 컴포넌트            │
│       ↕ postMessage / localStorage               │
│  ┌──────────────────────────────────────┐        │
│  │ Godot WASM (인게임만)                  │        │
│  │  ├─ game_root.gd (시뮬+렌더+HUD)     │        │
│  │  └─ 매치 종료 시 React에 알림          │        │
│  └──────────────────────────────────────┘        │
└─────────────────────────────────────────────────┘
        ↕ WebSocket
┌─────────────────────────────────────────────────┐
│  Node.js 허브 (src/*.ts)                         │
│  ├─ 방 관리, 채팅, 매칭                            │
│  └─ 매치 시작 시 Godot 서버에 신호                  │
└─────────────────────────────────────────────────┘
```

## 3. React ↔ Godot 통신

[Godot JavaScriptBridge](https://docs.godotengine.org/en/stable/tutorials/platform/web/javascript_bridge.html)와 React 간 통신 방법:

### React → Godot (매치 시작 시)
```typescript
// React: localStorage에 매치 정보 저장 후 Godot 시작
localStorage.setItem('gangup_from_hub', '1');
localStorage.setItem('gangup_name', playerName);
localStorage.setItem('gangup_room_id', roomId);
localStorage.setItem('gangup_you', String(slot));

// Godot Engine 시작
const engine = new Engine({ canvas: canvasRef.current });
await engine.startGame({ mainPack: '/godot/index.pck' });
```

### Godot → React (매치 종료 시)
```gdscript
# Godot: 매치 종료 시 React에 알림
if OS.has_feature("web"):
    JavaScriptBridge.eval("window.dispatchEvent(new CustomEvent('godot-match-end', {detail: {winner: %d}}))" % winner_slot)
```
```typescript
// React: Godot 이벤트 수신
useEffect(() => {
  const handler = (e: CustomEvent) => {
    setMatchResult(e.detail);
    setPhase('result');
    engine.current?.requestQuit(false);
  };
  window.addEventListener('godot-match-end', handler);
  return () => window.removeEventListener('godot-match-end', handler);
}, []);
```

### 기존 코드 호환
Godot 측의 `consume_hub_launch()`, `get_hub_name()`은 이미 localStorage를 읽는 구조이므로 React에서 값을 넣으면 그대로 동작한다.

## 4. Godot Engine JavaScript API

[Godot 웹 내보내기 문서](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)에 따르면:

```javascript
const engine = new Engine({
  canvas: document.getElementById('game-canvas'),
  args: [],
  onExit: () => { /* React에 복귀 */ }
});

// 프로그래매틱 시작
await engine.startGame({ mainPack: 'index.pck' });

// 종료 요청
engine.requestQuit(false);
```

React 컴포넌트로 감싸면:

```tsx
// components/GodotCanvas.tsx
export function GodotCanvas({ pckUrl, onExit }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const engineRef = useRef<Engine | null>(null);

  const start = useCallback(async () => {
    const engine = new Engine({ canvas: canvasRef.current!, onExit });
    engineRef.current = engine;
    await engine.startGame({ mainPack: pckUrl });
  }, [pckUrl, onExit]);

  return <canvas ref={canvasRef} id="game-canvas" style={{ width: '100%', height: '100%' }} />;
}
```

## 5. 프로젝트 구조

### 현재
```
apps/server-yjh-dev1/
  project/              # Godot 프로젝트 (로비+게임 전부)
    custom_shell.html   # HTML 로비 (482줄, 문제의 원인)
    scripts/ui/         # Godot 코드 전용 로비 UI
  src/                  # Node.js 허브 (TypeScript)
  public/               # 웹 정적 파일 (Caddy 서빙)
```

### 제안
```
apps/server-yjh-dev1/
  project/              # Godot 프로젝트 (인게임만)
    custom_shell.html   # 최소 셸 (캔버스+엔진 로더만, ~30줄)
    scripts/
      game_root.gd      # hub_launched 모드로 직접 진입
      ui/flow_screens.gd # 인트로/로비 제거, 인게임 HUD만 유지
  src/                  # Node.js 허브 (변경 없음)
  web/                  # React SPA (신규)
    package.json
    vite.config.ts
    src/
      main.tsx
      App.tsx
      pages/
        Home.tsx         # 게임 선택 (다굴/Snake/Hex)
        Lobby.tsx        # 방 목록 + 생성
        Room.tsx         # 대기실 + 채팅
        Game.tsx         # GodotCanvas 래퍼
        Result.tsx       # 매치 결과
      hooks/
        useHub.ts        # 허브 WebSocket 연결 훅
        useGodotLoader.ts # WASM 백그라운드 프리로더
      components/
        GodotCanvas.tsx  # Godot 캔버스 래퍼
        PlayerSlot.tsx   # 8인 슬롯 UI
        ChatBox.tsx      # 채팅
        ProgressBar.tsx  # WASM 다운로드 진행률
  public/               # 빌드 결과
    index.html          # React 앱 진입점
    assets/             # Vite 번들
    godot/              # Godot WASM+PCK (CI가 복사)
      index.wasm
      index.pck
      index.js
  Dockerfile            # Node.js 허브 + public/ 서빙
```

## 6. 빌드 파이프라인

```
apply-apps.py ship + helm:
  1. Godot 웹 내보내기 → project/web/ (WASM+PCK+JS)
  2. React 빌드 (cd web && npm run build) → web/dist/
  3. 합체: cp web/dist/* public/ && cp project/web/index.{wasm,pck,js} public/godot/
  4. Docker 빌드 (Node.js 허브 + public/)
  5. Helm 배포
```

## 7. React 허브 WebSocket 훅

현재 `network_manager.gd`의 프로토콜을 TypeScript로 재구현:

```typescript
// hooks/useHub.ts
export function useHub() {
  const [status, setStatus] = useState<'offline' | 'connecting' | 'lobby'>('offline');
  const [rooms, setRooms] = useState<Room[]>([]);
  const [room, setRoom] = useState<Room | null>(null);
  const [players, setPlayers] = useState<Player[]>([]);
  const wsRef = useRef<WebSocket | null>(null);

  const connect = useCallback(() => {
    const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    const ws = new WebSocket(`${proto}//${location.host}/gang-up`);
    ws.onopen = () => {
      ws.send(JSON.stringify({ t: 'hello', name: playerName, mode: 'full' }));
      setStatus('lobby');
    };
    ws.onmessage = (e) => {
      const msg = JSON.parse(e.data);
      switch (msg.t) {
        case 'rooms': setRooms(msg.rooms); break;
        case 'joined': setRoom(msg.room); setPlayers(msg.players); break;
        case 'peers': setPlayers(msg.players); break;
        case 'start': onMatchStart(msg); break;
        // ...
      }
    };
    wsRef.current = ws;
  }, []);

  const createRoom = () => wsRef.current?.send(JSON.stringify({ t: 'create' }));
  const joinRoom = (id: string) => wsRef.current?.send(JSON.stringify({ t: 'join', roomId: id }));
  const startMatch = () => wsRef.current?.send(JSON.stringify({ t: 'start' }));

  return { status, rooms, room, players, connect, createRoom, joinRoom, startMatch };
}
```

## 8. WASM 백그라운드 프리로더

```typescript
// hooks/useGodotLoader.ts
export function useGodotLoader(gameId: 'dagul' | 'snake' | 'hex') {
  const [progress, setProgress] = useState(0);
  const [ready, setReady] = useState(false);
  const compiledRef = useRef<WebAssembly.Module | null>(null);

  useEffect(() => {
    const wasmUrl = `/godot/${gameId}/index.wasm`;
    const pckUrl = `/godot/${gameId}/index.pck`;

    // 1. WASM 스트리밍 컴파일 (백그라운드, 메인 스레드 비블로킹)
    const wasmPromise = fetch(wasmUrl).then(res => {
      const total = Number(res.headers.get('content-length') || 0);
      const reader = res.body!.getReader();
      const chunks: Uint8Array[] = [];
      let loaded = 0;
      return new ReadableStream({
        pull(ctrl) {
          return reader.read().then(({ done, value }) => {
            if (done) { ctrl.close(); return; }
            loaded += value.byteLength;
            setProgress(total > 0 ? loaded / total : 0);
            chunks.push(value);
            ctrl.enqueue(value);
          });
        }
      });
    }).then(stream => new Response(stream))
      .then(res => WebAssembly.compileStreaming(res))
      .then(mod => { compiledRef.current = mod; });

    // 2. PCK 프리페치 (캐시)
    const pckPromise = fetch(pckUrl, { cache: 'force-cache' });

    Promise.all([wasmPromise, pckPromise]).then(() => setReady(true));
  }, [gameId]);

  return { progress, ready, compiledModule: compiledRef.current };
}
```

## 9. 3개 게임 통합 로비

React SPA가 3개 게임을 통합 관리:

```
Home.tsx
  ├─ [다굴] 카드 → /dagul/lobby
  ├─ [Snake Arena] 카드 → /snake/lobby
  └─ [Hex Clash] 카드 → /hex/lobby

각 게임의 로비/방/대기실은 같은 컴포넌트를 재사용하고,
허브 WebSocket 경로만 다름:
  - 다굴: /gang-up
  - Snake: /snake
  - Hex: /hexclash
```

각 게임의 WASM+PCK는 `/godot/{gameId}/`에 별도 저장.

## 10. Godot 측 컷오프

### 제거할 것
| 파일 | 이유 |
|---|---|
| `custom_shell.html` (482줄 HTML 로비) | React가 대체 |
| `flow_screens.gd` 인트로/로비 페이지 | React가 대체 |
| `lobby_builder.gd` | React가 대체 |
| `room_builder.gd` | React가 대체 |
| `settings_popup.gd` | React 설정 페이지로 이동 |
| `how_to_play_popup.gd` | React 도움말로 이동 |

### 유지할 것
| 파일 | 이유 |
|---|---|
| `game_root.gd` | 인게임 루프 (hub_launched 모드로 직접 진입) |
| `hud.gd` | 인게임 HUD |
| `hud_buffs.gd` | 인게임 버프 표시 |
| `touch_buttons.gd` | 모바일 터치 |
| `debug_renderer.gd` + 모듈 | 인게임 렌더링 |
| `sim/*.gd` | 시뮬레이션 (SSOT) |
| `net/*.gd` | 네트워크 |

### 수정할 것
| 파일 | 변경 |
|---|---|
| `game_root.gd` | `hub_launched` 모드가 기본, React에서 전달한 매치 정보로 즉시 시작 |
| `flow_screens.gd` | 인게임 결과 화면만 유지 (또는 제거하고 React가 결과 표시) |
| `custom_shell.html` | 최소 셸 (~30줄, 캔버스+엔진 로더만) |
| `network_manager.gd` | React가 이미 허브에 연결, Godot는 게임 서버만 연결 |

## 11. 구현 단계

### Phase 1: React SPA 골격 (1~2일)
- `web/` 디렉터리에 Vite + React + TypeScript 프로젝트 생성
- `useHub.ts` 훅으로 허브 WebSocket 연결
- Home → Lobby → Room 화면 흐름 구현
- 아직 Godot 연동 없이 로비만 동작

### Phase 2: Godot 연동 (1일)
- `GodotCanvas.tsx` 컴포넌트 구현
- `useGodotLoader.ts`로 WASM 백그라운드 프리로드
- 매치 시작 시 React → Godot 전환 (localStorage + Engine.startGame)
- 매치 종료 시 Godot → React 전환 (CustomEvent)

### Phase 3: Godot 컷오프 (1일)
- `flow_screens.gd`에서 인트로/로비 제거
- `game_root.gd`를 hub_launched 모드 전용으로 간소화
- `custom_shell.html`을 최소 셸로 축소

### Phase 4: 3개 게임 통합 (1일)
- Snake/Hex의 WASM을 `/godot/snake/`, `/godot/hex/`에 배치
- Home.tsx에서 게임 선택 UI
- 각 게임의 허브 경로 분리

### Phase 5: 빌드 파이프라인 (1일)
- CI에서 React 빌드 + Godot 내보내기 + 합체
- Dockerfile 수정 (public/ 서빙)
- 배포 확인

## 12. 기술 스택

| 계층 | 기술 |
|---|---|
| React SPA | Vite 6 + React 19 + TypeScript 5 |
| 스타일 | Tailwind CSS 또는 CSS Modules |
| 라우팅 | React Router 7 |
| 상태 관리 | React 내장 (useContext + useReducer) |
| WebSocket | 네이티브 WebSocket (훅으로 래핑) |
| 게임 엔진 | Godot 4.7 WASM (인게임만) |
| 통신 | localStorage + CustomEvent (React↔Godot) |
| 서버 | Node.js (기존 허브) |
| 빌드 | Vite (React) + Godot CI (WASM) |

## 참고 자료

- [React + WebGL/WASM 게임 통합](https://gitnation.com/contents/marrying-wasmwebgl-games-with-react-ui)
- [ReactBridge — Godot Asset Library](https://godotengine.org/asset-library/asset/4980)
- [jsgdbridge — Godot ↔ React 브릿지](https://github.com/KronbergerSpiele/jsgdbridge)
- [Godot JavaScriptBridge 문서](https://docs.godotengine.org/en/stable/tutorials/platform/web/javascript_bridge.html)
- [Godot 웹 내보내기 문서](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Godot 4.3 웹 내보내기 진행 보고](https://godotengine.org/article/progress-report-web-export-in-4-3/)
- [Godot 포럼: 기존 프론트엔드와 통합](https://forum.godotengine.org/t/is-it-possible-to-integrate-a-godot-game-with-an-existing-frontend-application/129699)
