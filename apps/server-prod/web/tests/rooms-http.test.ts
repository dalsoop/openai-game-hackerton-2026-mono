import { describe, expect, it } from "vitest";
import type { RoomAvailable } from "@colyseus/sdk";
import { roomsHttpBody } from "@/lib/hub/rooms-http";

const room = (id: string, extra: Record<string, unknown> = {}): RoomAvailable =>
  ({ roomId: id, clients: 1, metadata: { phase: "lobby", open: true }, ...extra }) as RoomAvailable;

describe("roomsHttpBody", () => {
  it("입장 가능한 방만 남긴다", () => {
    const body = roomsHttpBody([
      room("a"),
      room("b", { metadata: { phase: "playing", open: true } }),
      room("c", { locked: true }),
    ]);
    expect(body.rooms.map((r) => r.roomId)).toEqual(["a"]);
  });
});
