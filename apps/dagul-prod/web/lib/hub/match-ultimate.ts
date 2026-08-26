/* eslint-disable max-lines, complexity, max-depth -- 12지신 궁극기 3 GD + 차지를 exclusive 1파일로 이식 */
/**
 * 12지 궁극기 + 차지/파이팅서지 — 원본 ultimate_animal.gd + ultimate_summon.gd +
 * ultimate_effect.gd(wool/clones) + game_world.gd 차지 상수 + match_lifecycle.gd 킬 차지.
 * RNG·시계 없음: 상수와 dt 만으로 상태가 정해진다. 통합 배선은 이후 단계 몫.
 */
import {
  HERO_RADIUS,
  clampArena,
  nudgeOutOfCover,
  resolveCoverMotion,
  type CoverRect,
} from "./match-covers.js";
import { MATCH_TIME_LIMIT } from "./match-zone.js";
import { addEffect, type EffectStore } from "./match-effects.js";

export type Vec2 = { x: number; y: number };

/** game_world.gd:46-49 · crate 파랑 오브 비율 :62. */
export const ULTIMATE_MAX = 100;
export const ULT_CHARGE_PER_DAMAGE = 0.144;
export const ULT_CHARGE_TAKEN_RATIO = 0.6666667;
export const ULT_CHARGE_PER_SEC = 0.24;
/** match_lifecycle.gd:481 / :491. */
export const ULT_CHARGE_KILL = 35;
export const ULT_CHARGE_SHUTDOWN = 20;
/** crate_pickup.gd:129 — ULTIMATE_MAX * 0.34 = +34. */
export const CRATE_ORB_ULT_RATIO = 0.34;
/** try_ultimate 발동 하한 — ULTIMATE_MAX - 0.5. */
export const ULT_READY_EPSILON = 0.5;
export const ANIMAL_COUNT = 12;
export const ANIMAL_RAT = 0;
export const ANIMAL_OX = 1;
export const ANIMAL_TIGER = 2;
export const ANIMAL_RABBIT = 3;
export const ANIMAL_DRAGON = 4;
export const ANIMAL_SNAKE = 5;
export const ANIMAL_HORSE = 6;
export const ANIMAL_SHEEP = 7;
export const ANIMAL_MONKEY = 8;
export const ANIMAL_ROOSTER = 9;
export const ANIMAL_DOG = 10;
export const ANIMAL_PIG = 11;
export const ULT_CHARGE_CRATE_ORB = ULTIMATE_MAX * CRATE_ORB_ULT_RATIO;
export const DRAGON_SMOKE_SPEED_MULT = 1.3;
export const PIG_MUD_SPEED_MULT = 0.48;
/** game_world.gd:285-287. remaining 60s 진입 후 1.65s. */
export const FIGHT_SURGE_REMAINING = 60;
export const FIGHT_SURGE_DELAY = 1.65;
export const HERO_SPEED = 419;
export const HOP_LIFT_DEFAULT = 19;
export { MATCH_TIME_LIMIT };

const TAU = Math.PI * 2;
const LEN_EPS = 0.05;
const CHARGE_MIN = 0.0001;

export const SNAKE_SHED_GIANT: {
  id: string; name: string; kind: string; atk: number; spd: number; def: number;
  hp: number; rate: number; range: number; shield: number; dur: number;
} = {
  id: "giant",
  name: "GIANT",
  kind: "timed",
  atk: 3.0,
  spd: 5.0,
  def: 0.0,
  hp: 3.0,
  rate: 0.0,
  range: 0.0,
  shield: 0.0,
  dur: 12.0,
};

export type UltEvent = {
  tick: number;
  type: string;
  actor: number;
  target: number;
  data: Record<string, unknown>;
};

export type TimedBuff = {
  id: string;
  name: string;
  time: number;
  atk: number;
  spd: number;
  def: number;
  hp: number;
  rate: number;
  range: number;
  shield: number;
};

export type UltClone = {
  alive: boolean;
  ang: number;
  pos: Vec2;
  facing: Vec2;
  aim: Vec2;
  hopTime: number;
  hopHeight: number;
  animal: number;
  owner: number;
};

export type UltHero = {
  slot: number;
  animal: number;
  x: number;
  y: number;
  vel: Vec2;
  facing: Vec2;
  aim: Vec2;
  hp: number;
  maxHp: number;
  alive: boolean;
  downed: boolean;
  eliminated: boolean;
  ultimateCharge: number;
  ultimates: number;
  stunTime: number;
  launchTime: number;
  launchVel: Vec2;
  spawnProtect: number;
  superArmorTime: number;
  superArmorStrength: number;
  oxPhase: "" | "back" | "rush";
  oxTime: number;
  oxDir: Vec2;
  oxHit: number[];
  dogRush: boolean;
  dogWindup: number;
  dogBone: Vec2;
  dogHit: number[];
  burrowed: boolean;
  burrowLeft: number;
  burrowExit: Vec2;
  fleeTime: number;
  fleeFrom: Vec2;
  woolTime: number;
  woolHp: number;
  woolMax: number;
  ultCloneTime: number;
  ultClones: UltClone[];
  hopTime: number;
  hopHeight: number;
  fightSurgePending: boolean;
  rlTimed: TimedBuff[];
};

export type RatTide = {
  owner: number;
  pos: Vec2;
  dir: Vec2;
  life: number;
  travel: number;
  halfW: number;
  length: number;
};

export type DragonSmoke = { owner: number; pos: Vec2; radius: number; ttl: number };
export type SnakeSkin = {
  owner: number;
  pos: Vec2;
  facing: Vec2;
  aim: Vec2;
  animal: number;
  hp: number;
  maxHp: number;
  scale: number;
  ttl: number;
  flash: number;
  alive: boolean;
};
export type PigMud = { owner: number; pos: Vec2; radius: number; ttl: number };
export type RoosterEgg = {
  owner: number;
  pos: Vec2;
  ttl: number;
  arm: number;
  trigger: number;
  alive: boolean;
};
export type DogBone = { pos: Vec2; owner: number; ttl: number };
export type HorseKick = { pos: Vec2; dir: Vec2; age: number; life: number; reach: number };
export type TigerRoar = { pos: Vec2; age: number; life: number; radius: number; owner: number };
export type RabbitHole = { pos: Vec2; ttl: number; kind: "in" | "out" };

