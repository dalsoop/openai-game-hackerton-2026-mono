import { Schema, ArraySchema, MapSchema, type } from "@colyseus/schema";

/** packAuthoritySnap SnapPlayer 와 같은 필드. */
export class MatchHeroSchema extends Schema {
  @type("int8") slot = -1;
  @type("string") name = "";
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") aimX = 0;
  @type("float32") aimY = 0;
  @type("float32") hp = 0;
  @type("float32") maxHp = 0;
  @type("boolean") alive = true;
  @type("uint8") mag = 0;
  @type("uint8") magMax = 0;
  @type("float32") reloadLeft = 0;
  @type("string") weapon = "";
  @type("float32") ult = 0;
  @type("uint32") ack = 0;
  @type("int8") animal = -1;
  @type("string") characterId = "";
  @type("boolean") cpu = false;
  @type("string") item = "";
  @type("uint32") kills = 0;
  @type("boolean") downed = false;
  @type("float32") downLeft = 0;
  @type("uint32") deaths = 0;
  @type("float32") score = 0;
  @type("uint32") streak = 0;
  @type("int8") emote = -1;
  @type("float32") emoteTime = 0;
  @type("string") weaponId = "";
  @type("float32") stunT = 0;
  @type("float32") rootT = 0;
  @type("float32") ccT = 0;
  @type("float32") guardT = 0;
  @type("float32") armorT = 0;
  @type("float32") spawnT = 0;
  @type("float32") launchT = 0;
  @type("float32") launchVX = 0;
  @type("float32") launchVY = 0;
  @type("boolean") charging = false;
  @type("float32") chargeT = 0;
  @type("float32") dmgOrbT = 0;
  @type("float32") downTaken = 0;
  @type("float32") woolT = 0;
  @type("int16") woolHp = 0;
  @type("int16") woolMax = 0;
  @type("float32") rouT = 0;
  @type("string") rouRank = "";
  @type("string") rouPhase = "";
  @type("string") rouSpin = "";
  @type("string") rouLabel = "";
  @type("string") action = "";
  @type("string") heldItem = "";
  @type("float32") springT = 0;
  @type("float32") slideT = 0;
  /** JSON 배열 문자열. TimedBuff[] / {x,y}[] 는 nested ArraySchema 가 비싸다. */
  @type("string") rlTimed = "[]";
  @type("string") ultClones = "[]";
  @type("boolean") parked = false;
  @type("float32") pullT = 0;
  @type("float32") pocketT = 0;
  @type("float32") hopT = 0;
  @type("float32") hopMax = 0;
  @type("float32") hopHeight = 0;
  @type("float32") mobCd = 0;
  @type("float32") mvSpd = 0;
  @type("boolean") elim = false;
}

export class MatchBulletSchema extends Schema {
  @type("uint32") id = 0;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") vx = 0;
  @type("float32") vy = 0;
  @type("int8") owner = -1;
  @type("string") kind = "bolt";
  @type("float32") radius = 0;
  @type("boolean") arc = false;
  @type("boolean") heavy = false;
  @type("string") src = "";
  @type("float32") ttl = 0;
  @type("float32") maxTtl = 0;
  @type("float32") lx = 0;
  @type("float32") ly = 0;
  @type("float32") splash = 0;
}

export class MatchCoverSchema extends Schema {
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") w = 0;
  @type("float32") h = 0;
}

export class MatchCrateSchema extends Schema {
  @type("uint32") id = 0;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") hp = 0;
  @type("float32") maxHp = 0;
  @type("boolean") alive = true;
}

export class MatchCrateOrbSchema extends Schema {
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("boolean") red = false;
  @type("boolean") active = false;
}

export class MatchMidTowerSchema extends Schema {
  @type("boolean") alive = false;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") hp = 0;
  @type("float32") maxHp = 0;
  @type("float32") boing = 0;
}

export class MatchLootSchema extends Schema {
  @type("string") id = "";
  @type("string") kind = "item";
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("string") n = "";
}

export class MatchDeployableSchema extends Schema {
  @type("string") type = "";
  @type("int8") owner = -1;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") dx = 0;
  @type("float32") dy = 0;
  @type("float32") tdx = 0;
  @type("float32") tdy = 0;
  @type("float32") halfLength = 0;
  @type("float32") lifetime = 0;
  @type("float32") maxLifetime = 0;
  @type("float32") armTime = 0;
  @type("float32") armDuration = 0;
  @type("boolean") triggered = false;
  @type("float32") triggerRadius = 0;
  @type("float32") blastRadius = 0;
  @type("float32") fuseTime = 0;
  @type("float32") fuseDuration = 0;
}

export class MatchZoneSchema extends Schema {
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") radius = 0;
  @type("int8") owner = -1;
  @type("float32") delay = 0;
  @type("float32") warningDuration = 0;
  @type("string") color = "";
  @type("string") effectKind = "";
  @type("string") label = "";
}

export class MatchKnockoutSchema extends Schema {
  @type("int8") slot = -1;
  @type("int8") animal = -1;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") time = 0;
  @type("float32") maxTime = 0;
}

export class MatchFinishCineSchema extends Schema {
  @type("boolean") on = false;
  @type("int8") atk = -1;
  @type("int8") vic = -1;
  @type("float32") t = 0;
  @type("boolean") hit = false;
  @type("float32") hitAge = 0;
  @type("float32") fly = 0;
  @type("float32") vicX = 0;
  @type("float32") vicY = 0;
  @type("float32") vicSpin = 0;
  @type("float32") atkX = 0;
  @type("boolean") rush = false;
  @type("float32") midX = 0;
  @type("float32") midY = 0;
}

export class MatchCoreSchema extends Schema {
  @type("int8") slot = -1;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") hp = 0;
  @type("float32") maxHp = 0;
  @type("boolean") alive = true;
}

/** 시각 이펙트. packEffects 키와 같다. */
export class MatchEffectSchema extends Schema {
  @type("string") k = "";
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") r = 0;
  @type("float32") t = 0;
  @type("float32") maxT = 0;
  @type("string") color = "";
  @type("string") label = "";
  @type("float32") dx = 1;
  @type("float32") dy = 0;
  @type("int8") follow = -1;
  @type("float32") sx = 0;
  @type("float32") sy = 0;
  @type("boolean") dep = true;
}

/** 일회성 연출. d 는 소형 객체 JSON 문자열. */
export class MatchEventSchema extends Schema {
  @type("uint32") seq = 0;
  @type("uint32") t = 0;
  @type("string") k = "";
  @type("int8") a = -1;
  @type("int8") b = -1;
  @type("string") d = "{}";
}

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
