# AGENTS.md — openai-game-hackerton-2026-mono

에이전트·사람 공통. OpenAI 게임 해커톤 파티 엔트리 (형제: `ax-hackerton-2026-mono`).

더 자세한 배포는 `.claude/skills/hackertone-games-deploy/SKILL.md` 와 `apps/README.md`.
ship 잡 순서·Harbor·캐시·계약 테스트는 `deploy/README.md`.

## 제품 불변

1. 싱글 플레이 없음. 인간+CPU 개인전.
2. 조작감이 제품. 기본값은 빡셈.
3. `apps/game-pjh-gang-up`는 크리엘 원본. 수정하지 않는다.
4. 작업·배포는 `apps/server-*` 만. 폴더 이름 = `https://<폴더>.external.kr/`
5. 튜닝 패널은 개발 빌드만.

## 어디에 무엇을

| 둘 곳 | 내용 |
|---|---|
| `apps/dagul-prod/` | 제출·운영. 지금 다굴 정본 |
| `apps/server-pjh-dev1/` | 크리엘 개발환경 1. 지금 다굴 |
| `apps/server-pig-dev1/` | Figix 개발환경 1. 지금 다굴 |
| `apps/server-board/` | 배포 보드. `https://server-board.external.kr/` |
| `apps/server-*-dev2/` · `*-dev3/` | 그 사람의 개발환경 2·3 |
| `apps/game-pjh-gang-up/` | 원본. 읽기만 |
| `docs/` | 제품 설계 (`DESIGN.md`, `FEEL-TUNING.md`) |
| `deploy/` | Helm·`apply-apps.py`. 클러스터 YAML은 `apps/`에 두지 않는다 |

`server-*` 안:

```text
hackertone.yaml   # web.enabled, exportDir
README.md
project/          # godot --path 여기. 웹보내기는 project/web
src/              # 방 서버가 이 폴더에 있을 때만
```

방 서버는 `server-*` 폴더마다 따로다. 보드만 허브가 없다. 이미지는 그 폴더 Dockerfile이다.

`dev2`/`dev3`/`prod`도 `web.enabled`가 켜져 있다. 제출 슬롯은 `apps/dagul-prod/`다.

## 모노레포 규칙

- 배포·호스트 작업 전 스킬 `hackertone-games-deploy` 를 읽는다.
- 남의 `apps/game-*` 를 재구성하지 않는다.
- secret·개인 토큰 커밋 금지.
- 레포 밖 모노 수정 금지.

## 에이전트 행동

- 새 기능 전 `docs/DESIGN.md` 와 맞는지 본다.
- 조작감 숫자를 바꾸면 `docs/FEEL-TUNING.md`에 한 줄.
- Godot이 로드되지 않으면 머지하지 않는다.
- `pjh`/`pig` `dev1`의 게임플레이를 같이 맞출 때는 `project/`만 복사한다. 웹보내기는 CI가 만든다.

## 로컬

```bash
godot --path apps/dagul-prod/project
cd apps/dagul-prod/web && npm run godot:build && npm run godot:link
cd apps/dagul-prod && ./dev.sh
cd deploy/usability && node cli.mjs smoke
```

## 배포

`apps/server-*`를 main에 푸시하면 `pve-hackertone`이 바뀐 폴더만 `apply-apps.py ship` 한 뒤 `helm` 한다. 전 슬롯을 다시 굽지 않는다. wasm/pck는 git에 넣지 않는다. 보드는 `https://server-board.external.kr/`.

PR용으로만 브랜치를 가른다. URL을 받으려고 브랜치를 추가하지 않는다.

새 게임 추가: `apps/server-<name>/hackertone.yaml` + `Dockerfile` + `src/index.ts` + `project/` 작성 후 푸시하면 그 폴더만 올라간다.

## GDScript 코드 규칙
- 커밋 게이트(최초 1회): `git config core.hooksPath .githooks` — 배포 계약(`test_ship_contracts`). GD가 있으면 파스+유닛테스트도 차단한다. wasm/pck는 git에 넣지 않고 `apply-apps.py ship` 이 만든다.

에이전트가 GDScript 코드를 작성하거나 수정할 때 따라야 할 규칙:

