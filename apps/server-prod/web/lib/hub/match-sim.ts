import { characterBindNumber } from "../characters/index.js";

/** 허브 권위 시뮬 — 방장 Godot 이 아니라 방이 월드의 원본이다. */

export const ARENA_SIZE = { x: 7840, y: 4760 };
export const ARENA_CENTER = { x: 3920, y: 2380 };
export const ARENA_MARGIN = 104;
export const HERO_RADIUS = 20;
export const MOVE_SPEED = 419;
export const FIRE_SPEED = 1000;
export const FIRE_TTL = 0.44;
export const FIRE_INTERVAL = 0.105;
export const BULLET_RADIUS = 5;
export const HERO_MAX_HP = 176;
export const MAG_SIZE = 18;
export const FIXED_DT = 1 / 60;

export type MatchInput = {
  mx?: unknown;
  my?: unknown;
  aimX?: unknown;
  aimY?: unknown;
  fire?: unknown;
  firePressed?: unknown;
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
  fireCd: number;
  ack: number;
  animal: number;
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

function num(v: unknown, fallback = 0): number {
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

export function clampArena(x: number, y: number): { x: number; y: number } {
  return {
    x: Math.min(ARENA_SIZE.x - ARENA_MARGIN - HERO_RADIUS, Math.max(ARENA_MARGIN + HERO_RADIUS, x)),
    y: Math.min(ARENA_SIZE.y - ARENA_MARGIN - HERO_RADIUS, Math.max(ARENA_MARGIN + HERO_RADIUS, y)),
  };
}

export function spawnPoint(slot: number, count: number): { x: number; y: number } {
  const n = Math.max(1, count);
  const ang = (Math.PI * 2 * slot) / n - Math.PI / 2;
  return clampArena(ARENA_CENTER.x + Math.cos(ang) * 720, ARENA_CENTER.y + Math.sin(ang) * 520);
}

export class MatchSim {
  tick = 0;
  result: "playing" | "won" | "draw" = "playing";
  winner = -1;
  heroes = new Map<number, SimHero>();
  bullets = new Map<number, SimBullet>();
  fx: GunFireFx[] = [];
  private nextBulletId = 1;
  private inputs = new Map<number, MatchInput>();

  constructor(seats: readonly SeatSeed[]) {
    const count = Math.max(1, seats.length);
    for (const seat of seats) {
      const slot = seat.slot;
      if (slot < 0) {continue;}
      const pos = spawnPoint(slot, count);
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
        fireCd: 0,
        ack: 0,
        animal: characterBindNumber(seat.characterId ?? "", "animal") ?? (seat.cpu ? slot % 12 : -1),
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
    for (const [slot, hero] of this.heroes) {
      if (!hero.alive) {continue;}
      if (hero.cpu) {
        this.driveCpu(hero, dt);
        continue;
      }
      const cmd = this.inputs.get(slot);
      if (cmd) {this.applyHero(hero, cmd, dt);}
      else {hero.fireCd = Math.max(0, hero.fireCd - dt);}
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
      return;
    }
    const dx = prey.x - hero.x;
    const dy = prey.y - hero.y;
    const dist = Math.hypot(dx, dy) || 1;
    this.applyHero(hero, {
      mx: dx / dist,
      my: dy / dist,
      aimX: prey.x,
      aimY: prey.y,
      fire: dist < 980,
    }, dt);
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
    const next = clampArena(hero.x + mx * MOVE_SPEED * dt, hero.y + my * MOVE_SPEED * dt);
    hero.x = next.x;
    hero.y = next.y;
    const aimX = num(cmd.aimX, hero.x + 1);
    const aimY = num(cmd.aimY, hero.y);
    if ((aimX - hero.x) ** 2 + (aimY - hero.y) ** 2 > 0.01) {
      hero.aimX = aimX;
      hero.aimY = aimY;
    }
    hero.fireCd = Math.max(0, hero.fireCd - dt);
    const wantFire = Boolean(cmd.fire) || Boolean(cmd.firePressed);
    if (wantFire) {this.tryFire(hero);}
  }

  private tryFire(hero: SimHero): void {
    if (hero.fireCd > 0 || hero.mag <= 0) {return;}
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
    const victim = this.hitHero(b);
    if (!victim) {return false;}
    victim.hp = Math.max(0, victim.hp - 13.26);
    victim.alive = victim.hp > 0;
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
