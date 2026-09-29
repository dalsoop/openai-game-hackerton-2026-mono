# 운영 절차

## 준비물

| 도구 | 버전·위치 | 쓰는 곳 |
|---|---|---|
| Node.js·npm | 22 (이미지와 CI 기준). 이 Mac의 Node 24에서도 웹 게이트가 통과했다(2026-09-30) | `apps/dagul-prod/web`, 개발 슬롯 허브, `deploy/usability` |
| Python 3 | 표준 라이브러리만 사용 | `lint_gd.py`, `scripts/gd_test.py`, `deploy/scripts/*.py` |
| Godot | 4.7.1 Standard. macOS는 `/Applications/Godot.app/Contents/MacOS/Godot`을 기본으로 찾고, `GODOT_BIN`으로 바꿀 수 있다. 웹 익스포트에는 4.7.1 Web 익스포트 템플릿이 필요하다 | GD 테스트, 웹 익스포트 |
| Redis | 로컬 127.0.0.1:6379. Docker(또는 OrbStack)가 켜져 있으면 compose로, 아니면 `redis-server`로 띄운다 | `npm run dev` |
| brotli | 선택. 없으면 `.br` 사전 압축을 건너뛴다 | `godot:build` |

## dagul-prod 로컬 실행

순서가 중요하다. 2번 없이 3번을 하면 팩 신선도 검사에서 멈춘다.

```bash
# 1. 의존성 (apps/dagul-prod/web)
cd apps/dagul-prod/web
npm ci

# 2. Godot 웹 익스포트: GD 테스트 → export → 압축 → 매니페스트 → 소스 해시 스탬프
npm run godot:build
npm run godot:link        # public/godot 에 project/web 심볼릭 링크 (로컬 전용)

# 3. Redis 확인 후 허브+Next 개발 서버 (기본 포트 3100)
npm run dev
```

- `apps/dagul-prod/dev.sh`는 위 2·3번을 한 번에 한다. 팩이 없거나 `.gd`·`project.godot`이 팩보다 새면 다시 익스포트하고, 3100 포트의 죽은 리스너를 교체한다. `SKIP_SERVER=1 ./dev.sh`는 준비만 하고 서버를 띄우지 않는다.
- Godot 에디터로 인게임만 볼 때: `godot --path apps/dagul-prod/project`.
- `npm run godot:ship`은 빌드·복사 후 `scripts/restart-dev.sh --bg`로 개발 서버를 백그라운드 재시작한다.

## 개발 슬롯 로컬 실행

```bash
cd apps/server-pjh-dev1      # 또는 apps/server-fig-dev1
npm ci
npm run dev                  # tsx src/index.ts, 기본 포트 9120
godot --path apps/server-pjh-dev1/project   # 저장소 루트에서, 다른 터미널
```

`RUN_GAME.sh`·`RUN_SMOKE.sh`(Windows는 `.bat`)는 PATH의 `godot` 또는 `godot4`로 프로젝트를 연다.

## 검증 명령

```bash
# 저장소 루트
python3 lint_gd.py apps/dagul-prod/project --baseline lint_gd_baseline.json
python3 scripts/gd_test.py
python3 deploy/scripts/test_ship_contracts.py
python3 deploy/scripts/test_hub_scale.py

# apps/dagul-prod/web
npx tsc --noEmit
npx tsc --project tsconfig.server.json --noEmit
npm run lint
npm run schema:check
npx vitest run
npm run check:contract
```

- `npm run verify`는 tsc(클라이언트)·eslint·schema:check·vitest·check:contract·GD 테스트를 묶어 돌린다. 서버 tsconfig 타입 검사는 들어 있지 않다.
- `check:contract`는 `project/web`에 Godot 산출물이 없으면 산출물 버전 검사를 건너뛰고, 있으면 압축본 신선도까지 본다. macOS에서 빌드 직후 압축본이 낡았다고 나오면 `touch apps/dagul-prod/project/web/*.br apps/dagul-prod/project/web/*.gz` 후 다시 돌린다.
- 허브 스모크(브라우저 없이 WebSocket): `HUB_URL=http://127.0.0.1:3100 npm run smoke`(`scripts/smoke-hub.mjs`). 스크립트 기본 대상은 3000 포트라서 개발 서버(3100)에 붙이려면 `HUB_URL`을 줘야 한다. 브라우저 E2E: `npm run e2e`(Playwright core, 로컬 전용).

## 환경 변수 (dagul-prod 허브)

