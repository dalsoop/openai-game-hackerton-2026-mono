# 규칙

## 저장소 경계

- `apps/game-pjh-gang-up/`는 원작자의 원본 패키지다. 한 글자도 수정하지 않는다. 규칙·수치를 가져올 때는 읽기만 하고 다른 슬롯에 옮겨 구현한다.
- 다른 사람의 `apps/game-*` 폴더를 재구성하거나 옮기지 않는다.
- 이 저장소 밖의 저장소를 이 작업에서 수정하지 않는다.
- 클러스터 YAML은 `apps/`에 두지 않는다. 배포 정의는 `deploy/chart`와 각 슬롯의 `hackertone.yaml`에만 둔다.
- 배포할 슬롯 폴더 이름은 `server-` 또는 `dagul-`로 시작해야 한다. 다른 접두사는 CI 계획(`ci-plan.py`)과 수동 배포 입력 검사(`(server|dagul)-[a-z0-9-]+`)에서 걸러진다.
- 브랜치는 PR을 위해서만 만든다. URL을 얻으려고 브랜치를 만들지 않는다. URL은 폴더 이름으로 정해진다.

## 커밋 금지 대상

- Godot 웹 익스포트 산출물(`index.wasm`, `index.side.wasm`, `index.pck`, `*.br`, `*.gz`, `manifest.json`, `web/public/godot/**`)은 커밋하지 않는다. ship 과정이 만든다. 예외는 `apps/server-board/project/web/`(정적 보드 페이지)뿐이다.
- Colyseus GDExtension 플랫폼 바이너리(`apps/*/project/addons/colyseus/bin/*`)는 커밋하지 않는다.
- Colyseus GD 스키마 생성본 `apps/*/project/core/net/lobby_state_schema.gd`를 다시 만들거나 커밋하지 않는다. `lint_gd.py`의 `banned-file` 규칙과 웹 아키텍처 테스트가 이를 막는다.
- 토큰·비밀번호·개인 키·`.env`(예시 파일 제외)·Godot `export_credentials.cfg`는 커밋하지 않는다.
- `deploy/chart/values-games.yaml`과 `apps/server-board/project/web/slots.json`은 `deploy/scripts/plant-apps.py`의 생성물이다. 손으로 고치지 않고 스크립트를 다시 돌린다.

## 머지 전 검증 게이트

아래 명령이 모두 통과해야 머지한다. Godot이 브라우저에서 로드되지 않는 변경은 게이트 통과 여부와 무관하게 머지하지 않는다.

```bash
# 저장소 루트에서
python3 lint_gd.py apps/dagul-prod/project --baseline lint_gd_baseline.json
python3 scripts/gd_test.py            # Godot 4.7.1 헤드리스 필요. GDTEST SUMMARY fail=0 이어야 한다
python3 deploy/scripts/test_ship_contracts.py
python3 deploy/scripts/test_hub_scale.py

# apps/dagul-prod/web 에서
npm ci
npx tsc --noEmit
npx tsc --project tsconfig.server.json --noEmit
npm run lint
npm run schema:check
npx vitest run
npm run check:contract
```

- `lint_gd.py`의 `--baseline`은 래칫이다. 규칙별 위반 수가 `lint_gd_baseline.json` 값을 넘으면 실패한다. 새 위반을 들이려고 기준값을 올리지 않는다.
- 커밋 훅은 `git config core.hooksPath .githooks`로 켠다. 훅은 매 커밋마다 배포 계약 두 개를 돌리고, 스테이지에 `.gd`가 있으면 GD 린트·스테이지 파일 파스·GD 유닛 테스트를, 스테이지에 `apps/dagul-prod/web`의 `ts|tsx|mjs|json`이 있으면 스테이지된 트리 기준 tsc·eslint·vitest를 돌린다. 훅 우회(`--no-verify`)로 커밋하지 않는다.
- GitHub Actions에서는 `web-lint`(웹 정적 게이트), `gd-lint`(GD 래칫과 유닛 테스트), `Apps`의 `plan`·`lint-web`(배포 계약과 배포 대상 웹 검사)이 같은 검사를 한다. `Apps`의 `apply`는 `lint-web`이 성공해야 돈다.

## dagul-prod 정본 지도

한 역할의 코드는 한 곳에만 둔다. 아래 "정본" 밖에서 같은 일을 다시 구현하면 게이트가 실패한다.

