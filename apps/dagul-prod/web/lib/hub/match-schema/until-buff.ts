import { Schema, type } from "@colyseus/schema";

/** 목숨이 끝날 때까지 붙는 룰렛 버프. HUD 아이콘 분모. */
export class MatchUntilBuffSchema extends Schema {
  @type("float32") atk = 0;
  @type("float32") spd = 0;
  @type("float32") def = 0;
  @type("float32") hp = 0;
  @type("float32") rate = 0;
  @type("float32") range = 0;
}
