import { Schema, type } from "@colyseus/schema";

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
