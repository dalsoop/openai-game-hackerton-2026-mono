// 런타임 왕복 계약: 서버 인코더가 만든 바이트를 실제 디코더가 읽어 상태가 흘러야 한다.
// 구조 대조(schema-mirror.test.ts)가 못 잡는 계열을 잡는다 — 필드 한도 초과로 인한
// "refId not found" 붕괴, 패치 스트림 desync, 중첩 스키마 유실. 여기가 터지면
// 운영 증상은 "이펙트·총알 안 보임 / 이동 정지 / 봇 정지"로 나타난다.
import { Decoder, Encoder } from "@colyseus/schema";
import { describe, expect, it } from "vitest";
import { MatchStateSchema } from "@/lib/hub/match-schema";
import { writeMatchState } from "@/lib/hub/match-schema-write";
import { FIXED_DT, MatchSim } from "@/lib/hub/match-sim";

const NAMES = new Map([[0, "호스트"], [1, "게스트"]]);

function newSim(): MatchSim {
  return new MatchSim([{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }], 7, "full");
}

function hero0(sim: MatchSim): { x: number; y: number } {
  const h = sim.heroes.get(0);
  if (!h) {throw new Error("hero 0");}
  return h;
}

function assertMirrorSynced(
  mirror: MatchStateSchema, state: MatchStateSchema, sim: MatchSim, seq: number,
): void {
  expect(mirror.tick, `tick 흐름 (seq=${seq})`).toBe(state.tick);
  const row = mirror.heroes.get("0");
  if (!row) {throw new Error("decoded hero 0");}
  expect(row.x, `이동 반영 (seq=${seq})`).toBeCloseTo(hero0(sim).x, 2);
}

describe("계약: 스키마 인코드→디코드 왕복", () => {
  it("풀 인코드를 새 디코더가 예외 없이 전부 복원한다", () => {
    const state = new MatchStateSchema();
    const sim = newSim();
    for (let i = 0; i < 12; i += 1) {sim.step(FIXED_DT);}
    writeMatchState(state, sim, NAMES, "full");
    const encoder = new Encoder(state);
    const mirror = new MatchStateSchema();
    const decoder = new Decoder(mirror);
    decoder.decode(encoder.encodeAll());
    expect(mirror.tick).toBe(state.tick);
    expect(mirror.heroes.size).toBe(state.heroes.size);
    const row = mirror.heroes.get("0");
    if (!row) {throw new Error("decoded hero 0");}
    expect(row.x).toBeCloseTo(hero0(sim).x, 2);
    expect(row.hud.moveSpeed).toBeGreaterThan(0);
  });

  it("120틱 패치 스트림을 디코더가 끊김 없이 소화한다 — 이동·발사·틱이 흐른다", () => {
    const state = new MatchStateSchema();
    const sim = newSim();
    for (let i = 0; i < 600 && sim.countdown > 0; i += 1) {sim.step(FIXED_DT);}
    expect(sim.countdown, "카운트다운 종료").toBe(0);
    writeMatchState(state, sim, NAMES, "full");
    const encoder = new Encoder(state);
    const mirror = new MatchStateSchema();
    const decoder = new Decoder(mirror);
    decoder.decode(encoder.encodeAll());
    encoder.discardChanges();

    const start = { ...hero0(sim) };
    let sawBullet = false;
    for (let seq = 1; seq <= 120; seq += 1) {
      const a = hero0(sim);
      sim.pushInput(0, {
        mx: 1, my: 0, fire: seq % 4 === 0, firePressed: seq % 4 === 0,
        aimX: a.x + 200, aimY: a.y, seq,
      });
      sim.step(FIXED_DT);
      writeMatchState(state, sim, NAMES, "full");
      decoder.decode(encoder.encode());
      encoder.discardChanges();
      sawBullet = sawBullet || mirror.bullets.size > 0;
      if (seq % 30 === 0) {assertMirrorSynced(mirror, state, sim, seq);}
    }
    expect(hero0(sim).x, "입력이 시뮬을 움직인다").toBeGreaterThan(start.x);
    expect(sawBullet, "발사가 탄 스키마로 흐른다").toBe(true);
  });

  it("매치 2연전에도 패치 스트림이 살아 있다 — clear 뒤 refId 재사용 안전", async () => {
    const { clearMatchState } = await import("@/lib/hub/match-schema-write");
    const state = new MatchStateSchema();
    const encoder = new Encoder(state);
    const mirror = new MatchStateSchema();
    const decoder = new Decoder(mirror);
    decoder.decode(encoder.encodeAll());
    encoder.discardChanges();
    for (let round = 0; round < 2; round += 1) {
      const sim = newSim();
      for (let i = 0; i < 30; i += 1) {
        sim.step(FIXED_DT);
        writeMatchState(state, sim, NAMES, "full");
        decoder.decode(encoder.encode());
        encoder.discardChanges();
      }
      expect(mirror.heroes.size).toBe(2);
      clearMatchState(state);
      decoder.decode(encoder.encode());
      encoder.discardChanges();
      expect(mirror.heroes.size).toBe(0);
    }
  });
});
