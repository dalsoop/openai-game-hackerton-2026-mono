# 실무 지식

## Colyseus·허브

### 스키마 클래스 필드가 64개를 넘으면 클라이언트 상태가 무너진다
- 증상: 경기 중 클라이언트가 `refId not found` 오류를 내고 영웅 상태가 갱신되지 않는다.
- 원인: Colyseus 스키마는 클래스당 필드 64개가 한도다. `MatchHero`가 65필드였을 때 이 증상이 났다(2026-08-27 수정).
- 대응: 필드를 추가하기 전에 해당 스키마 클래스의 필드 수를 센다. 넘으면 하위 스키마로 나눈다. 수정 후 `npx vitest run`과 `npm run schema:check`로 확인한다.

### 8인 경기에서 총알이 안 보이고 월드가 멈춘다
- 증상: 인원과 총알·이펙트가 많아지면 패치 송신이 통째로 실패한다.
- 원인: Colyseus `Encoder.BUFFER_SIZE` 기본값 8KB로는 실제 경기 상태를 담지 못한다.
- 대응: `web/server.ts`에서 256KB로 올려 두었다. 스키마에 큰 배열·맵을 추가하면 이 값을 다시 검토한다.

### Redis 키 접두사를 쓰면 입장이 4002로 닫힌다
- 증상: `REDIS_URL`을 쓰는 환경에서 방 입장이 close code 4002로 끊긴다.
- 원인: ioredis `keyPrefix`를 쓰면 Colyseus의 pub/sub 채널과 예약 키가 접두사 유무로 갈라진다. 슬롯 여러 개가 Redis 하나를 같은 DB로 공유했을 때는 방 수 집계가 섞여 방 만들기가 523으로 실패했다.
- 대응: 슬롯 격리는 `REDIS_URL`의 logical DB 번호로만 한다(`values-games.yaml`의 `redis.slots`). Colyseus에는 공식 형태의 Redis URL을 그대로 넘긴다.

### 개발 서버에서 핫 리로드가 죽는다
- 원인: HTTP upgrade 요청 중 `/_next`(webpack HMR)까지 Colyseus가 가져가면 Next 핫 리로드가 끊긴다.
- 대응: `server.ts`는 `/_next`로 시작하는 upgrade만 Next 핸들러로 넘기고 나머지를 Colyseus에 준다. upgrade 처리 순서를 바꿀 때 이 분기를 유지한다.

## Godot 웹 빌드

### Colyseus GDExtension을 다시 넣으면 웹 엔진이 죽는다
- 증상: 웹에서 `WASM memory access out of bounds` 또는 없는 dylib를 여는 오류가 난다.
- 원인: GDExtension은 `index.side.wasm` 동적 로딩이 필요한데, 웹 빌드에서 메모리 크래시를 일으켰다(2026-08-27 제거).
- 대응: Godot은 Colyseus에 직접 붙지 않고 페이지 브릿지로만 통신한다. `addons/colyseus/plugin.cfg`, `core/net/lobby_state_schema.gd`가 다시 생기면 `lint_gd.py`가 실패한다. `EngineSocket` 오토로드는 남아 있지만 접속 함수가 비어 있어 항상 브릿지 경로로 떨어진다.

### `class_name` 전역 클래스가 해석되지 않는다
- 증상: 헤드리스 `--script` 실행 시 `WebContract` 같은 전역 클래스 이름으로 파스 에러가 대량으로 난다.
- 원인: 전역 클래스 목록은 `.godot` 임포트 캐시에 있다. 캐시가 없으면 해석되지 않는다.
- 대응: `--headless --path <project> --import --quit`로 먼저 임포트한다. `scripts/gd_test.py`와 `build-godot.sh`는 이 단계를 이미 한다. 직접 명령을 조합할 때 빠뜨리지 않는다.

### macOS에서 `godot:build` 직후 `check:contract`가 "낡은 압축본"으로 실패한다
- 증상: `npm run godot:build`가 성공한 직후 `npm run check:contract`가 `project/web 낡은 압축본: index.js.br …`로 실패한다(2026-09-30 이 Mac에서 재현).
- 원인: 압축본 신선도 검사는 `.br`/`.gz`의 수정 시각이 원본 이상이어야 통과한다. macOS의 `brotli`는 원본 수정 시각을 초 단위로 잘라 복사하고, `/usr/bin/gzip`은 마이크로초 하나 작게 복사해서 압축본이 원본보다 미세하게 과거가 된다.
- 대응: 로컬에서는 빌드 뒤 `touch apps/dagul-prod/project/web/*.br apps/dagul-prod/project/web/*.gz`를 하고 다시 검사한다. 이 조치 뒤 `check:contract`가 통과하는 것을 확인했다.