export type UltWorld = {
  tick: number;
  localSlot: number;
  ultimateFocusSlot: number;
  ultimateFocusTime: number;
  ultimateFocusMax: number;
  ratTides: RatTide[];
  dragonSmokes: DragonSmoke[];
  snakeSkins: SnakeSkin[];
  pigMuds: PigMud[];
  roosterEggs: RoosterEgg[];
  dogBones: DogBone[];
  horseKicks: HorseKick[];
  tigerRoars: TigerRoar[];
  rabbitHoles: RabbitHole[];
  fightCountdownEmitted: boolean;
  fightSurgeEmitted: boolean;
  fightSurgeAt: number;
  covers: CoverRect[];
  events: UltEvent[];
  effects?: EffectStore;
};

export type ChargeHero = {
  alive: boolean;
  eliminated: boolean;
  ultimateCharge: number;
  normalHits: number;
  equipmentHits: number;
};

export function vec(x = 0, y = 0): Vec2 {
  return { x, y };
}

function cloneVec(v: Vec2): Vec2 {
  return { x: v.x, y: v.y };
}

function lenSq(v: Vec2): number {
  return v.x * v.x + v.y * v.y;
}

function hypotVec(v: Vec2): number {
  return Math.hypot(v.x, v.y);
}

function normOr(v: Vec2, fallback: Vec2): Vec2 {
  const l = hypotVec(v);
  if (l * l < LEN_EPS) {return cloneVec(fallback);}
  return { x: v.x / l, y: v.y / l };
}

function normalizeOrRight(v: Vec2): Vec2 {
  return normOr(v, { x: 1, y: 0 });
}

function directionTo(from: Vec2, to: Vec2): Vec2 {
  return { x: to.x - from.x, y: to.y - from.y };
}

function rotate(v: Vec2, ang: number): Vec2 {
  const c = Math.cos(ang);
  const s = Math.sin(ang);
  return { x: v.x * c - v.y * s, y: v.x * s + v.y * c };
}

function dot(a: Vec2, b: Vec2): number {
  return a.x * b.x + a.y * b.y;
}

function dist(ax: number, ay: number, bx: number, by: number): number {
  return Math.hypot(ax - bx, ay - by);
}

function posmod(n: number, m: number): number {
  return ((n % m) + m) % m;
}

/** Godot maxf(0, t-dt) + <= 0. JS f64 잔여 1e-9 이하는 0. */
function decayTimer(t: number, dt: number): number {
  const next = t - dt;
  return next <= 1e-9 ? 0 : next;
}

/** Godot Vector2.angle_to — atan2(cross, dot), [-PI, PI]. */
function angleTo(a: Vec2, b: Vec2): number {
  return Math.atan2(a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y);
}

function emit(w: UltWorld, type: string, actor: number, target: number, data: Record<string, unknown> = {}): void {
  w.events.push({ tick: w.tick, type, actor, target, data });
}

function heroPos(h: UltHero): Vec2 {
  return { x: h.x, y: h.y };
}

function setPos(h: UltHero, p: Vec2): void {
  h.x = p.x;
  h.y = p.y;
}

function resolveMotion(w: UltWorld, from: Vec2, mx: number, my: number): Vec2 {
  return resolveCoverMotion(from.x, from.y, mx, my, w.covers);
}

function clampNudge(w: UltWorld, p: Vec2): Vec2 {
  const clamped = clampArena(p.x, p.y);
  return nudgeOutOfCover(clamped, w.covers);
}

function aimDir(h: UltHero, aim: Vec2): Vec2 {
  let dir = directionTo(heroPos(h), aim);
  if (lenSq(dir) < LEN_EPS) {dir = cloneVec(h.facing);}
  return normalizeOrRight(dir);
}

export function ultimateReady(charge: number): boolean {
  return charge >= ULTIMATE_MAX - ULT_READY_EPSILON;
}

export function chargeFromDamage(amount: number): number {
  return Math.max(0, amount) * ULT_CHARGE_PER_DAMAGE;
}

/** SimHero 생성 시 궁극기 관련 초기 필드 — game_world.gd:270. */
export function ultHeroSeedFields(slot: number, animal = slot): Omit<UltHero, "slot" | "x" | "y" | "hp" | "maxHp" | "alive"> {
  return {
    animal,
    vel: vec(),
    facing: vec(1, 0),
    aim: vec(1, 0),
    downed: false,
    eliminated: false,
    ultimateCharge: 0,
    ultimates: 0,
    stunTime: 0,
    launchTime: 0,
    launchVel: vec(),
    spawnProtect: 0,
    superArmorTime: 0,
    superArmorStrength: 0,
    oxPhase: "",
    oxTime: 0,
    oxDir: vec(1, 0),
    oxHit: [],
    dogRush: false,
    dogWindup: 0,
    dogBone: vec(),
    dogHit: [],
    burrowed: false,
    burrowLeft: 0,
    burrowExit: vec(),
    fleeTime: 0,
    fleeFrom: vec(),
    woolTime: 0,
    woolHp: 0,
    woolMax: 5,
    ultCloneTime: 0,
    ultClones: [],
    hopTime: 0,
    hopHeight: HOP_LIFT_DEFAULT,
    fightSurgePending: false,
    rlTimed: [],
  };
}

