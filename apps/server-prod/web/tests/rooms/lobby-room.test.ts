/**
 * LobbyRoom 룸 로직 단위테스트 — @colyseus/testing 공식 패키지.
 * 체인 6층: 실서버 스모크가 느리게 잡던 룸 규칙을 인메모리로 빠르게 검증한다.
 * 커버: 기본 타이틀·호스트 지정·호스트 전용 시작·매치 시작 상태 전파.
 */
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { Server } from "colyseus";
import { boot, type ColyseusTestServer } from "@colyseus/testing";
import { LobbyRoom } from "@/lib/hub/LobbyRoom";
import { MSG, KO } from "@/lib/hub/config";
import { parseStartPayload } from "@/lib/hub/start-payload";
import { nowUnixSec } from "@/lib/hub/lobby-idle";

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

// docs.colyseus.io/tools/unit-testing — 케이스마다 cleanup, 룸 인스턴스 재사용 금지.
beforeEach(async (): Promise<void> => {
  await colyseus.cleanup();
});

describe("LobbyRoom 규칙", () => {
  it("방 생성 — 기본 타이틀·로비 페이즈", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "첫호스트" });
    expect(room.state.title).toContain("방 #");
    expect(String(room.state.phase)).toBe("lobby");
    expect(room.state.players.length).toBe(0);
  });

  it("방 생성 — 유즈맵·제목을 옵션으로 확정한다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", {
      name: "호스트", game: "sparring", title: "저녁 한 판",
    });
    expect(room.state.gameId).toBe("sparring");
    expect(room.state.title).toBe("저녁 한 판");
  });

  it("방 생성 — 미등재 게임은 기본 게임으로 정규화한다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", {
      name: "호스트", game: "없는맵",
    });
    expect(room.state.gameId).toBe("dagul");
  });

  it("두 클라이언트 입장 — 첫 입장자가 호스트", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    await room.waitForNextPatch();
    expect(room.state.players.length).toBe(2);
    expect(room.state.hostSessionId).toBe(host.sessionId);
    expect(room.state.hostSessionId).not.toBe(guest.sessionId);
    // docs.colyseus.io/tools/unit-testing — 패치 이후 클라 상태는 서버와 같다.
    expect(host.state.toJSON()).toEqual(room.state.toJSON());
    expect(guest.state.toJSON()).toEqual(room.state.toJSON());
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

  it("호스트 시작 — START 본문은 StartPayload 계약과 맞는다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    await colyseus.connectTo(room, { name: "게스트" });

    const startP = host.waitForMessage(MSG.START);
    host.send(MSG.START, {});
    const payload = parseStartPayload(await startP);

    expect(payload).not.toBeNull();
    expect(payload?.you).toBe(0);
    expect(payload?.host).toBe(true);
    expect(payload?.seed).toBeGreaterThan(0);
    expect(payload?.seats).toHaveLength(2);
    expect(payload?.seats.map((s) => s.name)).toEqual(["호스트", "게스트"]);
    expect(payload?.seats.every((s) => s.characterId === "unknown")).toBe(true);
  });

  it("각 좌석이 자기 캐릭터만 고른다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    host.send(MSG.SET_CHARACTER, { characterId: "a2" });
    guest.send(MSG.SET_CHARACTER, { characterId: "missing" });
    await room.waitForNextPatch();
    const bySid = Object.fromEntries(
      [...room.state.players].map((p) => [p.sessionId, p.characterId]),
    );
    expect(bySid[host.sessionId]).toBe("a2");
    expect(bySid[guest.sessionId]).toBe("unknown");
  });

  it("방장만 대기실에서 게임을 바꾼다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트", game: "dagul" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    const errP = guest.waitForMessage(MSG.ERROR);
    guest.send(MSG.SET_GAME, { game: "sparring" });
    expect(((await errP) as { msg?: string }).msg).toBe(KO.HOST_ONLY_GAME);
    expect(room.state.gameId).toBe("dagul");
    host.send(MSG.SET_GAME, { game: "sparring" });
    await room.waitForNextPatch();
    expect(room.state.gameId).toBe("sparring");
    expect(room.state.mode).toBe("default");
  });

  it("게스트 팩 보고는 그 좌석만 바꾸고 SET_GAME 은 전좌석을 0 으로 돌린다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트", game: "dagul" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    await room.waitForNextPatch();
    guest.send(MSG.PACK_PCT, { pct: 42 });
    await room.waitForNextPatch();
    const bySid = Object.fromEntries(
      [...room.state.players].map((p) => [p.sessionId, p.packPct]),
    );
    expect(bySid[host.sessionId]).toBe(0);
    expect(bySid[guest.sessionId]).toBe(42);
    host.send(MSG.SET_GAME, { game: "sparring" });
    await room.waitForNextPatch();
    expect([...room.state.players].every((p) => p.packPct === 0)).toBe(true);
  });

  it("3퍼센트 상승은 거절한다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    await room.waitForNextPatch();
    host.send(MSG.PACK_PCT, { pct: 3 });
    await new Promise((r) => setTimeout(r, 40));
    expect(room.state.players[0].packPct).toBe(0);
  });

  it("playing 중 PACK_PCT 는 버린다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    await room.waitForNextPatch();
    host.send(MSG.PACK_PCT, { pct: 40 });
    await room.waitForNextPatch();
    expect(room.state.players[0].packPct).toBe(40);
    host.send(MSG.START, {});
    await room.waitForNextPatch();
    expect(String(room.state.phase)).toBe("playing");
    host.send(MSG.PACK_PCT, { pct: 100 });
    await new Promise((r) => setTimeout(r, 40));
    expect(room.state.players[0].packPct).toBe(40);
  });

  it("다른 좌석이 100 이 아니어도 호스트는 시작한다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    await colyseus.connectTo(room, { name: "게스트" });
    await room.waitForNextPatch();
    host.send(MSG.PACK_PCT, { pct: 100 });
    await room.waitForNextPatch();
    host.send(MSG.START, {});
    await room.waitForNextPatch();
    expect(String(room.state.phase)).toBe("playing");
  });

  it("대기실 방장 퇴장 — 다음 접속자가 방장을 이어받는다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    await room.waitForNextPatch();
    await host.leave();
    await room.waitForNextPatch();
    expect(room.state.hostSessionId).toBe(guest.sessionId);
    expect(String(room.state.phase)).toBe("lobby");
  });

  it("플레이 중 방장 좌석 제거 — 다음 접속자가 방장을 이어받고 매치는 유지된다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    host.send(MSG.START, {});
    await room.waitForNextPatch();
    const hostId = host.sessionId;
    (room as unknown as { removeSeat: (id: string) => void }).removeSeat(hostId);
    await room.waitForNextPatch();
    expect(String(room.state.phase)).toBe("playing");
    expect(room.state.hostSessionId).toBe(guest.sessionId);
    expect(room.state.players.length).toBe(1);
  });

  it("대기실 동의 퇴장 — 좌석을 즉시 반납한다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    await room.waitForNextPatch();
    await guest.leave();
    await room.waitForNextPatch();
    expect(room.state.players.length).toBe(1);
  });

  it("플레이 중 동의 퇴장 — 좌석을 즉시 반납하고 방장을 넘긴다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    host.send(MSG.START, {});
    await room.waitForNextPatch();

    await host.leave();
    await room.waitForNextPatch();
    expect(String(room.state.phase)).toBe("playing");
    expect(room.state.players.length).toBe(1);
    expect(room.state.hostSessionId).toBe(guest.sessionId);
  });

  it("방 닫기 — 재실자 강퇴·좌석 정리", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    await room.waitForNextPatch();

    const kickedP = guest.waitForMessage(MSG.KICKED);
    const leaveP = new Promise<boolean>((resolve) => {guest.onLeave(() => resolve(true));});
    host.send(MSG.ROOM_TOGGLE, {});
    const kicked = (await kickedP) as { msg?: string };

    expect(await leaveP).toBe(true);
    expect(kicked.msg).toBe(KO.KICKED_MSG);
    expect(room.state.open).toBe(false);
    await room.waitForNextPatch();
    expect(room.state.players.length).toBe(1); // 방장만 남는다
  });

  it("대기실 생성 — unix 초 유휴 마감이 올라간다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    await colyseus.connectTo(room, { name: "호스트" });
    expect(Number(room.state.idleUntilSec)).toBeGreaterThan(nowUnixSec() - 1);
  });

  it("유휴 폭파 — KICKED(reason=idle) 후 방이 닫힌다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    expect(Number(room.state.idleUntilSec)).toBeGreaterThan(0);
    const kickedP = host.waitForMessage(MSG.KICKED);
    (room as unknown as { burstIdle: () => void }).burstIdle();
    const kicked = (await kickedP) as { msg?: string; reason?: string };
    expect(kicked.reason).toBe("idle");
    expect(kicked.msg).toBe(KO.IDLE_START);
  });

  it("매치 시작 후 유휴 마감이 꺼진다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    host.send(MSG.START, {});
    await room.waitForNextPatch();
    expect(Number(room.state.idleUntilSec)).toBe(0);
  });

  it("대기실 방장 단절 — 유예 중에도 다음 접속자가 방장이다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    await room.waitForNextPatch();
    const seat = [...room.state.players].find((p) => p.sessionId === host.sessionId);
    expect(seat).toBeDefined();
    if (!seat) {return;}
    seat.connected = false;
    (room as unknown as { syncHost: () => void }).syncHost();
    await room.waitForNextPatch();
    expect(room.state.hostSessionId).toBe(guest.sessionId);
    expect(room.state.players.length).toBe(2);
  });

  it("PING 은 보낸 t 를 PONG 으로 그대로 돌려준다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const pongP = host.waitForMessage(MSG.PONG);
    host.send(MSG.PING, { t: 1234 });
    expect(await pongP).toEqual({ t: 1234 });
  });

  it("닫힌 방 — 입장 거부", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    host.send(MSG.ROOM_TOGGLE, {});
    await room.waitForNextPatch();
    expect(room.state.open).toBe(false);

    await expect(colyseus.connectTo(room, { name: "늦은이" }))
      .rejects.toThrow(KO.ROOM_CLOSED);
  });

  it("비호스트 토글 시도 — ERROR 거부", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });

    const errorP = guest.waitForMessage(MSG.ERROR);
    guest.send(MSG.ROOM_TOGGLE, {});
    const payload = (await errorP) as { msg?: string };

    expect(payload.msg).toBe(KO.HOST_ONLY_TOGGLE);
    expect(room.state.open).toBe(true); // 상태 불변
  });

  it("방 다시 열기 — 입장 재개", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    host.send(MSG.ROOM_TOGGLE, {});
    await room.waitForNextPatch();
    host.send(MSG.ROOM_TOGGLE, {});
    await room.waitForNextPatch();
    expect(room.state.open).toBe(true);

    await colyseus.connectTo(room, { name: "재입장" });
    await room.waitForNextPatch();
    expect(room.state.players.length).toBe(2);
  });
});

