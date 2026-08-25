import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { WebSocket } from "ws";

const SERVER = process.env.TEST_SERVER || "wss://server-yjh-dev1.external.kr/gang-up";
const TIMEOUT = 10_000;

interface Msg { t: string; [k: string]: unknown; }

class TestClient {
  ws!: WebSocket;
  inbox: Msg[] = [];
  private listeners: Array<(msg: Msg) => void> = [];

  async connect(): Promise<void> {
    await new Promise<void>((resolve, reject) => {
      this.ws = new WebSocket(SERVER);
      const t = setTimeout(() => reject(new Error("connect timeout")), TIMEOUT);
      this.ws.on("open", () => { clearTimeout(t); resolve(); });
      this.ws.on("error", (e) => { clearTimeout(t); reject(e); });
      this.ws.on("message", (raw) => {
        const msg: Msg = JSON.parse(String(raw));
        this.inbox.push(msg);
        for (const fn of [...this.listeners]) fn(msg);
      });
    });
  }

  send(msg: Msg): void { this.ws.send(JSON.stringify(msg)); }

  waitFor(type: string, ms = TIMEOUT): Promise<Msg> {
    const idx = this.inbox.findIndex((m) => m.t === type);
    if (idx >= 0) { const m = this.inbox[idx]!; this.inbox.splice(idx, 1); return Promise.resolve(m); }
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => { cleanup(); reject(new Error(`timeout waiting for "${type}"`)); }, ms);
      const handler = (msg: Msg) => { if (msg.t === type) { cleanup(); resolve(msg); } };
      const cleanup = () => { clearTimeout(timer); this.listeners = this.listeners.filter((f) => f !== handler); };
      this.listeners.push(handler);
    });
  }

  /** Collect all messages of a given type that arrive within `ms` milliseconds. */
  collectAll(type: string, ms: number): Promise<Msg[]> {
    return new Promise((resolve) => {
      const result: Msg[] = [];
      // Drain inbox first
      for (let i = this.inbox.length - 1; i >= 0; i--) {
        if (this.inbox[i]!.t === type) {
          result.push(this.inbox[i]!);
          this.inbox.splice(i, 1);
        }
      }
      const handler = (msg: Msg) => { if (msg.t === type) result.push(msg); };
      this.listeners.push(handler);
      setTimeout(() => {
        this.listeners = this.listeners.filter((f) => f !== handler);
        resolve(result);
      }, ms);
    });
  }

  close(): void { try { this.ws?.close(); } catch {} }
}

function wait(ms: number): Promise<void> { return new Promise((r) => setTimeout(r, ms)); }

async function setupPair(hostName: string, guestName: string): Promise<{ host: TestClient; guest: TestClient; roomId: string }> {
  const host = new TestClient();
  const guest = new TestClient();
  await host.connect();
  await guest.connect();
  await host.waitFor("welcome");
  await guest.waitFor("welcome");
  host.send({ t: "hello", name: hostName, mode: "classic" });
  guest.send({ t: "hello", name: guestName, mode: "classic" });
  await wait(300);
  host.send({ t: "create" });
  const joined = await host.waitFor("joined");
  const roomId = (joined.room as Msg).id as string;
  guest.send({ t: "join", roomId });
  await guest.waitFor("joined");
  await wait(200);
  host.inbox.length = 0;
  guest.inbox.length = 0;
  return { host, guest, roomId };
}

async function setupTrio(hName: string, g1Name: string, g2Name: string): Promise<{ host: TestClient; guestA: TestClient; guestB: TestClient; roomId: string }> {
  const host = new TestClient();
  const guestA = new TestClient();
  const guestB = new TestClient();
  await Promise.all([host.connect(), guestA.connect(), guestB.connect()]);
  await Promise.all([host.waitFor("welcome"), guestA.waitFor("welcome"), guestB.waitFor("welcome")]);
  host.send({ t: "hello", name: hName, mode: "classic" });
  guestA.send({ t: "hello", name: g1Name, mode: "classic" });
  guestB.send({ t: "hello", name: g2Name, mode: "classic" });
  await wait(300);
  host.send({ t: "create" });
  const joined = await host.waitFor("joined");
  const roomId = (joined.room as Msg).id as string;
  guestA.send({ t: "join", roomId });
  await guestA.waitFor("joined");
  guestB.send({ t: "join", roomId });
  await guestB.waitFor("joined");
  await wait(200);
  host.inbox.length = 0;
  guestA.inbox.length = 0;
  guestB.inbox.length = 0;
  return { host, guestA, guestB, roomId };
}

