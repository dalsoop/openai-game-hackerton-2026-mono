import { Schema, type } from "@colyseus/schema";

export class MatchCrateSchema extends Schema {
  @type("uint32") id = 0;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") hp = 0;
  @type("float32") maxHp = 0;
  @type("boolean") alive = true;
}
