import { BulletSchema, HeroSchema, type LobbyState } from "./lobby-state.js";
import { packAuthoritySnap, type SnapEvent } from "./match-authority-snap.js";
import {
  FIXED_DT, MatchSim,
  type GunFireFx, type MatchInput, type SeatSeed,
} from "./match-sim.js";

export { packAuthoritySnap, type SnapEvent, type SnapPlayer } from "./match-authority-snap.js";

const EVENT_CAP = 32;

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

/** 스냅은 20Hz. 부드러움은 클라 보간이 만든다. 60Hz 방송은 접속자당 600KB/s 로 웹 클라 프레임을 잃게 했다. */
export const SNAP_DT = FIXED_DT * 3;
/** 한 콜백에서 따라잡는 최대 틱. 밀린 dt 를 한 번에 20틱 돌리면 더 끊긴다. */
const MAX_STEPS = 4;

export class MatchAuthority {
  readonly sim: MatchSim;
  readonly names = new Map<number, string>();
  private acc = 0;
  private snapAcc = 0;
  private mode: string;
  private pendingEvents: SnapEvent[] = [];
  private ultEventAt = 0;

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

  setTickInput(slot: number, data: MatchInput): void {
    this.sim.setTickInput(slot, data);
  }

  hasQueuedInput(slot: number): boolean {
    return this.sim.hasQueuedInput(slot);
  }

  /** 인간 좌석만. CPU 는 항상 false. */
  setParked(slot: number, parked: boolean): void {
    const hero = this.sim.heroes.get(slot);
    if (!hero || hero.cpu) {return;}
    hero.parked = parked;
  }

  /** 인간 좌석만. 재접속 클라 seq 가 0부터라 누적 ack 가 pending 을 전부 폐기한다. */
  resetAck(slot: number): void {
    const hero = this.sim.heroes.get(slot);
    if (!hero || hero.cpu) {return;}
    hero.ack = 0;
  }

  advance(
    dtSec: number,
    _state: LobbyState,
  ): { snap: Record<string, unknown> | null; fx: GunFireFx[]; events: SnapEvent[] } {
    this.acc += dtSec;
    if (this.acc > FIXED_DT * MAX_STEPS) {this.acc = FIXED_DT * MAX_STEPS;}
    const fx: GunFireFx[] = [];
    let steps = 0;
    while (this.acc >= FIXED_DT - 1e-9 && steps < MAX_STEPS) {
      this.acc -= FIXED_DT;
      this.sim.step(FIXED_DT);
      const stepFx = this.sim.drainFx();
      fx.push(...stepFx);
      this.ingestEvents(stepFx);
      steps += 1;
    }
    this.snapAcc += dtSec;
    if (this.snapAcc < SNAP_DT - 1e-9) {return { snap: null, fx, events: [] };}
    this.snapAcc = 0;
    const events = this.takeEvents();
    return { snap: packAuthoritySnap(this.sim, this.names, this.mode, events), fx, events };
  }

  private ingestEvents(stepFx: readonly GunFireFx[]): void {
    const ult = this.sim.ultWorld.events;
    for (const ev of ult.slice(this.ultEventAt)) {
      this.pendingEvents.push({ t: ev.tick, k: ev.type, a: ev.actor, b: ev.target, d: ev.data });
    }
    this.ultEventAt = ult.length;
    for (const fire of stepFx) {
      this.pendingEvents.push(this.toGunFireEvent(fire));
    }
  }

  private toGunFireEvent(fire: GunFireFx): SnapEvent {
    const hero = this.sim.heroes.get(fire.slot);
    return {
      t: this.sim.tick, k: "gun_fire", a: fire.slot, b: -1,
      d: { equipment: hero?.equipment.id ?? "", x: fire.x, y: fire.y },
    };
  }

  private takeEvents(): SnapEvent[] {
    const all = this.pendingEvents;
    this.pendingEvents = [];
    if (all.length <= EVENT_CAP) {return all;}
    return all.slice(all.length - EVENT_CAP);
  }
}

export function acceptPlayInput(
  phase: string,
  players: ReadonlyArray<{ sessionId: string; slot: number }>,
  sessionId: string,
  data: Record<string, unknown>,
  authority: MatchAuthority | null,
  mappedSlot = -1,
): boolean {
  if (phase !== "playing" || !authority) {return false;}
  const seated = players.find((p) => p.sessionId === sessionId)?.slot ?? -1;
  const slot = seated >= 0 ? seated : mappedSlot;
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
): { snap: Record<string, unknown> | null; fx: GunFireFx[]; events: SnapEvent[] } {
  return authority.advance(dtSec, state);
}

export function apply(authority: MatchAuthority, slot: number, data: MatchInput): void {
  authority.pushInput(slot, data);
}

export function setHeroParked(
  authority: MatchAuthority | null,
  slot: number,
  parked: boolean,
): void {
  authority?.setParked(slot, parked);
}

export function setHeroAckReset(
  authority: MatchAuthority | null,
  slot: number,
): void {
  authority?.resetAck(slot);
}
