# 미해결 문제

## 푸시해도 배포되지 않고 공개 슬롯이 모두 내려가 있다
- 현상: `apps/**`를 `main`에 푸시하면 `Apps` 워크플로의 `apply` 잡이 self-hosted 러너 `[self-hosted, hackertone]`를 기다린다. `apply-apps.py`는 원격 명령을 `pve` 호스트 또는 SSH 별칭 `pve-lan`을 거쳐 k3s 노드에 보낸다. 이 러너와 `pve` 호스트는 2026-09-24에 퇴역했다. 2026-09-30 `status.py` 조회에서 `dagul-prod`는 네트워크 도달 불가, `server-board`·`server-fig-dev1`·`server-pjh-dev1`은 HTTP 523이었다. `Live hosts` 워크플로는 2026-09-13 이후 성공한 적이 없고 20분마다 실패를 쌓는다.
- 영향: 제출 엔트리가 공개 주소에서 동작하지 않는다. 어떤 수정도 운영에 반영할 수 없다. 내부 이미지 레지스트리(Harbor), 내부 Grafana, 클러스터 노드가 지금도 살아 있는지 저장소 안에서 확인할 방법이 없다.
- 지금 해결하지 못하는 이유: 새 배포 주체(러너)와 클러스터 접근 경로는 저장소 밖 인프라이고, 어디로 옮길지는 소유자가 정해야 한다.
- 가능한 접근: 새 러너 레이블과 접근 경로를 정한 뒤 `apps.yml`의 `runs-on`과 `apply-apps.py`의 `on_pve()`·`k3s_argv()`·`run_helm_argv()`·rsync 대상을 바꾸고, `test_ship_contracts.py`의 해당 기대값을 함께 고친다.

## `main`의 웹 게이트가 한글 리터럴 검사로 실패한다
- 현상: `apps/dagul-prod/web`에서 `npx vitest run`을 돌리면 `tests/architecture.test.ts`의 "한글 리터럴은 config(KO)·서버 안내문 정본 외에 없다"가 `lib/hub/stats-page.ts` 때문에 실패한다(2026-09-30 재현). 이 파일은 2026-08-30 커밋 0e0f256에서 들어왔다. 같은 날 `main` 5e2d383의 `Apps` 실행이 `lint-web`에서 실패해 `apply`를 건너뛰었고, `web-lint` 워크플로도 실패했다.
- 영향: `/stats`·`/api/stats`는 배포된 적이 없다. 웹 파일을 스테이지한 커밋은 커밋 훅의 웹 게이트에 막힌다. 배포 경로가 복구되어도 이 상태로는 배포가 `lint-web`에서 멈춘다.
- 지금 해결하지 못하는 이유: 소스 코드 수정이 필요하다. 운영자용 HTML 페이지 문구를 메시지 팩으로 옮길지, 이 파일을 한글 허용 목록에 넣을지 소유자가 정해야 한다.
- 가능한 접근: 문구를 `config.ts`의 `KO` 같은 허용된 정본으로 옮기거나, 아키텍처 테스트의 허용 파일 목록에 추가한다.

## 방 입장 경로의 접근 통제 문제
- 현상: 보안 이슈 있음, 비공개 추적. 방 입장 경로 하나의 접근 통제가 의도보다 넓다.
- 영향: 비공개로 추적한다.
- 지금 해결하지 못하는 이유: 서버 코드 수정과 소유자 결정이 필요하다.
- 가능한 접근: 비공개로 추적한다.

## 잠긴 방 보호 강도 문제
- 현상: 보안 이슈 있음, 비공개 추적. 잠긴 방 PIN과 메시지 처리의 남용 방지 장치가 약하다.
- 영향: 비공개로 추적한다.
- 지금 해결하지 못하는 이유: 서버 코드 수정과 파티 게임에 맞는 제한 수준에 대한 소유자 판단이 필요하다.
- 가능한 접근: 비공개로 추적한다.

