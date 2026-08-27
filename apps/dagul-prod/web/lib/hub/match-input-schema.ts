import { Schema, type } from "@colyseus/schema";
import { ARENA_SIZE } from "./match-covers.js";
import type { MatchInput } from "./match-input-queue.js";

/** Godot InputData 는 전부 float 로만 심는다. 참/거짓도 0/1. */
export class MatchInputSchema extends Schema {
  @type("float32") mx = 0;
  @type("float32") my = 0;
  @type("float32") aimX = 0;
  @type("float32") aimY = 0;
  @type("float32") fire = 0;
  @type("float32") firePressed = 0;
  @type("float32") equipment = 0;
  @type("float32") equipmentPressed = 0;
  @type("float32") equipmentReleased = 0;
  @type("float32") dash = 0;
  @type("float32") mobility = 0;
  @type("float32") use = 0;
  @type("float32") reload = 0;
  @type("float32") ultimate = 0;
  @type("float32") hop = 0;
  @type("float32") finish = 0;
  @type("float32") emote = -1;
}

export const MATCH_INPUT_SANITIZE = {
  mx: [-1, 1],
  my: [-1, 1],
  aimX: [0, ARENA_SIZE.x],
  aimY: [0, ARENA_SIZE.y],
  fire: [0, 1],
  firePressed: [0, 1],
  equipment: [0, 1],
  equipmentPressed: [0, 1],
  equipmentReleased: [0, 1],
  dash: [0, 1],
  mobility: [0, 1],
  use: [0, 1],
  reload: [0, 1],
  ultimate: [0, 1],
  hop: [0, 1],
  finish: [0, 1],
  emote: [-1, 32],
} as const;

/** 홀드만 남기고 에지는 끈다. 스키마 인스턴스를 스프레드하지 않는다. */
export function idleHoldFrame(latest: MatchInputSchema | undefined): true | Record<string, number> {
  if (!latest) {return true;}
  return {
    mx: latest.mx, my: latest.my,
    aimX: latest.aimX, aimY: latest.aimY,
    fire: latest.fire, equipment: latest.equipment,
    emote: -1,
  };
}

export function matchInputFromFrame(frame: MatchInputSchema, seq: number): MatchInput {
  return {
    mx: frame.mx, my: frame.my,
    aimX: frame.aimX, aimY: frame.aimY,
    fire: frame.fire > 0.5, firePressed: frame.firePressed > 0.5,
    equipment: frame.equipment > 0.5,
    equipmentPressed: frame.equipmentPressed > 0.5,
    equipmentReleased: frame.equipmentReleased > 0.5,
    dash: frame.dash > 0.5 || frame.mobility > 0.5,
    mobility: frame.mobility > 0.5,
    use: frame.use > 0.5, reload: frame.reload > 0.5,
    ultimate: frame.ultimate > 0.5, hop: frame.hop > 0.5,
    finish: frame.finish > 0.5,
    emote: frame.emote,
    seq,
  };
}
