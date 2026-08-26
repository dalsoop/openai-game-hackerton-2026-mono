# openai-game-hackerton-2026-mono

> **OpenAI 게임 해커톤** 제출용 파티게임 모노레포.  
> 형제 레포: [`ax-hackerton-2026-mono`](https://github.com/dalsoop/ax-hackerton-2026-mono) (AX 해커톤).

제출 엔트리는 Godot **다굴(gang-up) 하나**다. 모드 5종은 그 로비 안에 있다.

## 제품 한 줄

> 개인전 다굴 배틀로얄. 로비에서 방을 만들면 허브가 시뮬하고, 아니면 인간 1 + CPU.

원본은 `game-pjh-gang-up`에 두고, 배포·작업은 `apps/server-*`에서 한다. 협업은 `apps/README.md`, 에이전트는 `AGENTS.md`.

## 레포 구조

```text
├── AGENTS.md
├── apps/game-pjh-gang-up/     # 원본. 수정하지 않음
├── apps/server-yjh-dev1/      # 정한 개발환경 1
├── apps/server-pjh-dev1/      # 크리엘 개발환경 1
├── apps/server-pig-dev1/      # Figix 개발환경 1
├── apps/server-*-dev2|3/      # 그 사람의 개발환경 2·3
├── apps/dagul-prod/           # 제출·운영
├── apps/server-board/         # 배포 보드
├── deploy/                   # chart(Helm) · env.yaml · 웹 이미지
├── docs/
└── tools/
```

## 빠른 시작

```bash
godot --path apps/server-yjh-dev1/project

cd apps/server-yjh-dev1 && npm install && npm start
# 같은 Godot에서 로비 → 방만들기. 웹은 같은 호스트 /gang-up/ws
```

웹: `https://server-yjh-dev1.external.kr/`  
보드: `https://server-board.external.kr/`

## 협업

- 배포용으로 브랜치를 새로 파지 않는다. URL은 `apps/` 폴더명
- 올렸는지는 `python3 deploy/scripts/status.py`
- 작업: 자기 `apps/server-<이름>-dev1|2|3/` 또는 `dagul-prod`. 웹은 전부 켜져 있다.
- 크리엘 원본: `apps/game-pjh-gang-up/` (수정하지 않음)
- 비밀키·개인 토큰은 커밋 금지

## 팀

| 이름 | GitHub | 연락 | 역할 가정 |
|---|---|---|---|
| 윤정한 | [@dalsoop](https://github.com/dalsoop) | (owner) | 레포·인프라 |
| 이현진 (Figix) | [@Figix](https://github.com/Figix) | 1202hyunjin@naver.com | 조작감·감성 |
| 박진혁 (크리엘) | [@criel2019](https://github.com/criel2019) | pjhk579700@gmail.com | 구현·핫로드 워크플로 |

레포: https://github.com/dalsoop/openai-game-hackerton-2026-mono

## 라이선스

해커톤 팀 제출용. 외부 배포 정책은 제출 후 결정.
