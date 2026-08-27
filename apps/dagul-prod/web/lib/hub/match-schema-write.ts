import type { MapSchema } from "@colyseus/schema";
import {
  ARENA_CENTER, packItemField, packWantedSnap, type MatchSim, type SimHero,
} from "./match-sim.js";
import type { SnapEvent } from "./match-authority-snap.js";
import { MatchBulletSchema, MatchEventSchema, MatchHeroSchema } from "./match-schema.js";
import type { MatchStateSchema } from "./match-schema.js";
import { writeMatchWorld } from "./match-schema-world.js";
import { skillsEnabled } from "./config.js";

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
  row.stunT = h.stunTime;
  row.rootT = h.rootTime;
  row.ccT = h.ccTime;
  row.guardT = h.guardTime;
  row.armorT = h.superArmorTime;
  row.spawnT = h.spawnProtect;
  row.launchT = h.launchTime;
  row.launchVX = h.launchVel.x;
  row.launchVY = h.launchVel.y;
  row.charging = skillsEnabled() && h.chargingSkill;
  row.chargeT = skillsEnabled() ? h.chargeTime : 0;
  row.dmgOrbT = h.dmgOrbTime;
  row.downTaken = h.downTaken;
  row.woolT = h.woolTime;
  row.woolHp = h.woolHp;
  row.woolMax = h.woolMax;
  row.rouT = h.rouletteTime;
  row.rouRank = h.rouletteRank;
  row.rouPhase = h.roulettePhase;
  row.rouSpin = String(h.rouletteSpinId);
  row.rouLabel = h.rouletteLabel;
  row.action = skillsEnabled() || h.action !== "CHARGING_SKILL" ? h.action : "idle";
  row.heldItem = h.heldItem;
  row.springT = h.springTime;
  row.slideT = h.slideTime;
  row.pullT = h.pullTime;
  row.pocketT = h.pocketTime;
  row.hopT = h.hopTime;
  row.hopMax = h.hopMax;
  row.hopHeight = h.hopHeight;
  row.mobCd = h.mobilityCd;
  row.rlTimed = JSON.stringify(h.rlTimed);
  row.ultClones = JSON.stringify(h.ultClones.map((c) => ({ x: c.pos.x, y: c.pos.y })));
  row.parked = h.parked;
  fillHeroHudV2(row, h);
}

function fillHeroHudV2(row: MatchHeroSchema, h: SimHero): void {
  row.hud.reloadFlash = h.reloadFlash;
  row.hud.respawnLeft = h.respawnLeft;
  row.hud.sprayIndex = h.sprayIndex;
  row.hud.rouDesc = h.rouletteDesc;
  row.hud.hitstunT = h.hitstunTime;
  row.hud.comboCaptureT = h.comboCaptureTime;
  row.hud.mvSpd = h.equipment.moveSpeed;
  row.hud.elim = h.eliminated;
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

function writeEvents(match: MatchStateSchema, events: readonly SnapEvent[]): void {
  if (events.length === 0) {return;}
  for (const ev of events) {
    match.eventSeq += 1;
    const row = new MatchEventSchema();
    row.seq = match.eventSeq;
    row.t = ev.t;
    row.k = ev.k;
    row.a = ev.a;
    row.b = ev.b;
    row.d = JSON.stringify(ev.d);
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
