# apps/dagul-prod/project

## 맡는 일

운영 슬롯의 Godot 4.7.1 웹 클라이언트다. 경기 화면 렌더, 입력 조립, 스냅 보간·예측, 인게임 HUD·오디오를 맡는다. 웹 익스포트 결과(`web/`)는 허브 이미지의 `public/godot/<pack>/`으로 복사되어 서빙된다.

## 맡지 않는 일

- 로비·방·대기실 UI와 방 상태 관리는 `../web`(React·Colyseus)이 맡는다. 여기서 로비 화면이나 로비 메시지(`create`, `join`, `rooms`, `kick`, `mode`, `chat`)를 만들지 않는다.
- 경기 규칙의 권위는 `../web/lib/hub/match-*.ts`에 있다. 여기의 판정은 화면 연출과 예측용이며, 서버 결과와 다르면 서버가 맞다.
- 네트워크 소켓을 직접 열지 않는다. `WebSocketPeer.new()`와 Colyseus GDExtension을 쓰지 않는다.
- `addons/godot-touch-controls`는 `tools/godot-touch-controls`로 가는 심볼릭 링크다. 여기서 고치면 모든 슬롯이 바뀐다.
- `web/`의 익스포트 산출물(`index.wasm`, `index.pck`, 압축본, `manifest.json`)은 커밋하지 않는다.

## 불변 조건

- `core/`는 게임을 모른다. `core/`의 어떤 파일도 `res://games/`를 참조하지 않는다.
- 게임은 `games/<id>/game.gd`에서 `GameModule`(`core/contract/game_module.gd`)을 구현하고 자기 `main.tscn`을 가진다. 새 게임을 추가할 때 `core/`는 바꾸지 않는다.
- React와 주고받는 키·메시지 타입은 `core/contract/web_contract.gd`의 상수만 쓴다. `"gangup_…"` 문자열이나 메시지 타입 문자열을 코드에 직접 쓰지 않는다. 이 파일은 `../web/lib/contract/wire.ts`의 거울이며, 먼저 TS 쪽을 바꾸고 여기를 맞춘다.
- 네트워크는 `core/autoload/network_manager.gd`가 페이지 브릿지(DOM 이벤트)로만 한다.
- 매치 셸은 게임 모듈 `start` 뒤에 `ready`를 보낸다. 서버의 로딩 장벽이 이 신호로 열린다.
- 게임 모듈에 스냅을 넘길 때는 사본을 넘긴다. 공유 참조를 넘기면 보간이 망가진다.
- 색은 `core/ui/ui_theme.gd`의 `UiTheme` 상수로만 쓴다.
- `lint_gd.py` 한도: 파일 700줄, 함수 40줄, 함수 안 중첩 깊이 2. 오토로드 공개 멤버는 프로젝트 안에서 쓰이거나 `# lint-gd: public-api` 주석이 있어야 한다. 공개 `Array` 멤버를 함수 안에서 통째로 바꾸지 않는다.

## 구현 패턴

- 큰 클래스는 `RefCounted` 모듈로 나누고 파사드가 조합한다(예: `games/dagul/render/`, `games/dagul/net/`).
- 스냅 해석은 `games/dagul/net/snap_contract.gd`가 기준이다. 서버가 새 필드를 보내면 이 파일에 키와 기본값을 추가하고, 기본값과 같은 값은 서버가 생략할 수 있다는 전제로 `get(키, 기본값)`으로 읽는다.
- 오토로드는 `/root` 노드로 찾는다. 엔진 싱글톤 API로 오토로드를 찾지 않는다.
- 웹 오디오는 Sample 재생 방식과 Master 버스를 쓴다. 스트림 강제나 버스 추가 우회를 하지 않는다.

## 테스트

- `python3 lint_gd.py apps/dagul-prod/project --baseline lint_gd_baseline.json`(저장소 루트).
- `python3 scripts/gd_test.py`(저장소 루트): `tests/run_tests.gd`를 헤드리스로 돌리고 `GDTEST SUMMARY … fail=0`이어야 한다. `run_tests.gd`는 테스트 파일을 자동으로 찾지 않고 명시된 목록만 돌린다. 새 테스트 파일은 `tests/`에 두고 그 목록에 경로를 추가해야 실행된다.
- 스냅 해석·보간·예측·입력 채널을 바꾸면 `tests/`에 경계값(빈 이벤트 스냅, 필드 생략, 재접속 후 첫 스냅)을 추가한다.
- 브라우저 로드 확인은 `../web`에서 `npm run godot:build` 뒤 로컬 서버로 한다. 브라우저에서 Godot이 뜨지 않으면 머지하지 않는다.
