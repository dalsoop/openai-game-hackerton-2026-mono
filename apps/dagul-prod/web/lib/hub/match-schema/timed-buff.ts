import { Schema, type } from "@colyseus/schema";

/** 룰렛·궁 타임버프. HUD·대시차단·거대 스케일이 읽는 칸만 싣는다. */
export class MatchTimedBuffSchema extends Schema {
  @type("string") id = "";
  @type("string") name = "";
  @type("float32") time = 0;
  @type("float32") shield = 0;
}
