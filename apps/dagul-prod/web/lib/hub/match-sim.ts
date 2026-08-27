/* eslint-disable max-lines, complexity, max-depth -- 매치 시뮬 파사드: 모듈 조합·히어로 틱이 한 파일 */
import { idForBind, matchBindKey, seedSeatIdentities } from "../characters/index.js";
import {
  ARENA_SIZE, HERO_RADIUS, buildTiledCovers, clampArena,
  nudgeOutOfCover, pointInCover, resolveCoverMotion, resolveCoverMotionSwept, spawnKnockout, spawnPoint, tickKnockouts,
} from "./match-covers.js";
import type { CoverRect, SimKnockout } from "./match-covers.js";
import { CpuFleet } from "./match-cpu-think.js";
import { applyEmoteInput, emoteSeedFields, tickEmotes, type EmoteFields } from "./match-emote.js";
import {
  applyZoneLifeDamage, crawlDowned, downHero, lifeSeedFields, tickDowns,
  tickSpawnProtect, updateRespawns,
} from "./match-life.js";
import type { LifeHero } from "./match-life.js";
import {
  applyScoredDamage, awardWinScore, resetDeadStreaks, scoreSeedFields, streakCalloutSeed,
  tickStreakCallout, type ScoreFields, type StreakCalloutState,
} from "./match-score.js";
import {
  handleUseInput, lootSeedFields, seedHealthPickups, spawnGunLootPickup, tryCollectGunLoot,
  updateHealthPickups, steerSlide, SPRING_BOOST,
} from "./match-loot.js";
import type { LootHero, LootPickup } from "./match-loot.js";
import { heroInOwnPocket, updateItemPulses, type ItemHero, type ItemWorld } from "./match-item.js";
import {
  MATCH_TIME_LIMIT, createSafeZone, pickTimeLimitWinner, updateSafeZone,
} from "./match-zone.js";
import type { SafeZoneState } from "./match-zone.js";
import {
  addChargeBreakEffect, addEvadeEffect, addHeroHitEffect, addMobilityDashEffects,
  createEffectStore, decayEffects, type EffectStore,
} from "./match-effects.js";
import {
  accumulateComboDamage, applyControl, applyGuard, applyHitstun, ccSeedFields, comboAmplifier,
  movementControl, registerComboHit, superArmorActive, tickCc,
} from "./match-cc.js";
import type { CcHeroState } from "./match-cc.js";
import {
  packCoresSnap, spawnCores, damageCore, coreExposed, projectileHitsCore, zoneCoversCore,
  streakDamageMultiplier, PROJECTILE_CORE_DAMAGE_MULT, ZONE_CORE_DAMAGE_MULT,
} from "./match-core.js";
import type { SimCore } from "./match-core.js";
import {
  crateHeroSeedFields, spawnBreakableCrates, updateCrateOrbs, tickDmgOrbTime,
  hurtCrate, damageCratesAt, packCratesSnap, packCrateOrbsSnap, CRATE_ORB_DMG_MUL, CRATE_RADIUS,
  applySafeZoneCrateDamage,
} from "./match-crate.js";
import type { CrateHero, SimCrate, SimCrateOrb } from "./match-crate.js";
import {
  placeBounceWall, placeMine, seedDeployables, updateDeployables,
  type DeployableCore, type DeployableEvent, type DeployableState,
} from "./match-deployable.js";
import { snapDeployables, tickWallHitCd } from "./match-deployable-hit.js";
import { GUN_LOOT_MODES, makeEquipment, startEquipmentId, equipmentReach, nextGunLootId } from "./match-equipment.js";
import {
  applyGunInput, gunSeedFields, tickGun, weaponPassiveDamageMul,
  HOP_AIR, HOP_LIFT_DEFAULT, type GunHero, type GunApplyResult, type GunProjectile,
} from "./match-gun.js";
import { SlotInputBuffer, type MatchInput } from "./match-input-queue.js";
import { CHARGE_MOVE_MUL, cancelSkillCharge } from "./match-skill.js";
import { skillsEnabled } from "./config.js";
import {
  applyFinish, packFinishCine, seedFinishCine, tickFinishCine, type FinishCine,
} from "./match-finish.js";
import {
  applyLaunch, isHeavyBlast, launchSeedFields, tickLaunch, tickLaunchTrailFade,
} from "./match-launch.js";
import type { LaunchState } from "./match-launch.js";
import { MatchRng } from "./match-rng.js";
import {
  hurtTower, packMidTowerSnap, resetMidTower, updateMidTower, TOWER_RADIUS,
  type SimMidTower, type TowerHooks,
} from "./match-tower.js";
import type { TowerShell, TowerZone } from "./match-tower-fire.js";
import {
  absorbWoolShield, applyUltimateInput, seedUltWorld, tickFightSurge, tickOxCharges, tickRatTides,
  tickSnakeSkins, tickDragonSmokes, tickTigerRoars, tickRabbitBurrows, tickHorseKicks, tickDogRush,
  tickRoosterEggs, tickPigMuds, tickWoolShields, tickClones, tickPassiveUltCharge,
  applyHitUltCharge, chargeHeroSeedFields, heroMoveSpeed, ultHeroSeedFields,
  type ChargeHero, type UltHero, type UltWorld,
} from "./match-ultimate.js";
import {
  absorbRouletteShield, assistSlots, createWantedState, grantKillRoulettes, isBountyVictim,
  packWantedSnap, queueRoulette, recordLifeHit, rouletteSeedFields, rouletteStat, tickRoulettes,
  updateThreat, wantedSeedFields,
  type LifeHitRec, type RouletteHero, type WantedHero, type WantedState,
} from "./match-wanted.js";

export * from "./match-covers.js";
export * from "./match-cpu.js";
export * from "./match-cpu-think.js";
export * from "./match-emote.js";
export { ONE_SHOT_INPUT_KEYS, INPUT_QUEUE_CAP, idleHoldInput, SlotInputBuffer } from "./match-input-queue.js";
export type { MatchInput } from "./match-input-queue.js";
export * from "./match-life.js";
export * from "./match-loot.js";
export * from "./match-score.js";
export * from "./match-zone.js";

