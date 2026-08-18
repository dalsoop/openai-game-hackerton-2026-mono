# openai-game-hackerton-2026-mono

> **OpenAI 게임 해커톤** 제출용 파티게임 모노레포.  
> 형제 레포: [`ax-hackerton-2026-mono`](https://github.com/dalsoop/ax-hackerton-2026-mono) (AX 해커톤).

제출 엔트리는 Godot **다굴(gang-up)** 이다. 런처로 바로 실행한다.

## 제품 한 줄

> 6인 개인전 다굴 배틀로얄. 인간 1 + CPU, 자기장·맵이 있는 파티 전제.

## 레포 구조 (`ax-hackerton-2026-mono` 스타일)

```text
openai-game-hackerton-2026-mono/
├── AGENTS.md                 # 에이전트·사람 공통 규칙
├── README.md
├── apps/
│   ├── app-yjh-all-games-starter/  # apps/game-* 런처 (Rust+egui)
│   └── game-pjh-gang-up/     # 박진혁 Godot 다굴 배틀로얄
├── docs/
│   ├── DESIGN.md             # 제품·조작·튜닝 설계
│   └── FEEL-TUNING.md        # 조작감 조율 플레이북
└── tools/                    # 공용 스크립트
```

## 빠른 시작

```bash
# 런처 (남은 game-* 자동 스캔)
cd apps/app-yjh-all-games-starter && cargo run

# 다굴 직접 실행 (Godot 4.7.1)
godot --path apps/game-pjh-gang-up/project
```

조작·모드는 `apps/game-pjh-gang-up/README.md` 참조.

## 협업

- 브랜치: `feat/<이름>-<주제>` → PR → `main`
- 커밋: 한국어·영어 혼용 가능, **why** 한 줄
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
