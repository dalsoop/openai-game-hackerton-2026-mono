/* eslint-disable max-lines -- 스키마 기입 한 파일 */
import type { ArraySchema} from "@colyseus/schema";
import { type MapSchema } from "@colyseus/schema";
import {
  ARENA_CENTER, packWantedSnap, type MatchSim, type SimHero,
} from "./match-sim.js";
import { packItemField } from "./match-item-wire.js";
import type { SnapEvent } from "./match-authority-snap.js";
import {
  MatchBulletSchema, MatchCloneSchema, MatchEventSchema,
  MatchHeroSchema, MatchTimedBuffSchema,
} from "./match-schema/index.js";
import type { MatchStateSchema , MatchEventDataSchema} from "./match-schema/index.js";
import { writeMatchWorld } from "./match-schema-world.js";
import { skillsEnabled } from "./config.js";
import { syncLen } from "./schema-util.js";

/** 스키마 이벤트 링버퍼 상한. JSON 스냅 takeEvents 캡과 같다. */
export const EVENT_RING = 32;

function fillHero(row: MatchHeroSchema, h: SimHero, names: ReadonlyMap<number, string>): void {
  row.slot = h.slot;
  row.name = names.get(h.slot) ?? `P${h.slot + 1}`;
  row.x = h.x;
  row.y = h.y;
  row.aimX = h.aimX;
  row.aimY = h.aimY;
  row.hp = h.hp;
  row.maxHp = h.maxHp;
  row.alive = h.alive;
  row.mag = h.mag;
  row.magMax = h.magMax;
  row.reloadLeft = h.reloadLeft;
  row.weapon = h.equipment.name;
  row.ult = h.ultimateCharge;
  row.ack = h.ack;
  row.animal = h.animal;
  row.characterId = h.characterId;
  row.cpu = h.cpu;
  row.item = packItemField(h.medkits);
  row.kills = h.kills;
  row.downed = h.downed;
  row.downLeft = h.downLeft;
  row.deaths = h.deaths;
  row.score = h.score;
  row.streak = h.killStreak;
  row.emote = h.emote;
  row.emoteTime = h.emoteTime;
  row.weaponId = h.equipmentId;
  fillHeroV2(row, h);
}

function fillHeroV2(row: MatchHeroSchema, h: SimHero): void {
  row.stunTime = h.stunTime;
  row.rootTime = h.rootTime;
  row.ccTime = h.ccTime;
  row.guardTime = h.guardTime;
  row.armorTime = h.superArmorTime;
  row.spawnProtect = h.spawnProtect;
  row.launchTime = h.launchTime;
  row.launchVX = h.launchVel.x;
  row.launchVY = h.launchVel.y;
  row.charging = skillsEnabled() && h.chargingSkill;
  row.chargeTime = skillsEnabled() ? h.chargeTime : 0;
  row.dmgOrbTime = h.dmgOrbTime;
  row.downTaken = h.downTaken;
  row.woolTime = h.woolTime;
  row.woolHp = h.woolHp;
  row.woolMax = h.woolMax;
  row.rouletteTime = h.rouletteTime;
  row.rouletteRank = h.rouletteRank;
  row.roulettePhase = h.roulettePhase;
  row.rouletteSpin = String(h.rouletteSpinId);
  row.rouletteLabel = h.rouletteLabel;
  const isSkillAction = h.action === "CHARGING_SKILL" || h.action === "CHARGED_SKILL";
  row.action = !skillsEnabled() && isSkillAction ? "idle" : h.action;
  row.heldItem = h.heldItem;
  row.springTime = h.springTime;
  row.slideTime = h.slideTime;
  row.pullTime = h.pullTime;
  row.pocketTime = h.pocketTime;
  row.hopTime = h.hopTime;
  row.hopMax = h.hopMax;
  row.hopHeight = h.hopHeight;
  row.mobilityCd = h.mobilityCd;
  writeTimedBuffs(row.timedBuffs, h.timedBuffs);
  writeClones(row.clones, h.clones);
  row.parked = h.parked;
  fillHeroHudV2(row, h);
}

function writeTimedBuffs(
  dest: ArraySchema<MatchTimedBuffSchema>,
  buffs: SimHero["timedBuffs"],
): void {
  syncLen(dest, buffs.length, () => new MatchTimedBuffSchema());
  for (let i = 0; i < buffs.length; i += 1) {
    const src = buffs[i];
    const row = dest[i];
    row.id = src.id;
    row.name = src.name;
    row.time = src.time;
    row.shield = src.shield;
  }
}

