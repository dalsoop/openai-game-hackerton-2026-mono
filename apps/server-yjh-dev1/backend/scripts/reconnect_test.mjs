import { WebSocket } from "ws";

if (!process.env.GANG_UP_WS) throw new Error("missing env: GANG_UP_WS");
const URL = process.env.GANG_UP_WS;

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function until(pred, ms, label) {
  const start = Date.now();
  while (Date.now() - start < ms) {
    if (pred()) return true;
    await wait(20);
  }
  throw new Error(`timeout: ${label}`);
}

function connect(name, resume = "") {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(URL);
    const state = {
      ws,
      name,
      resume: "",
      id: "",
      room: null,
      you: -1,
      players: [],
      snaps: 0,
      lastSnap: null,
      started: false,
      resumed: false,
      error: "",
      dropped: false,
      notice: "",
    };
    ws.on("message", (raw) => {
      const msg = JSON.parse(String(raw));
      if (msg.t === "welcome") {
        state.id = msg.id;
        state.resume = msg.resume;
      }
      if (msg.t === "joined") {
        state.room = msg.room;
        state.you = msg.you;
        state.players = msg.players;
      }
      if (msg.t === "peers") {
        state.players = msg.players;
        if (msg.room) state.room = msg.room;
        if (msg.notice) state.notice = msg.notice;
      }
      if (msg.t === "start") state.started = true;
      if (msg.t === "resume") {
        state.resumed = true;
        state.you = msg.you;
        state.room = msg.room;
        state.players = msg.players;
        state.started = Boolean(msg.playing);
        if (msg.snap) state.lastSnap = msg.snap;
      }
      if (msg.t === "snap") {
        state.snaps += 1;
        state.lastSnap = msg;
      }
      if (msg.t === "error") state.error = msg.msg;
      if (msg.t === "dropped") state.dropped = true;
    });
    ws.on("open", () => {
      const hello = { t: "hello", name, mode: "classic", wantResume: Boolean(resume) };
      if (resume) hello.resume = resume;
      ws.send(JSON.stringify(hello));
      resolve(state);
    });
    ws.on("error", reject);
  });
}

function send(c, msg) {
  c.ws.send(JSON.stringify(msg));
}

function assert(ok, label) {
  if (!ok) throw new Error(label);
}

const host = await connect("호스트");
await wait(50);
send(host, { t: "create", title: "재접속방" });
await until(() => host.room, 4000, "create");
const guest = await connect("게스트");
send(guest, { t: "join", roomId: host.room.id });
await until(() => guest.room, 4000, "join");
const resume = guest.resume;
guest.ws.close();
await until(() => host.players.some((p) => p.dropped), 4000, "guest parked");
assert(host.players.length === 2, "seat kept");
const back = await connect("게스트", resume);
await until(() => back.resumed || back.room, 4000, "guest resume");
assert(back.resumed || back.you === 1, "reclaimed slot");
await until(() => host.players.every((p) => !p.dropped), 4000, "drop cleared");
send(host, { t: "start" });
await until(() => host.started && (back.started || back.snaps > 0), 4000, "start");
host.ws.close();
await wait(300);
assert(back.snaps > 0, "match continues after host blip");
back.ws.close();
console.log(JSON.stringify({ ok: true, resume: true, park: true }));
process.exit(0);
