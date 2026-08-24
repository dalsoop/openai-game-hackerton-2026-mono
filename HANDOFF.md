
---

## 추가 발견 (2026-08-24 후반 세션)

### Godot WebSocket 연결 실패
- Godot `hub_client.gd:73-78`이 `wss://<host>/gang-up/ws`로 연결하지만, 서버+Caddy+Cloudflare 경로에서 `/gang-up/ws`가 404 반환
- 웹 허브는 `wss://<host>/gang-up`(ws 없이)으로 잘 동작
- 원인: Caddy가 `/gang-up*` 패턴으로 프록시하지만 `/gang-up/ws`는 별도 매칭 필요, 또는 Cloudflare HTTP/2가 WS 업그레이드 차단
- 수정: hub_client.gd의 URL에서 `/ws` 제거 → `/gang-up`으로 변경 → web export 재빌드

### 닉네임 전달 미동작
- goToGame()에서 `gangup_name`을 localStorage에 저장하지만, Godot이 "플레이어82"로 표시 → consume_hub_launch 후 닉네임이 적용되기 전에 hello가 먼저 나갔을 가능성
- hub_client.gd의 player_name 설정 타이밍 확인 필요

### 스켈레톤 로딩 동작 확인
- /gang-up/ 로비 즉시 로드 ✔
- 프리페치 진행률 바 ✔ ("게임 다운로드 88%" → "게임 준비 완료")
- "게임으로 이동" 클릭 → / 이동 ✔
- Godot 로딩 + 캐시 히트 빠른 로드 ✔
- 서버 연결 실패 ✖ (WS URL 문제)
