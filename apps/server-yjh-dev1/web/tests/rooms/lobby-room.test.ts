/**
 * LobbyRoom 룸 로직 단위테스트 — @colyseus/testing 공식 패키지.
 * 체인 6층: 실서버 스모크가 느리게 잡던 룸 규칙을 인메모리로 빠르게 검증한다.
 * 커버: 기본 타이틀·호스트 지정·호스트 전용 시작·매치 시작 상태 전파.
 */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { Server } from "colyseus";
import { boot, type ColyseusTestServer } from "@colyseus/testing";
import { LobbyRoom } from "@/lib/hub/LobbyRoom";
import { MSG, KO } from "@/lib/hub/config";

let colyseus: ColyseusTestServer;

beforeAll(async (): Promise<void> => {
  // app.config 없이 Server 인스턴스 직접 조립 — boot()의 raw Server 오버로드.
  const server = new Server();
  server.define("lobby", LobbyRoom);
  colyseus = await boot(server);
});

afterAll(async (): Promise<void> => {
  await colyseus.shutdown();
});

describe("LobbyRoom 규칙", () => {
  it("방 생성 — 기본 타이틀·로비 페이즈", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "첫호스트" });
    expect(room.state.title).toContain("합본 #");
    expect(String(room.state.phase)).toBe("lobby");
    expect(room.state.players.length).toBe(0);
  });

  it("두 클라이언트 입장 — 첫 입장자가 호스트", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    await room.waitForNextPatch();
    expect(room.state.players.length).toBe(2);
    expect(room.state.hostSessionId).toBe(host.sessionId);
    expect(room.state.hostSessionId).not.toBe(guest.sessionId);
  });

  it("비호스트 시작 시도 — ERROR 거부, 페이즈 유지", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });

    const errorP = guest.waitForMessage(MSG.ERROR);
    guest.send(MSG.START, {});
    const payload = (await errorP) as { msg?: string };

    expect(payload.msg).toBe(KO.HOST_ONLY_START);
    expect(String(room.state.phase)).toBe("lobby");
  });

  it("호스트 시작 — playing 전이·시드 발급", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    await colyseus.connectTo(room, { name: "게스트" });

    host.send(MSG.START, {});
    await room.waitForNextPatch();

    expect(String(room.state.phase)).toBe("playing");
    expect(Number(room.state.seed)).toBeGreaterThan(0);
  });
});
