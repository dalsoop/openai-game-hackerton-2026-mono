import { Schema, type } from "@colyseus/schema";

export class MatchCoverSchema extends Schema {
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") w = 0;
  @type("float32") h = 0;
}
