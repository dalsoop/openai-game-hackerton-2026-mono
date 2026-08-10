# CLAUDE.md — 윤정한(yjh) Godot 웹 게임 도메인

루트 `AGENTS.md` 규칙이 우선. 이 문서는 `apps/game-yjh-*` 도메인 정보만 담는다.

## 이름 규칙

- 앱 디렉터리: `apps/game-{작성자이니셜}-{게임명}` (예: `game-yjh-slither`, `game-pjh-hiking`)
- 윤정한 = `yjh`. 새 게임을 추가하면 반드시 이 규칙을 따른다.
- 작업 브랜치: `jeongright-{이름}`.

## game-yjh-* 게임 카탈로그 (Godot 4 GDScript, 웹 export)

| 앱 | 장르 | 모드 | 포트 | 조작 |
|---|---|---|---|---|
| `game-yjh-agar-multi` | agar.io | 멀티 (서버 권위) | ws :9101 | 마우스 |
| `game-yjh-paper-multi` | paper.io 영토전 | 멀티 (서버 권위) | ws :9102 | 방향키/WASD |
| `game-yjh-slither` | 지렁이키우기 | 멀티 + AI 5 상주 | ws :9103 | 마우스, 클릭/스페이스 부스트 |
| `game-yjh-dodge` | 총알 생존 (누적 총알, 최장 생존 승) | 멀티 (라운드제) | ws :9104 | 방향키/WASD |

## 아키텍처 불변

- 각 앱은 단일 `main.gd` + `main.tscn` + `project.godot` + `export_presets.cfg` 구조.
- 멀티 게임은 **같은 스크립트가 dual-entry**: `--headless` 실행이면 WebSocket 서버,
  브라우저(웹 export)면 클라이언트. 서버 권위(server-authoritative) — 클라는 입력만 보낸다.
- 웹 빌드 산출물 `apps/game-yjh-*/web/` 은 gitignore — 커밋 금지.
- 포트는 게임마다 고유(9101~). 새 멀티 게임은 다음 포트를 이어 쓴다.

## 실행

```bash
cd apps/game-yjh-<게임>
godot --headless --path .                                # 멀티: 서버 기동
godot --path .                                           # 싱글: 로컬 실행
godot --headless --export-release "Web" web/index.html   # 웹 export → 정적 서빙
```

## 주의

- 레포 제품 불변(AGENTS.md): 파티게임 지향 — yjh 게임 4종은 전부 멀티(서버 권위).
- `game-pjh-*` (다른 작성자) 디렉터리는 수정하지 않는다.
