# 웹 멀티플레이어 배포 아키텍처

## 현재 인프라 분석

현재 배포는 2개 컴포넌트로 구성되어 있다:

```
클라이언트(브라우저)
  ↓ HTTPS
*.external.kr → Traefik Ingress → Caddy(web Pod)
  ├─ 정적 파일 서빙 (WASM/pck/html)
  └─ /gang-up → reverse_proxy → <슬롯>-hub Pod (Node.js, 포트 8080)
```

- **web Pod**: Caddy가 정적 파일을 서빙하고, `/gang-up` 경로를 허브로 프록시
- **hub Pod**: 슬롯별 Node.js 서버 (방 관리, 채팅, WebSocket 업그레이드)

새로 추가된 Godot 헤드리스 서버(game_server.gd)는 아직 배포 경로가 없다.

## 권고: 가장 단순한 방법

### Node.js 허브에 Godot 서버를 같이 넣어라 (단일 컨테이너)

별도 컨테이너를 만들지 않는다. 현재 Node.js 허브 프로세스가 Godot 헤드리스 프로세스를 `child_process.spawn`으로 기동하는 구조가 가장 간단하다.

이유:
- Helm 차트 변경 최소 (새 Deployment/Service/Ingress 불필요)
- 같은 Pod 안이므로 `localhost` 통신 (HTTP POST `/start-match` → `127.0.0.1:9122`)
- 프록시 설정 변경 최소

```
hub Pod (단일 컨테이너)
  ├─ Node.js (포트 8080)
  │   ├─ /gang-up        ← 기존 WebSocket (방 관리, 채팅)
  │   └─ /health          ← 헬스체크
  │
  └─ Godot headless (포트 9121 WS, 9122 HTTP) — Node.js가 spawn
      ├─ WS 9121          ← 게임 세션 (WebSocketMultiplayerPeer)
      └─ HTTP 9122        ← /start-match 엔드포인트
```

### Dockerfile 변경

```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npx tsc

FROM node:22-alpine
WORKDIR /app

# Godot 헤드리스 서버 바이너리 추가
COPY --from=godot-export /app/server.pck ./server.pck
# 또는 CI에서 빌드한 .pck를 COPY
# Godot 헤드리스 Linux 바이너리는 별도 다운로드 필요
ADD https://github.com/godotengine/godot-builds/releases/download/4.7.1-stable/Godot_v4.7.1-stable_linux.x86_64.zip /tmp/godot.zip
RUN unzip /tmp/godot.zip -d /usr/local/bin && rm /tmp/godot.zip && chmod +x /usr/local/bin/Godot_*

COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY public ./public

ENV PORT=8080
EXPOSE 8080 9121
CMD ["node", "dist/index.js"]
```

Node.js의 index.ts에서 Godot 프로세스를 spawn:

```typescript
import { spawn } from 'child_process';

const godot = spawn('Godot_v4.7.1-stable_linux.x86_64', [
  '--headless',
  '--main-pack', './server.pck',
  '--', '--port', '9121', '--http-port', '9122'
], { stdio: 'inherit' });
```

### 웹 클라이언트의 WebSocket 연결

클라이언트는 두 개의 WebSocket 연결을 유지한다:

| 연결 | 용도 | 경로 | 프로토콜 |
|---|---|---|---|
| 허브 | 방 관리, 채팅 | `wss://<슬롯>.external.kr/gang-up` | 기존 JSON 메시지 |
| 게임 서버 | 시뮬레이션 | `wss://<슬롯>.external.kr/game-ws` | Godot MultiplayerPeer |

### Caddy 프록시 변경

web.yaml의 Caddyfile에 게임 서버 경로를 추가한다:

```caddyfile
handle /gang-up* {
    reverse_proxy <슬롯>-hub:80 {
        flush_interval -1
    }
}

# 게임 서버 WebSocket — 같은 허브 Pod의 9121 포트로
handle /game-ws* {
    reverse_proxy <슬롯>-hub:9121 {
        flush_interval -1
    }
}
```

단, 현재 허브 Pod의 Service가 포트 80(→8080)만 노출하고 있으므로 9121 포트도 노출해야 한다.

hub.yaml의 Service 수정:
```yaml
ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: game-ws
    port: 9121
    targetPort: 9121
```

### game_client.gd의 URL 해석

현재 hub_client.gd의 `_resolve_url()` 패턴을 따른다:

```gdscript
func _resolve_game_url() -> String:
    if OS.has_feature("web"):
        var origin := _js_text("String(window.location.origin)")
        if origin.begins_with("https://"):
            return "wss://%s/game-ws" % origin.substr(8)
        if origin.begins_with("http://"):
            return "ws://%s/game-ws" % origin.substr(7)
    return "ws://127.0.0.1:9121"
```

또는 허브의 `match_started` 메시지에 포함된 `gameServerUrl`을 그대로 사용한다. state.ts의 `deriveGameWsUrl()`이 이미 이 URL을 생성한다.

## 대안 (더 깔끔하지만 작업량 증가)

### 허브가 게임 WS를 프록시

Godot 헤드리스 서버의 WebSocket을 Node.js 허브가 프록시하면, 외부에서 보이는 WebSocket 엔드포인트가 하나(`/gang-up`)로 통합된다.

장점: Caddy/Ingress 변경 없음, 포트 하나
단점: Node.js가 모든 게임 패킷을 중계해야 하므로 레이턴시 증가. 현재 허브가 스냅샷 중계를 제거한 이유가 이것이었으므로 비추천.

### 별도 컨테이너

Godot 헤드리스를 별도 Deployment로 배포하면 격리성이 높지만, Helm 차트에 새 템플릿(game-server.yaml)이 필요하고, values-games.yaml에 게임 서버 이미지/태그를 추가해야 한다. 해커톤에는 과한 구성.

## 실행 체크리스트

1. [ ] Dockerfile에 Godot 헤드리스 바이너리 + server.pck 추가
2. [ ] Node.js index.ts에서 Godot 프로세스 spawn
3. [ ] CI에서 server.pck 빌드 (Godot `--headless --export-pack server.pck`)
4. [ ] hub.yaml Service에 9121 포트 추가
5. [ ] web.yaml Caddyfile에 `/game-ws` → 허브:9121 프록시 추가
6. [ ] game_client.gd의 URL 해석에서 `/game-ws` 경로 사용
7. [ ] 테스트: 브라우저에서 로비 → 매치 시작 → 게임 서버 연결 확인

## 요약

| 결정 | 선택 |
|---|---|
| 배포 방식 | 단일 컨테이너 (Node.js + Godot spawn) |
| WS 경로 | `/gang-up` (허브) + `/game-ws` (게임) |
| 프록시 | Caddy가 경로별로 분기 |
| TLS | 기존 `*.external.kr` 와일드카드 인증서 그대로 |
| 추가 인프라 | 없음 (Helm 차트 최소 수정) |
