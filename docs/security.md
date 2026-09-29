# 보안 정책

## 보호 대상

| 자산 | 위협 | 현재 방어 |
|---|---|---|
| 좌석(누가 어느 칸의 입력을 내는가) | 남의 좌석을 가로채 조작 | 게스트 id + 게스트 키가 모두 일치해야 이어받기 |
| 잠긴 방(PIN) | 초대받지 않은 사람의 입장 | 4자리 PIN 비교 |
| 방장 권한(시작·강퇴·PIN·열고 닫기·게임 변경) | 일반 참가자의 권한 사용 | 서버가 메시지마다 `hostSessionId`와 보낸 세션을 비교 |
| 서버 자원 | 과도한 접속·큰 메시지 | 전역 동접 한도, WebSocket 최대 페이로드 32KB, 입력 값 범위 클램프 |
| 배포 자격(Cloudflare·Grafana 토큰, Harbor, 클러스터 SSH) | 저장소 유출 | 저장소에 두지 않고 러너 환경·러너 파일·클러스터 시크릿에만 둔다 |

## 인증 흐름

사용자 계정이나 로그인은 없다. 신원은 브라우저 쿠키 두 개로만 정한다.

1. 페이지가 처음 열리면 쿠키 `gangup_uid`(게스트 id, 100000~999999 숫자)와 `gangup_ukey`(32자 16진, `crypto.getRandomValues`로 생성)를 확인하고 없으면 만든다. 두 쿠키 모두 `Path=/`, 유효기간 2년, `SameSite=Lax`이고 JavaScript로 쓰므로 `HttpOnly`가 아니다.
2. 방에 들어갈 때 join 옵션에 이름, 게스트 id, 게스트 키, (PIN 방이면) PIN을 싣는다.
3. 서버는 입장 시 방 열림 여부, 좌석 이어받기 증명, PIN, 전역 동접 한도, 좌석 수를 확인하고, 조건에 맞지 않으면 사람이 읽을 수 있는 안내 문장과 함께 거절한다. 세부 판정 순서: 보안 이슈 있음, 비공개 추적.
4. 게스트 키가 32자 미만이거나 게스트 id가 양의 정수가 아니면 증명이 없는 것으로 보고 일반 입장으로 처리한다. 증명이 틀려도 오류를 내지 않고 새 좌석을 준다.
5. 쿠키를 쓸 수 없는 환경이면 증명 없이 입장한다. 이 경우 창을 새로 열면 좌석을 이어받지 못한다.

## 권한 표

| 주체 | 허용 | 금지 |
|---|---|---|
| 방장 | 시작, 게임 변경(대기실에서만, 카운트다운 중 불가), 강퇴(자기 자신 제외), PIN 설정·해제, 방 열고 닫기 | 경기 중 게임 변경 |
| 일반 착석자 | 자기 좌석 입력, 캐릭터 선택, 팩 진행률·`ready` 보고, 핑 | 시작·강퇴·PIN·열고 닫기·게임 변경(시도하면 `error` 메시지로 거절) |
| 방 밖 방문자 | `GET /rooms`로 방 목록(제목·게임·모드·phase·열림·PIN 유무·인원) 조회, 공개 방 입장, PIN을 아는 잠긴 방 입장 | 닫힌 방 입장, PIN 값 조회 |
| 엔진 보조 세션 | 좌석 없이 경기 입력 채널로 쓰인다 | 좌석 차지 |

- 방장은 연결된 착석자 중 좌석 번호가 가장 작은 사람으로 자동 결정된다. 방장 권한을 넘기는 별도 명령은 없다.
- 방 상태(`LobbyState`)는 방 안의 모든 세션에 동기화되며, 여기에는 PIN 문자열이 들어 있다. 방 목록 메타데이터에는 PIN 유무만 싣는다.

### 엔진 보조 세션

Godot이 허브에 직접 붙기 위해 남겨 둔 입장 경로다. 현재 정상 클라이언트는 이 경로를 쓰지 않는다. 보안 이슈 있음, 비공개 추적.

## 공개 HTTP 엔드포인트

