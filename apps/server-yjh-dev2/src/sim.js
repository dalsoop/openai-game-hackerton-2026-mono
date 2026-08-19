import { ARENA, ITEMS, MAX_PLAYERS, MODES, TICK_HZ, UNIQUE_START, WEAPONS } from "./modes.js";

const DT = 1 / TICK_HZ;
const NAMES = ["토토", "쥐돌이", "호랭이", "소뿔이", "오리", "곰돌", "냥이", "늑대"];
const COLORS = ["#f4f1de", "#5bc0eb", "#e55934", "#fa7921", "#9bc53d", "#b084cc", "#ffe066", "#70e7ff"];

function dist(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.hypot(dx, dy);
}

function clampToIsland(p) {
  const dx = p.x - ARENA.cx;
  const dy = p.y - ARENA.cy;
  const len = Math.hypot(dx, dy);
  const max = ARENA.radius - 18;
  if (len > max) {
    p.x = ARENA.cx + (dx / len) * max;
    p.y = ARENA.cy + (dy / len) * max;
  }
}

export function createMatch(modeId, humans) {
  const mode = MODES[modeId];
  const players = [];
  for (let i = 0; i < MAX_PLAYERS; i++) {
    const angle = -Math.PI / 2 + (Math.PI * 2 * i) / MAX_PLAYERS;
    const human = humans[i] ?? null;
    const startId = mode.startWeapon === "unique" ? UNIQUE_START[i] : mode.startWeapon;
    players.push({
      slot: i,
      id: human?.id ?? `cpu-${i}`,
      name: human?.name ?? `${NAMES[i]} CPU`,
      cpu: !human,
      color: COLORS[i],
      x: ARENA.cx + Math.cos(angle) * 260,
      y: ARENA.cy + Math.sin(angle) * 260,
      aimX: ARENA.cx,
      aimY: ARENA.cy,
      hp: 100,
      alive: true,
      weapon: { ...WEAPONS[startId] },
      item: null,
      fireCd: 0,
      dashCd: 0,
      lastSeq: 0,
      kills: 0,
      input: { mx: 0, my: 0, fire: false, dash: false, use: false },
    });
  }
  return {
    modeId,
    mode,
    tick: 0,
    time: 0,
    result: "playing",
    winner: -1,
    zoneR: ARENA.radius,
    zoneTarget: 280,
    zoneWait: 8,
    shrinking: false,
    bullets: [],
    loot: [],
    players,
  };
}

export function applyInput(match, clientId, input) {
  const p = match.players.find((pl) => pl.id === clientId && !pl.cpu);
  if (!p || !p.alive) return;
  p.input = {
    mx: Math.max(-1, Math.min(1, Number(input.mx) || 0)),
    my: Math.max(-1, Math.min(1, Number(input.my) || 0)),
    fire: Boolean(input.fire),
    dash: Boolean(input.dash),
    use: Boolean(input.use),
    aimX: Number(input.aimX) || p.aimX,
    aimY: Number(input.aimY) || p.aimY,
  };
  const seq = Number(input.seq);
  if (Number.isFinite(seq) && seq > (p.lastSeq || 0)) p.lastSeq = seq;
}

function cpuThink(match, p) {
  const prey = match.players
    .filter((o) => o.alive && o.slot !== p.slot)
    .sort((a, b) => dist(a, p) - dist(b, p))[0];
  if (!prey) return;
  const dx = prey.x - p.x;
  const dy = prey.y - p.y;
  const d = Math.hypot(dx, dy) || 1;
  const preferred = 180;
  let mx = dx / d;
  let my = dy / d;
  if (d < preferred * 0.7) {
    mx = -mx * 0.4 + -my * 0.8;
    my = -my * 0.4 + mx * 0.8;
  }
  p.input = { mx, my, fire: d < 340, dash: d > 300 && Math.random() < 0.02, use: p.hp < 40 && Boolean(p.item), aimX: prey.x, aimY: prey.y };
}

function dropLoot(match, victim) {
  const { mode } = match;
  if (mode.lootGuns) {
    match.loot.push({ id: `g-${match.tick}-${victim.slot}`, kind: "gun", weapon: { ...victim.weapon }, x: victim.x, y: victim.y });
  }
  if (mode.lootItems) {
    const item = Math.random() < 0.5 ? ITEMS.medkit : ITEMS.dash;
    match.loot.push({ id: `i-${match.tick}-${victim.slot}`, kind: "item", item: { ...item }, x: victim.x + 16, y: victim.y });
  }
}

