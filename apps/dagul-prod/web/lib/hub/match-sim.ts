import { seedSeatIdentities } from "../characters/index.js";
import {
  ARENA_SIZE, HERO_RADIUS, buildTiledCovers, clampArena,
  nudgeOutOfCover, pointInCover, resolveCoverMotion, spawnKnockout, spawnPoint, tickKnockouts,
} from "./match-covers.js";
import type { CoverRect, SimKnockout } from "./match-covers.js";
import { CpuFleet } from "./match-cpu.js";
import { applyEmoteInput, emoteSeedFields, tickEmotes, type EmoteFields } from "./match-emote.js";
import {
  applyZoneLifeDamage, crawlDowned, downHero, lifeSeedFields, tickDowns,
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
import { ccSeedFields, movementControl, tickCc } from "./match-cc.js";
import type { CcHeroState } from "./match-cc.js";
import { packCoresSnap, spawnCores, damageCore, coreExposed, projectileHitsCore } from "./match-core.js";
import type { SimCore } from "./match-core.js";
import {
  crateHeroSeedFields, spawnBreakableCrates, updateCrateOrbs, tickDmgOrbTime,
  hurtCrate, packCratesSnap, packCrateOrbsSnap, CRATE_RADIUS,
} from "./match-crate.js";
import type { CrateHero, SimCrate, SimCrateOrb } from "./match-crate.js";
import {
  seedDeployables, updateDeployables, type DeployableCore, type DeployableEvent, type DeployableState,
} from "./match-deployable.js";
import { snapDeployables, tickWallHitCd } from "./match-deployable-hit.js";
import { makeEquipment, startEquipmentId, equipmentReach } from "./match-equipment.js";
import {
  applyGunInput, gunSeedFields, tickGun, HOP_AIR, HOP_LIFT_DEFAULT, type GunHero, type GunProjectile,
} from "./match-gun.js";
import {
  applyFinish, packFinishCine, seedFinishCine, tickFinishCine, type FinishCine,
} from "./match-finish.js";
import { launchSeedFields, tickLaunch, tickLaunchTrailFade } from "./match-launch.js";
import type { LaunchState } from "./match-launch.js";
import { MatchRng } from "./match-rng.js";
import {
  packMidTowerSnap, resetMidTower, updateMidTower, type SimMidTower, type TowerHooks,
} from "./match-tower.js";
import type { TowerShell, TowerZone } from "./match-tower-fire.js";
import {
  applyUltimateInput, seedUltWorld, tickFightSurge, tickOxCharges, tickRatTides, tickSnakeSkins,
  tickDragonSmokes, tickTigerRoars, tickRabbitBurrows, tickHorseKicks, tickDogRush,
  tickRoosterEggs, tickPigMuds, tickWoolShields, tickUltClones, tickPassiveUltCharge,
  applyHitUltCharge, chargeHeroSeedFields, heroMoveSpeed, ultHeroSeedFields,
  type ChargeHero, type UltHero, type UltWorld,
} from "./match-ultimate.js";
import {
  createWantedState, packWantedSnap, queueRoulette, rouletteSeedFields, tickRoulettes,
  updateThreat, wantedSeedFields,
  type RouletteHero, type WantedHero, type WantedState,
} from "./match-wanted.js";

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
/** game_world.gd START_COUNTDOWN — 개전 전 전원 정지. */
export const START_COUNTDOWN = 3;
/** game_world.gd PLAYER_COUNT. */
export const PLAYER_COUNT = 8;
/** game_world.gd HOP_LOCK. */
export const HOP_LOCK = 0.08;

export type MatchInput = {
  mx?: unknown;
  my?: unknown;
  aimX?: unknown;
  aimY?: unknown;
  fire?: unknown;
  firePressed?: unknown;
  equipment?: unknown;
  equipmentPressed?: unknown;
  equipmentReleased?: unknown;
  dash?: unknown;
  mobility?: unknown;
  use?: unknown;
  reload?: unknown;
  ultimate?: unknown;
  hop?: unknown;
  finish?: unknown;
  emote?: unknown;
  seq?: unknown;
};

export type SimHero = LifeHero & Pick<LootHero, "medkits" | "useHeld"> & ScoreFields & EmoteFields
  & CcHeroState & LaunchState & CrateHero & WantedHero & RouletteHero & GunHero & UltHero & ChargeHero & {
    normalHits: number;
    equipmentHits: number;
    ack: number;
    characterId: string;
    cpu: boolean;
    magMax: number;
    vx: number;
    vy: number;
    hopLock: number;
    wallHitCd: number;
    equipmentId: string;
    preferredRange: number;
    normalReach: number;
    weight: number;
    action: string;
    coreDamage: number;
    eliminations: number;
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
  damage: number;
  radius: number;
  splash: number;
  pierce: number;
  knockback: number;
  source: string;
  heavy: boolean;
  leech: boolean;
  ccTime: number;
};

export type SimZone = {
  x: number;
  y: number;
  radius: number;
  owner: number;
  delay: number;
  damage: number;
  effectKind: string;
  label: string;
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

function truthy(v: unknown): boolean {
  return Boolean(v);
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
  cores: SimCore[] = [];
  crates: SimCrate[] = [];
  crateOrbs: SimCrateOrb[] = [];
  midTower: SimMidTower = resetMidTower();
  deploy: DeployableState = seedDeployables();
  finishCine: FinishCine = seedFinishCine();
  wanted: WantedState = createWantedState();
  ultWorld: UltWorld;
  zones: SimZone[] = [];
  callout = "NO TEAMS. ONLY TEMPORARY CONVENIENCE.";
  calloutTicks = 210;
  mode = "classic";
  private nextBulletId = 1;
  private inputs = new Map<number, MatchInput>();
  private readonly cpuFleet: CpuFleet;
  private readonly rng: MatchRng;
  /** 권위 매치에서만 true — 사람 입력이 오기 전까지 카운트다운을 깎지 않는다. */
  countdownHeld = true;
  private timeLimitWarningEmitted = false;

  /** seed — 방 시드(room.state.seed). 0/미지정이면 CpuFleet 이 고정 폴백 시드를 쓴다. */
  constructor(seats: readonly SeatSeed[], seed = 0, mode = "classic") {
    this.mode = mode;
    this.rng = new MatchRng(seed);
    this.cpuFleet = new CpuFleet(seed);
    this.ultWorld = seedUltWorld(this.covers);
    this.crates = spawnBreakableCrates(this.covers);
    const count = Math.max(1, seats.length);
    this.cores = spawnCores(this.covers, PLAYER_COUNT);
    const identities = seedSeatIdentities(seats);
    for (const seat of seats) {
      const slot = seat.slot;
      if (slot < 0) {continue;}
      const pos = nudgeOutOfCover(spawnPoint(slot, count), this.covers);
      const seeded = identities.get(slot) ?? { characterId: "", animal: 0 };
      const animal = seeded.animal;
      const eq = makeEquipment(startEquipmentId(mode, animal));
      const faceX = ARENA_SIZE.x * 0.5 - pos.x;
      const faceY = ARENA_SIZE.y * 0.5 - pos.y;
      const flen = Math.hypot(faceX, faceY) || 1;
      const facingX = faceX / flen;
      const facingY = faceY / flen;
      const gun = gunSeedFields(eq);
      const ult = ultHeroSeedFields(slot, animal);
      this.heroes.set(slot, {
        slot,
        x: pos.x,
        y: pos.y,
        aimX: pos.x + facingX * 100,
        aimY: pos.y + facingY * 100,
        alive: true,
        ack: 0,
        kills: 0,
        characterId: seeded.characterId,
        cpu: Boolean(seat.cpu),
        vx: 0,
        vy: 0,
        hopLock: 0,
        wallHitCd: 0,
        equipmentId: eq.id,
        preferredRange: eq.preferredRange,
        normalReach: equipmentReach(eq),
        weight: eq.weight,
        action: "READY",
        coreDamage: 0,
        eliminations: 0,
        facingX,
        facingY,
        ...lifeSeedFields(pos.x, pos.y),
        ...lootSeedFields(),
        ...scoreSeedFields(),
        ...emoteSeedFields(),
        ...ccSeedFields(),
        ...launchSeedFields(),
        ...crateHeroSeedFields(),
        ...wantedSeedFields(),
        ...rouletteSeedFields(),
        ...chargeHeroSeedFields(),
        ...gun,
        ...ult,
        equipment: eq,
        mag: eq.magSize,
        magMax: eq.magSize,
        facing: { x: facingX, y: facingY },
        aim: { x: facingX, y: facingY },
        vel: { x: 0, y: 0 },
        hp: HERO_MAX_HP,
        maxHp: HERO_MAX_HP,
        baseMaxHp: HERO_MAX_HP,
        animal,
        downed: false,
        eliminated: false,
        ultimateCharge: 0,
        normalHits: 0,
        equipmentHits: 0,
      });
    }
  }

  pushInput(slot: number, data: MatchInput): void {
    if (!this.heroes.has(slot)) {return;}
    this.inputs.set(slot, data);
  }

  step(dt = FIXED_DT): void {
    if (this.result !== "playing") {return;}
    this.tick += 1;
    this.ultWorld.tick = this.tick;
    this.fx = [];
    if (this.stepCountdown(dt)) {return;}
    this.matchTime = Math.min(MATCH_TIME_LIMIT, this.matchTime + dt);
    this.stepFightAndClock();
    if (this.matchTime >= MATCH_TIME_LIMIT) {
      this.matchTime = MATCH_TIME_LIMIT;
      this.resolveTimeLimit();
      return;
    }
    this.updateTimers(dt);
    updateSafeZone(this.zone, dt);
    this.applyHumans(dt);
    this.stepFinishCine(dt);
    this.applyCpus(dt);
    tickOxCharges(this.ultWorld, this.heroes, dt);
    tickRatTides(this.ultWorld, this.heroes, dt);
    tickSnakeSkins(this.ultWorld, dt);
    tickDragonSmokes(this.ultWorld, dt);
    tickTigerRoars(this.ultWorld, dt);
    tickRabbitBurrows(this.ultWorld, this.heroes, dt);
    tickHorseKicks(this.ultWorld, dt);
    tickDogRush(this.ultWorld, this.heroes, dt);
    this.moveLaunched(dt);
    tickRoosterEggs(this.ultWorld, this.heroes, dt);
    tickPigMuds(this.ultWorld, dt);
    tickWoolShields(this.heroes.values(), dt);
    for (const downed of applyZoneLifeDamage(this.heroes, this.zone, dt)) {
      this.knockouts.push(spawnKnockout(downed));
    }
    tickDowns(this.heroes, this.zone, dt);
    tickUltClones(this.ultWorld, this.heroes, dt);
    updateHealthPickups(this.loot, this.heroes, dt);
    updateCrateOrbs(this.crateOrbs, this.heroes, dt);
    updateRespawns(this.heroes, this.zone, this.covers, dt);
    tickKnockouts(this.knockouts, dt);
    this.stepDeployables(dt);
    this.stepTower(dt);
    this.advanceBullets(dt);
    this.advanceZones(dt);
    this.stepThreat(dt);
    resetDeadStreaks(this.heroes.values());
    this.resolveWinner();
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

  /** 210초 도달 — 비탈락 생존자 중 HP비율 > 점수(kills*100) > 낮은 슬롯. */
  private resolveTimeLimit(): void {
    if (this.result !== "playing") {return;}
    const ranks = [...this.heroes.values()].map((h) => ({
      slot: h.slot, hp: h.hp, maxHp: h.maxHp, kills: h.kills,
      alive: h.alive && !h.eliminated,
    }));
    const best = pickTimeLimitWinner(ranks);
    this.result = best < 0 ? "draw" : "won";
    this.winner = best;
  }

  private hasHumanSeat(): boolean {
    for (const h of this.heroes.values()) {
      if (!h.cpu) {return true;}
    }
    return false;
  }

  private hasHumanPlayInput(): boolean {
    for (const [slot] of this.inputs) {
      const hero = this.heroes.get(slot);
      if (hero && !hero.cpu) {return true;}
    }
    return false;
  }

  private freezeReady(): void {
    for (const h of this.heroes.values()) {
      h.vel = { x: 0, y: 0 };
      h.vx = 0;
      h.vy = 0;
      h.action = "READY";
    }
  }

  private announce(text: string, ticks: number): void {
    this.callout = text;
    this.calloutTicks = ticks;
  }

  private stepCountdown(dt: number): boolean {
    if (this.countdown <= 0) {return false;}
    if (this.countdownHeld) {
      if (!(this.hasHumanPlayInput() || !this.hasHumanSeat())) {
        this.freezeReady();
        return true;
      }
      this.countdownHeld = false;
    }
    this.countdown = Math.max(0, this.countdown - dt);
    this.freezeReady();
    if (this.countdown > 0.0001) {return true;}
    this.countdown = 0;
    this.announce("GO!", 45);
    return false;
  }

  private stepFightAndClock(): void {
    const before = this.ultWorld.events.length;
    tickFightSurge(this.ultWorld, this.heroes, this.matchTime);
    for (const ev of this.ultWorld.events.slice(before)) {
      if (ev.type === "fight_countdown") {this.announce("1 MINUTE LEFT", 80);}
      if (ev.type === "fight_surge") {this.announce("READY TO FIGHT", 90);}
      if (ev.type === "fight_surge_roulette") {
        const hero = this.heroes.get(ev.actor);
        if (hero) {queueRoulette(hero, "kill", this.rng);}
      }
    }
    if (!this.timeLimitWarningEmitted && MATCH_TIME_LIMIT - this.matchTime <= 10) {
      this.timeLimitWarningEmitted = true;
      this.announce("10 SECONDS TO HP DECISION", 90);
    }
  }

  private updateTimers(dt: number): void {
    this.calloutTicks = Math.max(0, this.calloutTicks - 1);
    tickSpawnProtect(this.heroes.values(), dt);
    tickEmotes(this.heroes.values(), dt);
    tickCc(this.heroes.values(), dt);
    tickDmgOrbTime(this.heroes.values(), dt);
    tickWallHitCd(this.heroes.values(), dt);
    tickRoulettes(this.heroes.values(), dt);
    for (const h of this.heroes.values()) {
      tickGun(h, dt);
      const prevHop = h.hopTime;
      h.hopTime = Math.max(0, prevHop - dt);
      if (prevHop > 0 && h.hopTime <= 0) {h.hopLock = HOP_LOCK;}
      else {h.hopLock = Math.max(0, h.hopLock - dt);}
      h.evadeTime = Math.max(0, h.evadeTime - dt);
      tickLaunchTrailFade(h, dt);
      tickPassiveUltCharge(h, dt);
      h.turtle = h.rlTimed.some((b) => b.id === "turtle" && b.time > 0);
      h.rouletteRate = h.rlUntil.rate + h.rlTimed.reduce((s, b) => s + b.rate, 0);
      h.rouletteRange = h.rlUntil.range + h.rlTimed.reduce((s, b) => s + b.range, 0);
      h.magMax = h.equipment.magSize;
    }
  }

  private applyHumans(dt: number): void {
    for (const [slot, hero] of this.heroes) {
      if (!hero.alive || hero.cpu) {continue;}
      const cmd = this.inputs.get(slot);
      if (cmd) {this.applyHero(hero, cmd, dt);}
    }
  }

  private applyCpus(dt: number): void {
    for (const hero of this.heroes.values()) {
      if (!hero.alive || !hero.cpu) {continue;}
      this.driveCpu(hero, dt);
    }
  }

  private driveCpu(hero: SimHero, dt: number): void {
    const cmd = this.cpuFleet.command(hero, this.heroes.values(), this.tick, this.zone);
    if (!cmd) {return;}
    this.applyHero(hero, {
      mx: cmd.mx, my: cmd.my, aimX: cmd.aimX, aimY: cmd.aimY,
      fire: cmd.fire, ultimate: cmd.ultimate, dash: false, mobility: false,
    }, dt);
  }

  private stepFinishCine(dt: number): void {
    const atkCmd = this.inputs.get(this.finishCine.atk);
    tickFinishCine(this.finishCine, this.heroes, { finish: truthy(atkCmd?.finish) }, dt, (atk, vic) => {
      const victim = this.heroes.get(vic);
      if (!victim) {return;}
      downHero(this.heroes, atk, victim);
      this.knockouts.push(spawnKnockout(victim));
    });
  }

  private moveLaunched(dt: number): void {
    tickLaunch(this.heroes.values(), dt, this.tick, this.covers);
  }

  private applyHero(hero: SimHero, cmd: MatchInput, dt: number): void {
    const seq = Math.max(0, Math.floor(num(cmd.seq)));
    if (seq > hero.ack) {hero.ack = seq;}
    handleUseInput(hero, truthy(cmd.use));
    applyEmoteInput(hero, Math.floor(num(cmd.emote, -1)));
    applyFinish(this.finishCine, this.heroes, hero.slot, truthy(cmd.finish));
    if (this.finishCine.on && (this.finishCine.atk === hero.slot || this.finishCine.vic === hero.slot)) {
      return;
    }
    let mx = num(cmd.mx);
    let my = num(cmd.my);
    const mlen = Math.hypot(mx, my);
    if (mlen > 1) {
      mx /= mlen;
      my /= mlen;
    }
    if (hero.downed) {
      crawlDowned(hero, mx, my, MOVE_SPEED, dt, this.covers);
      return;
    }
    if (hero.launchTime > 0 || hero.burrowed) {return;}
    const aimX = num(cmd.aimX, hero.x + 1);
    const aimY = num(cmd.aimY, hero.y);
    if ((aimX - hero.x) ** 2 + (aimY - hero.y) ** 2 > 0.01) {
      hero.aimX = aimX;
      hero.aimY = aimY;
      const dx = aimX - hero.x;
      const dy = aimY - hero.y;
      const len = Math.hypot(dx, dy) || 1;
      hero.facingX = dx / len;
      hero.facingY = dy / len;
      hero.facing = { x: hero.facingX, y: hero.facingY };
      hero.aim = { x: hero.facingX, y: hero.facingY };
    }
    applyUltimateInput(this.ultWorld, this.heroes, hero.slot, truthy(cmd.ultimate), { x: hero.aimX, y: hero.aimY });
    if (truthy(cmd.hop) && hero.hopTime <= 0 && hero.hopLock <= 0 && hero.rootTime <= 0 && !hero.turtle) {
      hero.hopTime = HOP_AIR;
      hero.hopMax = HOP_AIR;
      hero.hopHeight = HOP_LIFT_DEFAULT;
    }
    const ctrl = movementControl(hero);
    if (ctrl.locked) {return;}
    const spd = heroMoveSpeed(this.ultWorld, this.heroes, hero.slot, MOVE_SPEED) * ctrl.mult;
    const slid = resolveCoverMotion(hero.x, hero.y, mx * spd * dt, my * spd * dt, this.covers);
    const next = clampArena(slid.x, slid.y);
    hero.x = next.x;
    hero.y = next.y;
    hero.vx = mx * spd;
    hero.vy = my * spd;
    hero.vel = { x: hero.vx, y: hero.vy };
    hero.action = mlen > 0.04 ? "run" : "idle";
    const savedAimX = hero.aimX;
    const savedAimY = hero.aimY;
    const others = [...this.heroes.values()].filter((h) => h.slot !== hero.slot);
    const gun = applyGunInput(hero, {
      primary: truthy(cmd.fire),
      primaryPressed: truthy(cmd.firePressed) || truthy(cmd.fire),
      reload: truthy(cmd.reload),
      mobility: truthy(cmd.dash) || truthy(cmd.mobility),
      moveX: mx,
      moveY: my,
      equipmentPressed: truthy(cmd.equipment) || truthy(cmd.equipmentPressed),
    }, this.covers, others);
    hero.aimX = savedAimX;
    hero.aimY = savedAimY;
    hero.facing = { x: hero.facingX, y: hero.facingY };
    hero.aim = { x: hero.facingX, y: hero.facingY };
    if (gun.kind === "fire" && gun.used) {
      this.ingestProjectiles(gun.projectiles, hero);
      this.fx.push({ slot: hero.slot, x: hero.x, y: hero.y, aimX: hero.aimX, aimY: hero.aimY });
    }
    for (const hit of gun.hits) {
      const vic = this.heroes.get(hit.targetSlot);
      if (vic) {this.hurtHero(hero.slot, vic, hit.damage, hit.source);}
    }
  }

  private ingestProjectiles(shots: GunProjectile[], hero: SimHero): void {
    const dirLen = Math.hypot(hero.facingX, hero.facingY) || 1;
    const muzzleX = hero.x + (hero.facingX / dirLen) * 28;
    const muzzleY = hero.y + (hero.facingY / dirLen) * 28;
    for (const p of shots) {
      const id = this.nextBulletId;
      this.nextBulletId += 1;
      this.bullets.set(id, {
        id, x: muzzleX, y: muzzleY, vx: p.vx, vy: p.vy, owner: p.owner, ttl: p.ttl, kind: p.kind,
        damage: p.damage, radius: BULLET_RADIUS, splash: p.splash, pierce: p.pierce,
        knockback: p.knockback, source: p.source, heavy: p.heavy, leech: p.leech, ccTime: p.ccTime,
      });
    }
  }

  private ingestShell(shell: TowerShell): void {
    const id = this.nextBulletId;
    this.nextBulletId += 1;
    this.bullets.set(id, {
      id, x: shell.x, y: shell.y, vx: shell.vx, vy: shell.vy, owner: shell.owner, ttl: shell.ttl,
      kind: shell.kind, damage: shell.damage, radius: shell.radius, splash: shell.splash,
      pierce: shell.pierce, knockback: shell.knockback, source: shell.source, heavy: false,
      leech: shell.leech, ccTime: shell.ccTime,
    });
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
    this.hitCrates(b);
    this.hitCores(b);
    const victim = this.hitHero(b);
    if (!victim) {return false;}
    this.hurtHero(b.owner, victim, b.damage, b.source);
    if (b.pierce > 0) {
      b.pierce -= 1;
      return false;
    }
    return true;
  }

  private hitCrates(b: SimBullet): void {
    for (let i = 0; i < this.crates.length; i += 1) {
      const c = this.crates[i];
      if (!c.alive) {continue;}
      if (Math.hypot(b.x - c.x, b.y - c.y) > (b.radius || BULLET_RADIUS) + CRATE_RADIUS) {continue;}
      hurtCrate(this.crates, this.crateOrbs, i, b.damage);
    }
  }

  private hitCores(b: SimBullet): void {
    for (const core of this.cores) {
      if (!projectileHitsCore(b.x, b.y, b.radius || BULLET_RADIUS, core)) {continue;}
      const owner = this.heroes.get(core.slot);
      const attacker = this.heroes.get(b.owner);
      if (!attacker) {continue;}
      damageCore(core, owner, attacker, b.damage * 0.78);
    }
  }

  private hitHero(b: SimBullet): SimHero | null {
    const hitR = HERO_RADIUS + (b.radius || BULLET_RADIUS);
    for (const hero of this.heroes.values()) {
      if (!hero.alive || hero.slot === b.owner) {continue;}
      if ((hero.x - b.x) ** 2 + (hero.y - b.y) ** 2 <= hitR * hitR) {return hero;}
    }
    return null;
  }

  private hurtHero(owner: number, victim: SimHero, amount: number, source = "normal"): void {
    const attacker = this.heroes.get(owner);
    const event = applyScoredDamage(this.heroes, owner, victim, amount);
    if (attacker) {applyHitUltCharge(attacker, victim, amount, source, owner === victim.slot);}
    if (event === "down" || event === "dead") {
      this.knockouts.push(spawnKnockout(victim));
    }
  }

  private stepDeployables(dt: number): void {
    const cores = new Map<number, DeployableCore>();
    for (const c of this.cores) {
      const owner = this.heroes.get(c.slot);
      cores.set(c.slot, {
        slot: c.slot, x: c.x, y: c.y, alive: c.alive,
        exposed: coreExposed(c, owner),
      });
    }
    const events = updateDeployables(this.deploy, this.heroes, cores, this.covers, dt);
    for (const ev of events) {this.applyDeployableEvent(ev);}
  }

  private applyDeployableEvent(ev: DeployableEvent): void {
    if (ev.kind === "mineExplode") {
      this.zones.push({
        x: ev.x, y: ev.y, radius: ev.blastRadius, owner: ev.owner,
        delay: 0.01, damage: ev.damage, effectKind: "explosion", label: ev.label,
      });
      return;
    }
    if (ev.kind === "wallHitHero") {
      const vic = this.heroes.get(ev.target);
      if (vic) {this.hurtHero(ev.owner, vic, ev.damage, "equipment");}
      return;
    }
    if (ev.kind === "wallHitCore") {
      const core = this.cores.find((c) => c.slot === ev.target);
      const attacker = this.heroes.get(ev.owner);
      const owner = core ? this.heroes.get(core.slot) : undefined;
      if (core && attacker) {damageCore(core, owner, attacker, ev.damage);}
    }
  }

  private stepTower(dt: number): void {
    const hooks: TowerHooks = {
      damageHeroEnvironment: (slot, damage) => {
        const h = this.heroes.get(slot);
        if (h) {this.hurtHero(-1, h, damage, "environment");}
      },
      pushHero: (slot, pushX, pushY) => {
        const h = this.heroes.get(slot);
        if (!h) {return;}
        const slid = resolveCoverMotion(h.x, h.y, pushX, pushY, this.covers);
        const next = clampArena(slid.x, slid.y);
        h.x = next.x;
        h.y = next.y;
      },
      spawnShell: (shell) => {this.ingestShell(shell);},
      spawnZone: (zone: TowerZone) => {
        this.zones.push({
          x: zone.x, y: zone.y, radius: zone.radius, owner: zone.owner,
          delay: zone.delay, damage: zone.damage, effectKind: zone.effectKind, label: zone.label,
        });
      },
    };
    updateMidTower(this.midTower, this.heroes, this.result === "playing", this.matchTime, hooks, dt);
  }

  private advanceZones(dt: number): void {
    const kept: SimZone[] = [];
    for (const z of this.zones) {
      z.delay -= dt;
      if (z.delay > 0) {
        kept.push(z);
        continue;
      }
      for (const h of this.heroes.values()) {
        if (!h.alive || h.slot === z.owner) {continue;}
        if (Math.hypot(h.x - z.x, h.y - z.y) <= z.radius + HERO_RADIUS) {
          this.hurtHero(z.owner, h, z.damage, "equipment");
        }
      }
    }
    this.zones = kept;
  }

  private stepThreat(dt: number): void {
    const ev = updateThreat(this.wanted, this.heroes.values(), dt);
    if (ev) {this.announce(ev.announce, ev.announceTicks);}
  }
}

export function packZonesSnap(zones: readonly SimZone[]): Array<Record<string, unknown>> {
  return zones.map((z) => ({
    x: z.x, y: z.y, radius: z.radius, owner: z.owner, delay: z.delay,
    warning_duration: z.delay, color: "#ff3349", effect_kind: z.effectKind, label: z.label,
  }));
}

export function seed(seats: readonly SeatSeed[], matchSeed = 0, mode = "classic"): MatchSim {
  return new MatchSim(seats, matchSeed, mode);
}

export function tick(sim: MatchSim, dt = FIXED_DT): void {
  sim.step(dt);
}

export function apply(sim: MatchSim, slot: number, data: MatchInput): void {
  sim.pushInput(slot, data);
}

export function packMatchWorld(sim: MatchSim): Record<string, unknown> {
  return {
    cores: packCoresSnap(sim.cores),
    crates: packCratesSnap(sim.crates),
    crate_orbs: packCrateOrbsSnap(sim.crateOrbs),
    mid_tower: packMidTowerSnap(sim.midTower),
    deployables: snapDeployables(sim.deploy.deployables),
    zones: packZonesSnap(sim.zones),
    finish_cine: packFinishCine(sim.finishCine),
    callout: sim.callout,
    calloutTicks: sim.calloutTicks,
    ...packWantedSnap(sim.wanted),
  };
}

export {
  packCoresSnap, packCratesSnap, packCrateOrbsSnap,
  packFinishCine, packMidTowerSnap, packWantedSnap, snapDeployables,
};
