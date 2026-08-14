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
| `game-yjh-croc-teeth` | 악어 이빨 룰렛 3D (지뢰 이빨 물리면 패배) | 멀티 (턴제, 2인+) | ws :9105 | 마우스 클릭 |
| `game-yjh-balloon-pump` | 풍선 펌프 룰렛 (펌프 +1점, 터지면 -5점) | 멀티 (턴제 푸시-유어-럭, 2인+) | ws :9106 | 클릭/스페이스, 엔터=패스 |
| `game-yjh-bomb-pass` | 폭탄 돌리기 (비밀 심지, 스파크 힌트) | 멀티 (실시간 핫포테이토, 2인+) | ws :9107 | 다른 플레이어 클릭 |
| `game-yjh-mine-run` | 지뢰밭 달리기 (밟힌 지뢰 전원 공개) | 멀티 (격자 레이스, 2인+) | ws :9108 | 다음 줄 칸 클릭 |
| `game-yjh-260812-mafia` | 마피아 (밤: 마피아·경찰·의사 행동 → 낮: 토론 → 투표 처형) | 멀티 (라운드제, 4~10인) | ws :9109 | 마우스 클릭 |
| `game-yjh-260812-liar` | 라이어 게임 (제시어 모르는 라이어 찾기, 발언→투표→추측) | 멀티 (라운드제, 3~8인) | ws :9110 | 마우스 클릭 |

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

- 레포 제품 불변(AGENTS.md): 파티게임 지향 — yjh 게임 10종은 전부 멀티(서버 권위). 새 멀티 게임 포트는 :9111 부터.
- 3D 게임(croc-teeth)은 루트 Node3D + 코드로 씬 구성 — 별도 에셋 파일 없음.
- `game-pjh-*` (다른 작성자) 디렉터리는 수정하지 않는다.
