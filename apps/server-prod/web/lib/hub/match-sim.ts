import { seedSeatIdentities } from "../characters/index.js";
import {
  ARENA_SIZE, HERO_RADIUS, buildTiledCovers, clampArena, nudgeOutOfCover,
  pointInCover, resolveCoverMotion, spawnKnockout, spawnPoint, tickKnockouts,
} from "./match-covers.js";
import type { CoverRect, SimKnockout } from "./match-covers.js";

export * from "./match-covers.js";

/** 허브 권위 시뮬 — 방장 Godot 이 아니라 방이 월드의 원본이다. */

export const MOVE_SPEED = 419;
export const FIRE_SPEED = 1000;
export const FIRE_TTL = 0.44;
export const FIRE_INTERVAL = 0.105;
export const BULLET_RADIUS = 5;
export const HERO_MAX_HP = 176;
export const MAG_SIZE = 18;
export const RELOAD_TIME = 1.15;
export const FIXED_DT = 1 / 60;
/** burst 권총 normal_range 와 같다. 이보다 멀리서 쏘면 탄이 만료된다. */
export const EFFECTIVE_RANGE = FIRE_SPEED * FIRE_TTL;
/** CPU 목표 유지 거리 — EFFECTIVE_RANGE 의 55~75% 밴드 중심(65%). */
export const CPU_TARGET_RANGE = EFFECTIVE_RANGE * 0.65;
export const CPU_RANGE_SLACK = EFFECTIVE_RANGE * 0.1;
export const CPU_STRAFE_WEIGHT = 0.6;
export const CPU_STRAFE_PERIOD_TICKS = 90;
export const CPU_STRAFE_SLOT_PHASE = 1.7;
export const CPU_SEPARATION_DIST = HERO_RADIUS * 4;
export const CPU_SEPARATION_WEIGHT = 1.2;
/** 레거시 START_COUNTDOWN — 개전 전 전원 정지. */
export const START_COUNTDOWN = 3;

export type MatchInput = {
  mx?: unknown;
  my?: unknown;
  aimX?: unknown;
  aimY?: unknown;
  fire?: unknown;
  firePressed?: unknown;
  reload?: unknown;
  seq?: unknown;
};

export type SimHero = {
  slot: number;
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
  fireCd: number;
  ack: number;
  animal: number;
  characterId: string;
  cpu: boolean;
};

export type SimBullet = {
  id: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  owner: number;
  ttl: number;
  kind: string;
};

export type GunFireFx = {
  slot: number;
  x: number;
  y: number;
  aimX: number;
  aimY: number;
};

export type SeatSeed = { slot: number; name?: string; characterId?: string; cpu?: boolean };

/** 목표 거리보다 멀면 접근(+1), 가까우면 후퇴(-1), 밴드 안이면 정지(0). */
export function cpuAdvanceWeight(dist: number): number {
  if (dist > CPU_TARGET_RANGE + CPU_RANGE_SLACK) {return 1;}
  if (dist < CPU_TARGET_RANGE - CPU_RANGE_SLACK) {return -1;}
  return 0;
}

/** slot·tick 파생 결정론 위상 — 좌우 strafe 방향을 천천히 뒤집는다. */
export function cpuStrafePhase(slot: number, tick: number): number {
  return Math.sin((tick / CPU_STRAFE_PERIOD_TICKS) * Math.PI * 2 + slot * CPU_STRAFE_SLOT_PHASE);
}

