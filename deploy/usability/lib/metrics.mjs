export function stats(arr) {
  if (!arr.length) {
    return { n: 0, min: 0, p50: 0, p95: 0, max: 0, mean: 0, stdev: 0 };
  }
  const s = [...arr].sort((a, b) => a - b);
  const mean = s.reduce((a, b) => a + b, 0) / s.length;
  const variance = s.reduce((a, b) => a + (b - mean) ** 2, 0) / s.length;
  return {
    n: s.length,
    min: round(s[0]),
    p50: round(s[Math.floor(s.length * 0.5)]),
    p95: round(s[Math.min(s.length - 1, Math.floor(s.length * 0.95))]),
    max: round(s[s.length - 1]),
    mean: round(mean),
    stdev: round(Math.sqrt(variance)),
  };
}

function round(n) {
  return Number(n.toFixed(3));
}

export function playerAt(snap, slot) {
  return (snap?.players || []).find((p) => p.slot === slot) || null;
}

export function lerpSlot(buf, now, delayMs, slot) {
  if (buf.length === 0) return null;
  if (buf.length === 1) return playerAt(buf[0].snap, slot);
  const renderAt = now - delayMs;
  let a = buf[0];
  let b = buf[buf.length - 1];
  for (let i = 0; i < buf.length - 1; i++) {
    if (buf[i + 1].at >= renderAt) {
      a = buf[i];
      b = buf[i + 1];
      break;
    }
  }
  const pa = playerAt(a.snap, slot);
  const pb = playerAt(b.snap, slot);
  if (!pa || !pb) return pb || pa;
  const span = Math.max(1, b.at - a.at);
  const t = Math.max(0, Math.min(1, (renderAt - a.at) / span));
  return {
    x: pa.x + (pb.x - pa.x) * t,
    y: pa.y + (pb.y - pa.y) * t,
  };
}

export function motionJumps(snaps, slot, delayMs = 100) {
  if (snaps.length < 3) {
    return { raw: [], interp: [], snapToSnap: [] };
  }
  const snapToSnap = [];
  for (let i = 1; i < snaps.length; i++) {
    const p0 = playerAt(snaps[i - 1].snap, slot);
    const p1 = playerAt(snaps[i].snap, slot);
    if (p0 && p1) snapToSnap.push(Math.hypot(p1.x - p0.x, p1.y - p0.y));
  }
  const start = snaps[0].at;
  const end = snaps[snaps.length - 1].at;
  const raw = [];
  const interp = [];
  let lastRaw = null;
  let lastInterp = null;
  for (let t = start + 150; t < end; t += 16.67) {
    let latest = snaps[0];
    for (const s of snaps) {
      if (s.at <= t) latest = s;
      else break;
    }
    const rawP = playerAt(latest.snap, slot);
    const interpP = lerpSlot(
      snaps.filter((s) => s.at <= t + 0.5),
      t,
      delayMs,
      slot,
    );
    if (rawP && lastRaw) raw.push(Math.hypot(rawP.x - lastRaw.x, rawP.y - lastRaw.y));
    if (interpP && lastInterp) interp.push(Math.hypot(interpP.x - lastInterp.x, interpP.y - lastInterp.y));
    lastRaw = rawP;
    lastInterp = interpP;
  }
  return { raw, interp, snapToSnap };
}

export function snapGaps(snaps) {
  const gaps = [];
  const ticks = [];
  for (let i = 1; i < snaps.length; i++) {
    gaps.push(snaps[i].at - snaps[i - 1].at);
    ticks.push((snaps[i].snap.tick ?? 0) - (snaps[i - 1].snap.tick ?? 0));
  }
  return { gaps, ticks };
}
