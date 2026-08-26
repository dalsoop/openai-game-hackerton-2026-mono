import type { MapSchema } from "@colyseus/schema";
import {
  ARENA_CENTER, packItemField, packWantedSnap, type MatchSim, type SimHero,
} from "./match-sim.js";
import type { SnapEvent } from "./match-authority-snap.js";
import { MatchBulletSchema, MatchEventSchema, MatchHeroSchema } from "./match-schema.js";
import type { MatchStateSchema } from "./match-schema.js";
import { writeMatchWorld } from "./match-schema-world.js";

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
    match.events.push(row);
  }
  while (match.events.length > EVENT_RING) {match.events.shift();}
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
  match.callout = "";
  match.calloutTicks = 0;
  match.wantedSlot = -1;
  match.mode = "";
  match.heroes.clear();
  match.bullets.clear();
  match.covers.clear();
  match.crates.clear();
  match.crateOrbs.clear();
  match.loot.clear();
  match.deployables.clear();
  match.zones.clear();
  match.knockouts.clear();
  match.cores.clear();
  match.finishCine.on = false;
  match.events.clear();
  match.eventSeq = 0;
}
