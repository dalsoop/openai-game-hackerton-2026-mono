import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { WebSocket } from "ws";

const SERVER = process.env.TEST_SERVER || "wss://server-yjh-dev1.external.kr/gang-up";
const TIMEOUT = 10000;

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
      const timer = setTimeout(() => { cleanup(); reject(new Error(`timeout "${type}"`)); }, ms);
      const handler = (msg: Msg) => { if (msg.t === type) { cleanup(); resolve(msg); } };
      const cleanup = () => { clearTimeout(timer); this.listeners = this.listeners.filter((f) => f !== handler); };
      this.listeners.push(handler);
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
  // Clear inbox
  host.inbox.length = 0;
  guest.inbox.length = 0;
  return { host, guest, roomId };
}

describe("1. 접속·방 생성·입장", () => {
  it("두 클라이언트가 방에 입장합니다", async () => {
    const { host, guest } = await setupPair("H1", "G1");
    // Both are in the room — verify by requesting rooms
    host.send({ t: "rooms" });
    const rooms = await host.waitFor("rooms");
    assert.ok(Array.isArray(rooms.rooms));
    host.close(); guest.close();
  });
});

describe("2. 매치 시작 — host 플래그", () => {
  it("호스트는 host:true, 게스트는 host:false를 받습니다", async () => {
    const { host, guest } = await setupPair("H2", "G2");
    host.send({ t: "start" });
    const s1 = await host.waitFor("start");
    const s2 = await guest.waitFor("start");
    assert.equal(s1.host, true, "호스트는 host:true");
    assert.equal(s2.host, false, "게스트는 host:false");
    host.close(); guest.close();
  });
});

describe("3. 스냅샷 중계", () => {
  it("호스트의 host_snap이 게스트에게 snap으로 중계됩니다", async () => {
    const { host, guest } = await setupPair("H3", "G3");
    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    host.inbox.length = 0; guest.inbox.length = 0;

    host.send({ t: "host_snap", tick: 42, time: 2.1, result: "playing", winner: -1, heroes: [{ slot: 0, hp: 100 }] });
    const snap = await guest.waitFor("snap");
    assert.equal(snap.tick, 42);
    assert.equal(snap.result, "playing");
    host.close(); guest.close();
  });
});

describe("4. 입력 중계", () => {
  it("게스트 input → 호스트 peer_input으로 중계됩니다", async () => {
    const { host, guest } = await setupPair("H4", "G4");
    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    host.inbox.length = 0;

    guest.send({ t: "input", mx: 1, my: -1, fire: true, aimX: 500, aimY: 300 });
    const pi = await host.waitFor("peer_input");
    assert.equal(pi.mx, 1);
    assert.equal(pi.fire, true);
    assert.equal(typeof pi.slot, "number");
    host.close(); guest.close();
  });

  it("호스트 자신의 input은 peer_input으로 오지 않습니다", async () => {
    const { host, guest } = await setupPair("H4b", "G4b");
    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    host.inbox.length = 0;

    host.send({ t: "input", mx: 0, my: 1, fire: false, aimX: 800, aimY: 450 });
    await wait(1500);
    const found = host.inbox.some((m) => m.t === "peer_input");
    assert.equal(found, false, "호스트는 자신의 input을 peer_input으로 받으면 안 됩니다");
    host.close(); guest.close();
  });
});

describe("5. 게임 종료", () => {
  it("game over snap 후 로비로 복귀합니다", async () => {
    const { host, guest } = await setupPair("H5", "G5");
    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    guest.inbox.length = 0;

    host.send({ t: "host_snap", tick: 999, time: 60, result: "won", winner: 0, heroes: [] });
    const snap = await guest.waitFor("snap");
    assert.equal(snap.result, "won");

    // Wait for resetToLobby (5s + margin)
    const msg = await Promise.race([
      guest.waitFor("lobby", 8000),
      guest.waitFor("peers", 8000),
    ]).catch(() => null);
    assert.ok(msg, "로비 복귀 메시지를 받아야 합니다");
    host.close(); guest.close();
  });
});

describe("6. 보안", () => {
  it("비호스트의 host_snap은 무시됩니다", async () => {
    const { host, guest } = await setupPair("H6", "G6");
    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    host.inbox.length = 0;

    // guest pretends to be host
    guest.send({ t: "host_snap", tick: 1, result: "playing", heroes: [] });
    await wait(1500);
    const leaked = host.inbox.some((m) => m.t === "snap");
    assert.equal(leaked, false, "비호스트의 host_snap은 무시됩니다");
    host.close(); guest.close();
  });
});