function stepSim(room: LobbyRoom, n = 8, dt = 50): void {
  for (let i = 0; i < n; i += 1) {room.stepSim(dt);}
}

describe("허브 권위 매치", () => {
  it("시작 직후 호스트와 게스트가 같은 권위 스냅을 받는다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    const hostSnap = host.waitForMessage(MSG.SNAP);
    const guestSnap = guest.waitForMessage(MSG.SNAP);
    host.send(MSG.START, {});
    const [hs, gs] = await Promise.all([hostSnap, guestSnap]);
    const a = hs as { tick?: number; players?: { slot: number }[] };
    const b = gs as { tick?: number; players?: { slot: number }[] };
    expect(a.tick).toBe(b.tick);
    expect(a.players?.map((p) => p.slot).sort()).toEqual([0, 1]);
    await room.waitForNextPatch();
    expect(room.state.heroes.size).toBe(2);
  });

  it("호스트 input 도 권위에 들어가고 스키마에 반영된다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    await colyseus.connectTo(room, { name: "게스트" });
    const first = host.waitForMessage(MSG.SNAP);
    host.send(MSG.START, {});
    await first;
    const x0 = room.state.heroes.get("0")?.x ?? 0;
    expect(room.pushTestInput(host.sessionId, {
      mx: 1, my: 0, seq: 11, aimX: x0 + 80, aimY: 2380,
    })).toBe(true);
    stepSim(room, 10, 50);
    const me = room.state.heroes.get("0");
    expect(me?.x).toBeGreaterThan(x0 + 5);
    expect(me?.ack).toBe(11);
  });

  it("게스트 발사는 id 있는 탄을 만들고 host_snap 은 무시한다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    const bootSnap = host.waitForMessage(MSG.SNAP);
    host.send(MSG.START, {});
    await bootSnap;
    const fxP = host.waitForMessage(MSG.GUN_FIRE);
    expect(room.pushTestInput(guest.sessionId, {
      mx: 0, my: 0, fire: true, firePressed: true, seq: 4,
      aimX: 4000, aimY: 2380,
    })).toBe(true);
    host.send(MSG.HOST_SNAP, { tick: 9999, bullets: [{ id: 77 }] });
    stepSim(room, 6, 50);
    expect(room.state.bullets.size).toBeGreaterThan(0);
    const shot = [...room.state.bullets.values()][0];
    expect(shot.id).toBeGreaterThan(0);
    expect(shot.owner).toBe(1);
    expect(shot.id).not.toBe(77);
    const fx = (await fxP) as { slot: number };
    expect(fx.slot).toBe(1);
  });

  it("클라 INPUT 메시지가 권위 ack 에 남는다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    await colyseus.connectTo(room, { name: "게스트" });
    const first = host.waitForMessage(MSG.SNAP);
    host.send(MSG.START, {});
    await first;
    host.send(MSG.INPUT, { mx: 1, my: 0, seq: 5, aimX: 4000, aimY: 2380 });
    await new Promise((r) => setTimeout(r, 40));
    stepSim(room, 8, 50);
    expect(room.state.heroes.get("0")?.ack).toBe(5);
  });

  it("플레이 중 방장이 나가도 게스트 입력으로 매치가 이어진다", async () => {
    const room = await colyseus.createRoom<LobbyRoom>("lobby", { name: "호스트" });
    const host = await colyseus.connectTo(room, { name: "호스트" });
    const guest = await colyseus.connectTo(room, { name: "게스트" });
    const boot = guest.waitForMessage(MSG.SNAP);
    host.send(MSG.START, {});
    await boot;
    (room as unknown as { removeSeat: (id: string) => void }).removeSeat(host.sessionId);
    await room.waitForNextPatch();
    expect(String(room.state.phase)).toBe("playing");
    expect(room.pushTestInput(guest.sessionId, { mx: 1, my: 0, seq: 8 })).toBe(true);
    stepSim(room, 8, 50);
    expect(room.state.heroes.get("1")?.ack).toBe(8);
  });
});

