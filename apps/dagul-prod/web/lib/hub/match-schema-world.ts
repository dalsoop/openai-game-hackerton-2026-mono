import { packEffects } from "./match-effects.js";
import {
  packCoresSnap, packCrateOrbsSnap, packCratesSnap, packFinishCine, packLootSnap,
  packMidTowerSnap, packZonesSnap, snapDeployables,
} from "./match-sim.js";
import type { MatchSim } from "./match-sim.js";
import {
  MatchCoreSchema, MatchCoverSchema, MatchCrateOrbSchema, MatchCrateSchema,
  MatchDeployableSchema, MatchEffectSchema, MatchKnockoutSchema, MatchLootSchema,
  MatchZoneSchema,
} from "./match-schema/index.js";
import type { MatchStateSchema } from "./match-schema/index.js";
import { syncLen } from "./schema-util.js";

function writeCovers(match: MatchStateSchema, sim: MatchSim): void {
  syncLen(match.covers, sim.covers.length, () => new MatchCoverSchema());
  for (let i = 0; i < sim.covers.length; i += 1) {
    const row = match.covers[i];
    const c = sim.covers[i];
    row.x = c.x;
    row.y = c.y;
    row.w = c.w;
    row.h = c.h;
  }
}

function writeCrates(match: MatchStateSchema, sim: MatchSim): void {
  const crates = packCratesSnap(sim.crates);
  syncLen(match.crates, crates.length, () => new MatchCrateSchema());
  for (let i = 0; i < crates.length; i += 1) {
    const row = match.crates[i];
    const c = crates[i];
    row.id = Number(c.id);
    row.x = Number(c.x);
    row.y = Number(c.y);
    row.hp = Number(c.hp);
    row.maxHp = Number(c.max_hp);
    row.alive = Boolean(c.alive);
  }
}

function writeCrateOrbs(match: MatchStateSchema, sim: MatchSim): void {
  const orbs = packCrateOrbsSnap(sim.crateOrbs);
  syncLen(match.crateOrbs, orbs.length, () => new MatchCrateOrbSchema());
  for (let i = 0; i < orbs.length; i += 1) {
    const row = match.crateOrbs[i];
    const o = orbs[i];
    row.x = Number(o.x);
    row.y = Number(o.y);
    row.red = Boolean(o.red);
    row.active = Boolean(o.active);
  }
}

function writeLoot(match: MatchStateSchema, sim: MatchSim): void {
  const loot = packLootSnap(sim.loot);
  syncLen(match.loot, loot.length, () => new MatchLootSchema());
  for (let i = 0; i < loot.length; i += 1) {
    const row = match.loot[i];
    const p = loot[i];
    row.id = String(p.id);
    row.kind = String(p.kind);
    row.x = Number(p.x);
    row.y = Number(p.y);
    row.n = String(p.n);
    row.itemKind = String(p.itemKind ?? "");
  }
}

function fillDeployable(
  row: MatchDeployableSchema,
  d: ReturnType<typeof snapDeployables>[number],
): void {
  row.type = d.type;
  row.owner = d.owner;
  row.x = d.x;
  row.y = d.y;
  row.dx = d.dx;
  row.dy = d.dy;
  row.tdx = d.tdx;
  row.tdy = d.tdy;
  row.halfLength = d.half_length;
  row.lifetime = d.lifetime;
  row.maxLifetime = d.max_lifetime;
  row.armTime = d.arm_time;
  row.armDuration = d.arm_duration;
  row.triggered = d.triggered;
  row.triggerRadius = d.trigger_radius;
  row.blastRadius = d.blast_radius;
  row.fuseTime = d.fuse_time;
  row.fuseDuration = d.fuse_duration;
}

function writeDeployables(match: MatchStateSchema, sim: MatchSim): void {
  const list = snapDeployables(sim.deploy.deployables);
  syncLen(match.deployables, list.length, () => new MatchDeployableSchema());
  for (let i = 0; i < list.length; i += 1) {
    fillDeployable(match.deployables[i], list[i]);
  }
}

