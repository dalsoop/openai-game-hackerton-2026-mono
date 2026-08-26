import { describe, expect, it } from "vitest";
import {
  clearMyRoom,
  membershipOf,
  readMyRoom,
  saveMyRoom,
  sortRoomsByMembership,
} from "@/lib/room-membership";
import type { HubRoom } from "@/types";

const room = (id: string): HubRoom => ({ id, gameId: "", title: id, players: 1, mode: "", playing: false, open: true });

describe("readMyRoom / saveMyRoom / clearMyRoom — 저장소 주입", () => {
  it("저장·독자·폐기 왕복", () => {
    const store = new Map<string, string>();
    saveMyRoom((k, v) => store.set(k, v), { roomId: "r1", host: true });
    expect(readMyRoom((k) => store.get(k) ?? null)).toEqual({ roomId: "r1", host: true });
    clearMyRoom((k) => store.delete(k));
    expect(readMyRoom((k) => store.get(k) ?? null)).toBeNull();
  });

  it("빈 roomId·깨진 JSON은 null", () => {
    expect(readMyRoom(() => "")).toBeNull();
    expect(readMyRoom(() => "{broken")).toBeNull();
    expect(readMyRoom(() => '{"roomId":"","host":false}')).toBeNull();
  });

  it("옛 dagul_my_room 키도 읽는다", () => {
    const store = new Map<string, string>([["dagul_my_room", JSON.stringify({ roomId: "legacy", host: false })]]);
    expect(readMyRoom((k) => store.get(k) ?? null)).toEqual({ roomId: "legacy", host: false });
  });
});

describe("membershipOf", () => {
  it("내 방·방장", () => {
    expect(membershipOf(room("r1"), { roomId: "r1", host: true })).toEqual({ membership: "host", pinned: true });
  });
  it("내 방·참여자(튕긴 경우 재입장 대상)", () => {
    expect(membershipOf(room("r1"), { roomId: "r1", host: false })).toEqual({ membership: "member", pinned: true });
  });
  it("남의 방", () => {
    expect(membershipOf(room("r2"), { roomId: "r1", host: true })).toEqual({ membership: "none", pinned: false });
    expect(membershipOf(room("r1"), null)).toEqual({ membership: "none", pinned: false });
  });
});

describe("sortRoomsByMembership — 상단 고정", () => {
  const rooms = [room("a"), room("b"), room("c")];

  it("방장 방 > 참여 방 > 나머지, 비멤버십 순서 유지(안정)", () => {
    expect(sortRoomsByMembership(rooms, { roomId: "b", host: true }).map((r) => r.id)).toEqual(["b", "a", "c"]);
    expect(sortRoomsByMembership(rooms, { roomId: "c", host: false }).map((r) => r.id)).toEqual(["c", "a", "b"]);
    expect(sortRoomsByMembership(rooms, null).map((r) => r.id)).toEqual(["a", "b", "c"]);
  });
});