### `godot:build`가 추적 중인 파일을 바꾼다
- 증상: 로컬 빌드 뒤 `git status`에 `apps/dagul-prod/project/web/index.html`과 `apps/dagul-prod/web/public/godot/.export-src-hash`가 수정됨으로 뜬다. Godot 임포트가 저장소에 없는 `.uid` 파일(예: `project/tests/test_virtual_stick.gd.uid`)을 새로 만들기도 한다.
- 원인: 두 파일은 git이 추적하는 빌드 산출물이고, 소스 해시에는 `.uid` 파일도 들어간다. 그래서 `.uid`가 새로 생기면 해시가 달라진다.
- 대응: 빌드만 확인하려던 작업이면 두 파일을 `git checkout --`으로 되돌린다. 빌드 결과를 반영하려는 작업이면 의도적으로 커밋한다. 새로 생긴 `.uid`는 대응하는 `.gd`를 추가한 커밋에 같이 넣는다.

### 새로 받은 트리에서 `npm run dev`·`npm run build`가 바로 실패한다
- 증상: `check-godot-stale: Godot export가 소스와 다릅니다`.
- 원인: `public/godot/.export-src-hash`에 기록된 해시와 현재 `project/` 소스 해시가 다르다. Godot 팩이 아직 없거나 소스가 바뀐 경우다.
- 대응: `npm run godot:build` 뒤 `npm run godot:link`(로컬) 또는 `godot:publish`(이미지용)를 한다. 팩 없이 웹만 볼 때는 `SKIP_GODOT_STALE_CHECK=1 npm run dev`를 쓴다.

### 이미지 안에서 엔진이 404를 낸다
- 원인: `godot:link`는 `public/godot`에 심볼릭 링크를 만든다. 링크를 이미지에 구우면 이미지 안에 `project/web`이 없어 파일이 비어 있다.
- 대응: 이미지용은 `godot:publish`(복사)를 쓴다. `web/Dockerfile`은 `public/godot`에 링크가 있거나 `index.pck`가 없으면 빌드를 멈춘다.

### 웹 WASM에서 공개 배열을 통째로 바꾸면 크래시한다
- 증상: 웹 빌드에서만 간헐적으로 크래시한다.
- 원인: 공개 `Array` 멤버를 함수 안에서 새 배열로 바꿔 넣으면 복사 시 쓰기(COW) 동작과 얽혀 WASM에서 문제가 된다.
- 대응: `clear()` 후 채우는 방식으로 쓴다. `lint_gd.py`의 `array-cow-replace`가 이 패턴을 잡는다.

## 캐시와 배포

### 배포했는데 브라우저가 옛 엔진을 쓴다
- 원인: `dagul-prod.external.kr`은 Cloudflare DNS 전용(회색 구름)이라 Cloudflare 캐시 퍼지가 응답을 바꾸지 않는다. 캐시는 브라우저에만 있다.
- 대응: 서버는 버전 쿼리가 없는 Godot 파일에 `Cache-Control: no-store`와 `CDN-Cache-Control: no-store`를 붙이고, `?v=<해시>` 요청만 불변 캐시로 준다. 그래도 옛 엔진이면 브라우저 강력 새로고침(Cmd+Shift+R)으로 확인한다. 퍼지 실패는 helm을 막지 않는다(`HACKERTONE_REQUIRE_PURGE=1`일 때만 실패).

### 문서 한 줄만 고쳐도 슬롯이 다시 배포된다
- 원인: `ci-plan.py`는 `apps/<슬롯>/` 아래 파일이 하나라도 바뀌면 확장자와 무관하게 그 슬롯을 배포 대상으로 고르고 helm도 켠다. 허브 이미지 태그는 슬롯 입력 파일 트리의 해시이고, Godot 소스 해시(`check-godot-stale`)도 `project/` 아래 모든 파일(`.godot`, `web` 제외)을 포함한다. 그래서 `README.md`나 `AGENTS.md`만 바꿔도 새 태그로 이미지를 굽고, 로컬에서는 팩 신선도 검사가 실패한다.
- 대응: 슬롯 폴더 안 문서 변경은 배포와 Godot 재익스포트를 부른다는 전제로 묶어서 커밋한다. 로컬에서 신선도 검사에 걸리면 `npm run godot:build`로 스탬프를 갱신한다.

