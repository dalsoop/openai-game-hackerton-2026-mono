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
- T9: 동적 라우트 `app/[game]/page.tsx` 전환 ✅
- T10: GameSelect → game-registry SSOT 전환 ✅
- T11: COOP/COEP 헤더 (SharedArrayBuffer) ✅
- T12: 로컬 개발 환경 (dev.sh + Godot 에셋 심링크) ✅

## 로컬 개발 실행

```bash
# 방법 1: 스크립트
./dev.sh

# 방법 2: 직접
cd web && npx tsx server.ts
```

http://localhost:3000 에서 메인 → 게임 선택 → 로비 → 방 → 게임 시작 흐름을 테스트할 수 있다.
Godot 에셋은 `web/public/godot/dagul/` 심링크로 `apps/server-yjh-dev1/project/web/`를 참조한다.

## 미해소 — 다음 세션에서 할 것

### 1. main 머지
- 전체 완료 후 main에 --no-ff 머지

### 2. 배포
- web/Dockerfile 빌드 테스트
- Helm 차트에 Next.js 서비스 추가
- 기존 server-* 슬롯과 공존/전환 계획

### 3. snake/hex Godot export
- 현재 dagul만 Godot export 에셋이 있음
- snake/hex는 Godot 프로젝트 export 후 심링크 추가 필요

## 핵심 파일 지도
```
web/
  app/[game]/page.tsx         ← 동적 라우트 (모든 게임 통합)
  app/[game]/not-found.tsx    ← 잘못된 게임 ID 안내
  app/page.tsx                ← 메인 (게임 선택)
  components/AssetStatus.tsx  ← 에셋 다운로드 상태 표시
  components/GodotCanvas.tsx  ← Godot WASM 캔버스 래퍼
  components/GameSelect.tsx   ← 게임 카드 목록 (game-registry 사용)
  hooks/useGodotLoader.ts     ← WASM 백그라운드 프리로드
  hooks/useHub.ts             ← WebSocket 허브 연결
  lib/hub/                    ← 방 관리/릴레이 (기존 src/ 이전)
  lib/game-registry.ts        ← 게임 목록 SSOT
  games/dagul/config.ts       ← 게임별 설정
  server.ts                   ← Custom Server + WS
  next.config.ts              ← COOP/COEP 헤더 포함
  public/godot/dagul/         ← Godot export 심링크
dev.sh                        ← 로컬 개발 실행 스크립트
```

## 규칙 (AGENTS.md에 박혀있음)
- 파일 700줄 이하 (lint_gd.py 게이트)
- SSOT: yjh-dev1이 정본
- 하드코딩 금지 — config 기반으로
