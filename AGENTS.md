# AGENTS.md — openai-game-hackerton-2026-mono

에이전트·사람 공통 작업 규칙.  
맥락: **OpenAI 게임 해커톤** 파티게임 엔트리 (형제: `ax-hackerton-2026-mono`).

## 제품 불변

1. **싱글 플레이 없음** — 친구(로컬 2인+) 없으면 레이스 시작 불가. 파티게임.
2. **조작감이 제품** — 관성을 쉽게 만들지 말 것. 튜닝 UI로 수치를 올리되 기본값은 "빡셈".
3. **웹 우선** — `apps/web-game` Vite 핫 리로드. 네이티브 앱은 후순위.
4. **튜닝 패널은 개발 전용** — `import.meta.env.DEV` 일 때만 햄버거 조율 UI.

## 모노레포 규칙

- 앱 코드는 `apps/<app>/` 아래만.
- 공용 도구·스크립트는 `tools/`.
- 설계·결정 문서는 `docs/` (긴 채팅 복붙 금지, 요약만).
- secret·비밀번호·개인 토큰 커밋 금지.

## 에이전트 행동

- 새 기능 전 `docs/DESIGN.md` 와 충돌하는지 확인.
- 조작감 파라미터를 바꾸면 `docs/FEEL-TUNING.md` 에 한 줄 기록.
- `npm run build` 가 깨지면 머지하지 말 것.
- 레포 밖(다른 mono) 수정 금지.

## 로컬 루프

```bash
cd apps/web-game && npm run dev
```

브라우저에서 바로 키 입력·튜닝 확인.

## 브랜치 규칙

작업 브랜치는 **`jeongright-{이름}`** 으로 만든다 (예: `jeongright-godot-web-games`).
`{이름}`은 kebab-case 로 작업 내용이 드러나게 짓는다. main 직접 커밋 금지, PR 로 머지.

## 배포

`apps/`를 푸시하면 `Apps ship`이 Godot 웹 익스포트·허브 이미지·Helm을 올린다. wasm/pck는 git에 넣지 않는다. 보드는 `https://server-board.external.kr/`.

PR용으로만 브랜치를 가른다. URL을 받으려고 브랜치를 추가하지 않는다.