export function seedUltWorld(covers: readonly CoverRect[] = []): UltWorld {
  return {
    tick: 0,
    localSlot: -1,
    ultimateFocusSlot: -1,
    ultimateFocusTime: 0,
    ultimateFocusMax: 0,
    ratTides: [],
    dragonSmokes: [],
    snakeSkins: [],
    pigMuds: [],
    roosterEggs: [],
    dogBones: [],
    horseKicks: [],
    tigerRoars: [],
    rabbitHoles: [],
    fightCountdownEmitted: false,
    fightSurgeEmitted: false,
    fightSurgeAt: -1,
    covers: [...covers],
    events: [],
  };
}

export function chargeHeroSeedFields(): Pick<ChargeHero, "ultimateCharge" | "normalHits" | "equipmentHits"> {
  return { ultimateCharge: 0, normalHits: 0, equipmentHits: 0 };
}

export function addUltCharge(h: ChargeHero, charge: number): void {
  if (charge <= CHARGE_MIN) {return;}
  if (!h.alive || h.eliminated) {return;}
  h.ultimateCharge = Math.min(ULTIMATE_MAX, h.ultimateCharge + charge);
}

/** award_charge(damage_system.gd:411-420). source ultimate/mobility 는 공격자 차지 없음. */
export function awardDealtCharge(h: ChargeHero, amount: number, source: string): void {
  if (source === "ultimate" || source === "mobility") {return;}
  if (source === "equipment") {h.equipmentHits += 1;}
  else {h.normalHits += 1;}
  addUltCharge(h, chargeFromDamage(amount));
}

/** 피격자 차지 — charge_from_damage * ULT_CHARGE_TAKEN_RATIO (0.6666667). */
export function awardTakenCharge(h: ChargeHero, amount: number): void {
  addUltCharge(h, chargeFromDamage(amount) * ULT_CHARGE_TAKEN_RATIO);
}

/** 공격+피격 한 쌍 — damage_system.gd:346-349. 자해는 스킵. */
export function applyHitUltCharge(
  attacker: ChargeHero,
  victim: ChargeHero,
  amount: number,
  source: string,
  sameSlot: boolean,
): void {
  if (amount <= 0.01 || sameSlot) {return;}
  awardDealtCharge(attacker, amount, source);
  awardTakenCharge(victim, amount);
}

export function tickPassiveUltCharge(h: ChargeHero, dt: number): void {
  if (!h.alive || h.eliminated) {return;}
  addUltCharge(h, ULT_CHARGE_PER_SEC * dt);
}

/** crate_pickup.gd:129 — +34, 상한 100. */
export function applyCrateOrbUltCharge(h: ChargeHero): void {
  addUltCharge(h, ULTIMATE_MAX * CRATE_ORB_ULT_RATIO);
}

/** match_lifecycle.gd:481 — 킬 시 공격자가 살아 있으면 +35. */
export function applyKillUltCharge(h: ChargeHero): void {
  if (!h.alive) {return;}
  addUltCharge(h, ULT_CHARGE_KILL);
}

/** match_lifecycle.gd:483-491 — defeated_streak >= 3 이고 살아 있으면 +20. */
export function applyShutdownUltCharge(h: ChargeHero, defeatedStreak: number): void {
  if (defeatedStreak < 3 || !h.alive) {return;}
  addUltCharge(h, ULT_CHARGE_SHUTDOWN);
}

export function setUltimateFocus(w: UltWorld, slot: number, time: number): void {
  if (slot !== w.localSlot) {return;}
  w.ultimateFocusSlot = slot;
  w.ultimateFocusTime = time;
  w.ultimateFocusMax = Math.max(0.16, time);
}

function applySnakeGiant(h: UltHero): void {
  const face = SNAKE_SHED_GIANT;
  h.rlTimed.push({
    id: face.id,
    name: face.name,
    time: face.dur,
    atk: face.atk,
    spd: face.spd,
    def: face.def,
    hp: face.hp,
    rate: face.rate,
    range: face.range,
    shield: face.shield,
  });
  if (face.hp > 0) {
    h.maxHp += face.hp;
    h.hp = Math.min(h.maxHp, h.hp + face.hp);
  }
}

export function beginRatTide(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number, aim: Vec2): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  const dir = aimDir(h, aim);
  w.ratTides.push({
    owner: slot,
    pos: { x: h.x + dir.x * 70.0, y: h.y + dir.y * 70.0 },
    dir,
    life: 1.70,
    travel: 720.0,
    halfW: 118.0,
    length: 360.0,
  });
  setUltimateFocus(w, slot, 0.28);
  emit(w, "ultimate_used", slot, -1, { id: "rat_tide" });
}

export function heroInRatTide(hpos: Vec2, tide: RatTide): boolean {
  const rel = { x: hpos.x - tide.pos.x, y: hpos.y - tide.pos.y };
  const along = dot(rel, tide.dir);
  const side = Math.abs(dot(rel, rotate(tide.dir, Math.PI * 0.5)));
  const leng = tide.length;
  return along > -leng * 0.28 && along < leng * 0.72 && side <= tide.halfW;
}

export function tickRatTides(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, dt: number): void {
  const kept: RatTide[] = [];
  for (const tide of w.ratTides) {
    tide.life -= dt;
    if (tide.life <= 0) {continue;}
    const dir = tide.dir;
    tide.pos = { x: tide.pos.x + dir.x * tide.travel * dt, y: tide.pos.y + dir.y * tide.travel * dt };
    for (const [slot, h] of heroes) {
      if (slot === tide.owner) {continue;}
      if (!h.alive || h.downed) {continue;}
      if (!heroInRatTide(heroPos(h), tide)) {continue;}
      const wish = h.vel;
      const along = dot(wish, dir);
      const resist = along < -20.0 ? 0.40 : 1.0;
      const lateral = { x: wish.x - dir.x * along, y: wish.y - dir.y * along };
      h.vel = {
        x: lateral.x * 0.50 + dir.x * (860.0 * resist),
        y: lateral.y * 0.50 + dir.y * (860.0 * resist),
      };
    }
    kept.push(tide);
  }
  w.ratTides = kept;
}