/** 허브 권위 시뮬 — 방장 Godot 이 아니라 방이 월드의 원본이다. */

export const MOVE_SPEED = 419;
export const FIRE_INTERVAL = 0.105;
export const BULLET_RADIUS = 5;
/** equipment_registry.gd combat_stats_for("brawler").max_hp — 전역 기본이 아님. */
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
/** projectile_hit.gd splash 피해 배율. */
export const PROJECTILE_SPLASH_MUL = 0.55;
/** projectile_hit.gd leech 회복 배율. */
export const PROJECTILE_LEECH_MUL = 0.13;
/** projectile_hit.gd splash cc/knockback 배율. */
export const PROJECTILE_SPLASH_CC_MUL = 0.65;
export const PROJECTILE_SPLASH_KB_MUL = 0.65;
/** damage_system.gd:236 — 1 + clamp((match_time-65)/35, 0, 1.25). */
export const MATCH_DMG_TIME_START = 65;
export const MATCH_DMG_TIME_SPAN = 35;
export const MATCH_DMG_TIME_CAP = 1.25;
/** damage_system.gd:253 — 방어 룰렛 하한. */
export const ROULETTE_DEF_FLOOR = 0.05;

export type SimHero = LifeHero & Pick<LootHero, "medkits" | "useHeld" | "heldItem" | "pullTime" | "pocketTime"> & ScoreFields & EmoteFields
  & CcHeroState & LaunchState & CrateHero & WantedHero & RouletteHero & GunHero & UltHero & ChargeHero & {
    normalHits: number;
    equipmentHits: number;
    ack: number;
    characterId: string;
    cpu: boolean;
    parked: boolean;
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
    slideTime: number;
    springTime: number;
    lifeHits: Record<string, LifeHitRec>;
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
  hitSlots: number[];
  homing: number;
  arc: boolean;
  landingX: number;
  landingY: number;
  maxTtl: number;
  comboFinisher: boolean;
  label: string;
  controlKind: "slow" | "root" | "stun";
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
  source?: string;
  ccTime?: number;
  knockback?: number;
  leech?: boolean;
  comboFinisher?: boolean;
  controlKind?: "slow" | "root" | "stun";
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

/** DAGUL_SKILLS=off 이면 우클릭 차지/스킬 입력을 버리고 차지 상태를 끈다. */
function skillFlags(
  hero: SimHero,
  cmd: MatchInput,
): { held: boolean; pressed: boolean; released: boolean } {
  if (!skillsEnabled()) {
    if (hero.chargingSkill) {cancelSkillCharge(hero);}
    hero.equipmentHeld = false;
    return { held: false, pressed: false, released: false };
  }
  const held = truthy(cmd.equipment) || truthy(cmd.equipmentPressed);
  const pressed = truthy(cmd.equipmentPressed) || (held && !hero.equipmentHeld);
  const released = truthy(cmd.equipmentReleased) || (!held && hero.equipmentHeld);
  hero.equipmentHeld = held;
  return { held, pressed, released };
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
  readonly loot: LootPickup[];
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
  /** 스트릭·셧다운 콜아웃 상태 — match_lifecycle.gd:240-255. 스냅 헤더로 나간다. */
  readonly streakState: StreakCalloutState = streakCalloutSeed();
  /** 서버 권위 시각 이펙트 — projectile_hit.gd add_effect 대응. 스냅 "effects" 로 나간다. */
  readonly effects: EffectStore = createEffectStore();
  private nextBulletId = 1;
  private readonly inputBufs = new Map<number, SlotInputBuffer>();
  /** defineInput 이 이번 고정 틱에 준 명령. 있으면 큐 next() 보다 앞선다. */
  private readonly tickInputs = new Map<number, MatchInput>();
  /** 이번 틱에 next() 한 명령. finish cine 가 같은 프레임의 finish 를 읽는다. */
  private readonly appliedInputs = new Map<number, MatchInput>();
  private readonly cpuFleet: CpuFleet;
  private readonly rng: MatchRng;
  /** 권위 매치에서만 true — 전원 matchReady 전까지 카운트다운을 깎지 않는다. */
  countdownHeld = false;
  private timeLimitWarningEmitted = false;

  /** seed — 방 시드(room.state.seed). 0/미지정이면 CpuFleet 이 고정 폴백 시드를 쓴다. */
  constructor(seats: readonly SeatSeed[], seed = 0, mode = "classic") {
    this.mode = mode;
    this.rng = new MatchRng(seed);
    this.cpuFleet = new CpuFleet(seed);
    this.loot = seedHealthPickups(mode, this.rng);
    this.ultWorld = seedUltWorld(this.covers);
    this.ultWorld.effects = this.effects;
    this.crates = spawnBreakableCrates(this.covers);
    const count = Math.max(1, seats.length);
    this.cores = spawnCores(this.covers, PLAYER_COUNT);
    const bindKey = matchBindKey();
    const pinned = seats.map((seat) => {
      if (seat.cpu || (seat.characterId != null && seat.characterId !== "")) {return seat;}
      const characterId = idForBind(bindKey, seat.slot);
      return characterId ? { ...seat, characterId } : seat;
    });
    const identities = seedSeatIdentities(pinned);
    for (const seat of pinned) {
      const slot = seat.slot;
      if (slot < 0) {continue;}
      const pos = nudgeOutOfCover(spawnPoint(slot, count), this.covers);
      const seeded = identities.get(slot) ?? { characterId: "", animal: slot };
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
        parked: false,
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
        slideTime: 0,
        springTime: 0,
        lifeHits: {},
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
        hp: eq.maxHp,
        maxHp: eq.maxHp,
        baseMaxHp: eq.maxHp,
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
    let buf = this.inputBufs.get(slot);
    if (!buf) {
      buf = new SlotInputBuffer();
      this.inputBufs.set(slot, buf);
    }
    buf.enqueue(data);
  }

  /** 공식 고정 틱에서 defineInput.next() 결과를 이 스텝의 유일한 명령으로 둔다. */
  setTickInput(slot: number, data: MatchInput): void {
    if (!this.heroes.has(slot)) {return;}
    this.tickInputs.set(slot, data);
  }

  hasQueuedInput(slot: number): boolean {
    const buf = this.inputBufs.get(slot);
    return buf !== undefined && buf.q.length > 0;
  }

  step(dt = FIXED_DT): void {
    if (this.result !== "playing") {return;}
    this.tick += 1;
    this.ultWorld.tick = this.tick;
    this.fx = [];
    if (this.countdown > 0 || this.countdownHeld) {this.flushHeldInputs();}
    if (this.stepCountdown(dt)) {return;}
    this.matchTime = Math.min(MATCH_TIME_LIMIT, this.matchTime + dt);
    this.stepFightAndClock();
    this.updateTimers(dt);
    updateItemPulses(this.itemWorld(dt), dt);
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
    this.separateHeroes();
    tickRoosterEggs(this.ultWorld, this.heroes, dt);
    tickPigMuds(this.ultWorld, dt);
    tickWoolShields(this.heroes.values(), dt);
    for (const downed of applyZoneLifeDamage(this.zoneDamageHeroes(), this.zone, dt)) {
      this.knockouts.push(spawnKnockout(downed));
    }
    applySafeZoneCrateDamage(this.zone, this.crates, this.crateOrbs, dt);
    tickStreakCallout(this.streakState);
    decayEffects(this.effects, dt);
    tickDowns(this.heroes, this.zone, dt);
    tickClones(this.ultWorld, this.heroes, dt);
    updateHealthPickups(this.loot, this.heroes, dt, this.mode, {
      rng: this.rng, tick: this.tick, events: this.ultWorld.events, effects: this.effects,
    });
    updateCrateOrbs(this.crateOrbs, this.heroes, dt);
    updateRespawns(this.heroes, this.zone, this.covers, dt);
    tickKnockouts(this.knockouts, dt);
    this.stepDeployables(dt);
    this.stepTower(dt);
    this.advanceBullets(dt);
    this.advanceZones(dt);
    this.stepThreat(dt);
    resetDeadStreaks(this.heroes.values());
    if (this.matchTime >= MATCH_TIME_LIMIT) {
      this.matchTime = MATCH_TIME_LIMIT;
      this.resolveTimeLimit();
      return;
    }
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
    let standingCount = 0;
    let lastStanding: SimHero | undefined;
    for (const h of this.heroes.values()) {
      if (!h.eliminated) {standingCount += 1; lastStanding = h;}
    }
    if (standingCount > 1) {return;}
    this.result = standingCount === 0 ? "draw" : "won";
    this.winner = lastStanding?.slot ?? -1;
    if (lastStanding) {awardWinScore(lastStanding);}
  }

  /** 210초 도달 — 비탈락 생존자 중 HP비율 > 점수(kills*100) > 낮은 슬롯. */
  private resolveTimeLimit(): void {
    if (this.result !== "playing") {return;}
    const ranks: {slot: number; hp: number; maxHp: number; kills: number; score: number; alive: boolean}[] = [];
    for (const h of this.heroes.values()) {
      ranks.push({slot: h.slot, hp: h.hp, maxHp: h.maxHp, kills: h.kills, score: h.score, alive: h.alive && !h.eliminated});
    }
    const best = pickTimeLimitWinner(ranks);
    this.result = best < 0 ? "draw" : "won";
    this.winner = best;
    const winnerHero = best >= 0 ? this.heroes.get(best) : undefined;
    if (winnerHero) {awardWinScore(winnerHero);}
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
      this.freezeReady();
      return true;
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
      h.slideTime = Math.max(0, h.slideTime - dt);
      h.springTime = Math.max(0, h.springTime - dt);
      h.pullTime = Math.max(0, h.pullTime - dt);
      h.pocketTime = Math.max(0, h.pocketTime - dt);
      tickLaunchTrailFade(h, dt);
      tickPassiveUltCharge(h, dt);
      h.turtle = h.timedBuffs.some((b) => b.id === "turtle" && b.time > 0);
      h.rouletteRate = h.untilBuffs.rate + h.timedBuffs.reduce((s, b) => s + b.rate, 0);
      h.rouletteRange = h.untilBuffs.range + h.timedBuffs.reduce((s, b) => s + b.range, 0);
      h.magMax = h.equipment.magSize;
      h.equipmentId = h.equipment.id;
      h.preferredRange = h.equipment.preferredRange;
      h.normalReach = equipmentReach(h.equipment, h.rouletteRange);
    }
  }

  private applyHumans(dt: number): void {
    for (const [slot, hero] of this.heroes) {
      if (hero.cpu) {continue;}
      const forced = this.tickInputs.get(slot);
      this.tickInputs.delete(slot);
      const buf = this.inputBufs.get(slot);
      const cmd = forced ?? buf?.next();
      if (!cmd) {continue;}
      this.appliedInputs.set(slot, cmd);
      if (!hero.alive || hero.parked) {
        this.syncHoldFlags(hero, cmd);
        continue;
      }
      this.applyHero(hero, cmd, dt);
    }
  }

  /** 카운트다운·로딩 장벽 동안 쌓인 프레임을 홀드로 접고, fireHeld 를 맞춰 개전 합성 사격을 막는다. */
  private flushHeldInputs(): void {
    for (const [slot, hero] of this.heroes) {
      if (hero.cpu) {continue;}
      const buf = this.inputBufs.get(slot);
      if (!buf) {continue;}
      const held = buf.flushToIdle();
      if (!held) {continue;}
      this.appliedInputs.set(slot, held);
      this.syncHoldFlags(hero, held);
    }
  }

  private syncHoldFlags(hero: SimHero, cmd: MatchInput): void {
    hero.fireHeld = truthy(cmd.fire);
    if (skillsEnabled()) {
      hero.equipmentHeld = truthy(cmd.equipment) || truthy(cmd.equipmentPressed);
    }
  }

  private applyCpus(dt: number): void {
    for (const hero of this.heroes.values()) {
      if (!hero.alive || !hero.cpu) {continue;}
      this.driveCpu(hero, dt);
    }
  }

  private driveCpu(hero: SimHero, dt: number): void {
    const cmd = this.cpuFleet.command(hero, this.heroes.values(), this.tick, {
      zone: this.zone,
      pickups: this.loot,
      crates: this.crates,
      crateOrbs: this.crateOrbs,
      midTower: this.midTower,
      warnZones: this.zones,
      deployables: this.deploy.deployables,
      mode: this.mode,
      onTargetChange: (slot, from, to, betrayal): void => {
        this.ultWorld.events.push({ tick: this.tick, type: "target_changed", actor: slot, target: to, data: { from } });
        if (betrayal) {
          this.ultWorld.events.push({ tick: this.tick, type: "betrayal", actor: slot, target: to, data: { previous_target: from } });
        }
      },
    });
    if (!cmd) {return;}
    this.applyHero(hero, {
      mx: cmd.mx, my: cmd.my, aimX: cmd.aimX, aimY: cmd.aimY,
      fire: cmd.fire, firePressed: cmd.firePressed, ultimate: cmd.ultimate, dash: false,
      mobility: cmd.mobility, use: cmd.use,
      equipment: cmd.equipment, equipmentPressed: cmd.equipmentPressed,
      equipmentReleased: cmd.equipmentReleased,
    }, dt);
  }

  private stepFinishCine(dt: number): void {
    const atkCmd = this.appliedInputs.get(this.finishCine.atk);
    tickFinishCine(this.finishCine, this.heroes, { finish: truthy(atkCmd?.finish) }, dt, (atk, vic) => {
      const victim = this.heroes.get(vic);
      if (!victim) {return;}
      downHero(this.heroes, atk, victim);
      this.knockouts.push(spawnKnockout(victim));
    });
  }

  /** 원본 game_world.gd:35 — 코어 몸통 반경. */
  private static readonly CORE_RADIUS = 34;

  /** 히어로-코어·히어로-히어로 밀어내기 — 원본 hero_movement.gd:200-225 (원조 794-820). */
  private separateHeroes(): void {
    const heroes = [...this.heroes.values()];
    for (const h of heroes) {
      if (!h.alive) {continue;}
      this.pushOutOfCores(h);
    }
    for (let a = 0; a < heroes.length; a += 1) {
      if (!heroes[a].alive) {continue;}
      for (let b = a + 1; b < heroes.length; b += 1) {
        if (!heroes[b].alive) {continue;}
        this.pushApartPair(heroes[a], heroes[b]);
      }
    }
  }

  private pushOutOfCores(h: SimHero): void {
    for (const core of this.cores) {
      if (!core.alive || core.slot === h.slot) {continue;}
      const dx = h.x - core.x;
      const dy = h.y - core.y;
      const minDist = HERO_RADIUS + MatchSim.CORE_RADIUS;
      if (dx * dx + dy * dy >= minDist * minDist) {continue;}
      const len = Math.hypot(dx, dy) || 1;
      h.x = core.x + (dx / len) * minDist;
      h.y = core.y + (dy / len) * minDist;
    }
  }

  private pushApartPair(ha: SimHero, hb: SimHero): void {
    const dx = hb.x - ha.x;
    const dy = hb.y - ha.y;
    const minDist = HERO_RADIUS * 1.4;
    const distSq = dx * dx + dy * dy;
    if (distSq >= minDist * minDist) {return;}
    const len = Math.sqrt(distSq);
    // 원본: length_squared > 0.001 일 때만 정규화, 아니면 RIGHT.
    const nx = distSq > 0.001 ? dx / len : 1;
    const ny = distSq > 0.001 ? dy / len : 0;
    const push = Math.min(2, (minDist - len) * 0.4);
    ha.x -= nx * push;
    ha.y -= ny * push;
    hb.x += nx * push;
    hb.y += ny * push;
  }

  private moveLaunched(dt: number): void {
    tickLaunch(this.heroes.values(), dt, this.tick, this.covers, this.effects);
  }

  private itemWorld(dt: number): ItemWorld {
    return {
      mode: this.mode, tick: this.tick, dt,
      heroes: this.heroes as unknown as ReadonlyMap<number, ItemHero>,
      pickups: this.loot, events: this.ultWorld.events, effects: this.effects,
    };
  }

  private zoneDamageHeroes(): Map<number, SimHero> {
    const out = new Map<number, SimHero>();
    for (const [slot, h] of this.heroes) {
      if (heroInOwnPocket(h)) {continue;}
      out.set(slot, h);
    }
    return out;
  }

  private applyHero(hero: SimHero, cmd: MatchInput, dt: number): void {
    const seq = Math.max(0, Math.floor(num(cmd.seq)));
    if (seq > hero.ack) {hero.ack = seq;}
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
    if (truthy(cmd.ultimate)) {cancelSkillCharge(hero);}
    applyUltimateInput(this.ultWorld, this.heroes, hero.slot, truthy(cmd.ultimate), { x: hero.aimX, y: hero.aimY });
    if (truthy(cmd.hop) && hero.hopTime <= 0 && hero.hopLock <= 0 && hero.rootTime <= 0 && !hero.turtle) {
      hero.hopTime = HOP_AIR;
      hero.hopMax = HOP_AIR;
      hero.hopHeight = HOP_LIFT_DEFAULT;
    }
    const ctrl = movementControl(hero);
    if (ctrl.locked) {
      cancelSkillCharge(hero);
      return;
    }
    this.stepHeroMove(hero, mx, my, mlen, ctrl.mult, dt);
    handleUseInput(hero, truthy(cmd.use), this.itemWorld(dt));
    const savedAimX = hero.aimX;
    const savedAimY = hero.aimY;
    const others = [...this.heroes.values()].filter((h) => h.slot !== hero.slot);
    const skill = skillFlags(hero, cmd);
    const preDashX = hero.x;
    const preDashY = hero.y;
    // 원본 active_item.gd:52-61 — 대시가 콤보 캡처 탈출이면 ESCAPE, 콤보 중이면 COMBO BREAK.
    const preDashCombo: "none" | "combo_break" | "escape" = hero.comboCaptureTime > 0
      ? "escape" : (hero.comboHits > 0 ? "combo_break" : "none");
    const fireHeldNow = truthy(cmd.fire);
    const firePressed = truthy(cmd.firePressed) || (fireHeldNow && !hero.fireHeld);
    hero.fireHeld = fireHeldNow;
    const gun = applyGunInput(hero, {
      primary: fireHeldNow,
      primaryPressed: firePressed,
      reload: truthy(cmd.reload),
      mobility: truthy(cmd.dash) || truthy(cmd.mobility),
      moveX: mx,
      moveY: my,
      equipment: skill.held,
      equipmentPressed: skill.pressed,
      equipmentReleased: skill.released,
      dt,
      effects: this.effects,
    }, this.covers, others);
    hero.aimX = savedAimX;
    hero.aimY = savedAimY;
    hero.facing = { x: hero.facingX, y: hero.facingY };
    hero.aim = { x: hero.facingX, y: hero.facingY };
    if (hero.x !== preDashX || hero.y !== preDashY) {
      if (truthy(cmd.dash) || truthy(cmd.mobility)) {
        const dashLen = Math.hypot(hero.x - preDashX, hero.y - preDashY) || 1;
        addMobilityDashEffects(this.effects, {
          equipmentId: hero.equipment.id, slot: hero.slot,
          oldX: preDashX, oldY: preDashY, x: hero.x, y: hero.y,
          dirX: (hero.x - preDashX) / dashLen, dirY: (hero.y - preDashY) / dashLen,
          comboKind: preDashCombo,
        });
      }
    }
    this.consumeGunResult(hero, gun);
  }

  private stepHeroMove(hero: SimHero, mx: number, my: number, mlen: number, ctrlMult: number, dt: number): void {
    let mult = ctrlMult;
    if (hero.attackLockTime > 0) {mult *= 0.76;}
    if (hero.chargingSkill) {mult *= CHARGE_MOVE_MUL;}
    const spd = heroMoveSpeed(this.ultWorld, this.heroes, hero.slot, hero.equipment.moveSpeed) * mult;
    if (hero.slideTime > 0) {
      steerSlide(hero, mx, my, spd, dt);
    } else {
      hero.vx = mx * spd;
      hero.vy = my * spd;
      if (hero.springTime > 0) {this.applySpringBoost(hero, mx, my);}
      hero.vel = { x: hero.vx, y: hero.vy };
    }
    const slid = resolveCoverMotion(hero.x, hero.y, hero.vx * dt, hero.vy * dt, this.covers);
    const next = clampArena(slid.x, slid.y);
    hero.x = next.x;
    hero.y = next.y;
    if (hero.chargingSkill) {hero.action = "CHARGING_SKILL";}
    else {hero.action = mlen > 0.04 ? "run" : "idle";}
  }

  private applySpringBoost(hero: SimHero, mx: number, my: number): void {
    let bx = mx;
    let by = my;
    if (bx * bx + by * by < 0.1) {
      bx = hero.facingX;
      by = hero.facingY;
    }
    const len = Math.hypot(bx, by);
    if (len * len <= 0.1) {return;}
    hero.vx += (bx / len) * SPRING_BOOST;
    hero.vy += (by / len) * SPRING_BOOST;
  }

  private consumeGunResult(hero: SimHero, gun: GunApplyResult): void {
    const dropSkill = !skillsEnabled() && gun.kind === "skill";
    if (!dropSkill && (gun.kind === "fire" || gun.kind === "skill") && gun.used) {
      this.ingestProjectiles(gun.projectiles);
      this.fx.push({ slot: hero.slot, x: hero.x, y: hero.y, aimX: hero.aimX, aimY: hero.aimY });
    }
    if (dropSkill) {
      for (const hit of gun.hits) {
        const vic = this.heroes.get(hit.targetSlot);
        if (vic) {this.hurtHero(hero.slot, vic, hit.damage, hit.source);}
      }
      return;
    }
    for (const z of gun.zones) {
      this.zones.push({
        x: z.x, y: z.y, radius: z.radius, owner: z.owner, delay: z.delay, damage: z.damage,
        effectKind: z.effectKind, label: z.label, ccTime: z.ccTime, knockback: z.knockback,
        leech: z.leech, controlKind: z.controlKind,
      });
    }
    if (gun.mine) {
      placeMine(this.deploy, { slot: hero.slot, x: hero.x, y: hero.y }, gun.mine.x, gun.mine.y, this.covers, {
        damage: gun.mine.damage, blastRadius: gun.mine.blastRadius, armTime: gun.mine.armTime,
        lifetime: gun.mine.lifetime, fuseTime: gun.mine.fuseTime,
      }, this.effects);
    }
    if (gun.wall) {
      placeBounceWall(
        this.deploy, { slot: hero.slot, x: hero.x, y: hero.y },
        gun.wall.x, gun.wall.y, gun.wall.facingX, gun.wall.facingY, this.covers, {
          halfLength: gun.wall.halfLength, lifetime: gun.wall.lifetime, speed: gun.wall.speed,
          damage: gun.wall.damage, knockback: gun.wall.knockback,
        },
        this.effects,
      );
    }
    for (const hit of gun.hits) {
      const vic = this.heroes.get(hit.targetSlot);
      if (vic) {this.hurtHero(hero.slot, vic, hit.damage, hit.source);}
    }
  }

  private ingestProjectiles(shots: GunProjectile[]): void {
    for (const p of shots) {
      const id = this.nextBulletId;
      this.nextBulletId += 1;
      this.bullets.set(id, {
        id, x: p.x, y: p.y, vx: p.vx, vy: p.vy, owner: p.owner, ttl: p.ttl, kind: p.kind,
        damage: p.damage, radius: p.radius, splash: p.splash, pierce: p.pierce,
        knockback: p.knockback, source: p.source, heavy: p.heavy, leech: p.leech, ccTime: p.ccTime,
        hitSlots: [], homing: p.homing ?? 0, arc: Boolean(p.arc),
        landingX: p.landingX ?? 0, landingY: p.landingY ?? 0, maxTtl: p.maxTtl ?? p.ttl,
        comboFinisher: Boolean(p.comboFinisher), label: p.label ?? "",
        controlKind: p.controlKind ?? "slow",
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
      leech: shell.leech, ccTime: shell.ccTime, hitSlots: [], homing: 0, arc: false,
      landingX: 0, landingY: 0, maxTtl: shell.ttl, comboFinisher: false, label: "",
      controlKind: "slow",
    });
  }

  private advanceBullets(dt: number): void {
    for (const [id, b] of [...this.bullets]) {
      if (this.expireOrHit(b, dt)) {this.bullets.delete(id);}
    }
  }

  private expireOrHit(b: SimBullet, dt: number): boolean {
    if (b.arc) {return this.expireArcBomb(b, dt);}
    b.ttl -= dt;
    this.steerHoming(b, dt);
    b.x += b.vx * dt;
    b.y += b.vy * dt;
    if (b.ttl <= 0 || b.x < 0 || b.y < 0 || b.x > ARENA_SIZE.x || b.y > ARENA_SIZE.y) {
      return true;
    }
    if (pointInCover(b.x, b.y, this.covers)) {
      this.splashAround(b, -1);
      return true;
    }
    return this.consumeSolidHit(b);
  }

  /** projectile_hit.gd:101-103 — 착탄 시 풀딜 add_zone(delay=0.01). */
  private expireArcBomb(b: SimBullet, dt: number): boolean {
    b.ttl -= dt;
    b.x += b.vx * dt;
    b.y += b.vy * dt;
    if (b.ttl > 0) {return false;}
    b.x = b.landingX;
    b.y = b.landingY;
    this.zones.push({
      x: b.landingX, y: b.landingY, radius: b.splash, owner: b.owner, delay: 0.01,
      damage: b.damage, effectKind: "explosion", label: b.label, source: b.source || "normal",
      ccTime: b.ccTime, knockback: b.knockback, leech: false, comboFinisher: b.comboFinisher,
      controlKind: b.controlKind,
    });
    return true;
  }

  /** projectile_hit.gd:142-195 — 울 방패 → 히어로 → 코어 → 상자 → 타워. 명중 시 탄 소거. */
  private consumeSolidHit(b: SimBullet): boolean {
    if (this.hitWoolShield(b)) {return true;}
    const victim = this.hitHero(b);
    if (victim) {return this.finishHeroPierce(b, victim);}
    if (this.hitOneCore(b)) {return true;}
    if (this.hitOneCrate(b)) {return true;}
    return this.hitMidTower(b);
  }

  private finishHeroPierce(b: SimBullet, victim: SimHero): boolean {
    this.applyBulletHeroHit(b, victim);
    if (b.pierce > 0) {
      b.pierce -= 1;
      b.hitSlots.push(victim.slot);
      return false;
    }
    return true;
  }

  private hitWoolShield(b: SimBullet): boolean {
    const radius = b.radius || BULLET_RADIUS;
    for (const h of this.heroes.values()) {
      if (h.slot === b.owner) {continue;}
      if (absorbWoolShield(this.ultWorld, this.heroes, b.owner, h.slot, { x: b.x, y: b.y }, radius)) {
        return true;
      }
    }
    return false;
  }

  private applyBulletHeroHit(b: SimBullet, victim: SimHero): void {
    const attacker = this.heroes.get(b.owner);
    this.hurtHero(b.owner, victim, b.damage, b.source, {
      knockback: b.knockback,
      impactX: attacker?.x ?? b.x,
      impactY: attacker?.y ?? b.y,
      heavy: b.heavy,
      effectKind: projectileImpactKind(b.kind),
      ccTime: b.ccTime,
      attackFinisher: b.comboFinisher,
      label: b.label,
      controlKind: b.controlKind,
    });
    if (b.splash > 0) {this.splashAround(b, victim.slot);}
    if (b.leech && attacker?.alive) {
      attacker.hp = Math.min(attacker.maxHp, attacker.hp + b.damage * PROJECTILE_LEECH_MUL);
    }
  }

  private splashAround(b: SimBullet, primary: number): void {
    if (b.splash <= 0) {return;}
    const dmg = b.damage * PROJECTILE_SPLASH_MUL;
    const kb = b.knockback * PROJECTILE_SPLASH_KB_MUL;
    const cc = b.ccTime * PROJECTILE_SPLASH_CC_MUL;
    for (const h of this.heroes.values()) {
      if (!h.alive || h.slot === b.owner || h.slot === primary) {continue;}
      if (Math.hypot(h.x - b.x, h.y - b.y) > b.splash) {continue;}
      this.hurtHero(b.owner, h, dmg, b.source, {
        knockback: kb, impactX: b.x, impactY: b.y, effectKind: "explosion", label: "SPLASH", ccTime: cc,
      });
    }
    damageCratesAt(this.crates, this.crateOrbs, b.x, b.y, b.splash, dmg);
  }

  private hitOneCrate(b: SimBullet): boolean {
    const reach = (b.radius || BULLET_RADIUS) + CRATE_RADIUS;
    for (let i = 0; i < this.crates.length; i += 1) {
      const c = this.crates[i];
      if (!c.alive) {continue;}
      if (Math.hypot(b.x - c.x, b.y - c.y) > reach) {continue;}
      if (hurtCrate(this.crates, this.crateOrbs, i, b.damage) && isGunLootMode(this.mode)) {
        const breaker = this.heroes.get(b.owner);
        spawnGunLootPickup(this.loot, c.x, c.y, breaker ? nextGunLootId(breaker.equipment.id) : "");
      }
      if (b.splash > 0) {damageCratesAt(this.crates, this.crateOrbs, b.x, b.y, b.splash, b.damage);}
      return true;
    }
    return false;
  }

  private hitOneCore(b: SimBullet): boolean {
    const attacker = this.heroes.get(b.owner);
    if (!attacker) {return false;}
    for (const core of this.cores) {
      if (core.slot === b.owner) {continue;}
      if (!projectileHitsCore(b.x, b.y, b.radius || BULLET_RADIUS, core)) {continue;}
      damageCore(core, this.heroes.get(core.slot), attacker, b.damage * PROJECTILE_CORE_DAMAGE_MULT);
      return true;
    }
    return false;
  }

  private hitMidTower(b: SimBullet): boolean {
    const t = this.midTower;
    if (!t.alive) {return false;}
    if (Math.hypot(b.x - t.x, b.y - t.y) >= (b.radius || BULLET_RADIUS) + TOWER_RADIUS) {
      return false;
    }
    hurtTower(t, b.owner, b.damage, this.tick, this.heroes, this.effects);
    if (b.splash > 0) {
      hurtTower(t, b.owner, b.damage * 0.35, this.tick, this.heroes, this.effects);
    }
    return true;
  }

  private hitHero(b: SimBullet): SimHero | null {
    const hitR = HERO_RADIUS + (b.radius || BULLET_RADIUS);
    for (const hero of this.heroes.values()) {
      if (!hero.alive || hero.slot === b.owner || hero.burrowed) {continue;}
      if (b.hitSlots.includes(hero.slot)) {continue;}
      if ((hero.x - b.x) ** 2 + (hero.y - b.y) ** 2 <= hitR * hitR) {return hero;}
    }
    return null;
  }

  private steerHoming(b: SimBullet, dt: number): void {
    if (b.homing <= 0) {return;}
    let nearest: SimHero | null = null;
    let best = Infinity;
    for (const h of this.heroes.values()) {
      if (!h.alive || h.slot === b.owner) {continue;}
      const dist = Math.hypot(h.x - b.x, h.y - b.y);
      if (dist >= best) {continue;}
      best = dist;
      nearest = h;
    }
    if (!nearest) {return;}
    const speed = Math.hypot(b.vx, b.vy);
    if (speed <= 0) {return;}
    const dx = nearest.x - b.x;
    const dy = nearest.y - b.y;
    const dlen = Math.hypot(dx, dy) || 1;
    const turn = Math.min(1, Math.max(0, b.homing * dt));
    const nx = b.vx / speed + (dx / dlen - b.vx / speed) * turn;
    const ny = b.vy / speed + (dy / dlen - b.vy / speed) * turn;
    const nlen = Math.hypot(nx, ny) || 1;
    b.vx = (nx / nlen) * speed;
    b.vy = (ny / nlen) * speed;
  }

  private hurtHero(owner: number, victim: SimHero, amount: number, source = "normal", ctx: HurtCtx = {}): void {
    if (!victim.alive || victim.burrowed || victim.spawnProtect > 0) {return;}
    if (victim.evadeTime > 0) {
      victim.evadeTime = 0;
      addEvadeEffect(this.effects, victim.x, victim.y);
      return;
    }
    if (victim.chargingSkill) {
      // 원본 damage_system.gd:238-241 — 피격 시 차지 끊김 + charge_break 연출.
      cancelSkillCharge(victim);
      addChargeBreakEffect(this.effects, victim.x, victim.y);
    }
    const attacker = this.heroes.get(owner);
    const scaled = scaleGunHit(this, attacker, victim, amount, source, ctx);
    const cc = applyControl(victim, ctx.ccTime ?? 0, ctx.controlKind ?? "slow", {
      store: this.effects, x: victim.x, y: victim.y,
    });
    if (cc.zeroVelocity) {
      victim.vx = 0;
      victim.vy = 0;
      victim.vel = { x: 0, y: 0 };
    }
    if (cc.cancelCharge) {cancelSkillCharge(victim);}
    if (scaled.comboHit > 0 && source !== "normal") {
      applyHitstun(victim, scaled.comboHit, attacker?.equipment.id === "chain");
    }
    // 원본 damage_system.gd:350 — 피격 임팩트 연출 (반경 clamp 32~125).
    addHeroHitEffect(this.effects, {
      x: ctx.impactX ?? victim.x, y: ctx.impactY ?? victim.y,
      amount: scaled.amount, knockback: ctx.knockback ?? 0, source,
      kind: ctx.effectKind ?? "hit_spark", label: ctx.label ?? "",
      launchX: 0, launchY: 0,
      fromX: attacker?.x ?? victim.x, fromY: attacker?.y ?? victim.y,
    });
    if (owner >= 0) {recordLifeHit(victim.lifeHits, owner, scaled.amount, this.tick);}
    const event = applyScoredDamage(this.heroes, owner, victim, scaled.amount, this.streakState);
    if (attacker) {
      applyHitUltCharge(attacker, victim, scaled.amount, source, owner === victim.slot);
      this.applyGunShove(attacker, victim, source, ctx);
      if (event === "dead" && isGunLootMode(this.mode)) {
        tryCollectGunLoot(attacker, this.mode);
      }
    }
    if (event === "down") {
      this.knockouts.push(spawnKnockout(victim));
    }
    if (event === "dead") {
      this.queueKillRoulettes(owner, victim);
    }
  }

  private queueKillRoulettes(owner: number, victim: SimHero): void {
    if (owner < 0 || owner === victim.slot) {return;}
    const assists = assistSlots(owner, victim.slot, victim.lifeHits, this.heroes, this.tick);
    grantKillRoulettes(this.heroes, owner, victim.slot, isBountyVictim(this.wanted, victim.slot), assists, this.rng);
  }

  private applyGunShove(attacker: SimHero, victim: SimHero, source: string, ctx: HurtCtx): void {
    const effectKind = ctx.effectKind ?? "hit_spark";
    const label = ctx.label ?? "";
    const heavyBlast = isHeavyBlast(effectKind, label);
    applyLaunch(victim, {
      source,
      knockback: ctx.knockback ?? 0,
      guardTime: victim.guardTime,
      heavyBlast,
      attackFinisher: Boolean(ctx.attackFinisher),
      superArmorTime: victim.superArmorTime,
      superArmorStrength: victim.superArmorStrength,
      impactOrigin: { x: ctx.impactX ?? 0, y: ctx.impactY ?? 0 },
      attackerPos: { x: attacker.x, y: attacker.y },
      attackerAim: { x: attacker.aimX, y: attacker.aimY },
      weight: victim.weight,
      owner: attacker.slot,
      comboDamage: victim.comboDamage,
      covers: this.covers,
      chainWeapon: attacker.equipment.id === "chain",
    });
    const clamped = clampArena(victim.x, victim.y);
    victim.x = clamped.x;
    victim.y = clamped.y;
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
    const events = updateDeployables(this.deploy, this.heroes, cores, this.covers, dt, this.effects);
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
        const slid = resolveCoverMotionSwept(h.x, h.y, pushX, pushY, this.covers);
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
    updateMidTower(this.midTower, this.heroes, this.result === "playing", this.matchTime, hooks, dt, this.effects);
  }

  private advanceZones(dt: number): void {
    const kept: SimZone[] = [];
    for (const z of this.zones) {
      z.delay -= dt;
      if (z.delay > 0) {
        kept.push(z);
        continue;
      }
      this.applyZonePulse(z);
    }
    this.zones = kept;
  }

  private applyZonePulse(z: SimZone): void {
    const source = z.source ?? "equipment";
    for (const h of this.heroes.values()) {
      if (!h.alive || h.slot === z.owner) {continue;}
      if (Math.hypot(h.x - z.x, h.y - z.y) > z.radius + HERO_RADIUS) {continue;}
      this.hurtHero(z.owner, h, z.damage, source, {
        knockback: z.knockback ?? 0, impactX: z.x, impactY: z.y, effectKind: z.effectKind, label: z.label,
        ccTime: z.ccTime ?? 0, controlKind: z.controlKind ?? "slow", attackFinisher: z.comboFinisher,
      });
      if (z.leech) {
        const atk = this.heroes.get(z.owner);
        if (atk?.alive) {atk.hp = Math.min(atk.maxHp, atk.hp + z.damage * PROJECTILE_LEECH_MUL);}
      }
    }
    this.applyZoneCores(z);
  }

  private applyZoneCores(z: SimZone): void {
    const attacker = this.heroes.get(z.owner);
    if (!attacker) {return;}
    for (const core of this.cores) {
      if (core.slot === z.owner || !zoneCoversCore(z.x, z.y, z.radius, core)) {continue;}
      damageCore(core, this.heroes.get(core.slot), attacker, z.damage * ZONE_CORE_DAMAGE_MULT);
    }
  }

  private stepThreat(dt: number): void {
    const ev = updateThreat(this.wanted, this.heroes.values(), dt);
    if (ev) {this.announce(ev.announce, ev.announceTicks);}
  }
}

type HurtCtx = {
  knockback?: number;
  impactX?: number;
  impactY?: number;
  heavy?: boolean;
  attackFinisher?: boolean;
  label?: string;
  effectKind?: string;
  ccTime?: number;
  controlKind?: "slow" | "root" | "stun";
};

/** damage_system.gd:236. */
export function matchTimeDamageScale(matchTime: number): number {
  const t = (matchTime - MATCH_DMG_TIME_START) / MATCH_DMG_TIME_SPAN;
  return 1 + Math.min(MATCH_DMG_TIME_CAP, Math.max(0, t));
}

function isGunLootMode(mode: string): boolean {
  return (GUN_LOOT_MODES as readonly string[]).includes(mode);
}

/** projectile_hit.gd projectile_impact_kind. */
function projectileImpactKind(kind: string): string {
  if (kind === "beam") {return "beam_hit";}
  if (kind === "shell" || kind === "seeker") {return "explosion";}
  if (kind === "tether") {return "drain";}
  if (kind === "hammer") {return "hammer_slam";}
  if (kind === "slash") {return "slashwave";}
  if (kind === "fist") {return "fist_burst";}
  if (kind === "bomb") {return "explosion";}
  if (kind === "spear") {return "spear_line";}
  if (kind === "chain") {return "chain_arc";}
  if (kind === "shield") {return "shield_bash";}
  return "hit_spark";
}

function scaleGunHit(
  sim: MatchSim, attacker: SimHero | undefined, victim: SimHero, amount: number, source: string, ctx: HurtCtx,
): { amount: number; comboHit: number } {
  // damage_system.gd:227-257 — 스트릭·오브·패시브·시간·룰렛 atk/def·실드·가드는 소스 무관.
  // 콤보 증폭만 mobility 제외. 공격자 없는 환경 피해는 damage_hero_environment 경로.
  if (!attacker) {return { amount, comboHit: 0 };}
  amount *= streakDamageMultiplier(attacker.killStreak);
  if (attacker.dmgOrbTime > 0) {amount *= CRATE_ORB_DMG_MUL;}
  const dist = Math.hypot(attacker.x - victim.x, attacker.y - victim.y);
  amount *= weaponPassiveDamageMul(attacker.equipment.id, attacker.hp, attacker.maxHp, dist);
  amount *= matchTimeDamageScale(sim.matchTime);
  let comboHit = 0;
  if (source !== "mobility") {
    comboHit = registerComboHit(victim, attacker.slot, Boolean(ctx.attackFinisher));
    amount *= comboAmplifier(comboHit);
  }
  amount += rouletteStat(attacker, "atk");
  amount *= Math.max(ROULETTE_DEF_FLOOR, 1 - rouletteStat(victim, "def"));
  amount = absorbRouletteShield(victim, amount);
  const guarded = applyGuard(victim, amount, ctx.knockback ?? 0);
  amount = guarded.amount;
  ctx.knockback = guarded.knockback;
  if (superArmorActive(victim)) {victim.comboCaptureTime = 0;}
  if (source !== "mobility" && !victim.downed) {accumulateComboDamage(victim, amount);}
  return { amount, comboHit };
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