// ── Test 1: Full match cycle ─────────────────────────────────────────

describe("E2E 1: 풀 매치 사이클", { timeout: 15_000 }, () => {
  it("2인 풀 매치 → 로비 복귀 → 재시작", async () => {
    const { host, guest } = await setupPair("E2E-H1", "E2E-G1");

    // mode select + start
    host.send({ t: "mode", mode: "classic" });
    await wait(100);
    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    host.inbox.length = 0;
    guest.inbox.length = 0;

    // Host sends 10 snaps at ~50ms intervals (20Hz), guest sends 10 inputs concurrently
    const snapPromise = (async () => {
      for (let i = 0; i < 10; i++) {
        host.send({
          t: "host_snap", tick: i, time: i * 0.05, result: "playing", winner: -1,
          heroes: [{ slot: 0, hp: 100, x: 100, y: 100 }, { slot: 1, hp: 90, x: 200, y: 200 }],
        });
        await wait(50);
      }
    })();

    const inputPromise = (async () => {
      for (let i = 0; i < 10; i++) {
        guest.send({ t: "input", mx: 1, my: 0, fire: i % 2 === 0, aimX: 400 + i, aimY: 300 });
        await wait(50);
      }
    })();

    await Promise.all([snapPromise, inputPromise]);
    await wait(500);

    // Host should have received at least 10 peer_input messages
    const peerInputs = host.inbox.filter((m) => m.t === "peer_input");
    assert.ok(peerInputs.length >= 10, `host got ${peerInputs.length} peer_inputs, expected >= 10`);

    // Guest should have received at least 10 snap messages
    const snaps = guest.inbox.filter((m) => m.t === "snap");
    assert.ok(snaps.length >= 10, `guest got ${snaps.length} snaps, expected >= 10`);

    // Host sends game-over snap
    host.inbox.length = 0;
    guest.inbox.length = 0;
    host.send({ t: "host_snap", tick: 999, time: 60, result: "won", winner: 0, heroes: [] });
    const wonSnap = await guest.waitFor("snap");
    assert.equal(wonSnap.result, "won");

    // Wait for lobby reset (~5s + margin)
    const lobbyMsg = await Promise.race([
      guest.waitFor("lobby", 8_000),
      guest.waitFor("peers", 8_000),
    ]).catch(() => null);
    assert.ok(lobbyMsg, "로비 복귀 메시지를 받아야 합니다");

    // Second match start
    await wait(300);
    host.inbox.length = 0;
    guest.inbox.length = 0;
    host.send({ t: "start" });
    const s2h = await host.waitFor("start");
    const s2g = await guest.waitFor("start");
    assert.equal(s2h.host, true, "두 번째 매치에서도 호스트는 host:true");
    assert.ok(s2g, "두 번째 매치 start를 게스트가 수신");

    host.close();
    guest.close();
  });
});

// ── Test 2: Coordinate system verification ───────────────────────────

describe("E2E 2: 좌표계 검증", { timeout: 15_000 }, () => {
  it("맵 중앙 좌표(3920, 2380)가 잘리지 않고 전달된다", async () => {
    const { host, guest } = await setupPair("E2E-H2", "E2E-G2");

    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    guest.inbox.length = 0;

    host.send({
      t: "host_snap", tick: 1, time: 0.05, result: "playing", winner: -1,
      heroes: [{ slot: 0, hp: 100, x: 3920, y: 2380 }],
    });

    const snap = await guest.waitFor("snap");
    const heroes = snap.heroes as Array<{ x: number; y: number }>;
    assert.ok(heroes && heroes.length > 0, "heroes 배열이 있어야 합니다");
    assert.equal(heroes[0]!.x, 3920, "x 좌표가 3920이어야 합니다");
    assert.equal(heroes[0]!.y, 2380, "y 좌표가 2380이어야 합니다");

    // Verify coordinates are NOT clipped to 1600x900
    assert.ok(heroes[0]!.x > 1600, "x > 1600 → 좌표가 뷰포트 범위로 잘리지 않음");
    assert.ok(heroes[0]!.y > 900, "y > 900 → 좌표가 뷰포트 범위로 잘리지 않음");

    host.close();
    guest.close();
  });
});