function writeClones(
  dest: ArraySchema<MatchCloneSchema>,
  clones: SimHero["clones"],
): void {
  syncLen(dest, clones.length, () => new MatchCloneSchema());
  for (let i = 0; i < clones.length; i += 1) {
    const src = clones[i];
    const row = dest[i];
    row.x = src.pos.x;
    row.y = src.pos.y;
  }
}

function fillHeroHudV2(row: MatchHeroSchema, h: SimHero): void {
  row.hud.reloadFlash = h.reloadFlash;
  row.hud.respawnLeft = h.respawnLeft;
  row.hud.sprayIndex = h.sprayIndex;
  row.hud.rouletteDesc = h.rouletteDesc;
  row.hud.hitstunTime = h.hitstunTime;
  row.hud.comboCaptureTime = h.comboCaptureTime;
  row.hud.moveSpeed = h.equipment.moveSpeed;
  row.hud.eliminated = h.eliminated;
  row.hud.medkits = h.medkits;
  row.hud.mobilityDist = h.equipment.mobilityDistance;
  const until = h.untilBuffs;
  row.hud.untilBuffs.atk = until.atk;
  row.hud.untilBuffs.spd = until.spd;
  row.hud.untilBuffs.def = until.def;
  row.hud.untilBuffs.hp = until.hp;
  row.hud.untilBuffs.rate = until.rate;
  row.hud.untilBuffs.range = until.range;
}

function writeHeroes(
  heroes: MapSchema<MatchHeroSchema>,
  sim: MatchSim,
  names: ReadonlyMap<number, string>,
): void {
  const live = new Set<string>();
  for (const h of sim.heroes.values()) {
    const key = String(h.slot);
    live.add(key);
    let row = heroes.get(key);
    if (!row) {
      row = new MatchHeroSchema();
      heroes.set(key, row);
    }
    fillHero(row, h, names);
  }
  for (const key of [...heroes.keys()]) {
    if (!live.has(key)) {heroes.delete(key);}
  }
}

function writeBullets(bullets: MapSchema<MatchBulletSchema>, sim: MatchSim): void {
  const live = new Set<string>();
  for (const b of sim.bullets.values()) {
    const key = String(b.id);
    live.add(key);
    let row = bullets.get(key);
    if (!row) {
      row = new MatchBulletSchema();
      bullets.set(key, row);
    }
    row.id = b.id;
    row.x = b.x;
    row.y = b.y;
    row.vx = b.vx;
    row.vy = b.vy;
    row.owner = b.owner;
    row.kind = b.kind;
    row.radius = b.radius;
    row.arc = Boolean(b.arc);
    row.heavy = b.heavy;
    row.src = b.source;
    row.ttl = b.ttl;
    row.maxTtl = b.maxTtl;
    row.lx = b.landingX;
    row.ly = b.landingY;
    row.splash = b.splash;
  }
  for (const key of [...bullets.keys()]) {
    if (!live.has(key)) {bullets.delete(key);}
  }
}

function writeScalars(match: MatchStateSchema, sim: MatchSim, mode: string): void {
  match.tick = sim.tick;
  match.time = sim.matchTime;
  match.result = sim.result;
  match.winner = sim.winner;
  match.zoneR = sim.zone.radius;
  match.shrinking = sim.zone.shrinking;
  match.zoneCX = ARENA_CENTER.x;
  match.zoneCY = ARENA_CENTER.y;
  match.zonePhase = sim.zone.phase;
  match.startCountdown = sim.countdown;
  match.callout = sim.callout;
  match.calloutTicks = sim.calloutTicks;
  match.streakCallout = sim.streakState.streakCallout;
  match.streakSubtitle = sim.streakState.streakSubtitle;
  match.streakCalloutTicks = sim.streakState.streakCalloutTicks;
  match.streakCalloutShutdown = sim.streakState.streakCalloutShutdown;
  match.wantedSlot = packWantedSnap(sim.wanted).wantedSlot;
  match.mode = mode;
}

