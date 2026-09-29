# 시스템 구성

## 전체 구성

저장소 안에는 서로 다른 두 가지 멀티플레이 구조가 공존한다. 제출·운영 슬롯 `apps/dagul-prod`는 서버가 시뮬레이션을 돌리는 구조이고, 개발 슬롯 `apps/server-pjh-dev1`·`apps/server-fig-dev1`은 방장 브라우저의 Godot이 시뮬레이션을 돌리고 서버는 메시지만 중계하는 구조다. 두 구조는 와이어 프로토콜도, 폴더 구성도 다르므로 한쪽 코드를 다른 쪽으로 그대로 옮길 수 없다.

```text
브라우저
 ├─ React 페이지 (Next.js, 로비·방·대기실)
 │    └─ @colyseus/sdk WebSocket ──────────────┐
 └─ Godot 웹 엔진 (캔버스, 인게임 렌더·입력)      │
      └─ 페이지 브릿지(DOM 이벤트) ↔ React 소켓    │
                                               ▼
dagul-prod 허브 프로세스 (Node, web/server.ts)
 ├─ Colyseus 서버: 방 이름 "<슬롯>-lobby" (LobbyRoom)
 │    └─ 60Hz 고정 틱 → MatchSim(TS 권위 시뮬) → 스키마 패치 + JSON SNAP
 ├─ Next.js 요청 처리 (페이지·/api/*)
 ├─ 메타 HTTP: /health /metrics /ccu /api/version /api/stats /stats /rooms
 └─ Godot 팩 정적 서빙 (/godot/<pack>/…, 페이지 상대 wasm)
      │
      └─ Redis (REDIS_URL 이 있을 때만: presence·driver·DAU)
```

## 대표 흐름: 방 만들기부터 경기 종료까지 (dagul-prod)

1. 브라우저가 `/<locale>/create`에서 방 설정을 제출하면 React 훅이 `@colyseus/sdk`로 `<슬롯>-lobby` 방을 만든다. join 옵션에는 이름, 게임 id, 잠금 여부, 쿠키의 게스트 id·게스트 키가 실린다.
2. `LobbyRoom.onCreate`는 전역 동접 한도를 확인한 뒤 방 상태(`LobbyState`)를 만들고, 방 목록용 메타데이터(게임·제목·모드·phase·open·PIN 유무)를 올린다. 로비 목록은 Colyseus 리스트 방이 아니라 HTTP `GET /rooms`가 이 메타데이터를 읽어 돌려준다.
3. 방장이 `start`를 보내면 5초 카운트다운 뒤 `bootAuthority`가 `MatchSim`을 만들고 각 좌석에 시작 페이로드를 보낸다. React는 Godot 팩(`/godot/<pack>/index.wasm`·`index.pck`)을 로드하고, 핸드오프 키를 통해 방 id·좌석 번호·시드를 Godot에 넘긴다.
4. Godot 셸(`core/shell/match_shell.gd`)이 게임 모듈을 시작하고 `ready`를 보낸다. 서버는 전원이 `ready`일 때 로딩 장벽을 연다.
5. 경기 중 Godot은 입력을 페이지 브릿지로 React에 넘기고, React 소켓이 `input`으로 서버에 보낸다. 서버는 60Hz로 시뮬을 한 틱씩 진행하고 스키마 델타와 JSON `snap`을 내려보낸다. Godot은 스냅을 보간·예측해서 그린다.
6. 승자가 정해지면 결과 스냅을 보낸 뒤 10초 후 전원을 대기실로 되돌린다.

## 모듈 지도

| 모듈 | 역할 | 의존 방향 |
|---|---|---|
| `apps/dagul-prod/web` | 허브 프로세스 전체. Next.js 페이지, Colyseus `LobbyRoom`, TS 권위 시뮬(`lib/hub/match-*.ts`), Godot 팩 서빙, 메트릭 | Godot 산출물(`project/web`)을 빌드 시 복사해 서빙한다. `project/` 소스를 import 하지 않는다 |
| `apps/dagul-prod/project` | Godot 4.7.1 웹 클라이언트. 셸(`core/`)과 게임 모듈(`games/dagul`, `games/sparring`) | 네트워크는 페이지 브릿지로만 React에 의존한다. 서버 코드를 모른다 |
| `apps/server-pjh-dev1`, `apps/server-fig-dev1` | 개발 슬롯. `src/`의 `ws` 중계 허브와 `project/`의 Godot 게임(방장이 시뮬 실행) | 서로 독립. `dagul-prod`와 코드 공유 없음 |
| `apps/server-board` | 슬롯 현황을 보여 주는 정적 페이지(`index.html`, `monitor.html`, `slots.json`) | `slots.json`은 `deploy/scripts/plant-apps.py`가 생성한다 |
| `apps/game-pjh-gang-up` | 다굴 Godot 원본 패키지(싱글 로컬 플레이, CPU 포함). 배포하지 않는다 | 다른 모듈이 import 하지 않는다. 시뮬 규칙의 출처다 |
| `apps/game-lhj-animal` | 다른 팀원의 신규 게임 스캐폴드와 기획 메모. 배포하지 않는다 | 독립 |
| `deploy/` | Helm 차트, `apply-apps.py`(ship·helm), 슬롯 카탈로그 생성, 계약 테스트, 허브 스모크(`usability/`), 로컬 Redis | `apps/*/hackertone.yaml`을 읽어 동작한다 |
| `tools/godot-touch-controls` | 가상 스틱·버튼 Godot 애드온 | 각 슬롯의 `project/addons/godot-touch-controls`가 이 폴더로 향하는 심볼릭 링크다 |
| `tools/monitoring` | `prom-client` 메트릭 헬퍼와 WebSocket 부하 스크립트 | 저장소 안에서 import 하는 곳이 없다 |

