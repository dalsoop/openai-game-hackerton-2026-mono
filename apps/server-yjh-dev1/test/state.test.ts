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

async function makeClient(name: string): Promise<TestClient> {
  const c = new TestClient();
  await c.connect();
  await c.waitFor("welcome");
  c.send({ t: "hello", name, mode: "classic" });
  await wait(200);
  return c;
}

async function setupPair(hostName: string, guestName: string): Promise<{ host: TestClient; guest: TestClient; roomId: string }> {
  const host = await makeClient(hostName);
  const guest = await makeClient(guestName);
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

// --- Tests ---

describe("1. 빈 방 — 만들고 나가면 rooms에서 사라짐", () => {
  it("혼자 방을 만들고 leave하면 rooms 목록에 해당 방이 없어야 함", async () => {
    const c = await makeClient("Solo");
    c.send({ t: "create" });
    const joined = await c.waitFor("joined");
    const roomId = (joined.room as Msg).id as string;

    c.send({ t: "leave" });
    await c.waitFor("left");
    await wait(300);

    c.inbox.length = 0;
    c.send({ t: "rooms" });
    const roomsMsg = await c.waitFor("rooms");
    const list = roomsMsg.rooms as Msg[];
    const found = list.some((r) => r.id === roomId);
    assert.equal(found, false, "나간 방은 rooms 목록에 없어야 합니다");
    c.close();
  });
});

describe("2. 가득 찬 방 — 9번째 join은 error", () => {
  it("8명이 찬 방에 9번째 클라이언트가 join하면 error를 받아야 함", async () => {
    const clients: TestClient[] = [];
    const host = await makeClient("Full-H");
    clients.push(host);

    host.send({ t: "create" });
    const joined = await host.waitFor("joined");
    const roomId = (joined.room as Msg).id as string;

    for (let i = 1; i <= 7; i++) {
      const g = await makeClient(`Full-G${i}`);
      clients.push(g);
      g.send({ t: "join", roomId });
      await g.waitFor("joined");
      await wait(100);
    }

    const ninth = await makeClient("Full-G8");
    clients.push(ninth);
    ninth.send({ t: "join", roomId });
    const err = await ninth.waitFor("error");
    assert.ok(err.msg, "9번째 클라이언트는 error를 받아야 합니다");

    for (const c of clients) c.close();
    ninth.close();
  });
});

describe("3. 킥 — 호스트가 게스트를 kick하면 kicked 메시지", () => {
  it("호스트가 kick을 보내면 게스트에게 kicked가 와야 함", async () => {
    const { host, guest } = await setupPair("KickH", "KickG");

    // guest는 slot 1
    host.send({ t: "kick", slot: 1 });
    const kicked = await guest.waitFor("kicked");
    assert.ok(kicked.msg, "게스트는 kicked 메시지를 받아야 합니다");

    host.close();
    guest.close();
  });
});

describe("4. 매치 중 게스트 나감 — 호스트에게 peer_parked", () => {
  it("게스트 ws.close() 시 호스트에게 peer_parked가 와야 함", async () => {
    const { host, guest } = await setupPair("ParkH", "ParkG");

    host.send({ t: "start" });
    await host.waitFor("start");
    await guest.waitFor("start");
    host.inbox.length = 0;

    guest.close();
    const parked = await host.waitFor("peer_parked");
    assert.equal(typeof parked.slot, "number", "peer_parked에 slot이 있어야 합니다");

    host.close();
  });
});

describe("5. 게스트 재접속 — resume 토큰으로 같은 슬롯 복귀", () => {
  it("resume 토큰으로 재접속하면 같은 슬롯을 받아야 함", async () => {
    const host = await makeClient("ResumeH");
    const guest = await makeClient("ResumeG");

    host.send({ t: "create" });
    const hostJoined = await host.waitFor("joined");
    const roomId = (hostJoined.room as Msg).id as string;

    guest.send({ t: "join", roomId });
    const guestJoined = await guest.waitFor("joined");
    const originalSlot = guestJoined.you as number;

    // guest의 welcome에서 resume 토큰 가져오기 — inbox에서 찾거나 재접속 시 활용
    // welcome 메시지는 이미 소비됐으므로, guest의 joined에서 id 확인
    // 새 클라이언트로 연결 후 hello에서 resume 토큰 전달
    // 실제로는 welcome 메시지의 resume 필드를 저장해야 함
    // makeClient가 welcome을 소비하므로 별도로 처리

    const guest2 = new TestClient();
    await guest2.connect();
    const welcome2 = await guest2.waitFor("welcome");
    const resumeToken = welcome2.resume as string;

    // 먼저 guest의 welcome에서 resume를 가져와야 하므로, 다른 방식으로 접근
    // guest를 닫고, 원래 guest의 resume 토큰이 필요
    // 수정: makeClient 대신 수동으로 연결하여 resume 토큰을 캡처

    guest2.close();

    // 재시도: guest 연결 시 resume 토큰을 캡처
    const guestFresh = new TestClient();
    await guestFresh.connect();
    const guestWelcome = await guestFresh.waitFor("welcome");
    const guestResume = guestWelcome.resume as string;
    guestFresh.send({ t: "hello", name: "ResumeG", mode: "classic" });
    await wait(200);

    guestFresh.send({ t: "join", roomId });
    const guestFreshJoined = await guestFresh.waitFor("joined");
    const freshSlot = guestFreshJoined.you as number;

    // start match
    host.send({ t: "start" });
    await host.waitFor("start");
    await guestFresh.waitFor("start");
    host.inbox.length = 0;

    // guest 연결 끊기
    guestFresh.ws.close();
    await host.waitFor("peer_parked");
    await wait(500);

    // resume 토큰으로 재접속
    const guestResumed = new TestClient();
    await guestResumed.connect();
    await guestResumed.waitFor("welcome");
    guestResumed.send({ t: "hello", name: "ResumeG", mode: "classic", resume: guestResume, wantResume: true });
    const resumeMsg = await guestResumed.waitFor("resume");
    assert.equal(resumeMsg.you, freshSlot, "재접속 시 같은 슬롯을 받아야 합니다");

    host.close();
    guest.close();
    guestResumed.close();
  });
});

describe("6. 중복 방 생성 — 이미 방에 있는 상태에서 create하면 이전 방을 나감", () => {
  it("방에 있는 상태에서 create하면 기존 방을 나가고 새 방이 만들어져야 함", async () => {
    const c = await makeClient("DupCreate");

    c.send({ t: "create" });
    const joined1 = await c.waitFor("joined");
    const room1Id = (joined1.room as Msg).id as string;

    c.inbox.length = 0;
    c.send({ t: "create" });
    const joined2 = await c.waitFor("joined");
    const room2Id = (joined2.room as Msg).id as string;

    assert.notEqual(room1Id, room2Id, "새로운 방 ID를 받아야 합니다");

    // 이전 방은 사라져야 함
    await wait(300);
    c.inbox.length = 0;
    c.send({ t: "rooms" });
    const roomsMsg = await c.waitFor("rooms");
    const list = roomsMsg.rooms as Msg[];
    const oldFound = list.some((r) => r.id === room1Id);
    assert.equal(oldFound, false, "이전 방은 rooms에서 사라져야 합니다");

    c.close();
  });
});

describe("7. 비호스트 start — 게스트가 start하면 error", () => {
  it("게스트가 start를 보내면 error를 받아야 함", async () => {
    const { host, guest } = await setupPair("StartH", "StartG");

    guest.send({ t: "start" });
    const err = await guest.waitFor("error");
    assert.ok(err.msg, "게스트는 error를 받아야 합니다");

    host.close();
    guest.close();
  });
});