// ── Test 3: 3-player simultaneous play ───────────────────────────────

describe("E2E 3: 3인 동시 플레이", { timeout: 15_000 }, () => {
  it("호스트 snap → 게스트 2명 수신, 게스트별 input → 호스트가 slot 구분해 수신", async () => {
    const { host, guestA, guestB } = await setupTrio("E2E-H3", "E2E-GA3", "E2E-GB3");

    host.send({ t: "start" });
    await host.waitFor("start");
    await guestA.waitFor("start");
    await guestB.waitFor("start");
    host.inbox.length = 0;
    guestA.inbox.length = 0;
    guestB.inbox.length = 0;

    // Host sends snap → both guests should receive
    host.send({
      t: "host_snap", tick: 1, time: 0.05, result: "playing", winner: -1,
      heroes: [
        { slot: 0, hp: 100, x: 100, y: 100 },
        { slot: 1, hp: 90, x: 200, y: 200 },
        { slot: 2, hp: 80, x: 300, y: 300 },
      ],
    });

    const [snapA, snapB] = await Promise.all([
      guestA.waitFor("snap"),
      guestB.waitFor("snap"),
    ]);
    assert.ok(snapA, "게스트A가 snap을 수신");
    assert.ok(snapB, "게스트B가 snap을 수신");

    // GuestA sends input → host receives peer_input with slot=1
    guestA.send({ t: "input", mx: 1, my: 0, fire: true, aimX: 500, aimY: 300 });
    const piA = await host.waitFor("peer_input");
    assert.equal(piA.slot, 1, "게스트A의 slot은 1");

    // GuestB sends input → host receives peer_input with slot=2
    guestB.send({ t: "input", mx: -1, my: 1, fire: false, aimX: 600, aimY: 400 });
    const piB = await host.waitFor("peer_input");
    assert.equal(piB.slot, 2, "게스트B의 slot은 2");

    host.close();
    guestA.close();
    guestB.close();
  });
});

// ── Test 4: Reconnect and resume ─────────────────────────────────────

describe("E2E 4: 재접속 후 게임 속행", { timeout: 15_000 }, () => {
  it("게스트 끊김 → peer_parked → resume 토큰 재접속 → playing:true + peer_reclaimed", async () => {
    // Build pair manually to capture resume token from welcome
    const host = new TestClient();
    const guest = new TestClient();
    await host.connect();
    await guest.connect();
    await host.waitFor("welcome");
    const welcomeG = await guest.waitFor("welcome");
    const guestResume = welcomeG.resume as string;
    assert.ok(guestResume, "게스트 resume 토큰이 있어야 합니다");

    host.send({ t: "hello", name: "E2E-H4", mode: "classic" });
    guest.send({ t: "hello", name: "E2E-G4", mode: "classic" });
    await wait(300);

    host.send({ t: "create" });
    const joined = await host.waitFor("joined");
    const roomId = (joined.room as Msg).id as string;
    guest.send({ t: "join", roomId });
    await guest.waitFor("joined");
    await wait(200);
    host.inbox.length = 0;
    guest.inbox.length = 0;

    // Start match
    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    host.inbox.length = 0;

    // Keep alive with a snap
    host.send({
      t: "host_snap", tick: 1, time: 0.05, result: "playing", winner: -1,
      heroes: [{ slot: 0, hp: 100 }, { slot: 1, hp: 90 }],
    });
    await wait(200);
    host.inbox.length = 0;

    // Guest disconnects mid-match
    guest.ws.close();
    const parked = await host.waitFor("peer_parked", 5_000);
    assert.ok(parked, "호스트가 peer_parked를 수신");

    // Guest reconnects with resume token
    const guest2 = new TestClient();
    await guest2.connect();
    await guest2.waitFor("welcome");
    guest2.send({ t: "hello", name: "E2E-G4", mode: "classic", resume: guestResume, wantResume: true });

    const resumeMsg = await guest2.waitFor("resume", 5_000);
    assert.equal(resumeMsg.playing, true, "resume 메시지에 playing:true");

    // Host should receive peer_reclaimed
    const reclaimed = await host.waitFor("peer_reclaimed", 5_000);
    assert.ok(reclaimed, "호스트가 peer_reclaimed를 수신");

    host.close();
    guest2.close();
  });
});
