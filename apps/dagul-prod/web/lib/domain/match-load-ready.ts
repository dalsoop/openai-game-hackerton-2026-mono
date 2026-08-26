/** 접속 중인 좌석만 로딩 완료해야 카운트다운을 푼다. 접속자가 없으면(CPU만) 바로 푼다. */
// 대기실 packPct(WASM)와 별개 — 인게임 모듈 로드가 끝난 좌석만 matchReady.
export function allConnectedMatchReady(
  players: readonly { connected: boolean; matchReady: boolean }[],
): boolean {
  const live = players.filter((p) => p.connected);
  if (live.length === 0) {return true;}
  return live.every((p) => p.matchReady);
}

/** true 면 3초 카운트다운을 깎지 않는다. 타임아웃이 지나면 강제 해제. */
export function shouldHoldCountdown(
  players: readonly { connected: boolean; matchReady: boolean }[],
  waitedMs: number,
  timeoutMs: number,
): boolean {
  if (waitedMs >= timeoutMs) {return false;}
  return !allConnectedMatchReady(players);
}
