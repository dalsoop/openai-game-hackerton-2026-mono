import { Schema, type } from "@colyseus/schema";

export class MatchZoneSchema extends Schema {
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") radius = 0;
  @type("int8") owner = -1;
  @type("float32") delay = 0;
  @type("float32") warningDuration = 0;
  @type("string") color = "";
  @type("string") effectKind = "";
  @type("string") label = "";
}
