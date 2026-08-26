/** 자리에 남은 좌석이 전부 ready 여야 카운트다운을 푼다. 빈 명단(CPU만)은 바로 푼다.
 * 끊김(connected=false)만으로는 빼지 않는다 — 유예 중 드롭이 시작 신호가 되면 안 된다. */
export function allSeatsMatchReady(
  players: readonly { matchReady: boolean; connected?: boolean; name?: string }[],
): boolean {
  if (players.length === 0) {return true;}
  return players.every((p) => p.matchReady);
}

/** true 면 3초 카운트다운을 깎지 않는다. 타임아웃이 지나면 강제 해제. */
export function shouldHoldCountdown(
  players: readonly { matchReady: boolean; connected?: boolean; name?: string }[],
  waitedMs: number,
  timeoutMs: number,
): boolean {
  if (waitedMs >= timeoutMs) {return false;}
  return !allSeatsMatchReady(players);
}

export function pendingLoadNames(
  seats: readonly { slot?: number; name: string; matchReady: boolean }[],
  you = -1,
): string[] {
  return seats
    .filter((s) => !s.matchReady && (you < 0 || s.slot !== you))
    .map((s) => s.name);
}

/** 장벽이 열린 뒤에는 목록을 비운다. */
export function matchWaitNames(
  seats: readonly { slot?: number; name: string; matchReady: boolean }[],
  you: number,
  loadHeld: boolean,
): string[] {
  if (!loadHeld) {return [];}
  return pendingLoadNames(seats, you);
}

/** useRoomState 가 중첩 Schema 변이를 놓치지 않게 하는 지문. */
export function lobbyReadySig(
  players: readonly { slot?: number; matchReady?: boolean }[],
  loadHeld = false,
): string {
  const ready = players.map((p) => `${p.slot ?? -1}:${p.matchReady ? 1 : 0}`).join(",");
  return `${loadHeld ? 1 : 0}|${ready}`;
}
