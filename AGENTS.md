# AGENTS.md — openai-game-hackerton-2026-mono

에이전트·사람 공통. OpenAI 게임 해커톤 파티 엔트리 (형제: `ax-hackerton-2026-mono`).

더 자세한 배포는 `.claude/skills/hackertone-games-deploy/SKILL.md` 와 `apps/README.md`.

## 제품 불변

1. 싱글 플레이 없음. 인간+CPU 개인전.
2. 조작감이 제품. 기본값은 빡셈.
3. `apps/game-pjh-gang-up`는 크리엘 원본. 수정하지 않는다.
4. 작업·배포는 `apps/server-*` 만. 폴더 이름 = `https://<폴더>.external.kr/`
5. 튜닝 패널은 개발 빌드만.

## 어디에 무엇을

| 둘 곳 | 내용 |
|---|---|
| `apps/server-yjh-dev1/` | 정한 본 슬롯. Godot + 클러스터 허브 |
| `apps/server-pjh-dev1/` | 크리엘 본 슬롯. Godot + 로컬 허브 코드 |
| `apps/server-pig-dev1/` | Figix 본 슬롯. Godot + 로컬 허브 코드 |
| `apps/server-board/` | 배포 보드. `https://server-board.external.kr/` |
| `apps/server-*-dev2/` · `*-dev3/` · `server-prod/` | 빈 슬롯. 트리를 복사하지 않음 |
| `apps/game-pjh-gang-up/` | 원본. 읽기만 |
| `docs/` | 제품 설계 (`DESIGN.md`, `FEEL-TUNING.md`) |
| `deploy/` | Helm·`apply-apps.py`. 클러스터 YAML은 `apps/`에 두지 않는다 |

`server-*` 안:

```text
hackertone.yaml   # web.enabled, exportDir
README.md
project/          # godot --path 여기. 웹보내기는 project/web
src/              # 방 서버가 이 폴더에 있을 때만
```

방 서버는 `server-*` 폴더마다 따로다. 보드만 허브가 없다. 이미지는 그 폴더 Dockerfile이다.

빈 슬롯은 `web.enabled: false`다. `project/web`을 넣은 뒤에만 켠다. `dev2`/`dev3`에 본게임을 통째로 복사하지 않는다.

## 모노레포 규칙

- 배포·호스트 작업 전 스킬 `hackertone-games-deploy` 를 읽는다.
- 남의 `apps/game-*` 를 재구성하지 않는다.
- secret·개인 토큰 커밋 금지.
- 레포 밖 모노 수정 금지.

## 에이전트 행동

- 새 기능 전 `docs/DESIGN.md` 와 맞는지 본다.
- 조작감 숫자를 바꾸면 `docs/FEEL-TUNING.md`에 한 줄.
- Godot이 로드되지 않으면 머지하지 않는다.
- `yjh`/`pjh`/`pig` `dev1`의 게임플레이를 같이 맞출 때는 `project/`만 복사한다. 웹보내기는 CI가 만든다.

## 로컬

```bash
godot --path apps/server-yjh-dev1/project
cd apps/server-yjh-dev1 && npm start
```

## 배포

`apps/`의 허브 코드를 푸시하면 `Apps ship`이 이미지와 Helm을 올린다. Godot 웹은 git에 넣지 않고 `python3 deploy/scripts/apply-apps.py web <폴더>`로 올린다. Helm은 Apps ship만 돌린다. 보드는 `https://server-board.external.kr/`.

PR용으로만 브랜치를 가른다. URL을 받으려고 브랜치를 추가하지 않는다.