### 배포 SIGTERM에 경기가 30초 만에 끊긴다
- 원인: 허브는 진행 중 경기를 240초까지 기다리지만, k8s `terminationGracePeriodSeconds`가 그보다 짧으면 kubelet이 먼저 강제 종료한다.
- 대응: 차트의 값(270초)을 허브 드레인 시간 이상으로 유지한다.

### 로컬 `dev.sh`가 기존 서버 프로세스를 죽인다
- 동작: 3100 포트에 리스너가 있는데 `/health`가 `"ok":true`를 돌려주지 않으면 그 프로세스를 SIGTERM, 이어서 SIGKILL로 종료한다. 응답이 정상이면 새 팩만 링크하고 기존 서버를 그대로 쓴다.
- 대응: 3100 포트에서 다른 서비스를 돌리고 있으면 `PORT`를 바꿔 실행한다.

## 슬롯 사이의 코드 이동

- `dagul-prod`와 개발 슬롯은 구조가 다르다. `dagul-prod/project`는 `core/`+`games/<id>/` 구조이고 서버가 시뮬을 돌린다. 개발 슬롯의 `project`는 `scripts/`·`scenes/` 구조이고 방장 클라이언트가 시뮬을 돌리며 `src/`의 중계 서버와 `host_snap`/`peer_input` 메시지로 통신한다. 한쪽 `project/`를 다른 쪽에 복사하면 동작하지 않는다.
- 두 개발 슬롯(`server-pjh-dev1`, `server-fig-dev1`)끼리 게임플레이를 맞출 때는 `project/`만 복사한다. `src/` 허브는 두 슬롯이 서로 다르게 고쳐져 있어 통째로 덮으면 한쪽 변경이 사라진다. 웹 익스포트 산출물은 복사하지 않는다. 배포 과정이 다시 만든다.
- 게임 규칙·수치는 원본(`game-pjh-gang-up`)과 `server-pjh-dev1`의 GDScript에서 `dagul-prod/web/lib/hub/match-*.ts`로 결정론 포팅해 왔다. 파일 머리 주석에 원본 GD 파일과 함수 이름이 적혀 있다. 규칙을 고칠 때는 TS 시뮬과 Godot 쪽 스냅 해석(`games/dagul/net/snap_contract.gd` 등)을 함께 본다.

## 반복 작업 체크리스트

### dagul-prod에 게임 모듈 추가
1. `project/games/<id>/game.gd`에 GameModule 계약(`id`, `start`, `tick`, `push_snap` 등)을 구현하고 `main.tscn`을 둔다. `core/`는 바꾸지 않는다.
2. `web/lib/games/catalog.ts`의 `GAME_CATALOG`에 항목을 추가한다. `pack`은 산출물 폴더 이름이다(지금은 모든 게임이 `dagul` 팩 하나).
3. `web/messages/ko.json`, `en.json`에 `titleKey`, `blurbKey` 문구를 넣는다.
4. 검증: `npm run check:contract`, `npx vitest run`(i18n 키 실존 테스트 포함), `python3 lint_gd.py apps/dagul-prod/project --baseline lint_gd_baseline.json`, `python3 scripts/gd_test.py`.

### 새 배포 슬롯 추가
1. `apps/server-<이름>/`에 `hackertone.yaml`, `Dockerfile`, 허브 소스, `project/`를 만든다.
2. `python3 deploy/scripts/plant-apps.py`로 `values-games.yaml`과 보드 `slots.json`을 다시 만든다.
3. 검증: `python3 deploy/scripts/test_ship_contracts.py`, `python3 deploy/scripts/test_hub_scale.py`.

## 테스트 관찰

- `tests/rooms/lobby-room.test.ts`의 "이어받은 방장이 시작·게임변경·강퇴를 쓴다"는 전체 실행에서 한 번 실패하고 단독 재실행에서 통과했다(2026-09-30). 강퇴 직후 패치 한 번을 기다린 시점에 강퇴된 세션이 아직 좌석 목록에 남아 있었다. 전체 스위트가 실패하면 이 테스트를 단독으로 다시 돌려 구분한다.