function tryFire(match, p) {
  const w = p.weapon;
  if (p.fireCd > 0) return;
  const hold = p.input.fire;
  if (!hold) return;
  if (!w.auto && p._fired) return;
  p._fired = true;
  p.fireCd = w.interval;
  const ang = Math.atan2(p.input.aimY - p.y, p.input.aimX - p.x);
  match.bullets.push({
    x: p.x + Math.cos(ang) * 22,
    y: p.y + Math.sin(ang) * 22,
    vx: Math.cos(ang) * w.speed,
    vy: Math.sin(ang) * w.speed,
    owner: p.slot,
    dmg: w.damage,
    life: 0.9,
  });
}

export function step(match) {
  if (match.result !== "playing") return;
  match.tick += 1;
  match.time += DT;
  match.zoneWait -= DT;
  if (match.zoneWait <= 0 && !match.shrinking && match.zoneR > 90) {
    match.shrinking = true;
    match.zoneTarget = Math.max(90, match.zoneR * 0.62);
  }
  if (match.shrinking) {
    match.zoneR = Math.max(match.zoneTarget, match.zoneR - 18 * DT);
    if (match.zoneR <= match.zoneTarget + 0.5) {
      match.shrinking = false;
      match.zoneWait = 7;
    }
  }

  for (const p of match.players) {
    if (!p.alive) continue;
    if (p.cpu) cpuThink(match, p);
    if (!p.input.fire) p._fired = false;
    p.fireCd = Math.max(0, p.fireCd - DT);
    p.dashCd = Math.max(0, p.dashCd - DT);
    let speed = 210;
    if (p.input.dash && p.dashCd <= 0) {
      speed = 520;
      p.dashCd = 1.6;
    }
    const mlen = Math.hypot(p.input.mx, p.input.my);
    if (mlen > 0.05) {
      p.x += (p.input.mx / Math.max(1, mlen)) * speed * DT;
      p.y += (p.input.my / Math.max(1, mlen)) * speed * DT;
    }
    p.aimX = p.input.aimX;
    p.aimY = p.input.aimY;
    clampToIsland(p);
    const fromCenter = Math.hypot(p.x - ARENA.cx, p.y - ARENA.cy);
    if (fromCenter > match.zoneR) p.hp -= 8 * DT;
    if (p.input.use && p.item) {
      if (p.item.id === "medkit") p.hp = Math.min(100, p.hp + p.item.heal);
      if (p.item.id === "dash") p.dashCd = 0;
      p.item = null;
      p.input.use = false;
    }
    for (let i = match.loot.length - 1; i >= 0; i--) {
      const drop = match.loot[i];
      if (dist(drop, p) < 28) {
        if (drop.kind === "gun") p.weapon = { ...drop.weapon };
        if (drop.kind === "item") p.item = { ...drop.item };
        match.loot.splice(i, 1);
      }
    }
    tryFire(match, p);
    if (p.hp <= 0) {
      p.alive = false;
      p.hp = 0;
      dropLoot(match, p);
    }
  }

  for (let i = match.bullets.length - 1; i >= 0; i--) {
    const b = match.bullets[i];
    b.x += b.vx * DT;
    b.y += b.vy * DT;
    b.life -= DT;
    let hit = false;
    for (const p of match.players) {
      if (!p.alive || p.slot === b.owner) continue;
      if (dist(b, p) < 18) {
        p.hp -= b.dmg;
        hit = true;
        if (p.hp <= 0) {
          p.alive = false;
          p.hp = 0;
          const killer = match.players[b.owner];
          if (killer) killer.kills += 1;
          dropLoot(match, p);
        }
        break;
      }
    }
    if (hit || b.life <= 0) match.bullets.splice(i, 1);
  }

  const alive = match.players.filter((p) => p.alive);
  if (alive.length <= 1) {
    match.result = alive.length === 1 ? "won" : "draw";
    match.winner = alive[0]?.slot ?? -1;
  }
}

function r1(n) {
  return Math.round(n * 10) / 10;
}

export function snapshot(match) {
  return {
    t: "snap",
    tick: match.tick,
    time: r1(match.time),
    result: match.result,
    winner: match.winner,
    zoneR: r1(match.zoneR),
    shrinking: match.shrinking,
    mode: match.modeId,
    bullets: match.bullets.map((b) => ({ x: r1(b.x), y: r1(b.y), owner: b.owner })),
    loot: match.loot.map((l) => ({
      id: l.id,
      kind: l.kind,
      x: r1(l.x),
      y: r1(l.y),
      n: l.weapon?.name || l.item?.name || "",
    })),
    players: match.players.map((p) => ({
      slot: p.slot,
      name: p.name,
      cpu: p.cpu,
      x: r1(p.x),
      y: r1(p.y),
      aimX: r1(p.aimX),
      aimY: r1(p.aimY),
      hp: Math.round(p.hp),
      alive: p.alive,
      weapon: p.weapon.name,
      item: p.item?.name ?? "",
      kills: p.kills,
      ack: p.lastSeq || 0,
    })),
  };
}
