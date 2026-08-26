import { seedSeatIdentities } from "../characters/index.js";
import {
  ARENA_SIZE, FIRE_SPEED, FIRE_TTL, HERO_RADIUS, buildTiledCovers, clampArena,
  nudgeOutOfCover, pointInCover, resolveCoverMotion, spawnKnockout, spawnPoint, tickKnockouts,
} from "./match-covers.js";
import type { CoverRect, SimKnockout } from "./match-covers.js";
import { CpuFleet } from "./match-cpu.js";
import { applyEmoteInput, emoteSeedFields, tickEmotes, type EmoteFields } from "./match-emote.js";
import {
  applyZoneLifeDamage, crawlDowned, lifeSeedFields, tickDowns,
  tickSpawnProtect, updateRespawns,
} from "./match-life.js";
import type { LifeHero } from "./match-life.js";
import {
  applyScoredDamage, resetDeadStreaks, scoreSeedFields, type ScoreFields,
} from "./match-score.js";
import { buildHealthPickups, handleUseInput, lootSeedFields, updateHealthPickups } from "./match-loot.js";
import type { LootHero, LootPickup } from "./match-loot.js";
import {
  MATCH_TIME_LIMIT, createSafeZone, pickTimeLimitWinner, updateSafeZone,
} from "./match-zone.js";
import type { SafeZoneState } from "./match-zone.js";

export * from "./match-covers.js";
export * from "./match-cpu.js";
export * from "./match-emote.js";
export * from "./match-life.js";
export * from "./match-loot.js";
export * from "./match-score.js";
export * from "./match-zone.js";

/** 허브 권위 시뮬 — 방장 Godot 이 아니라 방이 월드의 원본이다. */

export const MOVE_SPEED = 419;
export const FIRE_INTERVAL = 0.105;
export const BULLET_RADIUS = 5;
export const HERO_MAX_HP = 176;
export const MAG_SIZE = 18;
export const RELOAD_TIME = 1.15;
export const FIXED_DT = 1 / 60;
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
  use?: unknown;
  emote?: unknown;
  seq?: unknown;
};

export type SimHero = LifeHero & Pick<LootHero, "medkits" | "useHeld"> & ScoreFields & EmoteFields & {
  aimX: number;
  aimY: number;
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

function num(v: unknown, fallback = 0): number {
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

export class MatchSim {
  tick = 0;
  result: "playing" | "won" | "draw" = "playing";
  countdown = START_COUNTDOWN;
  winner = -1;
  /** 카운트다운 소진 뒤부터 누적되는 매치 시간(초) — 210 에서 고정 (카운트다운 3초 불포함). */
  matchTime = 0;
  readonly zone: SafeZoneState = createSafeZone();
  heroes = new Map<number, SimHero>();
  bullets = new Map<number, SimBullet>();
  readonly covers: CoverRect[] = buildTiledCovers();
  readonly loot: LootPickup[] = buildHealthPickups();
  knockouts: SimKnockout[] = [];
  fx: GunFireFx[] = [];
  private nextBulletId = 1;
  private inputs = new Map<number, MatchInput>();
  private readonly cpuFleet: CpuFleet;

  /** seed — 방 시드(room.state.seed). 0/미지정이면 CpuFleet 이 고정 폴백 시드를 쓴다. */
  constructor(seats: readonly SeatSeed[], seed = 0) {
    this.cpuFleet = new CpuFleet(seed);
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
        kills: 0,
        characterId: seeded.characterId,
        animal: seeded.animal,
        cpu: Boolean(seat.cpu),
        ...lifeSeedFields(pos.x, pos.y),
        ...lootSeedFields(),
        ...scoreSeedFields(),
        ...emoteSeedFields(),
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
    this.matchTime = Math.min(MATCH_TIME_LIMIT, this.matchTime + dt);
    updateSafeZone(this.zone, dt);
    tickSpawnProtect(this.heroes.values(), dt);
    tickEmotes(this.heroes.values(), dt);
    // 환경 피해 — 다운 체계 경유, 킬 크레딧 없음. knockout 연출은 다운 전이 시.
    for (const downed of applyZoneLifeDamage(this.heroes, this.zone, dt)) {
      this.knockouts.push(spawnKnockout(downed));
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
    updateHealthPickups(this.loot, this.heroes, dt);
    this.advanceBullets(dt);
    tickDowns(this.heroes, this.zone, dt);
    resetDeadStreaks(this.heroes.values());
    updateRespawns(this.heroes, this.zone, this.covers, dt);
    this.resolveWinner();
    this.resolveTimeLimit();
  }

  drainFx(): GunFireFx[] {
    const out = this.fx;
    this.fx = [];
    return out;
  }

  /** 승자 판정 — 사양 7절: 영구 탈락(eliminated) 기준. 리스폰 대기자는 아직 경기 중이다. */
  private resolveWinner(): void {
    if (this.result !== "playing" || this.heroes.size < 2) {return;}
    const standing = [...this.heroes.values()].filter((h) => !h.eliminated);
    if (standing.length > 1) {return;}
    this.result = standing.length === 0 ? "draw" : "won";
    this.winner = standing[0]?.slot ?? -1;
  }

  /** 210초 도달 — 비탈락자 중 HP비율 > 점수(kills*100) > 낮은 슬롯. 전원 탈락이면 draw. */
  private resolveTimeLimit(): void {
    if (this.result !== "playing" || this.matchTime < MATCH_TIME_LIMIT) {return;}
    const ranks = [...this.heroes.values()].map((h) => ({
      slot: h.slot, hp: h.hp, maxHp: h.maxHp, kills: h.kills, alive: !h.eliminated,
    }));
    const best = pickTimeLimitWinner(ranks);
    this.result = best < 0 ? "draw" : "won";
    this.winner = best;
  }

  private driveCpu(hero: SimHero, dt: number): void {
    const cmd = this.cpuFleet.command(hero, this.heroes.values(), this.tick, this.zone);
    if (!cmd) {
      hero.fireCd = Math.max(0, hero.fireCd - dt);
      this.tickReload(hero, dt, false);
      return;
    }
    this.applyHero(hero, cmd, dt);
  }

  private applyHero(hero: SimHero, cmd: MatchInput, dt: number): void {
    const seq = Math.max(0, Math.floor(num(cmd.seq)));
    if (seq > hero.ack) {hero.ack = seq;}
    handleUseInput(hero, Boolean(cmd.use));
    applyEmoteInput(hero, Math.floor(num(cmd.emote, -1)));
    let mx = num(cmd.mx);
    let my = num(cmd.my);
    const mlen = Math.hypot(mx, my);
    if (mlen > 1) {
      mx /= mlen;
      my /= mlen;
    }
    // 다운 중 — 16% 속도로 기어가기만. 조준·발사·재장전 불가.
    if (hero.downed) {
      crawlDowned(hero, mx, my, MOVE_SPEED, dt, this.covers);
      return;
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
      if (hero.reloadLeft === 0) {hero.mag = hero.magMax;}
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
    // 탄 피해도 다운 체계를 탄다 — 킬 크레딧·점수는 match-score 파이프라인이 적립.
    if (applyScoredDamage(this.heroes, b.owner, victim, 13.26) === "down") {
      this.knockouts.push(spawnKnockout(victim));
    }
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
