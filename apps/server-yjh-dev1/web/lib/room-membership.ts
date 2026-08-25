// 방 멤버십 순수 모듈 — 로비 목록에서 "내 방"을 식별·정렬한다.
// 저장소는 좁은 인터페이스로 주입(localStorage 대체 가능 → 테스트 용이).
import type { HubRoom } from "@/types";

export type RoomMembership = "host" | "member" | "none";

/** 내 방 식별 — 방장 여부와 재입장 가능 여부. */
export interface MyRoomIdentity {
  roomId: string;
  host: boolean;
}

export interface RoomMembershipView {
  membership: RoomMembership;
  /** 내 방은 목록 상단으로 */
  pinned: boolean;
}

const MY_ROOM_KEY = "dagul_my_room";

type GetItem = (key: string) => string | null;
type SetItem = (key: string, value: string) => void;

export function readMyRoom(get: GetItem): MyRoomIdentity | null {
  try {
    const raw = get(MY_ROOM_KEY);
    if (!raw) {return null;}
    const parsed = JSON.parse(raw) as Partial<MyRoomIdentity>;
    if (typeof parsed.roomId !== "string" || parsed.roomId === "") {return null;}
    return { roomId: parsed.roomId, host: Boolean(parsed.host) };
  } catch {
    return null;
  }
}

export function saveMyRoom(set: SetItem, identity: MyRoomIdentity): void {
  try {
    set(MY_ROOM_KEY, JSON.stringify(identity));
  } catch { /* localStorage 불가 — 멤버십 없이 진행 */ }
}

export function clearMyRoom(remove: (key: string) => void): void {
  try {
    remove(MY_ROOM_KEY);
  } catch { /* 동일 */ }
}

/** 방 하나의 멤버십 판정 — 순수 함수. */
export function membershipOf(room: Pick<HubRoom, "id">, mine: MyRoomIdentity | null): RoomMembershipView {
  if (!mine || room.id !== mine.roomId) {return { membership: "none", pinned: false };}
  return { membership: mine.host ? "host" : "member", pinned: true };
}

/** 멤버십 우선 정렬 — 방장 > 참여 > 나머지(원래 순서 유지, 안정 정렬). */
export function sortRoomsByMembership(rooms: HubRoom[], mine: MyRoomIdentity | null): HubRoom[] {
  const rank = (r: HubRoom): number => {
    const m = membershipOf(r, mine).membership;
    return m === "host" ? 0 : m === "member" ? 1 : 2;
  };
  return rooms
    .map((r, i) => ({ r, i }))
    .sort((a, b) => rank(a.r) - rank(b.r) || a.i - b.i)
    .map(({ r }) => r);
}
