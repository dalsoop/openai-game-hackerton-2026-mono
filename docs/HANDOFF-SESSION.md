# 세션 핸드오프 — Next.js 게임 플랫폼

## 현재 브랜치
`dryforge/nextjs-platform` (main에서 분기)

## 완료된 태스크
- T1: Next.js 골격 (app router + custom server) ✅
- T2: WebSocket 허브 이전 (lib/hub/) ✅
- T3: React 로비/방/대기실 UI ✅
- T4: Godot WASM 프리로더 + 캔버스 ✅
- T5: 세션 관리 ✅
- T6: Godot 컷오프 (custom_shell 최소화) ✅
- T7: Dockerfile ✅
- T8: 게임 플러그인 구조 (games/*/config.ts) ✅
- AssetStatus 컴포넌트 (다운로드 확인) ✅

## 미해소 — 다음 세션에서 할 것

### 1. 하드코딩 제거 (가장 급함)
- `app/dagul/page.tsx`에 `game="dagul"` 등이 하드코딩
- **해결**: `app/[game]/page.tsx` 동적 라우트로 전환
- `games/*/config.ts`의 `getGame(params.game)`으로 설정 로드
- 3개 게임 페이지(dagul, snake, hex)를 1개 동적 페이지로 통합

### 2. Snake/Hex 페이지 미적용
- dagul만 AssetStatus + GodotCanvas 연동됨
- 동적 라우트로 전환하면 자동 해결

### 3. next build 확인
- 현재 빌드 성공 상태
- 동적 라우트 전환 후 재확인 필요

### 4. main 머지
- 전체 완료 후 main에 --no-ff 머지

### 5. 배포
- web/Dockerfile 빌드 테스트
- Helm 차트에 Next.js 서비스 추가
- 기존 server-* 슬롯과 공존/전환 계획

## 핵심 파일 지도
```
web/
  app/dagul/page.tsx     ← 하드코딩 문제. [game]/page.tsx로 전환
  app/snake/page.tsx     ← 스텁. 동적 라우트로 대체
  app/hex/page.tsx       ← 스텁. 동적 라우트로 대체
  components/AssetStatus.tsx  ← 에셋 다운로드 상태 표시
  components/GodotCanvas.tsx  ← Godot WASM 캔버스 래퍼
  hooks/useGodotLoader.ts     ← WASM 백그라운드 프리로드
  hooks/useHub.ts             ← WebSocket 허브 연결
  lib/hub/                    ← 방 관리/릴레이 (기존 src/ 이전)
  lib/game-registry.ts        ← 게임 목록 수집
  games/dagul/config.ts       ← 게임별 설정
  server.ts                   ← Custom Server + WS
```

## 규칙 (AGENTS.md에 박혀있음)
- 파일 700줄 이하 (lint_gd.py 게이트)
- SSOT: yjh-dev1이 정본
- 하드코딩 금지 — config 기반으로
