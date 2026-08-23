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
| `apps/server-yjh-dev1/` | 정한 개발환경 1. 지금 다굴 |
| `apps/server-pjh-dev1/` | 크리엘 개발환경 1. 지금 다굴 |
| `apps/server-pig-dev1/` | Figix 개발환경 1. 지금 다굴 |
| `apps/server-board/` | 배포 보드. `https://server-board.external.kr/` |
| `apps/server-*-dev2/` · `*-dev3/` | 그 사람의 개발환경 2·3 |
| `apps/server-prod/` | 제출·운영 |
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

`dev2`/`dev3`/`prod`도 `web.enabled`가 켜져 있다. 각자 `dev1`과 같은 `project/`를 쓴다. `prod`는 `yjh-dev1`과 같다.

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
cd deploy/usability && node cli.mjs smoke
```

브라우저에서 바로 키 입력·튜닝 확인.

## 브랜치 규칙

작업 브랜치는 **`jeongright-{이름}`** 으로 만든다 (예: `jeongright-godot-web-games`).
`{이름}`은 kebab-case 로 작업 내용이 드러나게 짓는다. main 직접 커밋 금지, PR 로 머지.

## 배포

`apps/`를 푸시하면 `Apps ship`이 Godot 웹 익스포트·허브 이미지·Helm을 올린다. wasm/pck는 git에 넣지 않는다. 보드는 `https://server-board.external.kr/`.

PR용으로만 브랜치를 가른다. URL을 받으려고 브랜치를 추가하지 않는다.