export function beginOxGore(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number, aim: Vec2): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  const dir = aimDir(h, aim);
  h.oxPhase = "back";
  h.oxTime = 0.18;
  h.oxDir = dir;
  h.oxHit = [];
  h.facing = cloneVec(dir);
  setUltimateFocus(w, slot, 0.40);
  emit(w, "ultimate_used", slot, -1, { id: "ox_gore" });
}

export function tickOxCharges(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, dt: number): void {
  for (const [slot, h] of heroes) {
    const phase = h.oxPhase;
    if (phase === "") {continue;}
    if (!h.alive || h.downed) {
      h.oxPhase = "";
      continue;
    }
    let dir = h.oxDir;
    if (lenSq(dir) < LEN_EPS) {dir = { x: 1, y: 0 };}
    dir = normalizeOrRight(dir);
    h.oxTime -= dt;
    if (phase === "back") {
      h.vel = { x: -dir.x * 380.0, y: -dir.y * 380.0 };
      h.facing = cloneVec(dir);
      if (h.oxTime <= 0) {
        h.oxPhase = "rush";
        h.oxTime = 0.38;
        h.oxHit = [];
      }
      continue;
    }
    h.vel = { x: dir.x * 1100.0, y: dir.y * 1100.0 };
    h.facing = cloneVec(dir);
    const hit = h.oxHit;
    for (const [other, t] of heroes) {
      if (other === slot || hit.includes(other)) {continue;}
      if (!t.alive || t.downed) {continue;}
      if (dist(h.x, h.y, t.x, t.y) > 62.0) {continue;}
      hit.push(other);
      t.stunTime = Math.max(t.stunTime, 1.35);
      t.vel = { x: dir.x * 260.0, y: dir.y * 260.0 };
      const pushed = resolveMotion(w, heroPos(t), dir.x * 70.0, dir.y * 70.0);
      setPos(t, pushed);
    }
    h.oxHit = hit;
    if (h.oxTime <= 0) {
      h.oxPhase = "";
      h.vel = vec();
    }
  }
}

export function beginTigerRoar(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  const origin = heroPos(h);
  w.tigerRoars.push({ pos: origin, age: 0, life: 1.15, radius: 300.0, owner: slot });
  for (const [t, vic] of heroes) {
    if (t === slot) {continue;}
    if (!vic.alive || vic.eliminated) {continue;}
    if (vic.downed) {continue;}
    if (dist(vic.x, vic.y, origin.x, origin.y) > 300.0) {continue;}
    vic.fleeTime = 1.5;
    vic.fleeFrom = cloneVec(origin);
  }
  setUltimateFocus(w, slot, 0.24);
  emit(w, "ultimate_used", slot, -1, { id: "tiger_roar" });
}

export function tickTigerRoars(w: UltWorld, dt: number): void {
  const kept: TigerRoar[] = [];
  for (const roar of w.tigerRoars) {
    roar.age += dt;
    if (roar.age < roar.life) {kept.push(roar);}
  }
  w.tigerRoars = kept;
}

export function applyFleeVel(h: UltHero, moveSpeed = HERO_SPEED): void {
  if (h.fleeTime <= 0) {return;}
  if (!h.alive || h.downed) {return;}
  if (h.launchTime > 0 || h.stunTime > 0) {return;}
  let away = { x: h.x - h.fleeFrom.x, y: h.y - h.fleeFrom.y };
  if (lenSq(away) < 0.01) {away = cloneVec(h.facing);}
  const n = normalizeOrRight(away);
  const spd = moveSpeed * 1.12;
  h.vel = { x: n.x * spd, y: n.y * spd };
}

export function beginRabbitBurrow(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number, aim: Vec2): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  if (h.burrowed || h.downed) {
    h.ultimateCharge = ULTIMATE_MAX;
    return;
  }
  const enter = heroPos(h);
  const exitPos = clampNudge(w, aim);
  w.rabbitHoles.push({ pos: enter, ttl: 4.5, kind: "in" });
  h.burrowed = true;
  h.burrowLeft = 2.0;
  h.burrowExit = exitPos;
  h.vel = vec();
  setUltimateFocus(w, slot, 0.20);
  emit(w, "ultimate_used", slot, -1, { id: "rabbit_burrow" });
}

export function tickRabbitBurrows(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, dt: number): void {
  for (const [slot, h] of heroes) {
    if (!h.burrowed) {continue;}
    h.burrowLeft -= dt;
    h.vel = vec();
    if (h.burrowLeft <= 0) {
      const exitPos = clampNudge(w, h.burrowExit);
      w.rabbitHoles.push({ pos: cloneVec(exitPos), ttl: 3.5, kind: "out" });
      setPos(h, exitPos);
      h.burrowed = false;
      h.burrowLeft = 0;
      h.spawnProtect = Math.max(h.spawnProtect, 0.25);
      emit(w, "rabbit_emerge", slot, -1, { pos: exitPos });
    }
  }
  const kept: RabbitHole[] = [];
  for (const hole of w.rabbitHoles) {
    hole.ttl -= dt;
    if (hole.ttl > 0) {kept.push(hole);}
  }
  w.rabbitHoles = kept;
}

export function beginDragonSmoke(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  w.dragonSmokes.push({ owner: slot, pos: heroPos(h), radius: 300.0, ttl: 15.0 });
  setUltimateFocus(w, slot, 0.22);
  addEffect(w.effects, {
    kind: "afterimage", x: h.x, y: h.y, radius: 90, duration: 0.28,
    color: "#c8c8c8", label: "SMOKE",
  });
  emit(w, "ultimate_used", slot, -1, { id: "dragon_smoke" });
}

export function tickDragonSmokes(w: UltWorld, dt: number): void {
  const kept: DragonSmoke[] = [];
  for (const smoke of w.dragonSmokes) {
    smoke.ttl -= dt;
    if (smoke.ttl > 0) {kept.push(smoke);}
  }
  w.dragonSmokes = kept;
}

