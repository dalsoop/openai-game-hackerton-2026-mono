import { Schema, ArraySchema, type } from "@colyseus/schema";
import { asGameId, defaultModeOf } from "../games/catalog.js";

export class PlayerSchema extends Schema {
  @type("number") slot = -1;
  @type("string") sessionId = "";
  @type("string") name = "";
  @type("boolean") connected = true;
}

export class LobbyState extends Schema {
  @type("string") gameId = asGameId(undefined);
  @type("boolean") open = true;
  @type("string") phase: "lobby" | "playing" = "lobby";
  @type("string") hostSessionId = "";
  @type("string") title = "";
  @type("string") mode = defaultModeOf(asGameId(undefined));
  @type("number") seed = 0;
  @type([PlayerSchema]) players = new ArraySchema<PlayerSchema>();
}
