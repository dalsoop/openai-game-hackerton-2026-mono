# 테스트 구성 — 4층

| 층 | 도구 | 위치/스크립트 | 전제 | 어디서 도나 |
|---|---|---|---|---|
| **단위** | vitest | `tests/*.test.ts` (`npm test`) | 없음 (fetch·localStorage는 주입/스텁) | 로컬 `npm run verify` + CI `web-lint` + ship `lint-web.py` |
| **계약** | node | `scripts/check-contract.mjs` | 없음 (Godot 산출물 있으면 해시 검사) | `npm run verify` + CI `web-lint` |
| **통합(스모크)** | node + @colyseus/sdk | `npm run smoke` · `smoke:handoff` · `smoke:resume` | **서버 기동** (`npm start`) | 로컬 + helm 후 라이브 프로브 |
| **E2E** | playwright-core 헤드리스 | `npm run e2e` | 서버 + 로컬 Chrome 경로 | 로컬 (CI는 비용상 제외) |

GD(Godot) 쪽: `npm run test:gd` → 루트 `scripts/gd_test.py` (헤드리스 러너 `project/tests/`), CI `gd-lint`.

대기실 시작 카운트다운만: `npm run test:lobby-start`.

## 단위 테스트 작성 규칙

- 순수 로직은 `lib/` 모듈로 뽑고 훅은 그것을 소비 — 훅 자체는 단위 테스트 대상이 아니다 (jsdom 미도입).
- 외부 의존(localStorage, fetch)은 좁은 인터페이스로 주입하거나 `vi.stubGlobal` — 실제 저장소를 건드리지 않는다.
- 조합형 로직(전이표·멤버십)은 전수 케이스(`it.each`)로 — 누락 분기를 못 숨긴다.

## 무엇을 각 층에 넣나

- 상태 전이·판정·정규화·URL 체계 → **단위**
- TS↔GD 상수·산출물 해시 정합·카탈로그 pack 집합 → **계약**
- 허브 실왕복(방 생성·입장·시작·스냅 릴레이·재접속) → **통합**
- 브라우저 풀플로우(UI 클릭 → Godot 부팅 → Sample 총성) → **E2E** (`scripts/e2e/audio-probe.mjs`)
