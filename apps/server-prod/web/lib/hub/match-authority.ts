import { BulletSchema, HeroSchema, type LobbyState } from "./lobby-state.js";
import { ARENA_CENTER, MatchSim, type GunFireFx, type MatchInput, type SeatSeed } from "./match-sim.js";
import { KO } from "./config.js";

export type SnapPlayer = {
  slot: number;
  name: string;
  x: number;
  y: number;
  aimX: number;
  aimY: number;
  hp: number;
  maxHp: number;
  alive: boolean;
  mag: number;
  magMax: number;
  reloadLeft: number;
  weapon: string;
  ack: number;
  animal: number;
  characterId: string;
  cpu: boolean;
};

export function packAuthoritySnap(
  sim: MatchSim,
  names: ReadonlyMap<number, string>,
  mode: string,
): Record<string, unknown> {
  const players: SnapPlayer[] = [];
  for (const h of sim.heroes.values()) {
    players.push({
      slot: h.slot,
      name: names.get(h.slot) ?? `P${h.slot + 1}`,
      x: h.x,
      y: h.y,
      aimX: h.aimX,
      aimY: h.aimY,
      hp: h.hp,
      maxHp: h.maxHp,
      alive: h.alive,
      mag: h.mag,
      magMax: h.magMax,
      reloadLeft: h.reloadLeft,
      weapon: KO.WEAPON_PISTOL,
      ack: h.ack,
      animal: h.animal,
      characterId: h.characterId,
      cpu: h.cpu,
    });
  }
  const bullets = [...sim.bullets.values()].map((b) => ({
    id: b.id, x: b.x, y: b.y, vx: b.vx, vy: b.vy, owner: b.owner,
  }));
  // 부팅 후 불변이라 매 스냅 포함 — Godot parse_covers 필드명(x·y·w·h) 그대로.
  const covers = sim.covers.map((c) => ({ x: c.x, y: c.y, w: c.w, h: c.h }));
  // Godot parse_knockouts 필드명 — time 은 감소, max_time 은 초기 총 시간.
  const knockouts = sim.knockouts.map((k) => ({
    slot: k.slot, animal: k.animal, x: k.x, y: k.y, time: k.time, max_time: k.maxTime,
  }));
  // zones·deployables·cores·crates·crate_orbs·loot·mid_tower 는 허브 시뮬 미구현 — SnapContract 소비측은 빈 폴백.
  return {
    tick: sim.tick,
    time: sim.tick / 60,
    result: sim.result,
    winner: sim.winner,
    zoneR: 3304,
    shrinking: false,
    zoneCX: ARENA_CENTER.x,
    zoneCY: ARENA_CENTER.y,
    zonePhase: 0,
    startCountdown: sim.countdown,
    wantedSlot: -1,
    mode,
    players,
    bullets,
    covers,
    knockouts,
  };
}

export function writeMatchSchema(state: LobbyState, sim: MatchSim): void {
  state.matchTick = sim.tick;
  const liveHero = new Set<string>();
  for (const h of sim.heroes.values()) {
    const key = String(h.slot);
    liveHero.add(key);
    let row = state.heroes.get(key);
    if (!row) {
      row = new HeroSchema();
      state.heroes.set(key, row);
    }
    row.slot = h.slot;
    row.x = h.x;
    row.y = h.y;
    row.aimX = h.aimX;
    row.aimY = h.aimY;
    row.hp = h.hp;
    row.maxHp = h.maxHp;
    row.alive = h.alive;
    row.mag = h.mag;
    row.magMax = h.magMax;
    row.ack = h.ack;
    row.animal = h.animal;
  }
  for (const key of [...state.heroes.keys()]) {
    if (!liveHero.has(key)) {state.heroes.delete(key);}
  }
  const liveBullet = new Set<string>();
  for (const b of sim.bullets.values()) {
    const key = String(b.id);
    liveBullet.add(key);
    let row = state.bullets.get(key);
    if (!row) {
      row = new BulletSchema();
      state.bullets.set(key, row);
    }
    row.id = b.id;
    row.x = b.x;
    row.y = b.y;
    row.vx = b.vx;
    row.vy = b.vy;
    row.owner = b.owner;
    row.kind = b.kind;
  }
  for (const key of [...state.bullets.keys()]) {
    if (!liveBullet.has(key)) {state.bullets.delete(key);}
  }
}

export function clearMatchSchema(state: LobbyState): void {
  state.matchTick = 0;
  state.heroes.clear();
  state.bullets.clear();
}

export class MatchAuthority {
  readonly sim: MatchSim;
  readonly names = new Map<number, string>();
  private acc = 0;
  private snapAcc = 0;
  private mode: string;

  constructor(seats: readonly SeatSeed[], mode: string) {
    this.sim = new MatchSim(seats);
    this.mode = mode;
    for (const s of seats) {
      if (s.slot >= 0) {this.names.set(s.slot, s.name ?? `P${s.slot + 1}`);}
    }
  }

  pushInput(slot: number, data: MatchInput): void {
    this.sim.pushInput(slot, data);
  }

  advance(dtSec: number, state: LobbyState): { snap: Record<string, unknown> | null; fx: GunFireFx[] } {
    this.acc += dtSec;
    const fx: GunFireFx[] = [];
    while (this.acc >= 1 / 60 - 1e-9) {
      this.acc -= 1 / 60;
      this.sim.step(1 / 60);
      fx.push(...this.sim.drainFx());
    }
    writeMatchSchema(state, this.sim);
    this.snapAcc += dtSec;
    if (this.snapAcc < 1 / 20 - 1e-9) {return { snap: null, fx };}
    this.snapAcc = 0;
    return { snap: packAuthoritySnap(this.sim, this.names, this.mode), fx };
  }
}

export function acceptPlayInput(
  phase: string,
  players: ReadonlyArray<{ sessionId: string; slot: number }>,
  sessionId: string,
  data: Record<string, unknown>,
  authority: MatchAuthority | null,
): boolean {
  if (phase !== "playing" || !authority) {return false;}
  const slot = players.find((p) => p.sessionId === sessionId)?.slot ?? -1;
  if (slot < 0) {return false;}
  authority.pushInput(slot, data);
  return true;
}
