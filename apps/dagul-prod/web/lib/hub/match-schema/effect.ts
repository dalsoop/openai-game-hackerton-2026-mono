import { Schema, type } from "@colyseus/schema";

/** 시각 이펙트. packEffects 키와 같다. */
export class MatchEffectSchema extends Schema {
  @type("string") k = "";
  @type("float32") x = 0;
  @type("float32") y = 0;
  @type("float32") r = 0;
  @type("float32") t = 0;
  @type("float32") maxT = 0;
  @type("string") color = "";
  @type("string") label = "";
  @type("float32") dx = 1;
  @type("float32") dy = 0;
  @type("int8") follow = -1;
  @type("float32") sx = 0;
  @type("float32") sy = 0;
  @type("boolean") dep = true;
}