1. **파일 크기**: 모든 .gd 파일은 700줄 이하. 초과하면 모듈로 분리한다.
2. **함수 크기**: 함수는 40줄 이하. 초과하면 헬퍼로 분리한다.
3. **중첩 깊이**: if/for/while 중첩은 3단 이하. early return으로 평탄화한다.
4. **매직 컬러 금지**: `Color("hex")` 대신 `UiTheme.상수`를 사용한다.
5. **SSOT**: 같은 함수가 2곳 이상에 구현되면 안 된다. 정본 1곳 + 위임 래퍼.
6. **모듈 패턴**: 큰 클래스는 RefCounted 모듈로 분리하고 파사드가 조합한다.
   - sim/: GangGameWorld(파사드) + 19개 모듈
   - render/: debug_renderer(파사드) + 4개 모듈
7. **검증**: `python3 lint_gd.py apps/dagul-prod/project` + Godot 파싱 에러 0건
8. **human_slots**: 로컬 매치에서 반드시 `world.human_slots[world.local_slot] = true` 설정
9. **정본**: `apps/dagul-prod/`가 제출 정본. 다른 슬롯은 여기서 복사한다.

## 온라인 단일 구성 · 정본 지도 (lint_gd.py + check-contract 가 강제)

로비/방/대기실은 웹(React+Colyseus)이, 인게임은 Godot가 담당한다. 오프라인 모드·채팅 없음.
웹 플랫폼 위치: `apps/dagul-prod/web/` (허브+로비+Godot 로딩을 한 프로세스로 서빙).

| 역할 | 정본 (여기만 수정) | 금지 사항 |
|---|---|---|
| 로비·대기실 UI | `web/app/` + `web/components/` (React) | Godot에 로비 UI 재구현 금지 |
| 허브 서버 (방·좌석·릴레이) | `web/lib/hub/LobbyRoom.ts` (Colyseus state) | 커스텀 방 상태 메시지 신설 금지 — state 로 표현 |
| 허브 클라이언트 | `web/hooks/useHub.ts` (colyseus.js — 유일한 SDK import) | 다른 파일에서 colyseus.js 직접 import 금지 |
| React↔Godot 계약 | `web/lib/hub/config.ts` (HANDOFF·DOM_EVT·BRIDGE) ↔ 거울 `project/core/contract/web_contract.gd` | 키 하드코딩 금지 — check-contract 가 대조 |
| Godot 네트워크 | `project/core/autoload/network_manager.gd` (페이지 브릿지 소비) | GD 자체 WebSocket 금지 (ws-client-dup) |
| Godot 셸 | `project/core/shell/match_shell.gd` | 셸에 게임 지식 금지 — core→games 참조 금지 (core-games) |
| 게임 모듈 | `project/games/<id>/game.gd` (GameModule 계약 구현) | 게임이 방·릴레이·브릿지 세부를 알 필요 없음 |
| Godot 웹 로딩 | `web/lib/godot/runtime.ts` (팩당 싱글톤) | 훅·컴포넌트에서 fetch/Engine 직접 조작 금지 |
| GameId→팩 | `web/lib/games/catalog.ts` `packOf` | `/godot/${gameId}` 금지 — 폴더는 `pack` 필드 |
| Godot 산출물 배치 | `web/scripts/publish-godot-assets.mjs` (`catalog-packs.mjs`) | 팩 폴더 하드코딩 금지 — 카탈로그 pack 집합 |
| Godot 산출물 버전 | `project/web/manifest.json` (통합 해시) | 버전 쿼리 없는 immutable 캐시 금지 |
| Godot 빌드 | `deploy/scripts/build-godot.sh` (`npm run godot:build`) | 슬롯에 셸 복사 금지. export 실패를 숨기지 말 것 |

### 게임 폴더 추상화 (project/)

```
core/      게임 무관 — autoload(브릿지·상태·오디오) · contract(GameModule·registry·web_contract) · shell · ui(토큰·터치·설정) · assets(fonts)
games/<id>/  game.gd(계약 구현) + sim/ render/ hud/ net/ camera/ input/ audio/ assets/ + main.tscn
```

- 새 게임 추가 = `games/<id>/` 폴더 + `game.gd` 구현. core 는 한 줄도 바꾸지 않는다.
- 검증: `python3 lint_gd.py apps/dagul-prod/project` · `npm run check:contract` · `npm run smoke`