export function posInDragonSmoke(w: UltWorld, pos: Vec2): boolean {
  for (const smoke of w.dragonSmokes) {
    if (dist(pos.x, pos.y, smoke.pos.x, smoke.pos.y) <= smoke.radius) {return true;}
  }
  return false;
}

export function localIsDragon(w: UltWorld, heroes: ReadonlyMap<number, UltHero>): boolean {
  if (w.localSlot < 0) {return false;}
  const h = heroes.get(w.localSlot);
  if (!h) {return false;}
  return posmod(h.animal, ANIMAL_COUNT) === 4;
}

export function heroHiddenInSmoke(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): boolean {
  const h = heroes.get(slot);
  if (!h || !h.alive) {return false;}
  if (!posInDragonSmoke(w, heroPos(h))) {return false;}
  let localAnimal = 0;
  const local = heroes.get(w.localSlot);
  if (local) {localAnimal = posmod(local.animal, ANIMAL_COUNT);}
  if (slot === w.localSlot && localAnimal === 4) {return false;}
  return true;
}

export function beginSnakeShed(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  const maxHp = h.maxHp;
  w.snakeSkins.push({
    owner: slot,
    pos: heroPos(h),
    facing: cloneVec(h.facing),
    aim: cloneVec(h.aim),
    animal: 5,
    hp: maxHp,
    maxHp,
    scale: 1.5,
    ttl: 18.0,
    flash: 0,
    alive: true,
  });
  applySnakeGiant(h);
  setUltimateFocus(w, slot, 0.28);
  addEffect(w.effects, {
    kind: "afterimage", x: h.x, y: h.y, radius: 64, duration: 0.32,
    color: "#9ad47a", label: "SHED",
  });
  emit(w, "ultimate_used", slot, -1, { id: "snake_shed" });
}

export function tickSnakeSkins(w: UltWorld, dt: number): void {
  const kept: SnakeSkin[] = [];
  for (const skin of w.snakeSkins) {
    if (!skin.alive) {continue;}
    skin.ttl -= dt;
    skin.flash = Math.max(0, skin.flash - dt);
    if (skin.ttl <= 0 || skin.hp <= 0) {
      addEffect(w.effects, {
        kind: "hit_spark", x: skin.pos.x, y: skin.pos.y, radius: 48, duration: 0.24,
        color: "#b7d59a",
      });
      continue;
    }
    kept.push(skin);
  }
  w.snakeSkins = kept;
}

export function hurtSnakeSkin(w: UltWorld, index: number, damage: number): boolean {
  if (index < 0 || index >= w.snakeSkins.length) {return false;}
  const skin = w.snakeSkins[index];
  if (!skin.alive || damage <= 0) {return false;}
  skin.hp -= damage;
  skin.flash = 0.11;
  emit(w, "snake_shed_hit", -1, -1, { damage, pos: cloneVec(skin.pos) });
  if (skin.hp <= 0) {
    skin.hp = 0;
    skin.alive = false;
    addEffect(w.effects, {
      kind: "snake_pop", x: skin.pos.x, y: skin.pos.y, radius: 62, duration: 0.34,
      color: "#c8e8a8", label: "SHED",
    });
    emit(w, "snake_shed_break", -1, -1, {});
    return true;
  }
  return true;
}

export function hitSnakeSkin(w: UltWorld, owner: number, ppos: Vec2, radius: number, damage: number): boolean {
  let best = -1;
  let bestD = 99999.0;
  for (let i = 0; i < w.snakeSkins.length; i += 1) {
    const skin = w.snakeSkins[i];
    if (!skin.alive) {continue;}
    if (skin.owner === owner) {continue;}
    const d = dist(ppos.x, ppos.y, skin.pos.x, skin.pos.y);
    const skinR = HERO_RADIUS * skin.scale;
    if (d < radius + skinR && d < bestD) {
      bestD = d;
      best = i;
    }
  }
  if (best < 0) {return false;}
  return hurtSnakeSkin(w, best, damage);
}

export function beginHorseKick(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number, aim: Vec2): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  const face = aimDir(h, aim);
  const back = { x: -face.x, y: -face.y };
  const origin = heroPos(h);
  const reach = 400.0;
  const half = 1.15;
  w.horseKicks.push({ pos: origin, dir: back, age: 0, life: 0.42, reach });
  for (const [t, vic] of heroes) {
    if (t === slot) {continue;}
    if (!vic.alive || vic.eliminated) {continue;}
    if (vic.downed || vic.burrowed) {continue;}
    const delta = { x: vic.x - origin.x, y: vic.y - origin.y };
    const dlen = hypotVec(delta);
    if (dlen > reach || dlen < 1.0) {continue;}
    const nd = { x: delta.x / dlen, y: delta.y / dlen };
    if (Math.abs(angleTo(back, nd)) > half) {continue;}
    const push = { x: back.x * 380.0, y: back.y * 380.0 };
    vic.launchVel = cloneVec(push);
    vic.launchTime = Math.max(vic.launchTime, 0.26);
    vic.stunTime = Math.max(vic.stunTime, 1.15);
    vic.vel = cloneVec(push);
    const pushed = resolveMotion(w, heroPos(vic), back.x * 72.0, back.y * 72.0);
    setPos(vic, pushed);
  }
  setUltimateFocus(w, slot, 0.22);
  emit(w, "ultimate_used", slot, -1, { id: "horse_kick" });
}

export function tickHorseKicks(w: UltWorld, dt: number): void {
  const kept: HorseKick[] = [];
  for (const kick of w.horseKicks) {
    kick.age += dt;
    if (kick.age < kick.life) {kept.push(kick);}
  }
  w.horseKicks = kept;
}

export function beginWoolShield(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  h.woolTime = 5.0;
  h.woolHp = 5;
  h.woolMax = 5;
  setUltimateFocus(w, slot, 0.16);
  emit(w, "ultimate_used", slot, -1, { id: "wool_shield" });
}

