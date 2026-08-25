#!/usr/bin/env node
// Colyseus 허브 스모크 — 실왕복 없으면 실패.
// 전제: 서버 실행 중 (기본 http://127.0.0.1:3000). HUB_URL 로 재지정.
import { Client } from "@colyseus/sdk";

const BASE = process.env.HUB_URL || "http://127.0.0.1:3000";
const ROOM_NAME = `${(process.env.SLOT_FOLDER || "server-yjh-dev1").trim()}-lobby`;
const STEP_MS = 6000;
let passed = 0;
const step = (name) => console.log(`  ✓ ${++passed}. ${name}`);
const fail = (name, extra = "") => {
  console.error(`  ✗ FAIL: ${name}${extra ? " — " + extra : ""}`);
  process.exit(1);
};

// 서버 state 가 조건을 만족할 때까지 폴링한다.
async function waitState(room, pred, label) {
  const start = Date.now();
  while (Date.now() - start < STEP_MS) {
    if (pred(room.state)) return;
    await new Promise((r) => setTimeout(r, 100));
  }
  fail(label, "state 조건 미충족");
}

function waitMsg(room, type, label) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`${label}: "${type}" 미수신`)), STEP_MS);
    room.onMessage(type, (payload) => { clearTimeout(timer); resolve(payload); });
  });
}

try {
  const a = new Client(BASE);
  const b = new Client(BASE);

  // 1. A 방 생성 → state 에 본인 등장 (매치메이킹+WS+state 동기화 왕복)
  const roomA = await a.create(ROOM_NAME, { name: "스모크A" });
  await waitState(roomA, (s) => s.players?.length === 1, "A create");
  step(`A create → state.players=1 (room=${roomA.roomId})`);

  // 2. B join → 양쪽 state 에 2명
  const roomB = await b.joinById(roomA.roomId, { name: "스모크B" });
  await waitState(roomA, (s) => s.players.length === 2, "A 2인 동기화");
  await waitState(roomB, (s) => s.players.length === 2, "B 2인 동기화");
  step("B joinById → 양쪽 state.players=2");

  // 3. 호스트 start → start 메시지(슬롯·시드) + phase=playing
  const startA = waitMsg(roomA, "start", "A");
  const startB = waitMsg(roomB, "start", "B");
  roomA.send("start", {});
  const [sa, sb] = await Promise.all([startA, startB]);
  if (!sa.host || sb.host || typeof sa.seed !== "number") fail("start", JSON.stringify({ sa, sb }));
  await waitState(roomB, (s) => s.phase === "playing", "phase 전환");
  step("start → host/seed 정확, state.phase=playing");

  // 4. 호스트 snap → 게스트 수신 (릴레이)
  const snapB = waitMsg(roomB, "snap", "B");
  roomA.send("host_snap", { tick: 1, result: "playing" });
  if ((await snapB).tick !== 1) fail("snap 릴레이");
  step("host_snap → 게스트 snap 수신");

  // 5. 게스트 input → 호스트 peer_input (슬롯 태깅) — Godot 브릿지와 동일 경로
  const inputA = waitMsg(roomA, "peer_input", "A");
  roomB.send("input", { mx: 1, seq: 7 });
  const pin = await inputA;
  if (pin.seq !== 7 || pin.slot !== 1) fail("peer_input", JSON.stringify(pin));
  step("input → 호스트 peer_input (slot=1)");

  // 6. 게스트 강제 단절 → SDK 자동 재접속으로 같은 좌석 복귀 (allowReconnection 검증)
  // (SDK 보호: 방 가동 5초 미만이면 재접속 거부 — 충족될 때까지 대기)
  await new Promise((r) => setTimeout(r, 5200));
  roomB.connection.close();
  await new Promise((r) => setTimeout(r, 1500));
  await waitState(roomB, (s) => s.players?.length === 2 && s.phase === "playing", "자동 재접속 후 state");
  const snapB2 = waitMsg(roomB, "snap", "B(재접속)");
  roomA.send("host_snap", { tick: 2, result: "playing" });
  if ((await snapB2).tick !== 2) fail("재접속 후 snap");
  step("강제 단절 → SDK 자동 재접속 → 같은 좌석에서 snap 계속 수신");

  await roomA.leave(true);
  await roomB.leave(true);

  console.log(`\nsmoke-hub: ${passed}/6 통과 — Colyseus 허브 실왕복 정상`);
  process.exit(0);
} catch (e) {
  fail("스모크 실행", e.message);
}
