/**
 * 다운·부활·리스폰·스폰 보호 — 원본 match_lifecycle.gd + damage_system.gd 의 결정론 포팅.
 * RNG·시계 없음: 상수와 dt(1/60 고정틱)만으로 상태가 정해진다.
 */
import { ARENA_CENTER, clampArena, nudgeOutOfCover, resolveCoverMotion } from "./match-covers.js";
import type { CoverRect } from "./match-covers.js";
import { SAFE_ZONE_DAMAGE_PER_SEC, heroInSafeZone } from "./match-zone.js";
import type { SafeZoneState } from "./match-zone.js";

export const MAX_REVIVES = 3;
export const RESPAWN_BASE = 3.0;
export const RESPAWN_RANK_STEP = 0.5;
export const RESPAWN_MAX = 5.5;
export const DOWN_BLEED_TIME = 5.0;
export const DOWN_FINISH_HP = 48.0;
/** 리스폰 직후 무적(초) — match_lifecycle.gd:204. */
export const SPAWN_PROTECT_RESPAWN = 3.0;
/** stand_up(자동 기상) 직후 무적(초) — match_lifecycle.gd:309. */
export const SPAWN_PROTECT_STAND_UP = 1.2;
/** 다운 중 기어가는 이동 속도 배율 — hero_movement.gd:39-44. */
export const DOWN_MOVE_MULT = 0.16;
/** 다운 중 자기장 피해 배율 — damage_system.gd:438-439. */
export const DOWN_ZONE_DAMAGE_MULT = 3.0;
/** 기상 시 HP 비율 — match_lifecycle.gd:305 (max_hp * 0.5). */
export const STAND_UP_HP_RATIO = 0.5;
/** 리스폰 위치 — 세이프존 경계 안쪽 여유/최소 거리(match_lifecycle.gd:170-178). */
const RESPAWN_ZONE_INSET = 80;
const RESPAWN_ZONE_MIN_DIST = 36;

export type LifeHero = {
  slot: number;
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  alive: boolean;
  mag: number;
  magMax: number;
  reloadLeft: number;
  fireCd: number;
  kills: number;
  deaths: number;
  downed: boolean;
  downLeft: number;
  downTaken: number;
  revivesUsed: number;
  eliminated: boolean;
  respawnLeft: number;
  spawnProtect: number;
  spawnX: number;
  spawnY: number;
};

export type LifeEvent = "none" | "down" | "dead";

/** SimHero 생성 시 다운/리스폰 관련 초기 필드 묶음. */
export function lifeSeedFields(spawnX: number, spawnY: number): Pick<
  LifeHero,
  | "downed" | "downLeft" | "downTaken" | "revivesUsed" | "eliminated"
  | "respawnLeft" | "spawnProtect" | "deaths" | "spawnX" | "spawnY"
> {
  return {
    downed: false, downLeft: 0, downTaken: 0, revivesUsed: 0, eliminated: false,
    respawnLeft: 0, spawnProtect: 0, deaths: 0, spawnX, spawnY,
  };
}

/** 다운 진입 — enter_down(match_lifecycle.gd:273-298). 즉사 대신 출혈 카운트다운 시작. */
export function enterDown(hero: LifeHero): void {
  hero.downed = true;
  hero.downLeft = DOWN_BLEED_TIME;
  hero.downTaken = 0;
  hero.hp = 0;
}

/**
 * 플레이어 피해 경로 말단 — damage_hero(damage_system.gd:217-371).
 * 무적이면 무시, 다운 중이면 down_taken 누적 후 48 이상에서 확정 킬,
 * 그 외에는 hp 감소 후 0 이하에서 다운 진입(즉사 없음).
 */
export function applyHeroDamage(
  heroes: ReadonlyMap<number, LifeHero>,
  owner: number,
  target: LifeHero,
  amount: number,
): LifeEvent {
  if (!target.alive || target.spawnProtect > 0) {return "none";}
  if (target.downed) {
    target.hp = 0;
    target.downTaken += amount;
    if (target.downTaken >= DOWN_FINISH_HP) {
      downHero(heroes, owner, target);
      return "dead";
    }
    return "none";
  }
  target.hp = Math.max(0, target.hp - amount);
  if (target.hp <= 0) {
    enterDown(target);
    return "down";
  }
  return "none";
}

