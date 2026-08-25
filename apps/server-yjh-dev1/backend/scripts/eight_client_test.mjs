import { WebSocket } from "ws";

if (!process.env.GANG_UP_WS) throw new Error("missing env: GANG_UP_WS");
const URL = process.env.GANG_UP_WS;

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function until(pred, ms = 5000, label = "until") {
  const start = Date.now();
  while (Date.now() - start < ms) {
    if (pred()) return true;
    await wait(20);
  }
  throw new Error(`timeout: ${label}`);
}

function connect(name) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(URL);
    const state = {
      ws,
      name,
      room: null,
      you: -1,
      players: [],
      snaps: 0,
      lastSnap: null,
      started: false,
      error: "",
    };
    ws.on("message", (raw) => {
      const msg = JSON.parse(String(raw));
      if (msg.t === "joined") {
        state.room = msg.room;
        state.you = msg.you;
        state.players = msg.players;
      }
      if (msg.t === "peers") {
        state.players = msg.players;
        if (msg.room) state.room = msg.room;
      }
      if (msg.t === "start") {
        state.started = true;
        state.you = msg.you;
        if (msg.room) state.room = msg.room;
      }
      if (msg.t === "snap") {
        state.snaps += 1;
        state.lastSnap = msg;
      }
      if (msg.t === "error") state.error = msg.msg;
    });
    ws.on("open", () => {
      ws.send(JSON.stringify({ t: "hello", name, mode: "classic" }));
      resolve(state);
    });
    ws.on("error", reject);
  });
}

function send(client, msg) {
  client.ws.send(JSON.stringify(msg));
}

function assert(ok, label) {
  if (!ok) throw new Error(label);
}

const humans = [];
for (let i = 0; i < 8; i++) humans.push(await connect(`사람${i + 1}`));
send(humans[0], { t: "create", title: "8인검증" });
await until(() => humans[0].room, 4000, "create");
const roomId = humans[0].room.id;
for (let i = 1; i < 8; i++) {
  send(humans[i], { t: "join", roomId });
  await until(() => humans[i].room, 4000, `join ${i}`);
}
await until(() => humans[0].players.length === 8, 4000, "host sees 8");
assert(humans.every((c) => c.players.length === 8), "everyone sees 8 members");
assert(humans[0].you === 0, "host slot 0");

const ninth = await connect("넘침");
send(ninth, { t: "join", roomId });
await until(() => ninth.error.includes("가득"), 4000, "9th rejected");

send(humans[3], { t: "mode", mode: "full" });
await wait(200);
assert(humans[0].room.mode === "classic", "guest cannot change mode");
send(humans[0], { t: "mode", mode: "full" });
await until(() => humans.every((c) => c.room?.mode === "full"), 4000, "host mode broadcast");

const t0 = Date.now();
send(humans[0], { t: "start" });
await until(() => humans.every((c) => c.started), 4000, "all start");
await until(() => humans[0].snaps >= 20, 4000, "snaps");
const elapsed = Date.now() - t0;
const snap = humans[0].lastSnap;
assert(snap.players.length === 8, "snap 8 players");
assert(snap.players.filter((p) => !p.cpu).length === 8, "8 humans no cpu");
assert(snap.mode === "full", "started as full");
const bytes = Buffer.byteLength(JSON.stringify(snap));
assert(bytes < 2500, `snap too fat: ${bytes}`);
for (const human of humans) {
  send(human, { t: "input", mx: 1, my: 0, fire: true, dash: false, use: false, aimX: 800, aimY: 450 });
}
await wait(400);
assert(humans[0].lastSnap.tick > snap.tick, "tick advances after input");

for (const human of humans) human.ws.close();
ninth.ws.close();
console.log(
  JSON.stringify({
    ok: true,
    members: 8,
    mode: "full",
    snaps: humans[0].snaps,
    snapBytes: bytes,
    startTo20snapsMs: elapsed,
    tickHzApprox: Math.round((humans[0].snaps / elapsed) * 1000),
  })
);
process.exit(0);
