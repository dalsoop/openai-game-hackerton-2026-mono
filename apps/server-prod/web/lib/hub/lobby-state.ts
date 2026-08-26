import { Schema, ArraySchema, MapSchema, type } from "@colyseus/schema";
import { asCharacterId } from "../characters/index.js";
import { asGameId, defaultModeOf } from "../games/catalog.js";

export class PlayerSchema extends Schema {
  @type("number") slot = -1;
  @type("string") sessionId = "";
  @type("string") name = "";
  @type("boolean") connected = true;
  @type("uint8") packPct = 0;
  @type("string") characterId = asCharacterId(undefined);
}

/** 인게임 히어로 — id 는 Map 키(slot 문자열). 서버만 변이한다. */
export class HeroSchema extends Schema {
  @type("int8") slot = -1;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") aimX = 0;
  @type("float32") aimY = 0;
  @type("float32") hp = 0;
  @type("float32") maxHp = 0;
  @type("boolean") alive = true;
  @type("uint8") mag = 0;
  @type("uint8") magMax = 0;
  @type("uint32") ack = 0;
  @type("int8") animal = -1;
}

/** 인게임 탄 — id 는 Map 키. */
export class BulletSchema extends Schema {
  @type("uint32") id = 0;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") vx = 0;
  @type("float32") vy = 0;
  @type("int8") owner = -1;
  @type("string") kind = "bolt";
}

export class LobbyState extends Schema {
  @type("string") gameId = asGameId(undefined);
  @type("boolean") open = true;
  @type("string") phase: "lobby" | "playing" = "lobby";
  @type("string") hostSessionId = "";
  @type("string") title = "";
  @type("string") mode = defaultModeOf(asGameId(undefined));
  @type("number") seed = 0;
  @type("number") createdAtMs = 0;
  /** 대기실 유휴 마감 unix 초. 0 이면 타이머 없음. float32 ms 를 쓰지 않는다. */
  @type("uint32") idleUntilSec = 0;
  @type([PlayerSchema]) players = new ArraySchema<PlayerSchema>();
  @type("uint32") matchTick = 0;
  @type({ map: HeroSchema }) heroes = new MapSchema<HeroSchema>();
  @type({ map: BulletSchema }) bullets = new MapSchema<BulletSchema>();
}
