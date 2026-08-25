// 핸드오프 스모크 — 새 아키텍처(공식 Godot SDK reconnect)의 페이지 측 계약 검증.
// 시나리오: 호스트+게스트 2인 입장 → START 수신 → 양쪽 의도적 leave(false)
// → 각자 reconnect(token) 으로 같은 세션·좌석 승계 → snap 릴레이 지속.
// Godot 가 하는 일을 SDK 로 동일하게 재현한다(브라우저 E2E 의 서버측 등가).
import { Client } from "@colyseus/sdk";

const URL = process.env.SMOKE_URL || "http://127.0.0.1:3000";
const results = [];
function ok(name, cond) {
  results.push({ name, pass: !!cond });
  console.log(`${cond ? "  ✓" : "  ✗"} ${name}`);
  if (!cond) process.exitCode = 1;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
// SDK 0.17 Room 은 onXXX(callback) 등록 방식 — 폴링형 수신기로 감싼다.
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

// 1. 입장
const hostRoom = await host.create("lobby", { name: "호스트" });
const guestRoom = await guest.joinById(hostRoom.roomId, { name: "게스트" });
await sleep(500);
ok("1. 2인 입장 → players=2", hostRoom.state.players.length === 2);

// 2. 시작 — 양쪽 START 수신 (seats 동봉 확인)
const [hostStart, guestStart] = await Promise.all([
  onceEvent(hostRoom, "message:start"),
  onceEvent(guestRoom, "message:start"),
  hostRoom.send("start", {}),
]);
const seats = hostStart?.seats ?? [];
ok("2. START 수신 · seats 2명 동봉", seats.length === 2);
ok("   seats 에 slot·connected 표기", seats.every((s) => typeof s.slot === "number" && typeof s.connected === "boolean"));

// 3. 핸드오프 — 양쪽 의도적 leave(false) (consent 없이)
const hostToken = hostRoom.reconnectionToken;
const guestToken = guestRoom.reconnectionToken;
const [hostLeft] = await Promise.all([
  onceEvent(hostRoom, "leave"),
  onceEvent(guestRoom, "leave"),
  hostRoom.leave(false),
  guestRoom.leave(false),
]);
ok("3. leave(false) → close 코드 1000 아님(유예 대상)", hostLeft !== 1000);

// 4. 재승계 — Godot 역할: reconnect(token) 로 같은 세션·좌석
await sleep(700); // 유예 안에서 재접속
const hostRoom2 = await host.reconnect(hostToken);
const guestRoom2 = await guest.reconnect(guestToken);
await sleep(500);
ok("4. 재접속 → players=2 유지", hostRoom2.state.players.length === 2);
ok(
  "   같은 세션·같은 좌석",
  hostRoom2.sessionId === hostRoom.sessionId &&
    guestRoom2.sessionId === guestRoom.sessionId &&
    hostRoom2.state.players.find((p) => p.sessionId === hostRoom.sessionId)?.slot ===
      hostRoom.state.players.find((p) => p.sessionId === hostRoom.sessionId)?.slot,
);
ok("   connected 복귀", hostRoom2.state.players.every((p) => p.connected === true));

// 5. 멀티플레이 릴레이 지속 — 호스트 snap → 게스트 수신
const [guestSnap] = await Promise.all([
  onceEvent(guestRoom2, "message:snap"),
  hostRoom2.send("host_snap", { tick: 42, world: "demo" }),
]);
ok("5. 승계 후 snap 릴레이 지속", guestSnap?.tick === 42);

// 6. 게스트 인풋 → 호스트 수신 (slot 태깅)
const [hostInput] = await Promise.all([
  onceEvent(hostRoom2, "message:peer_input"),
  guestRoom2.send("input", { mx: 1, fire: true }),
]);
ok("6. 승계 후 input 릴레이 지속", typeof hostInput?.slot === "number" && typeof hostInput?.mx === "number");

await hostRoom2.leave(true);
await guestRoom2.leave(true);
await sleep(300);
console.log(`\n핸드오프 스모크: ${results.filter((r) => r.pass).length}/${results.length} 통과`);
process.exit(process.exitCode ?? 0);
