import { Schema, type } from "@colyseus/schema";

export class MatchKnockoutSchema extends Schema {
  @type("int8") slot = -1;
  @type("int8") animal = -1;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") time = 0;
  @type("float32") maxTime = 0;
}
