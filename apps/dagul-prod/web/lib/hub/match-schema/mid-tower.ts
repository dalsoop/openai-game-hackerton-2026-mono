import { Schema, type } from "@colyseus/schema";

export class MatchMidTowerSchema extends Schema {
  @type("boolean") alive = false;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") hp = 0;
  @type("float32") maxHp = 0;
  @type("float32") boing = 0;
}