function num(d: Record<string, unknown>, key: string, fallback = 0): number {
  const v = d[key];
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

function str(d: Record<string, unknown>, key: string): string {
  const v = d[key];
  return typeof v === "string" ? v : "";
}

function fillEventData(row: MatchEventDataSchema, d: Record<string, unknown>): void {
  row.equipment = str(d, "equipment");
  row.id = str(d, "id");
  row.source = str(d, "source");
  row.kind = str(d, "kind");
  row.rank = str(d, "rank");
  row.reason = str(d, "reason");
  row.dropped = str(d, "dropped");
  const pos = d.pos;
  if (pos && typeof pos === "object") {
    const p = pos as { x?: unknown; y?: unknown };
    row.x = typeof p.x === "number" ? p.x : 0;
    row.y = typeof p.y === "number" ? p.y : 0;
  } else {
    row.x = num(d, "x");
    row.y = num(d, "y");
  }
  row.damage = num(d, "damage");
  row.heal = num(d, "heal");
  row.amount = num(d, "amount");
  row.remaining = num(d, "remaining");
  row.from = num(d, "from");
  row.to = num(d, "to");
  row.hpRatio = d.hp_ratio !== undefined ? num(d, "hp_ratio") : num(d, "hpRatio");
  row.coreRatio = d.core_ratio !== undefined ? num(d, "core_ratio") : num(d, "coreRatio");
  row.score = num(d, "score");
  row.clones = num(d, "clones");
  row.crate = d.crate === undefined ? -1 : num(d, "crate", -1);
  row.target = d.target === undefined ? -1 : num(d, "target", -1);
  row.left = num(d, "left");
  row.phase = num(d, "phase");
  row.standing = num(d, "standing");
  row.pending = num(d, "pending");
  if (d.previousTarget !== undefined) {
    row.previousTarget = num(d, "previousTarget", -1);
  } else if (d.previous_target !== undefined) {
    row.previousTarget = num(d, "previous_target", -1);
  } else {
    row.previousTarget = -1;
  }
  row.predicted = Boolean(d.predicted);
  row.executed = Boolean(d.executed);
}

function writeEvents(match: MatchStateSchema, events: readonly SnapEvent[]): void {
  if (events.length === 0) {return;}
  for (const ev of events) {
    match.eventSeq += 1;
    const row = new MatchEventSchema();
    row.seq = match.eventSeq;
    row.tick = ev.tick;
    row.kind = ev.kind;
    row.actor = ev.actor;
    row.target = ev.target;
    fillEventData(row.data, ev.data);
    match.events.set(String(match.eventSeq), row);
  }
  trimEventRing(match);
}

function trimEventRing(match: MatchStateSchema): void {
  if (match.events.size <= EVENT_RING) {return;}
  const keys = [...match.events.keys()].sort((a, b) => Number(a) - Number(b));
  const drop = keys.length - EVENT_RING;
  for (let i = 0; i < drop; i += 1) {
    match.events.delete(keys[i]);
  }
}

/** packAuthoritySnap 과 같은 값을 Schema 에 대입한다. 매 틱 호출해도 dirty 만 패치된다. */
export function writeMatchState(
  match: MatchStateSchema,
  sim: MatchSim,
  names: ReadonlyMap<number, string>,
  mode: string,
  events: readonly SnapEvent[] = [],
): void {
  writeScalars(match, sim, mode);
  writeHeroes(match.heroes, sim, names);
  writeBullets(match.bullets, sim);
  writeMatchWorld(match, sim);
  writeEvents(match, events);
}

export function clearMatchState(match: MatchStateSchema): void {
  match.tick = 0;
  match.time = 0;
  match.result = "playing";
  match.winner = -1;
  match.zoneR = 0;
  match.shrinking = false;
  match.zoneCX = 0;
  match.zoneCY = 0;
  match.zonePhase = 0;
  match.startCountdown = 0;
  match.callout = "";
  match.calloutTicks = 0;
  match.streakCallout = "";
  match.streakSubtitle = "";
  match.streakCalloutTicks = 0;
  match.streakCalloutShutdown = false;
  match.wantedSlot = -1;
  match.mode = "";
  match.heroes.clear();
  match.bullets.clear();
  match.effects.clear();
  match.covers.clear();
  match.crates.clear();
  match.crateOrbs.clear();
  match.loot.clear();
  match.deployables.clear();
  match.zones.clear();
  match.knockouts.clear();
  match.cores.clear();
  clearFinishCine(match);
  clearMidTower(match);
  match.events.clear();
  match.eventSeq = 0;
}

/** 로비 복귀 후에도 엔진 세션이 스키마를 읽는다 — 직전 매치 시네 좌표가 남으면 안 된다. */
function clearFinishCine(match: MatchStateSchema): void {
  const cine = match.finishCine;
  cine.on = false;
  cine.atk = -1;
  cine.vic = -1;
  cine.t = 0;
  cine.hit = false;
  cine.hitAge = 0;
  cine.fly = 0;
  cine.vicX = 0;
  cine.vicY = 0;
  cine.vicSpin = 0;
  cine.atkX = 0;
  cine.rush = false;
  cine.midX = 0;
  cine.midY = 0;
}

function clearMidTower(match: MatchStateSchema): void {
  const tower = match.midTower;
  tower.alive = false;
  tower.x = 0;
  tower.y = 0;
  tower.hp = 0;
  tower.maxHp = 0;
  tower.boing = 0;
}