function num(v: unknown, fallback = 0): number {
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

export class MatchSim {
  tick = 0;
  result: "playing" | "won" | "draw" = "playing";
  countdown = START_COUNTDOWN;
  winner = -1;
  heroes = new Map<number, SimHero>();
  bullets = new Map<number, SimBullet>();
  readonly covers: CoverRect[] = buildTiledCovers();
  knockouts: SimKnockout[] = [];
  fx: GunFireFx[] = [];
  private nextBulletId = 1;
  private inputs = new Map<number, MatchInput>();

  constructor(seats: readonly SeatSeed[]) {
    const count = Math.max(1, seats.length);
    const identities = seedSeatIdentities(seats);
    for (const seat of seats) {
      const slot = seat.slot;
      if (slot < 0) {continue;}
      const pos = nudgeOutOfCover(spawnPoint(slot, count), this.covers);
      const seeded = identities.get(slot) ?? { characterId: "", animal: 0 };
      this.heroes.set(slot, {
        slot,
        x: pos.x,
        y: pos.y,
        aimX: pos.x + 100,
        aimY: pos.y,
        hp: HERO_MAX_HP,
        maxHp: HERO_MAX_HP,
        alive: true,
        mag: MAG_SIZE,
        magMax: MAG_SIZE,
        reloadLeft: 0,
        fireCd: 0,
        ack: 0,
        characterId: seeded.characterId,
        animal: seeded.animal,
        cpu: Boolean(seat.cpu),
      });
    }
  }

  pushInput(slot: number, data: MatchInput): void {
    if (!this.heroes.has(slot)) {return;}
    this.inputs.set(slot, data);
  }

  step(dt = FIXED_DT): void {
    this.tick += 1;
    this.fx = [];
    if (this.countdown > 0) {
      this.countdown = Math.max(0, this.countdown - dt);
      return;
    }
    tickKnockouts(this.knockouts, dt);
    for (const [slot, hero] of this.heroes) {
      if (!hero.alive) {continue;}
      if (hero.cpu) {
        this.driveCpu(hero, dt);
        continue;
      }
      const cmd = this.inputs.get(slot);
      if (cmd) {this.applyHero(hero, cmd, dt);}
      else {
        hero.fireCd = Math.max(0, hero.fireCd - dt);
        this.tickReload(hero, dt, false);
      }
    }
    this.advanceBullets(dt);
    this.resolveWinner();
  }

  drainFx(): GunFireFx[] {
    const out = this.fx;
    this.fx = [];
    return out;
  }

  private resolveWinner(): void {
    if (this.result !== "playing" || this.heroes.size < 2) {return;}
    const alive = [...this.heroes.values()].filter((h) => h.alive);
    if (alive.length > 1) {return;}
    this.result = alive.length === 0 ? "draw" : "won";
    this.winner = alive[0]?.slot ?? -1;
  }

  private driveCpu(hero: SimHero, dt: number): void {
    const prey = this.nearestPrey(hero);
    if (!prey) {
      hero.fireCd = Math.max(0, hero.fireCd - dt);
      this.tickReload(hero, dt, false);
      return;
    }
    const dx = prey.x - hero.x;
    const dy = prey.y - hero.y;
    const dist = Math.hypot(dx, dy) || 1;
    const ux = dx / dist;
    const uy = dy / dist;
    const advance = cpuAdvanceWeight(dist);
    const strafe = cpuStrafePhase(hero.slot, this.tick) * CPU_STRAFE_WEIGHT;
    const sep = this.cpuSeparation(hero);
    this.applyHero(hero, {
      mx: ux * advance - uy * strafe + sep.x * CPU_SEPARATION_WEIGHT,
      my: uy * advance + ux * strafe + sep.y * CPU_SEPARATION_WEIGHT,
      aimX: prey.x,
      aimY: prey.y,
      fire: dist < EFFECTIVE_RANGE - 40,
    }, dt);
  }

  /** 가까운 다른 히어로들로부터 밀어내는 분리 벡터(뭉침 방지). */
  private cpuSeparation(hero: SimHero): { x: number; y: number } {
    let sx = 0;
    let sy = 0;
    for (const other of this.heroes.values()) {
      if (!other.alive || other.slot === hero.slot) {continue;}
      const dx = hero.x - other.x;
      const dy = hero.y - other.y;
      const d = Math.hypot(dx, dy);
      if (d === 0 || d >= CPU_SEPARATION_DIST) {continue;}
      const push = (CPU_SEPARATION_DIST - d) / CPU_SEPARATION_DIST;
      sx += (dx / d) * push;
      sy += (dy / d) * push;
    }
    return { x: sx, y: sy };
  }

  private nearestPrey(hero: SimHero): SimHero | null {
    let best: SimHero | null = null;
    let bestD = Infinity;
    for (const other of this.heroes.values()) {
      if (!other.alive || other.slot === hero.slot) {continue;}
      const d = (other.x - hero.x) ** 2 + (other.y - hero.y) ** 2;
      if (d < bestD) {
        bestD = d;
        best = other;
      }
    }
    return best;
  }

  private applyHero(hero: SimHero, cmd: MatchInput, dt: number): void {
    const seq = Math.max(0, Math.floor(num(cmd.seq)));
    if (seq > hero.ack) {hero.ack = seq;}
    let mx = num(cmd.mx);
    let my = num(cmd.my);
    const mlen = Math.hypot(mx, my);
    if (mlen > 1) {
      mx /= mlen;
      my /= mlen;
    }
    const slid = resolveCoverMotion(hero.x, hero.y, mx * MOVE_SPEED * dt, my * MOVE_SPEED * dt, this.covers);
    const next = clampArena(slid.x, slid.y);
    hero.x = next.x;
    hero.y = next.y;
    const aimX = num(cmd.aimX, hero.x + 1);
    const aimY = num(cmd.aimY, hero.y);
    if ((aimX - hero.x) ** 2 + (aimY - hero.y) ** 2 > 0.01) {
      hero.aimX = aimX;
      hero.aimY = aimY;
    }
    hero.fireCd = Math.max(0, hero.fireCd - dt);
    this.tickReload(hero, dt, Boolean(cmd.reload));
    const wantFire = Boolean(cmd.fire) || Boolean(cmd.firePressed);
    if (wantFire) {this.tryFire(hero);}
  }

  private tickReload(hero: SimHero, dt: number, wantReload: boolean): void {
    if (hero.reloadLeft > 0) {
      hero.reloadLeft = Math.max(0, hero.reloadLeft - dt);
      if (hero.reloadLeft === 0) {
        hero.mag = hero.magMax;
      }
      return;
    }
    if ((wantReload && hero.mag < hero.magMax) || hero.mag <= 0) {
      hero.reloadLeft = RELOAD_TIME;
    }
  }

  private tryFire(hero: SimHero): void {
    if (hero.reloadLeft > 0 || hero.fireCd > 0 || hero.mag <= 0) {return;}
    const dx = hero.aimX - hero.x;
    const dy = hero.aimY - hero.y;
    const len = Math.hypot(dx, dy) || 1;
    const ux = dx / len;
    const uy = dy / len;
    const id = this.nextBulletId;
    this.nextBulletId += 1;
    this.bullets.set(id, {
      id,
      x: hero.x + ux * 28,
      y: hero.y + uy * 28,
      vx: ux * FIRE_SPEED,
      vy: uy * FIRE_SPEED,
      owner: hero.slot,
      ttl: FIRE_TTL,
      kind: "bolt",
    });
    hero.mag -= 1;
    hero.fireCd = FIRE_INTERVAL;
    this.fx.push({ slot: hero.slot, x: hero.x, y: hero.y, aimX: hero.aimX, aimY: hero.aimY });
  }

  private advanceBullets(dt: number): void {
    for (const [id, b] of [...this.bullets]) {
      if (this.expireOrHit(b, dt)) {this.bullets.delete(id);}
    }
  }

  private expireOrHit(b: SimBullet, dt: number): boolean {
    b.ttl -= dt;
    b.x += b.vx * dt;
    b.y += b.vy * dt;
    if (b.ttl <= 0 || b.x < 0 || b.y < 0 || b.x > ARENA_SIZE.x || b.y > ARENA_SIZE.y) {
      return true;
    }
    if (pointInCover(b.x, b.y, this.covers)) {return true;}
    const victim = this.hitHero(b);
    if (!victim) {return false;}
    victim.hp = Math.max(0, victim.hp - 13.26);
    victim.alive = victim.hp > 0;
    if (!victim.alive) {this.knockouts.push(spawnKnockout(victim));}
    return true;
  }

  private hitHero(b: SimBullet): SimHero | null {
    const hitR = HERO_RADIUS + BULLET_RADIUS;
    for (const hero of this.heroes.values()) {
      if (!hero.alive || hero.slot === b.owner) {continue;}
      if ((hero.x - b.x) ** 2 + (hero.y - b.y) ** 2 <= hitR * hitR) {return hero;}
    }
    return null;
  }
}