export function tickWoolShields(heroes: Iterable<UltHero>, dt: number): void {
  for (const h of heroes) {
    if (h.woolTime <= 0) {continue;}
    if (!h.alive || h.downed) {
      h.woolTime = 0;
      h.woolHp = 0;
      continue;
    }
    h.woolTime -= dt;
    if (h.woolTime <= 0) {
      h.woolTime = 0;
      h.woolHp = 0;
    }
  }
}

export function woolShieldPos(h: UltHero): Vec2 {
  return heroPos(h);
}

export function popWoolShield(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  const center = woolShieldPos(h);
  addEffect(w.effects, {
    kind: "sheep_pop", x: center.x, y: center.y, radius: 150, duration: 0.36, color: "#fff1c8",
  });
  for (const [t, vic] of heroes) {
    if (t === slot) {continue;}
    if (!vic.alive || vic.eliminated) {continue;}
    if (vic.burrowed) {continue;}
    if (dist(vic.x, vic.y, center.x, center.y) > 150.0) {continue;}
    let dir = directionTo(center, heroPos(vic));
    if (lenSq(dir) < 0.0001) {dir = cloneVec(h.facing);}
    dir = normalizeOrRight(dir);
    const push = { x: dir.x * 560.0, y: dir.y * 560.0 };
    vic.launchVel = cloneVec(push);
    vic.launchTime = Math.max(vic.launchTime, 0.38);
    vic.stunTime = Math.max(vic.stunTime, 0.55);
    vic.vel = cloneVec(push);
    const pushed = resolveMotion(w, heroPos(vic), dir.x * 70.0, dir.y * 70.0);
    setPos(vic, pushed);
  }
}

export function absorbWoolShield(
  w: UltWorld,
  heroes: ReadonlyMap<number, UltHero>,
  owner: number,
  target: number,
  pos: Vec2,
  radius: number,
): boolean {
  const h = heroes.get(target);
  if (!h) {return false;}
  if (owner === target) {return false;}
  if (h.woolTime <= 0 || h.woolHp <= 0) {return false;}
  if (!h.alive) {return false;}
  const shield = woolShieldPos(h);
  if (dist(pos.x, pos.y, shield.x, shield.y) > radius + 58.0) {return false;}
  h.woolHp -= 1;
  addEffect(w.effects, {
    kind: "impact", x: shield.x, y: shield.y, radius: 36, duration: 0.18, color: "#fff6d8",
  });
  if (h.woolHp <= 0) {
    h.woolTime = 0;
    popWoolShield(w, heroes, target);
    return true;
  }
  return true;
}

export function spawnMirageClones(w: UltWorld, h: UltHero, slot: number): void {
  h.ultCloneTime = 8.0;
  const origin = heroPos(h);
  const clones: UltClone[] = [];
  for (let i = 1; i < 8; i += 1) {
    const ang = TAU * 0.125 * i;
    clones.push({
      alive: true,
      ang,
      pos: cloneVec(origin),
      facing: rotate(h.facing, ang),
      aim: rotate(h.aim, ang),
      hopTime: h.hopTime,
      hopHeight: h.hopHeight,
      animal: h.animal,
      owner: slot,
    });
  }
  h.ultClones = clones;
  setUltimateFocus(w, slot, 0.28);
  emit(w, "ultimate_used", slot, -1, { id: "mirage", clones: 7 });
}

export function tickUltClones(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, dt: number): void {
  for (const [slot, h] of heroes) {
    let left = h.ultCloneTime;
    if (left <= 0) {
      if (h.ultClones.length > 0) {h.ultClones = [];}
      continue;
    }
    left = Math.max(0, left - dt);
    h.ultCloneTime = left;
    if (left <= 0 || !h.alive || h.downed) {
      h.ultClones = [];
      continue;
    }
    const kept: UltClone[] = [];
    for (const clone of h.ultClones) {
      if (!clone.alive) {continue;}
      const mirrored = rotate(h.vel, clone.ang);
      const next = resolveMotion(w, clone.pos, mirrored.x * dt, mirrored.y * dt);
      const clamped = clampArena(next.x, next.y);
      clone.pos = clamped;
      clone.facing = rotate(h.facing, clone.ang);
      clone.aim = rotate(h.aim, clone.ang);
      clone.hopTime = h.hopTime;
      clone.hopHeight = h.hopHeight;
      clone.animal = h.animal;
      clone.owner = slot;
      kept.push(clone);
    }
    h.ultClones = kept;
  }
}

export function popUltClone(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number, index: number): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  if (index < 0 || index >= h.ultClones.length) {return;}
  const pos = h.ultClones[index].pos;
  h.ultClones.splice(index, 1);
  addEffect(w.effects, {
    kind: "monkey_pop", x: pos.x, y: pos.y, radius: 54, duration: 0.28, color: "#c9e7ff",
  });
  emit(w, "clone_pop", slot, -1, {});
}

export function hitUltClone(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, owner: number, ppos: Vec2, radius: number): boolean {
  for (const [slot, h] of heroes) {
    if (slot === owner) {continue;}
    if (h.ultCloneTime <= 0) {continue;}
    for (let i = 0; i < h.ultClones.length; i += 1) {
      const c = h.ultClones[i];
      if (!c.alive) {continue;}
      if (dist(ppos.x, ppos.y, c.pos.x, c.pos.y) < radius + HERO_RADIUS) {
        popUltClone(w, heroes, slot, i);
        return true;
      }
    }
  }
  return false;
}

export function beginRoosterEgg(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  w.roosterEggs.push({
    owner: slot,
    pos: heroPos(h),
    ttl: 8.0,
    arm: 0.55,
    trigger: 150.0,
    alive: true,
  });
  setUltimateFocus(w, slot, 0.18);
  emit(w, "ultimate_used", slot, -1, { id: "rooster_egg" });
}

