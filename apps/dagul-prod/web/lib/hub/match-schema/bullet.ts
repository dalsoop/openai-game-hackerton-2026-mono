import { Schema, type } from "@colyseus/schema";

export class MatchBulletSchema extends Schema {
  @type("uint32") id = 0;
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") vx = 0;
  @type("float32") vy = 0;
  @type("int8") owner = -1;
  @type("string") kind = "bolt";
  @type("float32") radius = 0;
  @type("boolean") arc = false;
  @type("boolean") heavy = false;
  @type("string") src = "";
  @type("float32") ttl = 0;
  @type("float32") maxTtl = 0;
  @type("float32") lx = 0;
  @type("float32") ly = 0;
  @type("float32") splash = 0;
}