## 슬롯과 배포 토폴로지

- `apps/<폴더>/hackertone.yaml`이 있고 폴더 이름이 `server-` 또는 `dagul-`로 시작하면 배포 대상 슬롯이다. 폴더 이름이 곧 서브도메인이다(`https://<폴더>.external.kr/`).
- 배포는 k3s 클러스터(노드 선택자 `k3s-prod`)에 Helm 차트 하나로 모든 슬롯을 올린다. 허브는 슬롯마다 StatefulSet 하나(기본 1 복제)이고, `dagul-prod`만 CPU 70% 기준 HPA로 최대 2복제까지 늘어난다. 이 상한은 `HUB_CONFIG`의 목표 동접 1000 ÷ 프로세스당 500에서 나온 값이다. `test_hub_scale.py`는 차트에 `maxReplicas: 2`가 그대로 있는지만 확인하고, `HUB_CONFIG`와의 일치는 사람이 맞춘다. `dagul-prod`에는 Godot 팩만 서빙하는 `hub-static` Deployment(2복제, `HUB_ROLE=static`)가 따로 있고, 이때 허브 본체는 `HUB_STATIC_SPLIT=1`로 팩 서빙을 넘긴다. 허브 이미지는 그 슬롯 `hackertone.yaml`의 `hub.dockerfile`로 굽는다. `dagul-prod`는 `web/Dockerfile`, 개발 슬롯은 루트 `Dockerfile`이다.
- `dagul-prod` 허브는 `/`에서 서빙하고, 개발 슬롯 허브는 `/gang-up` 접두사 아래에서 서빙한다(`hub.pathPrefix`).
- 요청 경로: Traefik 와일드카드 인그레스 → 공용 `web` Deployment(Caddy, `deploy/web` 이미지와 차트 ConfigMap의 Caddyfile) → 호스트 이름으로 슬롯을 고른 뒤, 웹 정적 파일은 노드 경로(`/data/hackertone/g/<폴더>`를 `/srv/g`로 마운트)에서 직접 서빙하고, 허브 경로(`dagul-prod`는 `/`·`/rooms`·`/matchmake*`·`/health` 등, 개발 슬롯은 `/gang-up*`)는 `<폴더>-hub` 서비스로, `dagul-prod`의 `/godot*`·`/addons*`는 `<폴더>-hub-static`으로, `/hubp/<pod>` 경로는 해당 허브 Pod로 직접 프록시한다.
- Redis는 클러스터에 하나이고 슬롯마다 logical DB 번호를 나눠 쓴다(`deploy/chart/values-games.yaml`의 `redis.slots`: prod 1, fig-dev1 2, pjh-dev1 3).
- 이미지는 내부 Harbor 레지스트리에 올리고, 푸시가 안 되면 준비된 노드가 1개 이상일 때 `k3s ctr import`로 k3s-prod 노드에 직접 적재하고 계속한다(허브는 이 노드에 고정되어 있다). 준비된 노드가 없으면 ship이 실패한다.
- 배포 실행 주체는 GitHub Actions `Apps` 워크플로의 `apply` 잡이고, 이 잡은 self-hosted 러너 `[self-hosted, hackertone]`에서 돈다. `apply-apps.py`는 호스트 이름이 `pve`이거나 `HACKERTONE_APPLY_HOST=pve`일 때 그 호스트에서, 아니면 SSH 별칭 `pve-lan`을 거쳐 k3s 노드에 명령을 보낸다. 이 러너와 `pve` 호스트는 2026-09-24에 퇴역했고, 2026-09-30에 공개 호스트를 조회했을 때 모든 슬롯이 응답하지 않았다.

## 외부 시스템

| 외부 시스템 | 쓰는 곳 | 경계를 넘는 것 |
|---|---|---|
| Redis | `dagul-prod` 허브 (`REDIS_URL`) | Colyseus presence·driver 데이터, DAU HyperLogLog와 첫 접속일 키(`dagul:` 접두사). `REDIS_URL`이 없으면 전부 프로세스 메모리로 대신한다 |
| Harbor 레지스트리 | `apply-apps.py ship` | 슬롯 허브 이미지 |
| k3s + Helm + Traefik + cert-manager | `deploy/chart` | 인그레스, TLS(Let's Encrypt, Cloudflare DNS01), 유지보수 페이지 |
| Cloudflare | DNS, 캐시 퍼지(`purge-cache.py`) | 퍼지 요청. `dagul-prod`는 DNS 전용이라 퍼지가 응답을 바꾸지 않는다 |
| Prometheus·Grafana | 허브 `/metrics`, ServiceMonitor, 대시보드 UID `dagul-game` | 메트릭 텍스트, 배포 주석 |
| GitHub Actions | `.github/workflows/` 5개 | 계약 테스트, 웹·GD 린트, 배포, 호스트 조회 |