/**
 * 확정 킬 — down_hero(match_lifecycle.gd:338-503).
 * 킬 크레딧은 다운 진입이 아니라 이 시점에 적립된다(_reward_attacker 대응).
 * revives_used 소진(>= MAX_REVIVES) 시 eliminated, 아니면 리스폰 대기 시작.
 */
export function downHero(
  heroes: ReadonlyMap<number, LifeHero>,
  owner: number,
  target: LifeHero,
): void {
  target.alive = false;
  target.hp = 0;
  target.downed = false;
  target.downLeft = 0;
  target.downTaken = 0;
  target.spawnProtect = 0;
  target.deaths += 1;
  if (owner >= 0 && owner !== target.slot) {
    const killer = heroes.get(owner);
    if (killer) {killer.kills += 1;}
  }
  const used = target.revivesUsed;
  if (used >= MAX_REVIVES) {
    target.eliminated = true;
    target.respawnLeft = 0;
    return;
  }
  target.revivesUsed = used + 1;
  target.respawnLeft = respawnDelayFor(heroes, target.slot);
}

/** 순위 비교 — score(허브는 kills*100) 내림차순 → kills 내림차순 → slot 오름차순. */
function compareStanding(a: LifeHero, b: LifeHero): number {
  const scoreA = a.kills * 100;
  const scoreB = b.kills * 100;
  if (scoreA !== scoreB) {return scoreB - scoreA;}
  if (a.kills !== b.kills) {return b.kills - a.kills;}
  return a.slot - b.slot;
}

/** 리스폰 딜레이 공식 — respawn_delay_for: min(5.5, 3.0 + 0.5 * from_last). */
export function respawnDelayFor(heroes: ReadonlyMap<number, LifeHero>, slot: number): number {
  const roster = [...heroes.values()].filter((h) => !h.eliminated || h.slot === slot);
  roster.sort(compareStanding);
  const rankFromTop = Math.max(0, roster.findIndex((h) => h.slot === slot));
  const fromLast = Math.max(0, roster.length - 1 - rankFromTop);
  return Math.min(RESPAWN_MAX, RESPAWN_BASE + RESPAWN_RANK_STEP * fromLast);
}

/** 자동 기상 — stand_up(match_lifecycle.gd:300-314). 세이프존 안 출혈 만료 시 50% HP + 1.2초 무적. */
export function standUp(hero: LifeHero): void {
  hero.downed = false;
  hero.downLeft = 0;
  hero.downTaken = 0;
  hero.alive = true;
  hero.hp = Math.max(1, hero.maxHp * STAND_UP_HP_RATIO);
  hero.spawnProtect = SPAWN_PROTECT_STAND_UP;
}

/** 무적 타이머 감소 — update_timers(match_lifecycle.gd:103) 대응. */
export function tickSpawnProtect(heroes: Iterable<LifeHero>, dt: number): void {
  for (const h of heroes) {
    h.spawnProtect = Math.max(0, h.spawnProtect - dt);
  }
}

/**
 * 다운 틱 — tick_downs(match_lifecycle.gd:316-336).
 * 출혈 만료 시 세이프존 밖이면 사망(크레딧 없음), 안이면 자동 기상.
 */
export function tickDowns(
  heroes: ReadonlyMap<number, LifeHero>,
  zone: SafeZoneState,
  dt: number,
): void {
  for (const h of heroes.values()) {
    if (!h.downed) {continue;}
    if (!h.alive) {
      h.downed = false;
      continue;
    }
    h.downLeft -= dt;
    if (h.downLeft > 0) {continue;}
    if (heroInSafeZone(zone, h.x, h.y)) {standUp(h);}
    else {downHero(heroes, -1, h);}
  }
}

