# apps/server-fig-dev1

## 맡는 일

이현진(Figix)의 개발 슬롯이다. `https://server-fig-dev1.external.kr/`에 배포되도록 선언되어 있다(`hackertone.yaml`). 두 부분으로 이뤄진다.

- `src/`: `ws` 기반 중계 허브(포트 기본 9120). 방·좌석·재접속·채팅을 관리하고, 경기 중에는 방장 클라이언트의 `host_snap`을 다른 사람에게 `snap`으로, 게스트 입력을 방장에게 `peer_input`으로 전달한다. 허브는 시뮬을 돌리지 않는다.
- `project/`: Godot 4.7.1 게임. 로비 UI와 경기 시뮬을 모두 가지고, 방장 클라이언트가 시뮬 권위를 가진다.

## 맡지 않는 일

- 운영 슬롯 `apps/dagul-prod`와 구조가 다르다. 이 폴더의 `project/`나 `src/`를 `dagul-prod`에 복사하지 않고, 반대 방향으로도 복사하지 않는다. 규칙·수치를 운영 슬롯에 반영할 때는 `dagul-prod/web/lib/hub/match-*.ts`로 옮겨 구현한다.
- 다른 개발 슬롯의 파일을 이 슬롯 작업 중에 고치지 않는다.
- `apps/game-pjh-gang-up` 원본을 고치지 않는다.
- `project/addons/godot-touch-controls`는 `tools/godot-touch-controls`로 가는 심볼릭 링크다. 여기서 고치면 모든 슬롯이 바뀐다.

## 불변 조건

- 허브 경로 접두사는 `/gang-up`이다(`hackertone.yaml`의 `hub.pathPrefix`). 헬스·메트릭·상태는 `/health`·`/metrics`·`/status`와 `/gang-up/…` 두 형태를 모두 받는다. 보드의 `monitor.html`이 `/gang-up/status`를 읽으므로 이 경로를 바꾸지 않는다.
- 방 최대 인원은 8명(`src/modes.ts` `MAX_PLAYERS`)이다.
- 재접속은 `hello` 메시지의 32자 16진 `resume` 토큰으로만 한다.
- 클러스터에서는 Redis logical DB 2번을 쓴다(`deploy/chart/values-games.yaml`).
- `SLOT_FOLDER`가 없으면 `src/config.ts`의 기본값(삭제된 옛 슬롯 이름)이 쓰인다. 클러스터에서는 차트가 값을 넣어 준다. 로컬에서 슬롯 이름이 필요하면 환경 변수로 준다.
- Godot 웹 익스포트 산출물(`project/web/`의 wasm·pck·압축본)은 커밋하지 않는다.

## 구현 패턴

- 허브 메시지 타입은 `src/config.ts`의 `MSG`, 한국어 안내문은 `src/messages.ts`의 `KO`에 둔다.
- 클라이언트별 메시지 빈도는 토큰 버킷(`rateBudget`, `rateRefillPerMs`)으로 제한한다.
- Godot 코드는 `project/scripts/`(sim·net·render·ui 등)와 `project/autoload/`에 있다.

## 테스트

- 허브: `npm run build`(tsc)로 타입을 확인한다. `GANG_UP_WS=ws://127.0.0.1:9120 node scripts/eight_client_test.mjs`, `node scripts/reconnect_test.mjs`로 8인 접속과 재접속을 확인한다.
- Godot: `RUN_SMOKE.sh`(헤드리스 `tests/smoke_test.gd`), `project/tests/`의 결정론 비교 테스트.
- 저장소 루트의 `lint_gd.py`는 CI와 커밋 훅에서 이 슬롯을 검사하지 않는다. 필요하면 `python3 lint_gd.py apps/server-fig-dev1/project`로 직접 돌린다.
