# handoff.md — Next.js 게임 플랫폼

## 문서 역할

| 문서 | 역할 | 충돌 시 |
|---|---|---|
| spec.md | 동작 정의 (정본) | spec이 이긴다 |
| plan.md | 작업 순서 + 파일 대상 (잠정) | 자유롭게 수정 가능 |
| handoff.md | 실행 맥락 + 제약 | 프로젝트 전체 제약 |

## 파일 위치

- `.dryforge/spec.md`, `.dryforge/plan.md`, `.dryforge/handoff.md`

## 실행 형태

8개 태스크, 4개 wave. T1(골격) → T2+T3+T4+T5(병렬: 허브+UI+프리로더+세션) → T6+T8(컷오프+플러그인) → T7(배포).

## 제약

- Godot 시뮬레이션 코드를 수정하지 않는다 (game_world.gd 모듈 구조 유지).
- 기존 WebSocket 프로토콜을 유지한다 (기존 Godot 클라이언트 호환).
- K3s + Caddy + Docker 배포 환경을 유지한다.
- pjh-dev1은 criel이 별도 관리한다 — 동기화하지 않는다.

## 설계 결정

- **Next.js App Router를 선택한 이유:** SSR + API Routes + React를 하나의 프레임워크에서 처리. Vercel이 아닌 자체 서버 배포이므로 Custom Server로 WebSocket도 통합.
- **통합 SPA를 선택한 이유:** 3개 게임의 로비/방/매칭 로직이 동일하므로 공통화. 게임별 차이는 config.ts로 분리.
- **WASM 백그라운드 프리로드:** 로비에서 방을 잡는 동안 Godot WASM을 다운로드+컴파일. 게임 시작 시 즉시 렌더링. 사용자가 66MB를 기다리지 않도록.
- **세션(쿠키)을 선택한 이유:** OAuth는 해커톤에 과하고, 닉네임만으로도 플레이에 충분. 세션으로 전적만 유지.
- **Custom Server를 선택한 이유:** Next.js App Router는 WebSocket을 네이티브 지원하지 않으므로, `ws` 라이브러리로 HTTP Upgrade를 처리하는 Custom Server가 필요.

---

## Project Foundation (첫 사이클 프로젝트 맥락)

> 이 섹션은 실행 대상이 아니라 프로젝트 전체 맥락이다.

### 1. 프로젝트 정체성

다굴(Gang-Up) 게임 플랫폼. OpenAI 게임 해커톤 파티 엔트리에서 출발해, 3종 멀티플레이어 웹 게임을 호스팅하는 플랫폼으로 확장. Godot 4 + GDScript로 게임을 만들고, Next.js + TypeScript로 웹 플랫폼을 제공한다. 3명 개발자(정한/크리엘/Figix).

### 2. 도메인 모델

**게임:** 3종 — 다굴(8인 배틀로얄), Snake Arena(50인 뱀), Hex Clash(6인 영토). 각 게임은 독립된 Godot 프로젝트이지만 같은 플랫폼에서 서빙된다.

**방:** 게임별 독립된 방 풀. 방 생성→참가→대기→시작→플레이→결과→로비 복귀 생명주기. 호스트/게스트 구분. 최대 인원은 게임별로 다름.

**세션:** 닉네임 + 전적. 쿠키 기반, 인메모리. 24시간 만료.

**WASM:** 게임별 독립된 WASM+PCK 번들. 백그라운드 프리로드. 캐시 활용.

### 3. 기술 결정

- **프레임워크:** Next.js 15 App Router + React 19 + TypeScript
- **WebSocket:** `ws` 라이브러리, Custom Server에서 HTTP Upgrade
- **게임 엔진:** Godot 4.7, GDScript, 웹 내보내기(GL Compatibility)
- **통신:** React→Godot는 localStorage + CustomEvent, Godot→React는 JavaScriptBridge.eval()
- **빌드:** Vite (Next.js 내장) + Godot CI 웹 내보내기
- **배포:** Docker + K3s + Caddy (기존 인프라)

### 4. 향후 범위

- OAuth 인증 (구글/디스코드)
- 리더보드 DB (PostgreSQL 또는 SQLite)
- 관전 모드 React UI
- 모바일 반응형 UI
- 게임 내 상점/커스터마이즈
- Godot 헤드리스 서버 배포 (서버 권위 모델 실가동)