export function explodeRoosterEgg(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, egg: RoosterEgg): void {
  const origin = egg.pos;
  const owner = egg.owner;
  const blast = 170.0;
  for (const [t, vic] of heroes) {
    if (t === owner) {continue;}
    if (!vic.alive || vic.eliminated) {continue;}
    if (vic.burrowed) {continue;}
    if (dist(vic.x, vic.y, origin.x, origin.y) > blast) {continue;}
    let away = { x: vic.x - origin.x, y: vic.y - origin.y };
    if (lenSq(away) < 0.01) {away = { x: 1, y: 0 };}
    away = normalizeOrRight(away);
    vic.stunTime = Math.max(vic.stunTime, 1.20);
    vic.vel = { x: away.x * 220.0, y: away.y * 220.0 };
  }
  addEffect(w.effects, {
    kind: "rooster_burst", x: origin.x, y: origin.y, radius: 82, duration: 0.42,
    color: "#ffe27a", label: "EGG",
  });
  emit(w, "rooster_egg_boom", owner, -1, {});
}

export function tickRoosterEggs(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, dt: number): void {
  const kept: RoosterEgg[] = [];
  for (const egg of w.roosterEggs) {
    if (!egg.alive) {continue;}
    egg.ttl = decayTimer(egg.ttl, dt);
    egg.arm = decayTimer(egg.arm, dt);
    if (egg.ttl <= 0) {continue;}
    const origin = egg.pos;
    const trig = egg.trigger + HERO_RADIUS;
    let boom = false;
    if (egg.arm <= 0) {
      for (const vic of heroes.values()) {
        if (!vic.alive || vic.eliminated) {continue;}
        if (vic.burrowed) {continue;}
        if (dist(vic.x, vic.y, origin.x, origin.y) <= trig) {
          boom = true;
          break;
        }
      }
    }
    if (boom) {
      explodeRoosterEgg(w, heroes, egg);
      continue;
    }
    kept.push(egg);
  }
  w.roosterEggs = kept;
}

export function beginDogFetch(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number, aim: Vec2): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  const dest = clampNudge(w, aim);
  w.dogBones.push({ pos: dest, owner: slot, ttl: 5.0 });
  h.dogRush = false;
  h.dogWindup = 1.0;
  h.dogBone = dest;
  h.dogHit = [];
  setUltimateFocus(w, slot, 0.18);
  emit(w, "ultimate_used", slot, -1, { id: "dog_fetch" });
}

export function tickDogRush(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, dt: number): void {
  for (const [slot, h] of heroes) {
    let wind = h.dogWindup;
    if (wind > 0) {
      wind = decayTimer(wind, dt);
      h.dogWindup = wind;
      if (!h.alive || h.downed) {
        h.dogWindup = 0;
        h.dogRush = false;
        continue;
      }
      if (wind <= 0) {
        h.dogRush = true;
        h.dogHit = [];
        h.superArmorTime = 2.2;
        h.superArmorStrength = 1.0;
      }
      if (!h.dogRush) {continue;}
    }
    if (!h.dogRush) {continue;}
    if (!h.alive || h.downed) {
      h.dogRush = false;
      h.dogWindup = 0;
      continue;
    }
    const dest = h.dogBone;
    const to = { x: dest.x - h.x, y: dest.y - h.y };
    if (hypotVec(to) <= 36.0) {
      h.dogRush = false;
      h.vel = vec();
      h.superArmorTime = 0;
      continue;
    }
    const dir = normalizeOrRight(to);
    h.facing = cloneVec(dir);
    h.vel = { x: dir.x * 1020.0, y: dir.y * 1020.0 };
    h.superArmorTime = Math.max(h.superArmorTime, 0.2);
    h.superArmorStrength = 1.0;
    const hit = h.dogHit;
    for (const [t, vic] of heroes) {
      if (t === slot || hit.includes(t)) {continue;}
      if (!vic.alive || vic.eliminated) {continue;}
      if (vic.burrowed) {continue;}
      if (dist(h.x, h.y, vic.x, vic.y) > 52.0) {continue;}
      hit.push(t);
      const push = { x: dir.x * 780.0, y: dir.y * 780.0 };
      vic.launchVel = cloneVec(push);
      vic.launchTime = Math.max(vic.launchTime, 0.48);
      vic.stunTime = Math.max(vic.stunTime, 1.25);
      vic.vel = cloneVec(push);
      const pushed = resolveMotion(w, heroPos(vic), dir.x * 90.0, dir.y * 90.0);
      setPos(vic, pushed);
    }
    h.dogHit = hit;
  }
  const kept: DogBone[] = [];
  for (const bone of w.dogBones) {
    bone.ttl -= dt;
    const ownerH = heroes.get(bone.owner);
    if (ownerH !== undefined && (ownerH.dogRush || ownerH.dogWindup > 0)) {
      bone.ttl = Math.max(bone.ttl, 0.05);
    }
    if (bone.ttl > 0) {kept.push(bone);}
  }
  w.dogBones = kept;
}

export function beginPigMud(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): void {
  const h = heroes.get(slot);
  if (!h) {return;}
  w.pigMuds.push({ owner: slot, pos: heroPos(h), radius: 200.0, ttl: 6.0 });
  setUltimateFocus(w, slot, 0.18);
  emit(w, "ultimate_used", slot, -1, { id: "pig_mud" });
}

export function tickPigMuds(w: UltWorld, dt: number): void {
  const kept: PigMud[] = [];
  for (const mud of w.pigMuds) {
    mud.ttl -= dt;
    if (mud.ttl > 0) {kept.push(mud);}
  }
  w.pigMuds = kept;
}

export function posInEnemyMud(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, slot: number): boolean {
  const h = heroes.get(slot);
  if (!h) {return false;}
  for (const mud of w.pigMuds) {
    if (mud.owner === slot) {continue;}
    if (dist(h.x, h.y, mud.pos.x, mud.pos.y) <= mud.radius) {return true;}
  }
  return false;
}

/**
 * try_ultimate(ultimate_animal.gd:16-42). 차지 소모 후 animal 분기.
 * aim 은 월드 좌표(조준점).
 */
