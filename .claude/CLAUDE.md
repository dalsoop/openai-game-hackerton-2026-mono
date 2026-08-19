# CLAUDE.md — 제출 앱 도메인

루트 `AGENTS.md`가 우선. 배포는 `.claude/skills/hackertone-games-deploy/SKILL.md`.

## 앱

| 앱 | 역할 | 실행 |
|---|---|---|
| `server-yjh-dev1` | 정한 본 슬롯. 클라 + 클러스터 허브 | `godot --path apps/server-yjh-dev1/project` · `npm start` |
| `server-pjh-dev1` | 크리엘 본 슬롯 | `godot --path apps/server-pjh-dev1/project` |
| `server-pig-dev1` | Figix 본 슬롯 | `godot --path apps/server-pig-dev1/project` |
| `server-board` | 배포 보드 | `https://server-board.external.kr/` |
| `*-dev2` · `*-dev3` | 그 사람의 개발환경 2·3 | `project/`를 채운 뒤 `web.enabled` |
| `server-prod` | 제출·운영 | `project/`를 채운 뒤 `web.enabled` |
| `game-pjh-gang-up` | 크리엘 원본. 수정 금지 | 읽기만 |

`apps/server-*` → `https://<폴더>.external.kr/`  
확인: `python3 deploy/scripts/status.py` · 보드 `https://server-board.external.kr/`

방 서버는 `server-*`마다 따로다. 보드만 빼면 자기 호스트 `/gang-up`을 갖는다. `apps/` 푸시 후 Actions `Apps ship`이 허브와 Godot 웹을 올린다.
