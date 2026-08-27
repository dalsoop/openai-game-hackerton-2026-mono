import { Schema, type } from "@colyseus/schema";

export class MatchCoreSchema extends Schema {
  @type("int8") slot = -1;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") hp = 0;
  @type("float32") maxHp = 0;
  @type("boolean") alive = true;
}