| 역할 | 정본 | 금지 |
|---|---|---|
| 로비·대기실 UI | `web/app/`, `web/components/` | Godot에 로비·방 UI를 다시 만들기(`lint_gd.py` `lobby-verb`, `banned-file`) |
| 방 상태·좌석·중계 | `web/lib/hub/LobbyRoom.ts`와 `lib/hub/lobby-*.ts` | 방 상태를 전달하는 커스텀 메시지 신설. 상태는 Colyseus 스키마로 표현한다 |
| React↔Godot 핸드오프·메시지 키 | `web/lib/contract/wire.ts` ↔ 거울 `project/core/contract/web_contract.gd` | GD에서 `gangup_*` 키나 메시지 타입 문자열 직접 쓰기(`contract-handoff`, `contract-msg`). 두 파일이 어긋나면 `check:contract`가 실패한다 |
| Godot 네트워크 | `project/core/autoload/network_manager.gd`(페이지 브릿지 소비) | GD에서 `WebSocketPeer.new()`(`ws-client-dup`) |
| Godot 셸 | `project/core/shell/match_shell.gd` | `core/`에서 `res://games/` 참조(`core-games`) |
| 게임 모듈 | `project/games/<id>/game.gd`(GameModule 계약 구현) | 게임 모듈이 방·릴레이·브릿지 세부를 아는 것 |
| 게임 카탈로그 | `web/lib/games/catalog.ts`(TS) ↔ `project/core/contract/game_registry.gd`(GD) | 게임 id로 `/godot/${id}` 경로 만들기. 산출물 폴더는 카탈로그 `pack` 필드로만 정한다 |
| Godot 웹 로딩 | `web/lib/godot/runtime.ts` 등 `lib/godot/` | 훅·컴포넌트에서 엔진 파일을 직접 fetch 하거나 Engine을 직접 조작 |
| Godot 산출물 배치 | `web/scripts/publish-godot-assets.mjs`(카탈로그 pack 집합을 `catalog-packs.mjs`로 읽음) | 팩 폴더 하드코딩 |
| Godot 산출물 버전 | `project/web/manifest.json`(통합 해시). 무버전 경로는 `no-store`, `?v=해시`만 불변 캐시 | 버전 쿼리 없는 불변 캐시 |
| 사용자 문구 | `web/messages/{ko,en}.json`, 서버 안내문은 `lib/hub/config.ts`의 `KO` | 그 밖의 TS/TSX 파일에 한글 리터럴(아키텍처 테스트가 실패) |
| 상태·이펙트 훅 | `web/hooks/` | `components/`와 `page.tsx`에서 상태·이펙트 훅 호출 |

## GDScript 규칙 (`lint_gd.py`가 강제)

`lint_gd.py`는 대상 프로젝트의 `core/`, `games/`, `scripts/`, `autoload/` 아래 `.gd`를 검사한다.

- 파일 700줄 이하(생성 파일 제외). 넘으면 RefCounted 모듈로 나누고 파사드가 조합한다.
- 함수 본문 40줄 이하.
- 함수 안 중첩 깊이 2 이하(함수 본문 들여쓰기 기준 `if/elif/else/for/while/match`). early return으로 평탄화한다.
- `Color("RRGGBB")` 리터럴은 `ui_theme.gd` 밖에서 쓰지 않는다. `UiTheme` 상수를 쓴다.
- 오토로드 공개 멤버가 프로젝트 어디에서도 쓰이지 않으면 실패한다. 외부(웹)에서 부르는 API는 `# lint-gd: public-api` 주석으로 예외 처리한다.
- 공개 `Array` 멤버를 함수 안에서 통째로 바꿔 넣지 않는다(`array-cow-replace`). 제자리에서 비우고 채운다.

## 웹(TypeScript) 규칙

- 서버와 브라우저가 같은 입력 정규화를 쓰는 규칙(방 설정·이름·PIN)은 `lib/hub/room-options.ts`, `lib/hub/room-password.ts` 한 곳에만 둔다.
- Colyseus 스키마(`lib/hub/match-schema/*.ts`, `lib/hub/lobby-state.ts`)를 바꾸면 `npm run schema:check`가 통과해야 한다. 이 검사는 임시 폴더에서 TS 스키마 codegen이 성공하는지, 그리고 `project/`에 GD 생성본이 없는지를 본다.
- 스키마 클래스 하나의 필드는 64개를 넘길 수 없다(Colyseus 한도). 넘기면 클라이언트가 `refId not found`로 무너진다.
- 서버 코드의 `@/` 경로 별칭은 이미지 빌드에서 `tsc-alias`와 `rewrite-dist-aliases.mjs`로 풀린다. `dist/`에 `require("@/…")`가 남으면 이미지 빌드가 실패한다.
- 정적 이미지에 JPEG를 쓰지 않는다(아키텍처 테스트).

## 설정 규칙

- `HUB_CONFIG.shutdownDrainMs`(240초)를 바꾸면 `deploy/chart/values.yaml`의 `hub.terminationGracePeriodSeconds`(현재 270)가 그 값 이상이 되도록 함께 바꾼다.
- Redis 격리는 슬롯마다 다른 logical DB 번호로 한다. ioredis `keyPrefix`를 쓰지 않는다.
- 로컬 개발 포트는 3100, 컨테이너 포트는 8080이다.

## 기록 규칙

- 조작감 관련 수치(속도·피해·쿨다운 등)를 바꾸면 `docs/FEEL-TUNING.md`에 날짜와 함께 한 줄을 남긴다. 이 규칙은 게이트가 강제하지 않는다.
