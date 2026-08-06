# openai-game-hackerton-2026-mono

> **OpenAI 게임 해커톤** 제출용 파티게임 모노레포.  
> 형제 레포: [`ax-hackerton-2026-mono`](https://github.com/dalsoop/ax-hackerton-2026-mono) (AX 해커톤).

로컬 협동 **관성 레이싱** 파티 미니게임.  
친구와 한 키보드로 달리는 초갈 감성 — **싱글 플레이 없음** (파티 전제).

## 제품 한 줄

> 관성이 빡센 조작감 + 로컬 협동만 되는 짧은 레이스. 혼자서는 못 함. OpenAI 게임 해커톤 엔트리.

## 레포 구조 (`ax-hackerton-2026-mono` 스타일)

```text
openai-game-hackerton-2026-mono/
├── AGENTS.md                 # 에이전트·사람 공통 규칙
├── README.md
├── apps/
│   └── web-game/             # Vite + TypeScript 캔버스 게임 (핫 리로드)
├── docs/
│   ├── DESIGN.md             # 제품·조작·튜닝 설계
│   └── FEEL-TUNING.md        # 조작감 조율 플레이북
└── tools/                    # 공용 스크립트
```

## 빠른 시작

```bash
cd apps/web-game
npm install
npm run dev
# → http://localhost:5173  핫 리로드
```

배포(GitHub Pages): https://dalsoop.github.io/openai-game-hackerton-2026-mono/

### 조작 (기본)

| 플레이어 | 키 | 역할 |
|---|---|---|
| P1 | `W` `A` `S` `D` | 가속·좌·후진·우 |
| P2 | `↑` `←` `↓` `→` | 동일 |

개발 중 **햄버거(☰)** 로 관성·마찰·조향 등 실시간 조율.  
최종 빌드(`npm run build`)에서는 튜닝 UI 제거.

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
