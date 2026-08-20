import { motionJumps, playerAt, snapGaps, stats } from "../lib/metrics.mjs";
import {
  createRoom,
  defaultWsUrl,
  drainSnaps,
  driveInput,
  fetchHealth,
  hello,
  joinRoom,
  leave,
  openSocket,
  sleep,
  startMatch,
  waitMsg,
} from "../lib/hub.mjs";

export async function runSmoke(opts) {
  const url = opts.url || defaultWsUrl();
  const holdMs = Number(opts.hold || 2200);
  const checks = [];
  const sockets = [];
  const record = (name, ok, detail = "") => {
    checks.push({ name, ok, detail });
    const mark = ok ? "PASS" : "FAIL";
    console.log(`  [${mark}] ${name}${detail ? ` — ${detail}` : ""}`);
  };

  console.log(`smoke ${url}`);

  try {
    const health = await fetchHealth(url);
    record(
      "health",
      health.ok && health.body?.ok === true,
      `HTTP ${health.status} rooms=${health.body?.rooms ?? "?"}`,
    );

    const host = await openSocket(url);
    sockets.push(host);
    const welcome = await hello(host, "스모크A");
    record("welcome+hello", Boolean(welcome?.id && welcome?.resume), `id=${welcome.id}`);

    const joined = await createRoom(host, "스모크방");
    const roomId = joined.room?.id;
    record("create", Boolean(roomId) && joined.you === 0, `room=${roomId} you=${joined.you}`);

    const guest = await openSocket(url);
    sockets.push(guest);
    await hello(guest, "스모크B");
    const guestJoin = await joinRoom(guest, roomId);
    record("join", guestJoin.t === "joined" && guestJoin.you === 1, guestJoin.msg || `you=${guestJoin.you}`);

    const started = await startMatch(host);
    await waitStart(guest);
    record("start", started.t === "start", `you=${started.you}`);

    const hostSeq = await driveInput(host, holdMs);
    await sleep(80);
    const snaps = drainSnaps(host);
    record("snap 수신", snaps.length >= 8, `${snaps.length}개 / ${holdMs}ms`);

    const last = snaps.at(-1)?.snap;
    const players = last?.players || [];
    const humans = players.filter((p) => !p.cpu);
    const cpus = players.filter((p) => p.cpu);
    record("8인 스냅(빈 자리 CPU)", players.length === 8, `human=${humans.length} cpu=${cpus.length}`);

    const { gaps, ticks } = snapGaps(snaps);
    const gap = stats(gaps);
    const tick = stats(ticks);
    const gapOk = gap.n > 0 && gap.mean >= 35 && gap.mean <= 95 && gap.p95 <= 160;
    record("snap 간격 ~50ms", gapOk, `mean=${gap.mean} p95=${gap.p95} tick.mean=${tick.mean}`);

    const hostSlot = started.you ?? 0;
    const acks = snaps.map((s) => playerAt(s.snap, hostSlot)?.ack ?? 0);
    const ackGrew = acks.length >= 2 && acks[acks.length - 1] > acks[0] && acks[acks.length - 1] > 0;
    record("ack 증가", ackGrew, `${acks[0] ?? 0} → ${acks.at(-1) ?? 0} (sent seq=${hostSeq})`);

    const motion = motionJumps(snaps, hostSlot, 100);
    const raw = stats(motion.raw);
    const interp = stats(motion.interp);
    const smoother =
      interp.n > 10 &&
      raw.n > 10 &&
      (interp.mean < raw.mean * 0.9 || interp.stdev < raw.stdev * 0.55);
    record(
      "보간 점프 < 원시 텔레포트",
      smoother,
      `raw mean=${raw.mean} stdev=${raw.stdev} | interp mean=${interp.mean} stdev=${interp.stdev}`,
    );

    leave(guest);
    leave(host);
    record("leave", true, "소켓 종료");
  } catch (err) {
    record("예외 없이 종료", false, String(err.message || err));
  } finally {
    for (const ws of sockets) {
      try {
        ws.close();
      } catch {
        /* ignore */
      }
    }
  }

  const failed = checks.filter((c) => !c.ok);
  const report = {
    kind: "smoke",
    url,
    at: new Date().toISOString(),
    ok: failed.length === 0,
    failed: failed.length,
    checks,
  };
  return report;
}

async function waitStart(ws) {
  try {
    await waitMsg(ws, (m) => m.t === "start", 5000);
  } catch {
    /* host start is enough */
  }
}
