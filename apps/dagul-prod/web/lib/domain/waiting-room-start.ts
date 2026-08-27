/** 대기실에서 호스트가 시작을 누른 뒤 매치로 넘어가기까지. */
export const LOBBY_START_SEC = 5;
/** 남은 초가 이 값 이하면 나가기 UI 를 끈다. 5·4 는 나갈 수 있다. */
export const LOBBY_LEAVE_LOCK_SEC = 3;

export function lobbyLeaveLocked(startInSec: number): boolean {
  const n = Math.floor(Number(startInSec));
  return n > 0 && n <= LOBBY_LEAVE_LOCK_SEC;
}

/** 카운트다운 5·4초에서 호스트가 나가면 취소를 한다. 3초부터는 잠금. */
export function lobbyStartCancelOnHostLeave(startInSec: number): boolean {
  const n = Math.floor(Number(startInSec));
  return n > LOBBY_LEAVE_LOCK_SEC;
}
