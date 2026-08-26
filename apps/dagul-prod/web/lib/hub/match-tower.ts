/**
 * 중앙 바운티 타워 — 원본 mid_tower.gd 의 결정론 포팅. RNG·시계 없음.
 * 포탄·장판·환경 피해·밀치기는 TowerHooks 로 내보내고 통합측이 배선한다.
 * 발사 패턴(링·부채꼴·카펫)은 match-tower-fire.ts 에 있다.
 */
import { ARENA_CENTER, HERO_RADIUS } from "./match-covers.js";
import { addEffect, type EffectStore } from "./match-effects.js";
import {
  TOWER_DAMAGE,
  TOWER_RADIUS,
  firePattern,
  type TowerHooks,
} from "./match-tower-fire.js";

export { TOWER_DAMAGE, TOWER_INTERVAL, TOWER_RADIUS } from "./match-tower-fire.js";
export type { TowerHooks, TowerShell, TowerZone } from "./match-tower-fire.js";

export const TOWER_SPAWN_TIME = 75;
export const TOWER_MAX_HP = 2400;
export const TOWER_RANGE = 820;
/** 파괴 보상 — killer 는 wanted 룰렛 3회, 어시스트는 1회 (mid_tower.gd:104-109). */
export const TOWER_KILLER_ROULETTE = 3;
/** 어시스트 최소 피해 비율 — max(28, max_hp*0.18)=432 (match_lifecycle.gd:133). */
export const TOWER_ASSIST_RATIO = 0.18;
/** 어시스트 인정 창 — 8초 = 480틱 (match_lifecycle.gd:134, FIXED_DT 1/60). */
export const TOWER_ASSIST_WINDOW_TICKS = 480;
const ASSIST_MIN_DAMAGE = 28;
/** 스폰 직후 첫 발사 대기 — update_mid_tower(mid_tower.gd:40). */
const SPAWN_FIRE_CD = 1.2;
/** reset 시 초기 fire_cd — reset_mid_tower(mid_tower.gd:23). */
const RESET_FIRE_CD = 0.8;
/** 근접 크러시 — tower_point_blank: 재사용 0.32s, 도달 = 86+20+26, 피해 22*0.85, 밀치기 34. */
const CRUSH_CD = 0.32;
const CRUSH_BOING = 0.16;
const CRUSH_REACH = TOWER_RADIUS + HERO_RADIUS + 26;
const CRUSH_DAMAGE = TOWER_DAMAGE * 0.85;
const CRUSH_PUSH = 34;

export type TowerHero = {
  slot: number;
  x: number;
  y: number;
  alive: boolean;
  eliminated: boolean;
};

export type TowerHitRecord = { dmg: number; tick: number };

export type SimMidTower = {
  alive: boolean;
  spawned: boolean;
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  fireCd: number;
  pattern: number;
  boing: number;
  crushCd: number;
  lastHit: number;
  hits: Map<number, TowerHitRecord>;
};

/** 라운드 시작 상태 — reset_mid_tower. 75초 전에는 spawned/alive 둘 다 false. */
export function resetMidTower(): SimMidTower {
  return {
    alive: false,
    spawned: false,
    x: ARENA_CENTER.x,
    y: ARENA_CENTER.y,
    hp: TOWER_MAX_HP,
    maxHp: TOWER_MAX_HP,
    fireCd: RESET_FIRE_CD,
    pattern: 0,
    boing: 0,
    crushCd: 0,
    lastHit: -1,
    hits: new Map(),
  };
}

function spawnTower(tower: SimMidTower, fx?: EffectStore): void {
  tower.spawned = true;
  tower.alive = true;
  tower.hp = TOWER_MAX_HP;
  tower.maxHp = TOWER_MAX_HP;
  tower.hits = new Map();
  tower.lastHit = -1;
  tower.fireCd = SPAWN_FIRE_CD;
  tower.pattern = 0;
  tower.boing = 0;
  addEffect(fx, {
    kind: "explosion", x: ARENA_CENTER.x, y: ARENA_CENTER.y, radius: 90, duration: 0.45,
    color: "#ffb347", label: "TOWER",
  });
}

function crushHero(
  tower: SimMidTower, hero: TowerHero, hooks: TowerHooks, fx?: EffectStore,
): boolean {
  if (!hero.alive || hero.eliminated) {return false;}
  if (Math.hypot(hero.x - tower.x, hero.y - tower.y) > CRUSH_REACH) {return false;}
  hooks.damageHeroEnvironment(hero.slot, CRUSH_DAMAGE);
  let pushX = hero.x - tower.x;
  let pushY = hero.y - tower.y;
  const len = Math.hypot(pushX, pushY);
  if (len > 0) {
    pushX /= len;
    pushY /= len;
  }
  // direction_to 결과의 length_squared < 0.05 — 영벡터만 Vector2.RIGHT.rotated(slot).
  if (pushX * pushX + pushY * pushY < 0.05) {
    pushX = Math.cos(hero.slot);
    pushY = Math.sin(hero.slot);
  }
  hooks.pushHero(hero.slot, pushX * CRUSH_PUSH, pushY * CRUSH_PUSH);
  addEffect(fx, {
    kind: "explosion", x: hero.x, y: hero.y, radius: 42, duration: 0.18,
    color: "#ff7a3a", label: "TOWER",
  });
  return true;
}