/** 다운 중 자기장 피해 — 3배 가산 후 down_taken 누적, 48 이상이면 확정 킬(owner=-1). */
function bleedZoneDamage(heroes: ReadonlyMap<number, LifeHero>, h: LifeHero, amount: number): void {
  h.downTaken += amount * DOWN_ZONE_DAMAGE_MULT;
  if (h.downTaken >= DOWN_FINISH_HP) {downHero(heroes, -1, h);}
}

/**
 * 자기장 환경 피해 — damage_hero_environment + apply_lethal_or_down 대응.
 * 환경 피해는 킬 크레딧이 없다. 반환 = 이번 스텝에 새로 다운된 히어로(연출용).
 */
export function applyZoneLifeDamage<H extends LifeHero>(
  heroes: ReadonlyMap<number, H>,
  zone: SafeZoneState,
  dt: number,
): H[] {
  const downedNow: H[] = [];
  for (const h of heroes.values()) {
    if (!h.alive || heroInSafeZone(zone, h.x, h.y)) {continue;}
    if (h.downed) {
      bleedZoneDamage(heroes, h, SAFE_ZONE_DAMAGE_PER_SEC * dt);
      continue;
    }
    h.hp = Math.max(0, h.hp - SAFE_ZONE_DAMAGE_PER_SEC * dt);
    if (h.hp <= 0) {
      enterDown(h);
      downedNow.push(h);
    }
  }
  return downedNow;
}

/**
 * 리스폰 위치 — respawn_point(match_lifecycle.gd:170-178).
 * 원 스폰 위치가 세이프존 안이면 그대로, 밖이면 존 중심→홈 방향 경계 안쪽 80px.
 */
export function respawnPoint(
  hero: LifeHero,
  zone: SafeZoneState,
  covers: readonly CoverRect[],
): { x: number; y: number } {
  if (heroInSafeZone(zone, hero.spawnX, hero.spawnY)) {
    return nudgeOutOfCover(clampArena(hero.spawnX, hero.spawnY), covers);
  }
  const dx = hero.spawnX - ARENA_CENTER.x;
  const dy = hero.spawnY - ARENA_CENTER.y;
  const d = Math.hypot(dx, dy) || 1;
  const dist = Math.max(RESPAWN_ZONE_MIN_DIST, zone.radius - RESPAWN_ZONE_INSET);
  const safe = clampArena(ARENA_CENTER.x + (dx / d) * dist, ARENA_CENTER.y + (dy / d) * dist);
  return nudgeOutOfCover(safe, covers);
}

/** 리스폰 실행 — update_respawns(match_lifecycle.gd:180-213)의 본문. 3.0초 무적. */
function respawnHero(h: LifeHero, zone: SafeZoneState, covers: readonly CoverRect[]): void {
  const pos = respawnPoint(h, zone, covers);
  h.x = pos.x;
  h.y = pos.y;
  h.alive = true;
  h.hp = h.maxHp;
  h.mag = h.magMax;
  h.reloadLeft = 0;
  h.fireCd = 0;
  h.downed = false;
  h.downLeft = 0;
  h.downTaken = 0;
  h.respawnLeft = 0;
  h.spawnProtect = SPAWN_PROTECT_RESPAWN;
}

/** 리스폰 카운트다운 — 탈락자와 생존자는 건너뛴다. */
export function updateRespawns(
  heroes: ReadonlyMap<number, LifeHero>,
  zone: SafeZoneState,
  covers: readonly CoverRect[],
  dt: number,
): void {
  for (const h of heroes.values()) {
    if (h.eliminated || h.alive) {continue;}
    h.respawnLeft -= dt;
    if (h.respawnLeft > 0) {continue;}
    respawnHero(h, zone, covers);
  }
}

/** 다운 중 이동 — 정상 이동속도의 16% 로 기어간다(조준·발사·재장전 불가는 호출측 책임). */
export function crawlDowned(
  hero: LifeHero,
  mx: number,
  my: number,
  speed: number,
  dt: number,
  covers: readonly CoverRect[],
): void {
  const step = speed * DOWN_MOVE_MULT * dt;
  const slid = resolveCoverMotion(hero.x, hero.y, mx * step, my * step, covers);
  const next = clampArena(slid.x, slid.y);
  hero.x = next.x;
  hero.y = next.y;
}
