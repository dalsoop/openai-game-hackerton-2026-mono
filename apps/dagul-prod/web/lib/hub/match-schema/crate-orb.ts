import { Schema, type } from "@colyseus/schema";

export class MatchCrateOrbSchema extends Schema {
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("boolean") red = false;
  @type("boolean") active = false;
}
