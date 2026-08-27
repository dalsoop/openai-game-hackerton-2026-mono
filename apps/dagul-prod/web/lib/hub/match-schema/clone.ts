import { Schema, type } from "@colyseus/schema";

/** 궁 분신 위치. 렌더는 {x,y} 만 본다. */
export class MatchCloneSchema extends Schema {
  @type("float32") x = 0;
  @type("float32") y = 0;
}
