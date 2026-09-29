# 외부 인터페이스 계약

## 공통 규칙

- 인증은 없다. 브라우저 신원은 쿠키 `gangup_uid`(게스트 id)와 `gangup_ukey`(32자 이상 비밀 키)다.
- HTTP JSON 응답은 모두 `content-type: application/json`, `cache-control: no-store`다. 메트릭은 Prometheus 텍스트 형식(`text/plain; version=0.0.4`)이다.
- 서버가 사람에게 보여 줄 오류는 한국어 문장 `msg`로 보낸다. 클라이언트는 문장 내용으로 분기하지 않고 메시지 타입과 `reason`으로 분기한다.
- `dagul-prod`는 호스트 루트(`/`)에서, 개발 슬롯은 `/gang-up` 접두사 아래에서 서빙한다.

## HTTP 엔드포인트 (dagul-prod 허브)

| 경로 | 입력 | 출력 | 오류 |
|---|---|---|---|
| `GET /health`, `/healthz` | 없음 | `{"ok":true,"slot":"<슬롯>","ccu":n,"cap":n,"level":"quiet|busy|very_busy|full","admit":bool}` | 없음(프로세스가 살아 있으면 200) |
| `GET /ccu`, `/api/ccu` | 없음 | `{"ccu":n,"cap":n,"level":…,"admit":bool}`. 전역 CCU 조회가 3초 안에 끝나지 않으면 이 프로세스의 CCU로 대신한다 | 없음 |
| `GET /api/version` | 없음 | `{"id":"<빌드 id>"}`. 열린 탭은 첫 값을 기억하고 값이 바뀌면 새 배포로 판단한다 | 없음 |
| `GET /rooms` | 없음 | `{"rooms":[RoomAvailable…]}`. 대기실(`playing` 아님)이고 열려 있고 잠기지 않았고 8명 미만인 방만 담는다. PIN 방도 목록에 오르며 메타데이터 `hasPassword`로 구분한다 | 3초 안에 조회가 끝나지 않으면 503 `{"rooms":[]}` |
| `GET /api/stats` | 없음 | 운영 지표 JSON(ccu, ccu_cap, admit, rooms, rooms_playing, players, dau, games_started 등 누적값) | 없음 |
| `GET /stats` | 없음 | 운영 지표 HTML 페이지 | 없음 |
| `GET /metrics` | 없음 | Prometheus 텍스트(CCU, 방·플레이 지표, 운영 지표) | 없음 |
| `POST /api/load-time` | JSON `{"ms": number}` | 204. 유한한 숫자일 때만 로드 시간 지표에 더한다 | 본문이 JSON이 아니어도 204 |
| `GET /godot/<pack>/<파일>` | `?v=<해시>` 선택 | Godot 엔진 파일. `Accept-Encoding`에 따라 `.br`/`.gz`를 준다. `?v=`가 있으면 불변 캐시, 없으면 `no-store` | 없는 파일은 404 |
| `/matchmake/*` | Colyseus 매치메이킹 | Colyseus 표준 응답 | Colyseus 표준 |
| Host가 `server-prod.`로 시작하는 모든 요청 | 없음 | 410 `gone — https://dagul-prod.external.kr/` | 없음 |

## Colyseus 방 계약 (dagul-prod)

- 방 이름: `<SLOT_FOLDER>-lobby`(운영은 `dagul-prod-lobby`). 한 방의 `maxClients`는 16(사람 좌석 8 + 엔진 보조 세션).
- 상태 패치 빈도: 기본 60Hz. 서버 틱: 60Hz 고정.

### 방 만들기·입장 옵션

| 필드 | 형식 | 의미 |
|---|---|---|
| `name` | 문자열 | 표시 이름. 서버가 소독하고 24자로 자른다 |
| `game` | 문자열 | 게임 id. 만들 때만. 모르는 값은 `dagul` |
| `title` | 문자열 | 방 제목. 만들 때만 |
| `lock` | `true`·`"true"`·`"on"`·`1`·`"1"` | 만들 때 PIN 잠금 |
| `password` | 문자열·숫자 | PIN. 숫자 4자리만 유효 |
| `guestId`, `guestKey` | 숫자, 32자 이상 문자열 | 좌석 이어받기 증명 |
| `engine` | `true` | 엔진 보조 세션. 좌석을 차지하지 않는다 |

입장 거절은 Colyseus 입장 오류로 오며 메시지는 다음 중 하나다: "방이 닫혔습니다.", "방 비밀번호가 올바르지 않습니다.", "서버가 가득 찼습니다. 잠시 후 다시 시도해 주세요.", "방이 가득 찼습니다 (8)".

### 클라이언트 → 서버 메시지

