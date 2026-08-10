# CLAUDE.md — 윤정한(yjh) Godot 웹 게임 도메인

루트 `AGENTS.md` 규칙이 우선. 이 문서는 `apps/game-yjh-*` 도메인 정보만 담는다.

## 이름 규칙

- 앱 디렉터리: `apps/game-{작성자이니셜}-{게임명}` (예: `game-yjh-slither`, `game-pjh-hiking`)
- 윤정한 = `yjh`. 새 게임을 추가하면 반드시 이 규칙을 따른다.
- 작업 브랜치: `jeongright-{이름}`.

## game-yjh-* 게임 카탈로그 (Godot 4 GDScript, 웹 export)

| 앱 | 장르 | 모드 | 포트 | 조작 |
|---|---|---|---|---|
| `game-yjh-dodge` | 낙하물 피하기 | 싱글 (파이프라인 검증용) | — | ←→/AD, Enter 재시작 |
| `game-yjh-slither` | slither.io 지렁이 | 싱글 + AI 9 | — | 마우스, 클릭/스페이스 부스트 |
| `game-yjh-agar-multi` | agar.io | 멀티 (서버 권위) | ws :9101 | 마우스 |
| `game-yjh-paper-multi` | paper.io 영토전 | 멀티 (서버 권위) | ws :9102 | 방향키/WASD |
| `game-yjh-slither-multi` | 지렁이 멀티 | 멀티 + AI 5 상주 | ws :9103 | 마우스, 부스트 |

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

- 레포 제품 불변(AGENTS.md): 파티게임 지향 — 싱글 게임(`dodge`, `slither`)은
  파이프라인 검증·프로토타입 용도이며 최종 엔트리는 멀티 게임.
- `game-pjh-*` (다른 작성자) 디렉터리는 수정하지 않는다.
