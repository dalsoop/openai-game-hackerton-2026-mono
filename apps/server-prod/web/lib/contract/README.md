# 백엔드 계약

허브 메시지 정본은 [`wire.ts`](./wire.ts)이다. Godot 거울은 `project/core/contract/web_contract.gd`이다.

동접 상한은 허브 WebSocket 개수이다. 방은 최대 8명이고, 시뮬은 호스트 Godot가 둔다.

동접 숫자의 정본은 [`HUB_CONFIG`](../hub/config.ts)이다. 차트 `hub.scale.maxReplicas`는 `ceil(targetCcu / perProcessCcu)`와 같고, 평소 복제는 1대이며 HPA가 그 상한까지만 올린다. 차트에 목표 동접을 다시 적지 않는다.

자리 예약은 Redis Presence와 Driver가 한다. 스냅 본문은 Redis에 넣지 않는다. WASM과 pck는 `hub-static`이 맡고, 게임 프로세스는 소켓만 맡는다. `/hubp` 핀은 이 계약 밖이다.