| 타입 | 페이로드 | 누가 | 서버 동작 |
|---|---|---|---|
| `start` | 없음 | 방장 | 5초 카운트다운 후 경기 시작. 방장이 아니면 `error` |
| `input` | 입력 프레임 객체 | 착석자 | 자기 좌석 입력으로 적용 |
| `kick` | `{slot}` | 방장 | 해당 좌석 세션에 `kicked`(reason `kick`) 후 퇴장 |
| `set_password` | `{enabled?, password?}` | 방장 | PIN 설정·재발급·해제 |
| `room_toggle` | 없음 | 방장 | 열림/닫힘 전환. 닫으면 방장 외 착석자 퇴장 |
| `set_game` | `{game}` | 방장, 대기실 | 게임·모드 변경, 전원 팩 진행률 0 |
| `set_character` | `{characterId}` | 착석자, 대기실 | 캐릭터 선택. 모르는 id는 서버가 정규화한다 |
| `pack_pct` | `{pct}` | 착석자, 대기실 | 팩 다운로드 진행률 보고(서버가 범위를 클램프) |
| `ready` | 없음 | 착석자 | 경기 로딩 완료. 전원이면 로딩 장벽 해제 |
| `ping` | 임의 값 | 누구나 | 같은 값을 `pong`으로 되돌림 |
| `snap_off` / `snap_on` | 없음 | 누구나 | JSON `snap` 수신 끄기/켜기 |

Colyseus `defineInput` 채널도 열려 있다. 좌석당 버퍼 32프레임이고, 이동 축은 −1~1, 조준은 경기장 크기 안, 버튼은 0~1로 클램프된다.

### 서버 → 클라이언트 메시지

| 타입 | 페이로드 | 언제 |
|---|---|---|
| `start` | `{you, host, seed, mode, seats[{slot,name,connected,characterId}], engineJoin?{roomId}}` | 경기 시작 시 각 사람에게. `seats`에는 사람만 있고 CPU 좌석은 `snap`으로만 온다 |
| `snap` | 경기 스냅 JSON | 매 틱(`snap_off`한 세션 제외) |
| `gun_fire` | 발사 효과 | 경기 중 |
| `error` | `{msg}` | 권한 없는 명령, 방장 부팅 실패 등 |
| `kicked` | `{msg, reason}`. reason은 `kick`, `idle`, `load-wait`, `takeover` 중 하나(방 닫기로 인한 퇴장은 reason 없음) | 퇴장 직전 |
| `pong` | `ping`에서 받은 값 | 즉시 |
| `server_shutdown` | 안내 문자열 | 배포 SIGTERM, 경기 중인 방 |

방 상태 스키마(`LobbyState`)는 `gameId`, `open`, `phase`(`lobby`|`playing`), `hostSessionId`, `title`, `password`, `mode`, `seed`, `createdAtMs`, `idleUntilSec`, `players[]`, `matchTick`, `heroes`, `bullets`, `match`, `loadHeld`, `startInSec`를 가진다.

## React ↔ Godot 핸드오프 계약

정본은 `apps/dagul-prod/web/lib/contract/wire.ts`, Godot 거울은 `apps/dagul-prod/project/core/contract/web_contract.gd`다. `npm run check:contract`가 두 파일의 키를 대조한다.

| 종류 | 키 |
|---|---|
| 핸드오프 저장 키 | `gangup_from_hub`, `gangup_game`, `gangup_name`, `gangup_room_id`, `gangup_you`, `gangup_resume`, `gangup_match` |
| 웹 저장 키 | `gangup_my_room`, `gangup_nickname`, `gangup_uid`, `gangup_ukey`, `gangup_pending_join` |
| DOM 이벤트 | `godot-match-start`, `godot-match-end`, `gangup-to-engine`, `gangup-from-engine` |

Godot은 `gangup-from-engine` 이벤트로 `{type, payload}` 패킷을 올리고, React 브릿지가 그대로 `room.send(type, payload)` 한다. 서버에서 온 `snap`, `gun_fire`, `error`, `state`는 `gangup-to-engine`으로 Godot에 내려간다.

## 슬롯 선언 파일 `apps/<폴더>/hackertone.yaml`

| 키 | 의미 |
|---|---|
| `id` | 슬롯 짧은 id(`prod`, `pjh-dev1` 등). Redis DB 배정과 보드 표시에 쓴다 |
| `kind` | `game` 또는 `board` |
| `title`, `blurb`, `players` | 보드 표시용 |
| `web.enabled`, `web.exportDir` | Godot 웹 익스포트 여부와 위치(`project/web`) |
| `web.pipeline` | `platform`이면 Next 슬롯 방식(팩을 `web/public/godot`에 복사해 이미지에 넣음) |
| `hub.enabled`, `hub.pathPrefix`, `hub.dockerfile` | 허브 이미지 여부, 서빙 접두사, Dockerfile 경로(슬롯 루트 기준) |

## 개발 슬롯 허브 프로토콜 (server-pjh-dev1, server-fig-dev1)

`ws` 라이브러리의 JSON 메시지이고 필드 `t`가 타입이다. 로비 동사(`hello`, `create`, `join`, `rooms`, `kick`, `start` 등)와 경기 중계(`input`, `host_snap`, `snap`, `peer_input`, `peer_parked`, `peer_reclaimed`)로 이뤄진다. 방장 클라이언트가 `host_snap`을 올리면 허브가 다른 사람에게 `snap`으로 중계하고, 게스트 입력은 `peer_input`으로 방장에게 전달한다. 재접속은 `hello`의 32자 16진 `resume` 토큰으로 한다. HTTP는 `/health`·`/metrics`·`/status`(각각 `/gang-up/` 접두사 형태도 받음)와 `/gang-up` 아래 정적 파일이다. 서버 보드의 `monitor.html`은 `/gang-up/status`를 읽는다.
