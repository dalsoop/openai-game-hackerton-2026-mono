import { ArraySchema, MapSchema, Schema, type } from "@colyseus/schema";
import { MatchBulletSchema } from "./bullet.js";
import { MatchCoreSchema } from "./core.js";
import { MatchCoverSchema } from "./cover.js";
import { MatchCrateOrbSchema } from "./crate-orb.js";
import { MatchCrateSchema } from "./crate.js";
import { MatchDeployableSchema } from "./deployable.js";
import { MatchEffectSchema } from "./effect.js";
import { MatchEventSchema } from "./event.js";
import { MatchFinishCineSchema } from "./finish-cine.js";
import { MatchHeroSchema } from "./hero.js";
import { MatchKnockoutSchema } from "./knockout.js";
import { MatchLootSchema } from "./loot.js";
import { MatchMidTowerSchema } from "./mid-tower.js";
import { MatchZoneSchema } from "./zone.js";

/** 권위 시뮬 미러 — JSON SNAP 과 병행. 엔진 세션이 Schema 델타로 읽는다. */
export class MatchStateSchema extends Schema {
  @type("uint32") tick = 0;
  @type("float32") time = 0;
  @type("string") result = "playing";
  @type("int8") winner = -1;
  @type("float32") zoneR = 0;
  @type("boolean") shrinking = false;
  @type("float32") zoneCX = 0;
  @type("float32") zoneCY = 0;
  @type("uint8") zonePhase = 0;
  @type("float32") startCountdown = 0;
  @type("string") callout = "";
  @type("uint32") calloutTicks = 0;
  @type("int8") wantedSlot = -1;
  @type("string") mode = "";
  @type({ map: MatchHeroSchema }) heroes = new MapSchema<MatchHeroSchema>();
  @type({ map: MatchBulletSchema }) bullets = new MapSchema<MatchBulletSchema>();
  @type([MatchCoverSchema]) covers = new ArraySchema<MatchCoverSchema>();
  @type([MatchCrateSchema]) crates = new ArraySchema<MatchCrateSchema>();
  @type([MatchCrateOrbSchema]) crateOrbs = new ArraySchema<MatchCrateOrbSchema>();
  @type(MatchMidTowerSchema) midTower = new MatchMidTowerSchema();
  @type([MatchLootSchema]) loot = new ArraySchema<MatchLootSchema>();
  @type([MatchDeployableSchema]) deployables = new ArraySchema<MatchDeployableSchema>();
  @type([MatchZoneSchema]) zones = new ArraySchema<MatchZoneSchema>();
  @type([MatchKnockoutSchema]) knockouts = new ArraySchema<MatchKnockoutSchema>();
  @type(MatchFinishCineSchema) finishCine = new MatchFinishCineSchema();
  @type([MatchCoreSchema]) cores = new ArraySchema<MatchCoreSchema>();
  @type("uint32") eventSeq = 0;
  /** seq 문자열 키. ArraySchema.shift 는 클라 refId 를 깨뜨린다. */
  @type({ map: MatchEventSchema }) events = new MapSchema<MatchEventSchema>();
  @type("string") streakCallout = "";
  @type("string") streakSubtitle = "";
  @type("uint32") streakCalloutTicks = 0;
  @type("boolean") streakCalloutShutdown = false;
  @type([MatchEffectSchema]) effects = new ArraySchema<MatchEffectSchema>();
}