## DAU가 게스트 id가 아니라 표시 이름으로 집계된다
- 현상: `LobbyRoom.onJoin`이 `recordPlayerSession(p.name)`을 호출해 좌석 표시 이름을 DAU·첫 접속일 식별자로 쓴다. 이름은 사용자가 바꿀 수 있고 기본 이름("손님", 십이지 이름#id)이 겹칠 수 있다. `REDIS_URL`이 있으면 이 이름이 `dagul:first-seen:<이름>` 키로 30일간 남는다.
- 영향: DAU와 D1/D7 재방문 수치가 실제 사용자 수와 다르다. 사용자가 입력한 이름이 Redis에 남는다.
- 지금 해결하지 못하는 이유: 서버 코드 수정이 필요하고, 과거 수치와의 연속성을 어떻게 다룰지 소유자가 정해야 한다.
- 가능한 접근: 좌석 증명의 게스트 id를 해시해서 식별자로 쓴다.

## 에이전트 설정과 스킬이 삭제된 슬롯과 퇴역 호스트를 가리킨다
- 현상: `.claude/CLAUDE.md`는 삭제된 `server-yjh-dev1`을 정본으로 소개한다. `.claude/settings.json`의 편집 후 훅은 `lint_gd.py apps/server-yjh-dev1/project/scripts`를 실행하는데, 이 경로가 없어서 검사 파일 0개로 항상 통과한다(2026-09-30 확인). 스킬 `gdscript-quality`는 같은 없는 경로로 린트·파스를 안내하고, 스킬 `hackertone-games-deploy`는 `pve-hackertone` 배포를 안내한다.
- 영향: 에이전트가 `.gd`를 고쳐도 자동 린트가 실제로는 아무것도 검사하지 않는다. 에이전트가 없는 슬롯을 정본으로 믿고 작업하거나 퇴역 호스트로 배포하려 할 수 있다.
- 지금 해결하지 못하는 이유: 팀이 함께 쓰는 에이전트 설정·스킬 파일을 바꾸거나 지우는 일이라 소유자 결정이 필요하다.
- 가능한 접근: 훅과 스킬의 경로를 `apps/dagul-prod/project`로 바꾸고, `.claude/CLAUDE.md`는 루트 `CLAUDE.md`와 겹치므로 제거한다.

## 사람이 쓴 안내 문서가 실제 구성과 다르다
- 현상: `README.md`와 `apps/README.md`는 존재하지 않는 `server-pig-dev1`을 안내한다(실제 폴더는 `server-fig-dev1`). `apps/server-fig-dev1/README.md`도 제목과 주소가 `server-pig-dev1`이다. `docs/DESIGN.md`는 삭제된 `server-yjh-dev1`을 책임 위치로 적고 있다. `apps/README.md`, `deploy/README.md`는 `pve-hackertone` 배포를 현재 절차로 적고 있다. `deploy/usability`의 기본 대상 주소는 삭제된 `server-yjh-dev1`이다. 보드의 `monitor.html`은 삭제된 `server-yjh-dev1`과, `/gang-up/status`를 제공하지 않는 `dagul-prod`를 조회 대상으로 적어 두었다.
- 영향: 사람이 문서를 따라 하면 없는 주소로 접속하거나 퇴역 경로로 배포를 시도한다.
- 지금 해결하지 못하는 이유: 팀원이 직접 관리하는 문서라 어떻게 고칠지 소유자와 팀원이 정해야 한다. `usability` 기본값과 `monitor.html` 목록 변경은 코드 수정이다.
- 가능한 접근: 배포 경로를 다시 정한 뒤 한 번에 갱신한다.

## Godot 빌드가 추적 중인 파일을 바꾼다
- 현상: `npm run godot:build`를 하면 `apps/dagul-prod/project/web/index.html`과 `apps/dagul-prod/web/public/godot/.export-src-hash`가 수정되고, Godot 임포트가 저장소에 없는 `project/tests/test_virtual_stick.gd.uid`를 만든다(2026-09-30 재현). 새로 받은 트리에서는 기록된 소스 해시와 실제 해시가 달라 `npm run dev`·`npm run build`가 팩 신선도 검사에서 멈춘다.
- 영향: 로컬 빌드 뒤 의도하지 않은 파일이 커밋에 섞이기 쉽다. `.uid` 누락이 소스 해시를 기계마다 다르게 만든다.
- 지금 해결하지 못하는 이유: 빌드 산출물을 추적에서 뺄지, 빌드 스크립트를 바꿀지는 코드·설정 변경이고 배포 이미지 빌드(`web/Dockerfile`)에 영향이 있어 배포 경로가 복구된 뒤 이미지 빌드로 검증해야 한다.
- 가능한 접근: 두 파일을 `.gitignore`로 옮기고 이미지 빌드가 스스로 만들게 하거나, 빠진 `.uid`를 커밋해 해시를 고정한다.

## macOS에서 빌드 직후 압축본 신선도 검사가 실패한다
- 현상: macOS에서 `npm run godot:build` 직후 `npm run check:contract`가 `.br`/`.gz`를 낡은 압축본으로 판정해 실패한다. `brotli`와 `/usr/bin/gzip`이 원본 수정 시각을 초·마이크로초 단위로 잘라 복사하기 때문이다. 압축본을 `touch`하면 통과한다(2026-09-30 재현).
- 영향: 로컬에서 빌드 후 계약 검사가 거짓 실패한다. 리눅스 러너에서의 동작은 확인하지 못했다.
- 지금 해결하지 못하는 이유: `encoding-freshness.mjs`의 비교 규칙이나 `build-godot.sh`의 압축 단계를 바꾸는 코드 변경이 필요하다.
- 가능한 접근: 비교를 초 단위로 내림하거나, 압축 직후 압축본의 수정 시각을 현재로 갱신한다.

## LobbyRoom 이어받기 방장 테스트가 간헐적으로 실패한다
- 현상: 전체 `npx vitest run`에서 `tests/rooms/lobby-room.test.ts` "이어받은 방장이 시작·게임변경·강퇴를 쓴다"가 강퇴 직후 좌석 목록에 강퇴된 세션이 남아 실패했고, 단독 재실행에서는 통과했다(2026-09-30).
- 영향: 전체 스위트가 무작위로 빨갛게 되어 실제 회귀와 구분하기 어렵다.
- 지금 해결하지 못하는 이유: 테스트 코드 수정이 필요하고, 원인이 테스트 대기 방식인지 서버의 퇴장 처리 순서인지 확인해야 한다.
- 가능한 접근: 강퇴 뒤 패치 한 번이 아니라 좌석 목록 조건을 만족할 때까지 기다리도록 바꾼다.

## 선언되지 않은 의존성과 쓰이지 않는 경로
- 현상: `lib/hub/dau-redis.ts`는 `ioredis`를 import 하지만 `apps/dagul-prod/web/package.json`에는 없고 Colyseus Redis 패키지의 하위 의존성으로만 설치된다. `next.config.ts`는 `/api/rooms`를 `GAME_SERVER_URL`(기본 127.0.0.1:9122)로 넘기는데, 그 포트를 여는 프로세스가 저장소에 없다. `tools/monitoring`은 저장소 안에서 쓰는 곳이 없다.
- 영향: Colyseus Redis 패키지가 `ioredis`를 빼면 서버 빌드가 깨진다. `/api/rooms` 요청은 항상 실패한다.
- 지금 해결하지 못하는 이유: `package.json`·잠금 파일과 Next 설정을 바꾸는 코드 변경이다.
- 가능한 접근: `ioredis`를 직접 의존성으로 선언하고, `/api/rooms` rewrite와 쓰이지 않는 도구를 정리한다.

## `main` 브랜치에 보호 규칙이 없다
- 현상: GitHub `main` 브랜치 보호가 설정되어 있지 않다(2026-09-30 확인). 5e2d383이 머지된 직후 `main`의 `web-lint`와 `Apps` 실행이 실패했지만 이를 막는 장치가 없었다.
- 영향: 게이트가 빨간 변경이 그대로 `main`에 들어가고, 배포 경로가 복구되면 곧바로 배포를 시도한다.
- 지금 해결하지 못하는 이유: 저장소 설정 변경이고 팀 작업 방식에 관한 소유자 결정이 필요하다.
- 가능한 접근: `web-lint`, `gd-lint`, `Status`를 필수 검사로 지정한다.
