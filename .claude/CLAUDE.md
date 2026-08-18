# CLAUDE.md — 제출 앱 도메인

루트 `AGENTS.md` 규칙이 우선. `apps/game-*`만 줄이고, 런처·웹앱은 유지한다.

## 앱

| 앱 | 장르 | 실행 |
|---|---|---|
| `app-yjh-all-games-starter` | `apps/game-*` 런처 | `cd apps/app-yjh-all-games-starter && cargo run` |
| `game-pjh-gang-up` | 6인 개인전 다굴 배틀로얄 (Godot) | `godot --path apps/game-pjh-gang-up/project` |
| `web-game` | 로컬 협동 관성 레이싱 (Vite + TS) | `cd apps/web-game && npm run dev` |

## 이름 규칙

- 앱 디렉터리: `apps/game-{작성자이니셜}-{게임명}` 또는 `apps/web-game` / `apps/app-*`
- 작업 브랜치: `jeongright-{이름}`

## 주의

- 지우는 대상은 `apps/game-*` 뿐이다. `app-*`, `web-game`은 건드리지 말 것.
- `game-pjh-gang-up`은 `project/` 하위가 Godot 루트다.
