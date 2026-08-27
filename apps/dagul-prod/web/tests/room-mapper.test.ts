import { describe, expect, it } from "vitest";
import type { RoomAvailable } from "@colyseus/sdk";
import { listableRoom, removeRoom, roomJoinable, toHubRoom, upsertRoom } from "@/lib/hub/room-mapper";

const avail = (id: string, clients = 1, phase = "lobby"): RoomAvailable =>
  ({ roomId: id, clients, metadata: { title: `방${id}`, mode: "solo", phase } }) as unknown as RoomAvailable;

describe("toHubRoom — 뷰 모델 매핑", () => {
  it("메타데이터 → HubRoom", () => {
    expect(toHubRoom(avail("r1", 3, "playing"))).toEqual({
      id: "r1", gameId: "", title: "방r1", players: 3, mode: "solo", playing: true, open: true, hasPassword: false,
    });
  });
  it("메타 없으면 기본값", () => {
    const bare = { roomId: "r2", clients: 0 } as RoomAvailable;
    expect(toHubRoom(bare)).toEqual({ id: "r2", gameId: "", title: "r2", players: 0, mode: "", playing: false, open: true, hasPassword: false });
  });
  it("닫힌 방·게임 id 를 메타에서 읽는다", () => {
    const closed = {
      roomId: "r3", clients: 2,
      metadata: { title: "저녁", gameId: "sparring", mode: "full", phase: "lobby", open: false },
    } as unknown as RoomAvailable;
    expect(toHubRoom(closed)).toEqual({
      id: "r3", gameId: "sparring", title: "저녁", players: 2, mode: "full", playing: false, open: false, hasPassword: false,
    });
  });
});

describe("listableRoom", () => {
  it("비밀번호 방을 메타에서 읽는다", () => {
    const locked = {
      roomId: "r4", clients: 1,
      metadata: { title: "비밀", hasPassword: true },
    } as unknown as RoomAvailable;
    expect(toHubRoom(locked).hasPassword).toBe(true);
  });

  it("플레이 중·닫힘·만석·잠금은 뺀다", () => {
    expect(listableRoom(avail("a", 1, "lobby"))).toBe(true);
    expect(listableRoom(avail("b", 1, "playing"))).toBe(false);
    const full = { ...avail("c", 8, "lobby"), maxClients: 8 } as RoomAvailable;
    expect(listableRoom(full)).toBe(false);
    const locked = { ...avail("d", 1, "lobby"), locked: true } as RoomAvailable;
    expect(listableRoom(locked)).toBe(false);
  });
});

describe("roomJoinable", () => {
  it("대기 중이고 열린 방만 입장 가능", () => {
    expect(roomJoinable({ playing: false, open: true })).toBe(true);
    expect(roomJoinable({ playing: true, open: true })).toBe(false);
    expect(roomJoinable({ playing: false, open: false })).toBe(false);
  });
});

describe("upsertRoom / removeRoom — 델타 적용", () => {
  it("없으면 append, 있으면 교체", () => {
    const list = [avail("a"), avail("b")];
    expect(upsertRoom(list, "c", avail("c")).map((r) => r.roomId)).toEqual(["a", "b", "c"]);
    expect(upsertRoom(list, "a", avail("a", 5)).map((r) => r.clients)).toEqual([5, 1]);
  });
  it("제거는 해당 방만", () => {
    const list = [avail("a"), avail("b")];
    expect(removeRoom(list, "a").map((r) => r.roomId)).toEqual(["b"]);
    expect(removeRoom(list, "zzz").map((r) => r.roomId)).toEqual(["a", "b"]);
  });
});
