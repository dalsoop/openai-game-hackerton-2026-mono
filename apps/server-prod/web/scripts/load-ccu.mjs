#!/usr/bin/env node
// 목록 폴링 → 방 생성·입장 → 스냅 릴레이를 단계로 불어 프로세스당 CCU 감을 본다.
// 전제: 허브 실행 중. HUB_URL, LIST_N, ROOMS, SNAP_N 으로 조절.
import { Client } from "@colyseus/sdk";

const BASE = process.env.HUB_URL || "http://127.0.0.1:3100";
const SLOT = (process.env.SLOT_FOLDER || "server-prod").trim();
const ROOM_NAME = `${SLOT}-lobby`;
const LIST_N = Number(process.env.LIST_N || 40);
const ROOMS = Number(process.env.ROOMS || 4);
const SNAP_N = Number(process.env.SNAP_N || 30);
const PER = Number(process.env.PER_PROCESS_CCU || 500);
const TARGET = Number(process.env.TARGET_CCU || 10_000);

function replicaCount(target, per) {
  return Math.max(1, Math.ceil(Math.max(0, target) / Math.max(1, per)));
}

const now = () => performance.now();
const ms = (t0) => Math.round(performance.now() - t0);

try {
  const client = new Client(BASE);

  const tList = now();
  for (let i = 0; i < LIST_N; i++) {
    const res = await fetch(`${BASE}/rooms`, { cache: "no-store" });
    if (!res.ok) {throw new Error(`rooms ${res.status}`);}
    await res.json();
  }
  const listMs = ms(tList);
  console.log(`1. 목록 ${LIST_N}회  ${listMs}ms  (평균 ${(listMs / LIST_N).toFixed(1)}ms)`);

  const hosts = [];
  const guests = [];
  const tJoin = now();
  for (let i = 0; i < ROOMS; i++) {
    const host = await client.create(ROOM_NAME, { name: `부하호스트${i}` });
    const guest = await new Client(BASE).joinById(host.roomId, { name: `부하게스트${i}` });
    hosts.push(host);
    guests.push(guest);
  }
  const joinMs = ms(tJoin);
  console.log(`2. 방 ${ROOMS}개 생성+입장  ${joinMs}ms`);

  const tSnap = now();
  let sent = 0;
  for (const host of hosts) {
    for (let i = 0; i < SNAP_N; i++) {
      host.send("input", { mx: (i % 3) - 1, my: 0, seq: i });
      sent += 1;
    }
  }
  const snapMs = ms(tSnap);
  console.log(`3. 스냅 ${sent}개 송신  ${snapMs}ms`);

  await Promise.all([...hosts, ...guests].map((r) => r.leave()));

  const suggested = replicaCount(TARGET, PER);
  console.log(`권장 복제: ceil(${TARGET}/${PER}) = ${suggested}`);
  console.log(`차트 hub.scale.replicaCount 는 ${suggested} 와 같아야 합니다.`);
} catch (err) {
  console.error(err);
  process.exit(1);
}
