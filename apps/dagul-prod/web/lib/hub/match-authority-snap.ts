import {
  ARENA_CENTER, packCoresSnap, packCrateOrbsSnap, packCratesSnap,
  packFinishCine, packItemField, packLootSnap, packMidTowerSnap,
  packWantedSnap, packZonesSnap, snapDeployables,
  type MatchSim, type SimBullet, type SimHero,
} from "./match-sim.js";
import { packEffects, type EffectStore } from "./match-effects.js";

export type SnapEvent = {
  t: number;
  k: string;
  a: number;
  b: number;
  d: Record<string, unknown>;
};

export type SnapPlayer = {
  slot: number;
  name: string;
  x: number;
  y: number;
  aimX: number;
  aimY: number;
  hp: number;
  maxHp: number;
  alive: boolean;
  mag: number;
  magMax: number;
  reloadLeft: number;
  weapon: string;
  weaponId: string;
  ult: number;
  ack: number;
  animal: number;
  characterId: string;
  cpu: boolean;
  item: string;
  kills: number;
  downed: boolean;
  downLeft: number;
  deaths: number;
  score: number;
  streak: number;
  emote: number;
  emoteTime: number;
};

function putOmit(dst: Record<string, unknown>, key: string, value: unknown): void {
  if (value === 0 || value === false || value === "") {return;}
  if (Array.isArray(value) && value.length === 0) {return;}
  dst[key] = value;
}

function packPlayerV2(h: SimHero): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  putOmit(out, "action", h.action);
  putOmit(out, "stunT", h.stunTime);
  putOmit(out, "rootT", h.rootTime);
  putOmit(out, "ccT", h.ccTime);
  putOmit(out, "guardT", h.guardTime);
  putOmit(out, "armorT", h.superArmorTime);
  putOmit(out, "spawnT", h.spawnProtect);
  putOmit(out, "launchT", h.launchTime);
  putOmit(out, "launchVX", h.launchVel.x);
  putOmit(out, "launchVY", h.launchVel.y);
  putOmit(out, "charging", h.chargingSkill);
  putOmit(out, "chargeT", h.chargeTime);
  putOmit(out, "dmgOrbT", h.dmgOrbTime);
  putOmit(out, "downTaken", h.downTaken);
  putOmit(out, "woolT", h.woolTime);
  putOmit(out, "woolHp", h.woolHp);
  putOmit(out, "woolMax", h.woolMax);
  putOmit(out, "rouT", h.rouletteTime);
  putOmit(out, "rouRank", h.rouletteRank);
  putOmit(out, "rouPhase", h.roulettePhase);
  putOmit(out, "rouSpin", h.rouletteSpinId);
  putOmit(out, "rouLabel", h.rouletteLabel);
  putOmit(out, "rlTimed", h.rlTimed);
  putOmit(out, "ultClones", h.ultClones.map((c) => ({ x: c.pos.x, y: c.pos.y })));
  return out;
}

function packBullet(b: SimBullet): Record<string, unknown> {
  const row: Record<string, unknown> = {
    id: b.id, x: b.x, y: b.y, vx: b.vx, vy: b.vy, owner: b.owner, kind: b.kind,
  };
  putOmit(row, "radius", b.radius);
  putOmit(row, "heavy", b.heavy);
  putOmit(row, "src", b.source);
  return row;
}

function packHeroRow(h: SimHero, names: ReadonlyMap<number, string>): SnapPlayer {
  const row: SnapPlayer = {
    slot: h.slot,
    name: names.get(h.slot) ?? `P${h.slot + 1}`,
    x: h.x,
    y: h.y,
    aimX: h.aimX,
    aimY: h.aimY,
    hp: h.hp,
    maxHp: h.maxHp,
    alive: h.alive,
    mag: h.mag,
    magMax: h.magMax,
    reloadLeft: h.reloadLeft,
    weapon: h.equipment.name,
    weaponId: h.equipmentId,
    ult: h.ultimateCharge,
    ack: h.ack,
    animal: h.animal,
    kills: h.kills,
    characterId: h.characterId,
    cpu: h.cpu,
    item: packItemField(h.medkits),
    downed: h.downed,
    downLeft: h.downLeft,
    deaths: h.deaths,
    score: h.score,
    streak: h.killStreak,
    emote: h.emote,
    emoteTime: h.emoteTime,
  };
  Object.assign(row, packPlayerV2(h));
  return row;
}

export function packAuthoritySnap(
  sim: MatchSim,
  names: ReadonlyMap<number, string>,
  mode: string,
  events: readonly SnapEvent[] = [],
): Record<string, unknown> {
  const players: SnapPlayer[] = [];
  for (const h of sim.heroes.values()) {
    players.push(packHeroRow(h, names));
  }
  const bullets = [...sim.bullets.values()].map(packBullet);
  const covers = sim.covers.map((c) => ({ x: c.x, y: c.y, w: c.w, h: c.h }));
  const knockouts = sim.knockouts.map((k) => ({
    slot: k.slot, animal: k.animal, x: k.x, y: k.y, time: k.time, max_time: k.maxTime,
  }));
  const loot = packLootSnap(sim.loot);
  const wanted = packWantedSnap(sim.wanted);
  const snap: Record<string, unknown> = {
    tick: sim.tick,
    time: sim.matchTime,
    result: sim.result,
    winner: sim.winner,
    zoneR: sim.zone.radius,
    shrinking: sim.zone.shrinking,
    zoneCX: ARENA_CENTER.x,
    zoneCY: ARENA_CENTER.y,
    zonePhase: sim.zone.phase,
    startCountdown: sim.countdown,
    finishCine: packFinishCine(sim.finishCine),
    finish_cine: packFinishCine(sim.finishCine),
    callout: sim.callout,
    calloutTicks: sim.calloutTicks,
    wantedSlot: wanted.wantedSlot,
    cores: packCoresSnap(sim.cores),
    crates: packCratesSnap(sim.crates),
    crate_orbs: packCrateOrbsSnap(sim.crateOrbs),
    mid_tower: packMidTowerSnap(sim.midTower),
    deployables: snapDeployables(sim.deploy.deployables),
    zones: packZonesSnap(sim.zones),
    mode,
    players,
    bullets,
    covers,
    knockouts,
    loot,
    events,
  };
  putOmit(snap, "effects", packEffects((sim as MatchSim & { effects?: EffectStore }).effects));
  return snap;
}