아래 경로는 인증 없이 누구나 호출할 수 있다: `/health`, `/healthz`, `/metrics`, `/ccu`, `/api/ccu`, `/api/version`, `/api/stats`, `/stats`, `/rooms`, `POST /api/load-time`. `POST /api/load-time`은 클라이언트가 보고한 로드 시간을 운영 지표에 반영한다. 이 입력의 검증 수준: 보안 이슈 있음, 비공개 추적. 슬롯 개명 전 옛 호스트(`server-prod.`로 시작하는 Host)는 410으로 끊는다.

모든 허브 응답에 교차 출처 격리 헤더(`cross-origin-opener-policy: same-origin`, `cross-origin-embedder-policy: require-corp`, `cross-origin-resource-policy: same-origin`)를 붙인다. Next.js 페이지에는 `X-Frame-Options: DENY`와 `X-Content-Type-Options: nosniff`를 붙인다.

## 입력 검증

- 이름·제목: `< > & " ' \``를 제거하고 24자로 자른다.
- PIN: 숫자만 남겨 정확히 4자리일 때만 유효하다.
- 게임 id: 카탈로그에 없으면 기본 게임으로 바꾼다.
- 경기 입력: Colyseus `defineInput`의 sanitize 표로 이동 축(−1~1), 조준 좌표(경기장 크기 안), 버튼(0~1)을 클램프한다. 좌석당 입력 버퍼는 32프레임이다.
- WebSocket 한 메시지의 최대 크기는 32KB다.
- 메시지 빈도와 입장 시도 제한: 보안 이슈 있음, 비공개 추적.

## 기록 대상

별도 감사 로그는 없다. 서버가 남기는 기록은 Prometheus 메트릭뿐이다.

- 접속·해제 수, 세션 길이, 경기 시작 수, 대기 시간, 입장 거절(동접 한도) 수, 강퇴 수, 틱 소요 시간·초과 수, WebSocket 송신 대기량
- 일간 접속자(DAU)와 D1/D7 재방문: `REDIS_URL`이 있으면 Redis에 `dagul:dau:<날짜>`(HyperLogLog)와 `dagul:first-seen:<식별자>`를 30일 TTL로 저장한다. 식별자로 쓰는 값은 게스트 id가 아니라 좌석 표시 이름이다.

강퇴·PIN 변경·방 닫기가 누구에 의해 언제 일어났는지는 남지 않는다.

## 자격 증명

| 자격 | 두는 곳 | 쓰는 곳 | 수명·교체 |
|---|---|---|---|
| Cloudflare API 토큰 | 러너 환경 변수 `CLOUDFLARE_API_TOKEN` 또는 `CF_API_TOKEN`, 또는 러너 파일 `/etc/hackertone/cloudflare.env`, 또는 `HACKERTONE_CLOUDFLARE_ENV`가 가리키는 파일 | `purge-cache.py` | 저장소 밖에서 관리한다. 빈 GitHub 시크릿으로 러너 값을 덮지 않는다 |
| Cloudflare DNS01 토큰(TLS 발급) | 클러스터 시크릿 `cloudflare-api-token`(키 `api-token`). 네임스페이스에 없으면 차트가 `traefik` 네임스페이스의 같은 이름 시크릿을 복사한다 | cert-manager 발급자 | 클러스터에서 관리한다 |
| Grafana API 토큰 | 환경 변수 `GRAFANA_API_TOKEN` 또는 `GRAFANA_TOKEN` | helm 성공 후 대시보드 주석 | 없으면 주석을 건너뛴다 |
| 클러스터 접근 | SSH 별칭 `pve-lan`과 러너 호스트의 SSH 키 | `apply-apps.py`의 원격 명령·rsync | 러너 호스트가 퇴역해 현재 쓸 수 있는 경로가 없다 |

- 저장소에 토큰·비밀번호·개인 키를 커밋하지 않는다. Godot `export_credentials.cfg`와 `.env*`(단 `.env.example` 제외)는 `.gitignore`로 막혀 있다.

## 민감 정보

- 게스트 키는 비밀이다. 화면·로그·방 상태·메트릭에 싣지 않는다. 게스트 id는 닉네임에 공개되므로 비밀이 아니다.
- 좌석 표시 이름은 DAU 식별자로 Redis에 30일간 남는다.
- 공개 저장소의 `README.md`에 팀원 연락 이메일이 적혀 있다.