export function applyUltimate(
  w: UltWorld,
  heroes: ReadonlyMap<number, UltHero>,
  slot: number,
  aim: Vec2,
): boolean {
  const h = heroes.get(slot);
  if (!h) {return false;}
  if (!h.alive) {return false;}
  if (!ultimateReady(h.ultimateCharge)) {return false;}
  const animal = posmod(h.animal, ANIMAL_COUNT);
  h.ultimateCharge = 0;
  h.ultimates += 1;
  switch (animal) {
    case 0: beginRatTide(w, heroes, slot, aim); break;
    case 1: beginOxGore(w, heroes, slot, aim); break;
    case 2: beginTigerRoar(w, heroes, slot); break;
    case 3: beginRabbitBurrow(w, heroes, slot, aim); break;
    case 4: beginDragonSmoke(w, heroes, slot); break;
    case 5: beginSnakeShed(w, heroes, slot); break;
    case 6: beginHorseKick(w, heroes, slot, aim); break;
    case 7: beginWoolShield(w, heroes, slot); break;
    case 9: beginRoosterEgg(w, heroes, slot); break;
    case 10: beginDogFetch(w, heroes, slot, aim); break;
    case 11: beginPigMud(w, heroes, slot); break;
    default: spawnMirageClones(w, h, slot); break;
  }
  return true;
}

/** player_input.gd Q 에지 — ultimate=true 일 때만 발동. */
export function applyUltimateInput(
  w: UltWorld,
  heroes: ReadonlyMap<number, UltHero>,
  slot: number,
  wantUltimate: boolean,
  aim: Vec2,
): boolean {
  if (!wantUltimate) {return false;}
  return applyUltimate(w, heroes, slot, aim);
}

/** game_world.gd:302-307 궁극기 틱 순서(이동 전 ox/rat/snake/dragon/tiger/rabbit/horse/dog, 이동 후 egg/mud/wool/clones). */
export function tickUltimates(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, dt: number): void {
  w.ultimateFocusTime = Math.max(0, w.ultimateFocusTime - dt);
  if (w.ultimateFocusTime <= 0) {w.ultimateFocusSlot = -1;}
  tickOxCharges(w, heroes, dt);
  tickRatTides(w, heroes, dt);
  tickSnakeSkins(w, dt);
  tickDragonSmokes(w, dt);
  tickTigerRoars(w, dt);
  tickRabbitBurrows(w, heroes, dt);
  tickHorseKicks(w, dt);
  tickDogRush(w, heroes, dt);
  tickRoosterEggs(w, heroes, dt);
  tickPigMuds(w, dt);
  tickWoolShields(heroes.values(), dt);
  tickUltClones(w, heroes, dt);
}

export function grantFightSurge(w: UltWorld, heroes: ReadonlyMap<number, UltHero>): void {
  let standing = 0;
  let pending = 0;
  for (const h of heroes.values()) {
    if (h.eliminated) {continue;}
    h.ultimateCharge = ULTIMATE_MAX;
    if (h.alive && !h.downed) {
      h.fightSurgePending = false;
      standing += 1;
      emit(w, "fight_surge_roulette", h.slot, -1, { rank: "kill" });
    } else {
      h.fightSurgePending = true;
      pending += 1;
    }
  }
  emit(w, "fight_surge", -1, -1, { standing, pending });
}

export function deliverFightSurgeIfPending(w: UltWorld, h: UltHero): void {
  if (!h.fightSurgePending) {return;}
  if (h.eliminated || !h.alive) {return;}
  h.fightSurgePending = false;
  h.ultimateCharge = ULTIMATE_MAX;
  emit(w, "fight_surge_late", h.slot, -1, {});
}

/**
 * remaining 60s 진입 시 카운트다운, +1.65s 후 서지.
 * match_time 은 호출측이 이미 증가시킨 값(game_world.gd:284-293).
 */
export function tickFightSurge(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, matchTime: number): void {
  if (!w.fightCountdownEmitted && MATCH_TIME_LIMIT - matchTime <= FIGHT_SURGE_REMAINING) {
    w.fightCountdownEmitted = true;
    w.fightSurgeAt = matchTime + FIGHT_SURGE_DELAY;
    emit(w, "fight_countdown", -1, -1, { remaining: 60.0 });
  }
  if (w.fightSurgeAt >= 0 && !w.fightSurgeEmitted && matchTime >= w.fightSurgeAt) {
    w.fightSurgeEmitted = true;
    grantFightSurge(w, heroes);
  }
}

export function animalId(animal: number): number {
  return posmod(animal, ANIMAL_COUNT);
}

export function seed(covers: readonly CoverRect[] = []): UltWorld {
  return seedUltWorld(covers);
}

export function apply(
  w: UltWorld,
  heroes: ReadonlyMap<number, UltHero>,
  slot: number,
  aim: Vec2,
): boolean {
  return applyUltimate(w, heroes, slot, aim);
}

export function tick(w: UltWorld, heroes: ReadonlyMap<number, UltHero>, dt: number): void {
  tickUltimates(w, heroes, dt);
}

export function tickUltCharge(heroes: Iterable<ChargeHero>, dt: number): void {
  for (const h of heroes) {tickPassiveUltCharge(h, dt);}
}

export function heroMoveSpeed(
  w: UltWorld,
  heroes: ReadonlyMap<number, UltHero>,
  slot: number,
  base = HERO_SPEED,
): number {
  const h = heroes.get(slot);
  if (h === undefined) {return base;}
  let speed = base;
  if (posmod(h.animal, ANIMAL_COUNT) === ANIMAL_DRAGON && posInDragonSmoke(w, heroPos(h))) {
    speed *= DRAGON_SMOKE_SPEED_MULT;
  }
  if (posInEnemyMud(w, heroes, slot)) {speed *= PIG_MUD_SPEED_MULT;}
  return speed;
}

export function ultimateArmor(_equipmentId: string): { duration: number; strength: number } {
  return { duration: 0, strength: 0 };
}
