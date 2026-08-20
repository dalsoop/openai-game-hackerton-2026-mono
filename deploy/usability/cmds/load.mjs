import { snapGaps, stats } from "../lib/metrics.mjs";
import {
  createRoom,
  defaultWsUrl,
  drainSnaps,
  driveInput,
  fetchHealth,
  hello,
  isProdUrl,
  joinRoom,
  leave,
  openSocket,
  sleep,
  startMatch,
} from "../lib/hub.mjs";

const SAFE_ROOMS = 3;
const SAFE_PLAYERS = 3;
const SAFE_SECONDS = 8;

export function planLoad(opts) {
  const url = opts.url || defaultWsUrl();
  const rooms = clampInt(opts.rooms, 1, 32, 2);
  const players = clampInt(opts.players, 1, 8, 2);
  const seconds = clampInt(opts.seconds, 1, 120, 6);
  const force = Boolean(opts.force);
  const allowProd = Boolean(opts["allow-prod"]);
  const dryRun = Boolean(opts["dry-run"]);
  const sockets = rooms * players;
  const warnings = [];
  if (isProdUrl(url) && !allowProd) {
    warnings.push("prod URL은 --allow-prod 없이는 실행하지 않습니다.");
  }
  if ((rooms > SAFE_ROOMS || players > SAFE_PLAYERS || seconds > SAFE_SECONDS) && !force) {
    warnings.push(
      `기본 한도는 rooms<=${SAFE_ROOMS}, players<=${SAFE_PLAYERS}, seconds<=${SAFE_SECONDS}입니다. 더 크게 하려면 --force를 붙입니다.`,
    );
  }
  return {
    url,
    rooms,
    players,
    seconds,
    sockets,
    force,
    allowProd,
    dryRun,
    blocked: warnings.length > 0 && !dryRun,
    warnings,
  };
}

export async function runLoad(opts) {
  const plan = planLoad(opts);
  console.log("load plan");
  console.log(JSON.stringify({ ...plan, warnings: plan.warnings }, null, 2));
  if (plan.dryRun) {
    return { kind: "load", at: new Date().toISOString(), ok: true, dryRun: true, plan };
  }
  if (plan.blocked) {
    return {
      kind: "load",
      at: new Date().toISOString(),
      ok: false,
      blocked: true,
      plan,
      error: plan.warnings.join(" "),
    };
  }

  const health = await fetchHealth(plan.url);
  if (!health.ok) {
    return { kind: "load", ok: false, error: `health HTTP ${health.status}`, plan };
  }

  const started = performance.now();
  const rooms = await Promise.all(
    Array.from({ length: plan.rooms }, (_, i) => runRoom(plan, i).catch((err) => ({
      roomIndex: i,
      ok: false,
      error: String(err.message || err),
    }))),
  );
  const elapsed = performance.now() - started;
  const gaps = rooms.flatMap((r) => r.gaps || []);
  const errors = rooms.filter((r) => !r.ok);
  const report = {
    kind: "load",
    at: new Date().toISOString(),
    url: plan.url,
    plan,
    ok: errors.length === 0,
    elapsedMs: Math.round(elapsed),
    roomsOk: rooms.filter((r) => r.ok).length,
    roomsFail: errors.length,
    snapGap: stats(gaps),
    rooms: rooms.map(({ gaps: _gaps, ...room }) => room),
  };
  console.log(
    `load ${report.ok ? "OK" : "FAIL"} rooms ${report.roomsOk}/${plan.rooms} snapGap.p95=${report.snapGap.p95}ms`,
  );
  return report;
}

async function runRoom(plan, roomIndex) {
  const sockets = [];
  try {
    const host = await openSocket(plan.url);
    sockets.push(host);
    await hello(host, `L${roomIndex}H`);
    const joined = await createRoom(host, `부하${roomIndex}`);
    const roomId = joined.room.id;
    for (let i = 1; i < plan.players; i++) {
      const guest = await openSocket(plan.url);
      sockets.push(guest);
      await hello(guest, `L${roomIndex}G${i}`);
      const res = await joinRoom(guest, roomId);
      if (res.t === "error") throw new Error(res.msg || "join 실패");
    }
    await startMatch(host);
    await Promise.all(sockets.map((ws) => driveInput(ws, plan.seconds * 1000)));
    await sleep(50);
    const snaps = drainSnaps(host);
    const { gaps } = snapGaps(snaps);
    for (const ws of sockets) leave(ws);
    const gap = stats(gaps);
    return {
      roomIndex,
      roomId,
      ok: snaps.length >= Math.max(4, plan.seconds * 8),
      players: plan.players,
      snaps: snaps.length,
      snapGap: gap,
      gaps, // flattened for aggregate, stripped before write
    };
  } finally {
    for (const ws of sockets) {
      try {
        ws.close();
      } catch {
        /* ignore */
      }
    }
  }
}

function clampInt(value, min, max, fallback) {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, Math.round(n)));
}
