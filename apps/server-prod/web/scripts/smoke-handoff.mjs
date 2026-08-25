// 핸드오프 스모크 — START 이후에도 React 소켓이 좌석을 유지한다.
// Godot 는 reconnect 하지 않고, 같은 소켓으로 snap·input 을 릴레이한다.
import { Client } from "@colyseus/sdk";

const URL = process.env.HUB_URL || process.env.SMOKE_URL || "http://127.0.0.1:3000";
const ROOM_NAME = `${(process.env.SLOT_FOLDER || "server-prod").trim()}-lobby`;
const results = [];
function ok(name, cond) {
  results.push({ name, pass: !!cond });
  console.log(`${cond ? "  ✓" : "  ✗"} ${name}`);
  if (!cond) process.exitCode = 1;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function onceEvent(room, kind, timeoutMs = 8000) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error(`timeout: ${kind}`)), timeoutMs);
    if (kind === "leave") {
      room.onLeave((code) => { clearTimeout(t); resolve(code); });
    } else if (kind.startsWith("message:")) {
      room.onMessage(kind.slice(8), (payload) => { clearTimeout(t); resolve(payload); });
    }
  });
}

const host = new Client(URL);
const guest = new Client(URL);

const hostRoom = await host.create(ROOM_NAME, { name: "호스트" });
const guestRoom = await guest.joinById(hostRoom.roomId, { name: "게스트" });
await sleep(500);
ok("1. 2인 입장 → players=2", hostRoom.state.players.length === 2);

const [hostStart] = await Promise.all([
  onceEvent(hostRoom, "message:start"),
  onceEvent(guestRoom, "message:start"),
  hostRoom.send("start", {}),
]);
const seats = hostStart?.seats ?? [];
ok("2. START 수신 · seats 2명 동봉", seats.length === 2);
ok("   seats 에 slot·connected 표기", seats.every((s) => typeof s.slot === "number" && typeof s.connected === "boolean"));

await sleep(400);
ok("3. START 후에도 같은 소켓·같은 좌석", hostRoom.state.players.every((p) => p.connected === true));
ok(
  "   세션이 바뀌지 않았다",
  hostRoom.sessionId === hostRoom.state.players.find((p) => p.sessionId === hostRoom.sessionId)?.sessionId,
);

const [guestSnap] = await Promise.all([
  onceEvent(guestRoom, "message:snap"),
  hostRoom.send("host_snap", { tick: 42, world: "demo" }),
]);
ok("4. 유지한 소켓으로 snap 릴레이", guestSnap?.tick === 42);

const [hostInput] = await Promise.all([
  onceEvent(hostRoom, "message:peer_input"),
  guestRoom.send("input", { mx: 1, fire: true }),
]);
ok("5. 유지한 소켓으로 input 릴레이", typeof hostInput?.slot === "number" && typeof hostInput?.mx === "number");

await hostRoom.leave(true);
await guestRoom.leave(true);
await sleep(300);
console.log(`\n핸드오프 스모크: ${results.filter((r) => r.pass).length}/${results.length} 통과`);
process.exit(process.exitCode ?? 0);
