// 핸드오프 퇴장 — React 소켓을 비동의로 한 번만 넘긴다 (onDrop + 유예).
// useRoom 언마운트의 두 번째 leave 는 무시한다.
import { ROOM_LEAVE } from "@/lib/contract";

export interface LeaveOnceRoom {
  reconnection: { enabled: boolean };
  leave: (consent: boolean) => void;
}

/** 자동 재접속을 끄고 비동의 퇴장 한 번. 이후 leave 는 소켓을 다시 건드리지 않는다. */
export function leaveOnceForHandoff(room: LeaveOnceRoom): void {
  room.reconnection.enabled = false;
  const leave = room.leave.bind(room);
  room.leave = (): void => { /* useRoom 정리의 두 번째 호출 */ };
  leave(ROOM_LEAVE.HANDOFF);
}
