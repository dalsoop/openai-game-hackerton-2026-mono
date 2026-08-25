#!/usr/bin/env node
// 세션 재개 스모크 — 재접속 유예(대기실/플레이)와 token 재접속을 실왕복으로 검증.
// 전제: 서버 실행 중 (기본 http://127.0.0.1:3000). HUB_URL 로 재지정.
// 시나리오:
//   1. 방 생성(대기실) → 재접속 토큰 확보
//   2. 비의도 단절(1001 Going Away — 새로고침. 4000 은 동의 종료/강퇴)
//   3. 다른 클라이언트가 관측: 좌석이 "재접속 대기"(connected=false)로 유지된다
//   4. 새 클라이언트(=새로 고친 페이지) reconnect(token) → 같은 방·같은 좌석 복귀
//   5. 무효 토큰 reconnect → 거부된다 (유예 밖 세션은 재개 불가)
import { Client } from "@colyseus/sdk";

const BASE = process.env.HUB_URL || "http://127.0.0.1:3000";
const STEP_MS = 8000;
let passed = 0;
const step = (name) => console.log(`  ✓ ${++passed}. ${name}`);
const fail = (name, extra = "") => {
  console.error(`  ✗ FAIL: ${name}${extra ? " — " + extra : ""}`);
  process.exit(1);
};

async function waitFor(room, pred, label) {
  const start = Date.now();
  while (Date.now() - start < STEP_MS) {
    if (pred(room.state)) {return;}
    await new Promise((r) => setTimeout(r, 100));
  }
  fail(label, "state 조건 미충족");
}

function forceDrop(room) {
  // 비의도 단절: consent 없이 소켓을 닫는다(브라우저 새로고침과 동일 취급, code≠1000).
  const conn = room.connection ?? room["_connection"];
  const ws = conn?.websocket ?? conn?.ws ?? conn?.transport?.socket ?? conn?.socket;
  if (ws) { ws.close(1001, "simulate refresh"); } else { conn.close(); }
}

async function main() {
  const host = new Client(BASE);

  // 1. 방 생성 — 대기실 페이즈
  const room = await host.create("lobby", { name: "재개테스터" });
  const token = room.reconnectionToken;
  const roomId = room.roomId;
  step(`방 생성 (room=${roomId}, phase=lobby)`);

  // 2. 비의도 단절
  forceDrop(room);
  await new Promise((r) => setTimeout(r, 400));
  step("비의도 단절 (code=1001, 새로고침 시뮬레이션)");

  // 3. 관측자: 유예 안에서 좌석이 재접속 대기로 살아있는다
  const observer = new Client(BASE);
  const obs = await observer.joinById(roomId, { name: "관측자" });
  await new Promise((r) => { if (obs.state) {r(null);} else {obs.onStateChange(r);} });
  await waitFor(obs, (st) => (st?.players?.length ?? 0) === 2, "관측자 입장");
  await waitFor(
    obs,
    (st) => (st?.players ?? []).some((p) => p.name === "재개테스터" && !p.connected),
    "단절자 좌석이 재접속 대기로 유지",
  );
  step("대기실 유예 — 좌석 유지(connected=false) 관측");

  // 4. 새 클라이언트 재개 — 같은 방·같은 좌석
  const fresh = new Client(BASE);
  const resumed = await fresh.reconnect(token);
  if (resumed.roomId !== roomId) {fail("재개 방 불일치", `${resumed.roomId} ≠ ${roomId}`);}
  await new Promise((r) => { if (resumed.state) {r(null);} else {resumed.onStateChange(r);} });
  await waitFor(resumed, (st) => {
    const me = (st?.players ?? []).find((p) => p.name === "재개테스터");
    return me && me.connected;
  }, "재개 좌석 connected=true");
  step(`세션 재개 — 같은 방·같은 좌석 (room=${resumed.roomId})`);

  // 5. 무효 토큰 — 재개 거부
  let rejected = false;
  try {
    await new Client(BASE).reconnect("bogus-token-" + Date.now());
  } catch {
    rejected = true;
  }
  if (!rejected) {fail("무효 토큰 재개", "거부되지 않음");}
  step("무효 토큰 — 재개 거부 확인");

  await resumed.leave(true);
  await obs.leave(true);
  console.log("smoke-resume: 전 시나리오 통과");
  process.exit(0);
}

main().catch((e) => fail("예외", e.message));