function towerPointBlank(
  tower: SimMidTower,
  heroes: ReadonlyMap<number, TowerHero>,
  hooks: TowerHooks,
  dt: number,
  fx?: EffectStore,
): void {
  tower.crushCd = Math.max(0, tower.crushCd - dt);
  if (tower.crushCd > 0) {return;}
  let hitAny = false;
  const list = [...heroes.values()].sort((a, b) => a.slot - b.slot);
  for (const hero of list) {
    if (crushHero(tower, hero, hooks, fx)) {hitAny = true;}
  }
  if (!hitAny) {return;}
  tower.crushCd = CRUSH_CD;
  tower.boing = CRUSH_BOING;
}

function nearestHeroSlot(tower: SimMidTower, heroes: ReadonlyMap<number, TowerHero>): number {
  let best = -1;
  let bestDist = TOWER_RANGE;
  const list = [...heroes.values()].sort((a, b) => a.slot - b.slot);
  for (const hero of list) {
    if (!hero.alive || hero.eliminated) {continue;}
    const dist = Math.hypot(hero.x - tower.x, hero.y - tower.y);
    if (dist >= bestDist) {continue;}
    bestDist = dist;
    best = hero.slot;
  }
  return best;
}

/** 매 틱 갱신 — update_mid_tower: 75초 스폰 → 크러시 → 1.85s 주기 3패턴 발사. */
export function updateMidTower(
  tower: SimMidTower,
  heroes: ReadonlyMap<number, TowerHero>,
  playing: boolean,
  matchTime: number,
  hooks: TowerHooks,
  dt: number,
  fx?: EffectStore,
): void {
  if (!playing) {return;}
  if (!tower.spawned && matchTime >= TOWER_SPAWN_TIME) {
    spawnTower(tower, fx);
    return;
  }
  if (!tower.alive) {return;}
  tower.boing = Math.max(0, tower.boing - dt);
  tower.fireCd = Math.max(0, tower.fireCd - dt);
  towerPointBlank(tower, heroes, hooks, dt, fx);
  if (tower.fireCd > 0) {return;}
  const best = heroes.get(nearestHeroSlot(tower, heroes));
  if (!best) {return;}
  firePattern(tower, best.x, best.y, hooks);
}

export type TowerDownResult = {
  /** wanted 룰렛 3회 대상. 막타가 죽어 있으면 -1 (보상 없음, 원본과 동일). */
  killer: number;
  /** wanted 룰렛 1회 대상 — 432+ 피해를 8초 창 안에 넣은 생존자(막타 제외). */
  assists: number[];
};

function towerAssistSlots(
  tower: SimMidTower,
  tick: number,
  heroes: ReadonlyMap<number, TowerHero>,
): number[] {
  const need = Math.max(ASSIST_MIN_DAMAGE, tower.maxHp * TOWER_ASSIST_RATIO);
  const out: number[] = [];
  for (const [slot, rec] of tower.hits) {
    if (slot === tower.lastHit) {continue;}
    const hero = heroes.get(slot);
    if (!hero || !hero.alive) {continue;}
    if (rec.dmg + 0.001 < need) {continue;}
    if (tick - rec.tick > TOWER_ASSIST_WINDOW_TICKS) {continue;}
    out.push(slot);
  }
  return out;
}

function recordTowerHit(tower: SimMidTower, owner: number, damage: number, tick: number): void {
  if (owner < 0) {return;}
  tower.lastHit = owner;
  const rec = tower.hits.get(owner) ?? { dmg: 0, tick: 0 };
  rec.dmg += damage;
  rec.tick = tick;
  tower.hits.set(owner, rec);
}

/** 타워 피해 — hurt_tower. 파괴 시 보상 대상(TowerDownResult)을 돌려준다. */
export function hurtTower(
  tower: SimMidTower,
  owner: number,
  damage: number,
  tick: number,
  heroes: ReadonlyMap<number, TowerHero>,
  fx?: EffectStore,
): TowerDownResult | null {
  if (!tower.alive || damage <= 0) {return null;}
  tower.hp -= damage;
  recordTowerHit(tower, owner, damage, tick);
  if (tower.hp > 0) {return null;}
  tower.hp = 0;
  tower.alive = false;
  const killerHero = heroes.get(tower.lastHit);
  const killer = killerHero && killerHero.alive ? tower.lastHit : -1;
  addEffect(fx, {
    kind: "explosion", x: tower.x, y: tower.y, radius: 110, duration: 0.55,
    color: "#ff5a4a", label: "BOUNTY",
  });
  return { killer, assists: towerAssistSlots(tower, tick, heroes) };
}

/** 스냅 mid_tower — _snap_tower: Godot parse_mid_tower 필드 alive·x·y·hp·max_hp·boing. */
export function packMidTowerSnap(tower: SimMidTower): Record<string, unknown> {
  return {
    alive: tower.alive,
    x: tower.x,
    y: tower.y,
    hp: tower.hp,
    max_hp: tower.maxHp,
    boing: tower.boing,
  };
}

export const packMidTower = packMidTowerSnap;
export const seedMidTower = resetMidTower;
export const tickMidTower = updateMidTower;
export const applyTowerDamage = hurtTower;
export const seed = resetMidTower;
export const tick = updateMidTower;
export const apply = hurtTower;
export const pack = packMidTowerSnap;
