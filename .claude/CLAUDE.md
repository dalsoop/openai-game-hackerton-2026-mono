# CLAUDE.md — 제출 앱 도메인

루트 `AGENTS.md`가 우선. 배포는 `.claude/skills/hackertone-games-deploy/SKILL.md`.

## 앱

| 앱 | 역할 | 실행 |
|---|---|---|
| `server-yjh-dev1` | 정한 본 슬롯. 클라 + 클러스터 허브 | `godot --path apps/server-yjh-dev1/project` · `npm start` |
| `server-pjh-dev1` | 크리엘 본 슬롯 | `godot --path apps/server-pjh-dev1/project` |
| `server-fig-dev1` | Figix 본 슬롯 | `godot --path apps/server-fig-dev1/project` |
| `server-board` | 배포 보드 | `https://server-board.external.kr/` |
| `*-dev2` · `*-dev3` | 그 사람의 개발환경 2·3 | `https://<폴더>.external.kr/` |
| `server-prod` | 제출·운영 | `https://server-prod.external.kr/` |
| `game-pjh-gang-up` | 크리엘 원본. 수정 금지 | 읽기만 |

`apps/server-*` → `https://<폴더>.external.kr/`  
확인: `python3 deploy/scripts/status.py` · 보드 `https://server-board.external.kr/`

방 서버는 `server-*`마다 따로다. 보드만 빼면 자기 호스트 `/gang-up`을 갖는다. 배포는 `apply-apps.py ship` 다음 `helm`이다.

## GDScript 코드 규칙

`AGENTS.md`의 "GDScript 코드 규칙" + "온라인 단일 구성 · 정본 지도" 절을 따른다. 핵심:
- 파일 700줄 이하, 함수 40줄 이하, 중첩 3단 이하
- 매직 컬러 금지, SSOT(정본 1곳), 모듈 패턴
- 온라인 전용: 로비=React(`web/`), 허브=`web/lib/hub/`, Godot WS=`autoload/network_manager.gd`만. GD에 로비 동사·폐기 UI 부활 금지 (lint가 잡음)
- 검증: `python3 lint_gd.py apps/server-yjh-dev1/project/scripts`
- 정본: `apps/server-yjh-dev1/`
