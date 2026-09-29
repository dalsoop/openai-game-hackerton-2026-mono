# 현재 상태

기준 시점: 2026-09-30, `main` 5e2d383(2026-08-30 마지막 머지).

## 한눈에

- 제출 엔트리 다굴(`dagul-prod`)은 로비부터 경기 종료까지 구현되어 있고, 이 Mac에서 로컬 게이트 대부분이 통과했다.
- 운영 배포는 멈춰 있다. 배포 러너와 클러스터 접근 호스트가 2026-09-24에 퇴역했고, 2026-09-30 조회에서 모든 공개 슬롯이 응답하지 않았다.
- `main`의 웹 게이트가 빨간 상태다. 마지막 두 커밋(`/stats` 페이지, `/api/stats`)은 이 때문에 배포 단계까지 가지 못했다.

## 기능별 상태

| 영역 | 구현 | 검증 근거 |
|---|---|---|
| 방 만들기·입장·목록(`/rooms`)·PIN·방 열고 닫기·강퇴 | 구현됨 | vitest `tests/rooms/lobby-room.test.ts` 등. 2026-09-30 단독 실행 63개 통과 |
| 좌석 유예·재접속·새 창 이어받기 | 구현됨 | vitest(`use-session`, `lobby-room` 이어받기 케이스). 이어받기 방장 케이스 하나가 전체 실행에서 간헐 실패 |
| 로딩 장벽(전원 ready, 60초 초과 좌석 퇴장) | 구현됨 | vitest `match-load-ready`, `waiting-room-start` 계열 통과 |
| 서버 권위 경기 시뮬(자기장 5단계, 210초 판정, 다운·부활 3회, 장비·궁극기·확인사살·CC·코어·상자·타워, CPU) | 구현됨 | vitest 시뮬 모듈 테스트 통과. 실제 8인 경기 플레이 검증 기록은 2026-08-30 이후 없음 |
| Godot 셸·게임 모듈(`dagul`, 숨김 `sparring`)·스냅 보간·예측 | 구현됨 | `scripts/gd_test.py` 2026-09-30 `GDTEST SUMMARY pass=1447 fail=0` |
| React↔Godot 계약 대조 | 구현됨 | `check:contract` 2026-09-30 통과(빌드 산출물 있는 상태에서는 압축본 수정 시각 보정 후 통과) |
| Godot 웹 익스포트 | 구현됨 | `npm run godot:build` 2026-09-30 이 Mac에서 성공 |
| 한/영 로케일 | 구현됨 | vitest i18n 키 실존 테스트 통과 |
| 운영 지표(`/metrics`, DAU·D1/D7, `/api/stats`, `/stats`) | 구현됨 | `/stats` 페이지는 웹 아키텍처 테스트(한글 리터럴 금지)에 걸려 실패 중이며 배포된 적 없음 |
| 배포 파이프라인(ship·helm·퍼지·주석) | 구현됨 | `test_ship_contracts.py` 59개, `test_hub_scale.py` 4개 2026-09-30 통과. 실제 배포 실행 경로는 퇴역 |
| 개발 슬롯 `server-pjh-dev1`, `server-fig-dev1` | 구현됨(구조가 운영 슬롯과 다름) | 2026-09-30 이 세션에서 테스트를 돌리지 않음. 마지막 변경 2026-08-27 |
| 슬롯 보드 `server-board` | 구현됨 | 공개 주소 2026-09-30 HTTP 523 |
| `game-lhj-animal` | 스캐폴드와 기획 메모, 일부 이펙트 스크립트만 있음 | 검증 없음 |

## 2026-09-30 로컬 검증 결과 (macOS, Node 24.15, Python 3.14, Godot 4.7.1)

| 명령 | 결과 |
|---|---|
| `python3 lint_gd.py apps/dagul-prod/project --baseline lint_gd_baseline.json` | 통과. 위반 1건(nesting-depth), 기준값 1 이하 |
| `python3 scripts/gd_test.py` | 통과. pass=1447 fail=0 |
| `python3 deploy/scripts/test_ship_contracts.py` | 통과. 59개 |
| `python3 deploy/scripts/test_hub_scale.py` | 통과. 4개 |
| `npm ci` | 통과 |
| `npx tsc --noEmit` | 통과 |
| `npx tsc --project tsconfig.server.json --noEmit` | 통과 |
| `npm run lint` | 통과 |
| `npm run schema:check` | 통과 |
| `npx vitest run` | 실패. 140개 파일 중 2개, 1281개 테스트 중 2개 실패(29개 건너뜀). ① 아키텍처 테스트: `lib/hub/stats-page.ts` 한글 리터럴 ② `lobby-room` 이어받기 방장 케이스(단독 재실행 시 통과) |
| `npm run check:contract` | 통과 |
| `npm run godot:build` | 통과 |
| `python3 deploy/scripts/status.py` | 모든 슬롯 실패(`dagul-prod` 네트워크 도달 불가, 나머지 HTTP 523) |

GitHub Actions 기록: `main`의 마지막 `Apps` 실행(2026-08-30, 5e2d383)은 `lint-web` 실패로 `apply`를 건너뛰었고, 직전 성공 배포는 ce73e84(2026-08-30)다. `Live hosts` 조회 워크플로의 마지막 성공은 2026-09-13이다.

## 남은 일 (우선순위 순)

1. 배포 경로 재수립: 퇴역한 러너·SSH 경로를 대신할 배포 주체와 클러스터 접근 방법을 정하고 `apps.yml`의 `apply` 잡과 `apply-apps.py`의 원격 실행부를 바꾼다. 그 전에는 어떤 변경도 운영에 반영되지 않는다.
2. `main` 웹 게이트 복구: `lib/hub/stats-page.ts`의 한글 문구를 허용된 정본으로 옮기거나 예외 규칙을 정한다.
3. 엔진 보조 세션 입장 경로 정리: 쓰지 않는 `engine: true` 경로를 닫거나 PIN·닫힘·인원 검사를 적용한다.
4. PIN 추측 방지와 메시지 빈도 제한.
5. DAU 식별자를 표시 이름에서 게스트 id 계열로 바꾸기.
6. 개발 슬롯의 역할 정리: 운영 구조와 다른 두 슬롯을 계속 둘지, 운영 구조로 옮길지 결정.