function writeZones(match: MatchStateSchema, sim: MatchSim): void {
  const zones = packZonesSnap(sim.zones);
  syncLen(match.zones, zones.length, () => new MatchZoneSchema());
  for (let i = 0; i < zones.length; i += 1) {
    const row = match.zones[i];
    const z = zones[i];
    row.x = Number(z.x);
    row.y = Number(z.y);
    row.radius = Number(z.radius);
    row.owner = Number(z.owner);
    row.delay = Number(z.delay);
    row.warningDuration = Number(z.warning_duration);
    row.color = String(z.color);
    row.effectKind = String(z.effect_kind);
    row.label = String(z.label);
  }
}

function writeKnockouts(match: MatchStateSchema, sim: MatchSim): void {
  syncLen(match.knockouts, sim.knockouts.length, () => new MatchKnockoutSchema());
  for (let i = 0; i < sim.knockouts.length; i += 1) {
    const row = match.knockouts[i];
    const k = sim.knockouts[i];
    row.slot = k.slot;
    row.animal = k.animal;
    row.x = k.x;
    row.y = k.y;
    row.time = k.time;
    row.maxTime = k.maxTime;
  }
}

function writeCores(match: MatchStateSchema, sim: MatchSim): void {
  const cores = packCoresSnap(sim.cores);
  syncLen(match.cores, cores.length, () => new MatchCoreSchema());
  for (let i = 0; i < cores.length; i += 1) {
    const row = match.cores[i];
    const c = cores[i];
    row.slot = c.slot;
    row.x = c.x;
    row.y = c.y;
    row.hp = c.hp;
    row.maxHp = c.max_hp;
    row.alive = c.alive;
  }
}

function writeTower(match: MatchStateSchema, sim: MatchSim): void {
  const tower = packMidTowerSnap(sim.midTower);
  match.midTower.alive = Boolean(tower.alive);
  match.midTower.x = Number(tower.x);
  match.midTower.y = Number(tower.y);
  match.midTower.hp = Number(tower.hp);
  match.midTower.maxHp = Number(tower.max_hp);
  match.midTower.boing = Number(tower.boing);
}

function writeFinishCine(match: MatchStateSchema, sim: MatchSim): void {
  const cine = packFinishCine(sim.finishCine);
  match.finishCine.on = cine.on === true;
  match.finishCine.atk = Number(cine.atk ?? -1);
  match.finishCine.vic = Number(cine.vic ?? -1);
  match.finishCine.t = Number(cine.t ?? 0);
  match.finishCine.hit = Boolean(cine.hit);
  match.finishCine.hitAge = Number(cine.hit_age ?? 0);
  match.finishCine.fly = Number(cine.fly ?? 0);
  match.finishCine.vicX = Number(cine.vic_x ?? 0);
  match.finishCine.vicY = Number(cine.vic_y ?? 0);
  match.finishCine.vicSpin = Number(cine.vic_spin ?? 0);
  match.finishCine.atkX = Number(cine.atk_x ?? 0);
  match.finishCine.rush = Boolean(cine.rush);
  match.finishCine.midX = Number(cine.mx ?? 0);
  match.finishCine.midY = Number(cine.my ?? 0);
}

function writeEffects(match: MatchStateSchema, sim: MatchSim): void {
  const packed = packEffects(sim.effects);
  syncLen(match.effects, packed.length, () => new MatchEffectSchema());
  for (let i = 0; i < packed.length; i += 1) {
    const row = match.effects[i];
    const e = packed[i];
    row.k = String(e.k ?? "");
    row.x = Number(e.x);
    row.y = Number(e.y);
    row.r = Number(e.r);
    row.t = Number(e.t);
    row.maxT = Number(e.maxT);
    row.color = String(e.color ?? "");
    row.label = String(e.label ?? "");
    row.dx = Number(e.dx);
    row.dy = Number(e.dy);
    row.follow = Number(e.follow);
    row.sx = Number(e.sx ?? e.x);
    row.sy = Number(e.sy ?? e.y);
    row.dep = Boolean(e.dep ?? true);
  }
}

export function writeMatchWorld(match: MatchStateSchema, sim: MatchSim): void {
  writeCovers(match, sim);
  writeCrates(match, sim);
  writeCrateOrbs(match, sim);
  writeLoot(match, sim);
  writeDeployables(match, sim);
  writeZones(match, sim);
  writeKnockouts(match, sim);
  writeCores(match, sim);
  writeTower(match, sim);
  writeFinishCine(match, sim);
  writeEffects(match, sim);
}
