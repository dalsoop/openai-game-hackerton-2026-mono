// 핸드오프 퇴장 — React 소켓을 한 번만, 동의 없이 닫는다.
// useRoom 언마운트가 leave() 를 한 번 더 호출하면 이미 닫힌 소켓에
// send 가 나가 "WebSocket is already in CLOSING or CLOSED state" 가 콘솔을 채운다.

export interface LeaveOnceRoom {
  reconnection: { enabled: boolean };
  leave: (consent: boolean) => void;
}

/** 자동 재접속을 끄고 consent=false 로 떠난 뒤, 이후 leave 는 무시한다. */
export function leaveOnceForHandoff(room: LeaveOnceRoom): void {
  room.reconnection.enabled = false;
  const leave = room.leave.bind(room);
  room.leave = (): void => { /* useRoom 정리의 두 번째 호출 */ };
  leave(false);
}
