import { Schema, type } from "@colyseus/schema";
import { MatchEventDataSchema } from "./event-data.js";

/** 일회성 연출. */
export class MatchEventSchema extends Schema {
  @type("uint32") seq = 0;
  @type("uint32") tick = 0;
  @type("string") kind = "";
  @type("int8") actor = -1;
  @type("int8") target = -1;
  @type(MatchEventDataSchema) data = new MatchEventDataSchema();
}
