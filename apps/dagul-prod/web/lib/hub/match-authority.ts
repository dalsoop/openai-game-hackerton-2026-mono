import { BulletSchema, HeroSchema, type LobbyState } from "./lobby-state.js";
import {
  ARENA_CENTER, FIXED_DT, MatchSim, packCoresSnap, packCrateOrbsSnap, packCratesSnap,
  packFinishCine, packItemField, packLootSnap, packMidTowerSnap,
  packWantedSnap, packZonesSnap, snapDeployables,
  type GunFireFx, type MatchInput, type SeatSeed,
} from "./match-sim.js";

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
  ult: number;
  ack: number;
  animal: number;
  characterId: string;
  cpu: boolean;
  item: string;
  kills: number;
  downed: boolean;
  downLeft: number;
  deaths: number;
  score: number;
  streak: number;
  emote: number;
  emoteTime: number;
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
      weapon: h.equipment.name,
      ult: h.ultimateCharge,
      ack: h.ack,
      animal: h.animal,
      kills: h.kills,
      characterId: h.characterId,
      cpu: h.cpu,
      item: packItemField(h.medkits),
      downed: h.downed,
      downLeft: h.downLeft,
      deaths: h.deaths,
      score: h.score,
      streak: h.killStreak,
      emote: h.emote,
      emoteTime: h.emoteTime,
    });
  }
  const bullets = [...sim.bullets.values()].map((b) => ({
    id: b.id, x: b.x, y: b.y, vx: b.vx, vy: b.vy, owner: b.owner, kind: b.kind,
  }));
  const covers = sim.covers.map((c) => ({ x: c.x, y: c.y, w: c.w, h: c.h }));
  const knockouts = sim.knockouts.map((k) => ({
    slot: k.slot, animal: k.animal, x: k.x, y: k.y, time: k.time, max_time: k.maxTime,
  }));
  const loot = packLootSnap(sim.loot);
  const wanted = packWantedSnap(sim.wanted);
  return {
    tick: sim.tick,
    time: sim.matchTime,
    result: sim.result,
    winner: sim.winner,
    zoneR: sim.zone.radius,
    shrinking: sim.zone.shrinking,
    zoneCX: ARENA_CENTER.x,
    zoneCY: ARENA_CENTER.y,
    zonePhase: sim.zone.phase,
    startCountdown: sim.countdown,
    finishCine: packFinishCine(sim.finishCine),
    finish_cine: packFinishCine(sim.finishCine),
    callout: sim.callout,
    calloutTicks: sim.calloutTicks,
    wantedSlot: wanted.wantedSlot,
    cores: packCoresSnap(sim.cores),
    crates: packCratesSnap(sim.crates),
    crate_orbs: packCrateOrbsSnap(sim.crateOrbs),
    mid_tower: packMidTowerSnap(sim.midTower),
    deployables: snapDeployables(sim.deploy.deployables),
    zones: packZonesSnap(sim.zones),
    mode,
    players,
    bullets,
    covers,
    knockouts,
    loot,
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

/** 스냅은 시뮬과 같은 60Hz. 20Hz 이면 보간이 한 박자 늦게 미끄러진다. */
export const SNAP_DT = FIXED_DT;
/** 한 콜백에서 따라잡는 최대 틱. 밀린 dt 를 한 번에 20틱 돌리면 더 끊긴다. */
const MAX_STEPS = 4;

export class MatchAuthority {
  readonly sim: MatchSim;
  readonly names = new Map<number, string>();
  private acc = 0;
  private snapAcc = 0;
  private mode: string;

  /** seed — 방 시드(room.state.seed). CPU 결정론 난수의 뿌리. */
  constructor(seats: readonly SeatSeed[], mode: string, seed = 0) {
    this.sim = new MatchSim(seats, seed, mode);
    this.sim.countdownHeld = seats.some((s) => s.slot >= 0 && !s.cpu);
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
    if (this.acc > FIXED_DT * MAX_STEPS) {this.acc = FIXED_DT * MAX_STEPS;}
    const fx: GunFireFx[] = [];
    let steps = 0;
    while (this.acc >= FIXED_DT - 1e-9 && steps < MAX_STEPS) {
      this.acc -= FIXED_DT;
      this.sim.step(FIXED_DT);
      fx.push(...this.sim.drainFx());
      steps += 1;
    }
    writeMatchSchema(state, this.sim);
    this.snapAcc += dtSec;
    if (this.snapAcc < SNAP_DT - 1e-9) {return { snap: null, fx };}
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

export function seed(seats: readonly SeatSeed[], mode: string, matchSeed = 0): MatchAuthority {
  return new MatchAuthority(seats, mode, matchSeed);
}

export function tick(
  authority: MatchAuthority,
  dtSec: number,
  state: LobbyState,
): { snap: Record<string, unknown> | null; fx: GunFireFx[] } {
  return authority.advance(dtSec, state);
}

export function apply(authority: MatchAuthority, slot: number, data: MatchInput): void {
  authority.pushInput(slot, data);
}
