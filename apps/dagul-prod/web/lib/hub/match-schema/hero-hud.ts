import { Schema, type } from "@colyseus/schema";
import { MatchUntilBuffSchema } from "./until-buff.js";

/**
 * MatchHeroSchema 가 Colyseus 64필드 한도에 닿아 넘치는 필드를 중첩한다.
 * 한도는 실재한다 — 인코더가 (index | operation) 한 바이트 패킹이라
 * 인덱스 64 이상은 DELETE(64)/ADD(128) 비트와 충돌해 "refId not found" 로 붕괴한다.
 */
export class MatchHeroHudSchema extends Schema {
  @type("float32") reloadFlash = 0;
  @type("float32") respawnLeft = 0;
  @type("float32") sprayIndex = 0;
  @type("string") rouletteDesc = "";
  @type("float32") hitstunTime = 0;
  @type("float32") comboCaptureTime = 0;
  @type("float32") moveSpeed = 0;
  @type("boolean") eliminated = false;
  @type("uint8") medkits = 0;
  @type("float32") mobilityDist = 0;
  @type("float32") equipmentCd = 0;
  @type(MatchUntilBuffSchema) untilBuffs = new MatchUntilBuffSchema();
}
