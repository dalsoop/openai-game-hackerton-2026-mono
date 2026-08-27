import { Schema, type } from "@colyseus/schema";

/** 일회성 연출 payload. 클라가 읽는 칸만 싣는다. */
export class MatchEventDataSchema extends Schema {
  @type("string") equipment = "";
  @type("string") id = "";
  @type("string") source = "";
  @type("string") kind = "";
  @type("string") rank = "";
  @type("string") reason = "";
  @type("string") dropped = "";
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") damage = 0;
  @type("float32") heal = 0;
  @type("float32") amount = 0;
  @type("float32") remaining = 0;
  @type("float32") from = 0;
  @type("float32") to = 0;
  @type("float32") hpRatio = 0;
  @type("float32") coreRatio = 0;
  @type("float32") score = 0;
  @type("int32") clones = 0;
  @type("int32") crate = -1;
  @type("int32") target = -1;
  @type("int32") left = 0;
  @type("int32") phase = 0;
  @type("int32") standing = 0;
  @type("int32") pending = 0;
  @type("int32") previousTarget = -1;
  @type("boolean") predicted = false;
  @type("boolean") executed = false;
}
