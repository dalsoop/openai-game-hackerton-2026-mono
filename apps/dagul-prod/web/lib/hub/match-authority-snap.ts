import {
  ARENA_CENTER, packCoresSnap, packCrateOrbsSnap, packCratesSnap,
  packFinishCine, packLootSnap, packMidTowerSnap,
  packWantedSnap, packZonesSnap, snapDeployables,
  type MatchSim, type SimBullet, type SimHero,
} from "./match-sim.js";
import { packItemField } from "./match-item-wire.js";
import { packEffects } from "./match-effects.js";
import { skillsEnabled } from "./config.js";

export type SnapEvent = {
  tick: number;
  kind: string;
  actor: number;
  target: number;
  data: Record<string, unknown>;
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
  parked: boolean;
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
  const isSkillAction = h.action === "CHARGING_SKILL" || h.action === "CHARGED_SKILL";
  putOmit(out, "action", !skillsEnabled() && isSkillAction ? "idle" : h.action);
  putOmit(out, "stunTime", h.stunTime);
  putOmit(out, "rootTime", h.rootTime);
  putOmit(out, "ccTime", h.ccTime);
  putOmit(out, "guardTime", h.guardTime);
  putOmit(out, "armorTime", h.superArmorTime);
  putOmit(out, "spawnProtect", h.spawnProtect);
  putOmit(out, "launchTime", h.launchTime);
  putOmit(out, "launchVX", h.launchVel.x);
  putOmit(out, "launchVY", h.launchVel.y);
  if (skillsEnabled()) {
    putOmit(out, "charging", h.chargingSkill);
    putOmit(out, "chargeTime", h.chargeTime);
  }
  putOmit(out, "heldItem", h.heldItem);
  putOmit(out, "springTime", h.springTime);
  putOmit(out, "slideTime", h.slideTime);
  putOmit(out, "pullTime", h.pullTime);
  putOmit(out, "pocketTime", h.pocketTime);
  putOmit(out, "hopTime", h.hopTime);
  putOmit(out, "hopMax", h.hopTime > 0 ? h.hopMax : 0);
  putOmit(out, "hopHeight", h.hopTime > 0 ? h.hopHeight : 0);
  putOmit(out, "mobilityCd", h.mobilityCd);
  putOmit(out, "equipmentCd", h.equipmentCd);
  putOmit(out, "moveSpeed", h.equipment.moveSpeed);
  putOmit(out, "eliminated", h.eliminated);
  putOmit(out, "dmgOrbTime", h.dmgOrbTime);
  putOmit(out, "downTaken", h.downTaken);
  putOmit(out, "woolTime", h.woolTime);
  putOmit(out, "woolHp", h.woolHp);
  putOmit(out, "woolMax", h.woolMax);
  putOmit(out, "rouletteTime", h.rouletteTime);
  putOmit(out, "rouletteRank", h.rouletteRank);
  putOmit(out, "roulettePhase", h.roulettePhase);
  putOmit(out, "rouletteSpin", String(h.rouletteSpinId));
  putOmit(out, "rouletteLabel", h.rouletteLabel);
  putOmit(out, "timedBuffs", h.timedBuffs);
  putOmit(out, "clones", h.clones.map((c) => ({ x: c.pos.x, y: c.pos.y })));
  putOmit(out, "reloadFlash", h.reloadFlash);
  putOmit(out, "respawnLeft", h.respawnLeft);
  putOmit(out, "sprayIndex", h.sprayIndex);
  putOmit(out, "rouletteDesc", h.rouletteDesc);
  putOmit(out, "hitstunTime", h.hitstunTime);
  putOmit(out, "comboCaptureTime", h.comboCaptureTime);
  putOmit(out, "medkits", h.medkits);
  putOmit(out, "mobilityDist", h.equipment.mobilityDistance);
  putOmit(out, "untilBuffs", packUntilBuffs(h.untilBuffs));
  return out;
}

function packUntilBuffs(u: SimHero["untilBuffs"]): Record<string, number> | 0 {
  if (u.atk === 0 && u.spd === 0 && u.def === 0 && u.hp === 0 && u.rate === 0 && u.range === 0) {
    return 0;
  }
  return { atk: u.atk, spd: u.spd, def: u.def, hp: u.hp, rate: u.rate, range: u.range };
}

function packBullet(b: SimBullet): Record<string, unknown> {
  const row: Record<string, unknown> = {
    id: b.id, x: b.x, y: b.y, vx: b.vx, vy: b.vy, owner: b.owner, kind: b.kind,
    ttl: b.ttl, maxTtl: b.maxTtl, lx: b.landingX, ly: b.landingY, splash: b.splash,
  };
  putOmit(row, "radius", b.radius);
  putOmit(row, "heavy", b.heavy);
  putOmit(row, "src", b.source);
  putOmit(row, "arc", b.arc);
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
    parked: h.parked,
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
  const cine = packFinishCine(sim.finishCine);
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
    finishCine: cine,
    finish_cine: cine,
    callout: sim.callout,
    calloutTicks: sim.calloutTicks,
    streakCallout: sim.streakState.streakCallout,
    streakSubtitle: sim.streakState.streakSubtitle,
    streakCalloutTicks: sim.streakState.streakCalloutTicks,
    streakCalloutShutdown: sim.streakState.streakCalloutShutdown,
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
    effects: packEffects(sim.effects),
  };
  return snap;
}
