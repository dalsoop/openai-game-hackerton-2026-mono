import { describe, expect, it } from "vitest";
import { packAuthoritySnap } from "@/lib/hub/match-authority";
import { MatchStateSchema } from "@/lib/hub/match-schema";
import { writeMatchState } from "@/lib/hub/match-schema-write";
import { FIXED_DT, MatchSim } from "@/lib/hub/match-sim";

type Snap = {
  tick: number;
  zoneR: number;
  players: Array<{ slot: number; x: number; y: number; hp: number }>;
  bullets: Array<{ id: number; x: number; y: number }>;
};

describe("writeMatchState", () => {
  it("스키마 값이 packAuthoritySnap 의 대표 필드와 같다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    sim.countdown = 0;
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    const hero0 = sim.heroes.get(0);
    const aimX = (hero0?.x ?? 0) + 80;
    sim.pushInput(0, {
      mx: 1, my: 0, fire: true, firePressed: true, seq: 1, aimX, aimY: 2380,
    });
    for (let i = 0; i < 12; i += 1) {sim.step(FIXED_DT);}
    const match = new MatchStateSchema();
    writeMatchState(match, sim, names, "full");
    const snap = packAuthoritySnap(sim, names, "full") as Snap;
    expect(match.tick).toBe(snap.tick);
    expect(match.zoneR).toBe(snap.zoneR);
    const p0 = snap.players.find((p) => p.slot === 0);
    const row = match.heroes.get("0");
    expect(row?.x).toBe(p0?.x);
    expect(row?.y).toBe(p0?.y);
    expect(row?.hp).toBe(p0?.hp);
    expect(snap.bullets.length).toBeGreaterThan(0);
    expect(match.bullets.size).toBe(snap.bullets.length);
    const b = snap.bullets[0];
    const bullet = match.bullets.get(String(b.id));
    expect(bullet?.x).toBe(b.x);
    expect(bullet?.y).toBe(b.y);
  });
});
