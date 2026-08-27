import { Schema, type } from "@colyseus/schema";

export class MatchLootSchema extends Schema {
  @type("string") id = "";
  @type("string") kind = "item";
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("string") n = "";
  @type("string") itemKind = "";
}