| 변수 | 기본값 | 의미 |
|---|---|---|
| `PORT` | 개발 3100, 이미지 8080, 코드 기본 3000 | 허브·Next가 함께 듣는 포트 |
| `NODE_ENV` | 이미지 `production` | `production`이 아니면 Next 개발 모드 |
| `REDIS_URL` | 개발 `redis://127.0.0.1:6379` | 있으면 Colyseus presence·driver와 DAU를 Redis로. 없으면 단일 프로세스 메모리 |
| `SLOT_FOLDER` | `dagul-prod` | 방 이름 접두사(`<슬롯>-lobby`). 브라우저 번들에도 빌드 시 박힌다 |
| `DAGUL_SKILLS` | `on` | `off`·`0`·`false`·`no`면 우클릭 장비 스킬을 끈다 |
| `DAGUL_CCU_CAP` | 100 | 전역 입장 한도. 1 미만이나 숫자가 아니면 100 |
| `HUB_PATCH_HZ` | 60 | 상태 패치 빈도. 0이나 숫자가 아니면 60, 20이면 Colyseus 기본(50ms) |
| `HUB_PUBLIC_PREFIX`, `POD_NAME` | 없음 | 둘 다 있으면 클라이언트가 이 Pod로 직접 WebSocket을 연결하는 공개 주소를 만든다(다중 복제용) |
| `HUB_ROLE` | 없음 | `static`이면 Colyseus·Next 없이 Godot 팩과 메타 엔드포인트만 서빙한다 |
| `HUB_STATIC_SPLIT` | 없음 | `1`이면 허브가 팩 경로를 서빙하지 않는다(정적 전용 Pod가 따로 있을 때) |
| `SKIP_GODOT_STALE_CHECK` | 없음 | `1`이면 `npm run dev`의 팩 신선도 검사를 건너뛴다 |
| `GAME_SERVER_URL` | `http://127.0.0.1:9122` | Next rewrite `/api/rooms`의 대상. 현재 이 포트를 여는 프로세스는 저장소에 없다 |

## 배포

### 구조 (코드에 적힌 흐름)

1. `main`(또는 `jeongright-gang-up-multi`)에 `apps/**`·`deploy/**`가 푸시되면 GitHub Actions `Apps`가 돈다.
2. `plan`(ubuntu): 배포 계약 테스트 두 개 → `ci-plan.py --changed <before> <sha>`가 바뀐 슬롯 폴더와 helm 필요 여부를 정한다. 수동 실행(`workflow_dispatch`)은 `folders` 입력으로 폴더를 직접 고른다.
3. `lint-web`(ubuntu): `lint-web.py <폴더들>`이 배포 대상 웹을 tsc·eslint·vitest로 검사한다.
4. `apply`(self-hosted `hackertone` 러너, 동시성 그룹 `apps-ship`, 45분 제한): `apply-apps.py ship <폴더들>` → `apply-apps.py helm`.
   - `ship`: 슬롯마다 Godot 웹 익스포트(GD 테스트 통과 후) → 허브 이미지 `docker build` → Harbor 푸시(3회 시도, 실패하면 준비된 노드가 1개 이상일 때 경고를 남기고 `k3s ctr import`로 k3s-prod에 직접 적재, 0개면 ship 실패) → 웹 정적 파일을 노드 `/data/hackertone/g`에 올리고 `.export-hash` 기록 → `plant`로 `values-games.yaml` 태그 갱신.
   - `helm`: 이미지를 만들지 않는다. 심은 태그가 클러스터에 있는지 확인하고 `helm upgrade` → 허브 스모크 → Cloudflare 퍼지 시도 → Grafana 주석.
5. 원격 명령은 호스트 이름이 `pve`이거나 `HACKERTONE_APPLY_HOST=pve`면 그 호스트에서 k3s 노드로, 아니면 SSH 별칭 `pve-lan`을 거쳐 보낸다.

### 현재 상태

`hackertone` self-hosted 러너와 `pve` 호스트는 2026-09-24에 퇴역했다. 위 4·5번을 실행할 수 있는 경로가 현재 없으므로 푸시해도 배포되지 않는다. 마지막 `Apps` 실행(2026-08-30, `main` 5e2d383)은 `lint-web` 단계에서 실패해 `apply`까지 가지 못했다. 배포 경로를 새로 정하기 전에는 `apply-apps.py`를 로컬에서 돌리지 않는다.

### 슬롯 상태 확인

```bash
python3 deploy/scripts/status.py      # apps/ 의 슬롯마다 https://<폴더>.external.kr/ 와 /health 를 조회
```

2026-09-30 실행 결과 모든 슬롯이 실패했다(`dagul-prod`는 네트워크 도달 불가, 나머지는 HTTP 523).

## 개발 슬롯 허브 스모크·부하 (`deploy/usability`)

```bash
cd deploy/usability
node cli.mjs smoke --url ws://127.0.0.1:9120
node cli.mjs load --dry-run
```

이 도구는 개발 슬롯의 중계 프로토콜(`create`/`join`/`start`/`snap`)을 쓴다. `dagul-prod`의 Colyseus 허브에는 맞지 않는다. `--url`이나 `GANG_UP_WS`를 주지 않으면 이미 삭제된 슬롯 주소로 붙는다. 주소에 `dagul-prod`나 `//prod.`가 들어간 대상에는 `--allow-prod` 없이 부하를 걸지 않고, 기본 한도를 넘는 방·인원·시간은 `--force`가 필요하다. 결과는 `last-report.json`에 덮어쓰며 git에 넣지 않는다.

## 슬롯 카탈로그 재생성

```bash
python3 deploy/scripts/plant-apps.py
```

`apps/*/hackertone.yaml`을 읽어 `deploy/chart/values-games.yaml`과 `apps/server-board/project/web/slots.json`을 다시 쓴다. 슬롯을 추가·삭제하거나 `hackertone.yaml`을 바꾼 뒤 실행하고, 이어서 `test_ship_contracts.py`를 돌린다.
