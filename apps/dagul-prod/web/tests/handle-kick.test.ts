import { describe, expect, it, vi } from "vitest";
import { handleKick, handleSetPassword } from "@/lib/hub/lobby-waiting";
import { KO } from "@/lib/hub/config";
import { MSG } from "@/lib/contract";
import type { LobbyHandle } from "@/lib/hub/lobby-waiting";

function fakeRoom(hostId: string, players: Array<{ slot: number; sessionId: string }>): {
  room: LobbyHandle;
  errors: string[];
  kicked: string[];
} {
  const errors: string[] = [];
  const kicked: string[] = [];
  const clients = players.map((p) => ({
    sessionId: p.sessionId,
    send: (type: string, payload: { msg?: string }): void => {
      if (type === MSG.ERROR) {errors.push(payload.msg ?? "");}
      if (type === MSG.KICKED) {kicked.push(p.sessionId);}
    },
    leave: vi.fn(),
  }));
  const room = {
    state: {
      hostSessionId: hostId,
      password: "1111",
      players,
      phase: "lobby",
    },
    clients,
    metadata: {},
    setMetadata: vi.fn(),
    clock: { setTimeout: vi.fn() },
    broadcast: vi.fn(),
  } as unknown as LobbyHandle;
  return { room, errors, kicked };
}

describe("handleKick", () => {
  it("호스트가 아닌 사람은 못 내보낸다", () => {
    const { room, errors } = fakeRoom("host", [{ slot: 0, sessionId: "host" }, { slot: 1, sessionId: "guest" }]);
    handleKick(room, { sessionId: "guest", send: room.clients[1].send, leave: vi.fn() } as never, { slot: 0 });
    expect(errors).toContain(KO.HOST_ONLY_KICK);
  });

  it("호스트는 다른 좌석을 내보낸다", () => {
    const { room, kicked } = fakeRoom("host", [{ slot: 0, sessionId: "host" }, { slot: 1, sessionId: "guest" }]);
    handleKick(room, { sessionId: "host", send: vi.fn(), leave: vi.fn() } as never, { slot: 1 });
    expect(kicked).toEqual(["guest"]);
  });
});

describe("handleSetPassword", () => {
  const host = { sessionId: "host", send: vi.fn(), leave: vi.fn() };

  it("게스트는 PIN 을 못 바꾼다", () => {
    const { room, errors } = fakeRoom("host", [{ slot: 0, sessionId: "host" }]);
    handleSetPassword(room, { sessionId: "guest", send: (t: string, p: { msg?: string }) => {if (t === MSG.ERROR) {errors.push(p.msg ?? "");}}, leave: vi.fn() } as never, { password: "9999" });
    expect(errors).toContain(KO.HOST_ONLY_PASSWORD);
    expect((room.state as { password: string }).password).toBe("1111");
  });

  it("호스트는 4자리로 바꾸고 메타에 잠금을 올린다", () => {
    const { room } = fakeRoom("host", [{ slot: 0, sessionId: "host" }]);
    handleSetPassword(room, host as never, { password: "42-42" });
    expect((room.state as { password: string }).password).toBe("4242");
    expect(room.setMetadata).toHaveBeenCalledWith(expect.objectContaining({ hasPassword: true }));
  });

  it("호스트가 끄면 PIN 을 비우고 잠금 메타를 내린다", () => {
    const { room } = fakeRoom("host", [{ slot: 0, sessionId: "host" }]);
    handleSetPassword(room, host as never, { enabled: false });
    expect((room.state as { password: string }).password).toBe("");
    expect(room.setMetadata).toHaveBeenCalledWith(expect.objectContaining({ hasPassword: false }));
  });

  it("켜기만 하면 4자리를 새로 뽑는다", () => {
    const { room } = fakeRoom("host", [{ slot: 0, sessionId: "host" }]);
    handleSetPassword(room, host as never, { enabled: true });
    expect((room.state as { password: string }).password).toMatch(/^\d{4}$/);
    expect(room.setMetadata).toHaveBeenCalledWith(expect.objectContaining({ hasPassword: true }));
  });
});
