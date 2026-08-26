import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";
import { HUB_CONFIG } from "@/lib/hub/config";
import { hubReplicaCount } from "@/lib/hub/ccu-plan";
import { snapByteLength, shouldRelaySnap } from "@/lib/hub/snap-relay";

/** NetworkHost.build_snapshot + ArenaGeometry.build_tiled_covers 의 상한 모형. */
function hostPackedSnap(): Record<string, unknown> {
  const players = Array.from({ length: 8 }, (_, slot) => ({
    slot,
    name: `플레이어${slot + 1}`,
    cpu: slot > 3,
    parked: false,
    x: 1000 + slot * 200,
    y: 1200 + slot * 80,
    aimX: 1100,
    aimY: 1200,
    hp: 176,
    maxHp: 176,
    alive: true,
    weapon: "GLOCK 18",
    mag: 18,
    magMax: 18,
    reloadLeft: 0,
    ult: 40,
    animal: slot,
    item: "medkit",
    kills: slot,
    emote: -1,
    emoteTime: 0,
    ack: 12,
  }));
  const xy = (n: number) =>
    Array.from({ length: n }, (_, i) => ({ x: 2000 + i * 30, y: 1800 + i * 20, owner: i % 8 }));
  return {
    tick: 1800,
    time: 90,
    result: "playing",
    winner: -1,
    zoneR: 2200,
    shrinking: true,
    zoneCX: 3920,
    zoneCY: 2380,
    zonePhase: 2,
    startCountdown: 0,
    wantedSlot: 0,
    mode: "full",
    players,
    bullets: xy(40),
    loot: xy(8).map((p, i) => ({ id: `p${i}`, kind: "item", x: p.x, y: p.y, n: "" })),
    zones: xy(8).map((p) => ({
      x: p.x, y: p.y, radius: 80, owner: p.owner, delay: 0.2, warning_duration: 0.2,
      color: "#ff3349", effect_kind: "explosion", label: "",
    })),
    deployables: xy(6).map((p) => ({
      type: "mine", owner: p.owner, x: p.x, y: p.y, dx: 1, dy: 0, tdx: 1, tdy: 0,
      half_length: 0, lifetime: 4, max_lifetime: 8, arm_time: 0, arm_duration: 0.4,
      triggered: false, trigger_radius: 40, blast_radius: 80, fuse_time: 0, fuse_duration: 0,
    })),
    cores: players.map((p) => ({ slot: p.slot, x: p.x, y: p.y, hp: 210, max_hp: 210, alive: true })),
    covers: Array.from({ length: 44 }, (_, i) => ({ x: i * 80, y: 400, w: 168, h: 98 })),
    knockouts: [{ slot: 2, x: 3000, y: 2000, time: 1.2, max_time: 2.15 }],
    crates: xy(8).map((p, i) => ({ id: i, x: p.x, y: p.y, hp: 48, max_hp: 48, alive: true })),
    crate_orbs: xy(4).map((p) => ({ x: p.x, y: p.y, red: true, active: true })),
    mid_tower: { alive: true, x: 3920, y: 2380, hp: 1800, max_hp: 2400, boing: 0 },
  };
}

describe("snap budget", () => {
  it("호스트 패킹 상한이 중계 한도 안이다", () => {
    const snap = hostPackedSnap();
    const bytes = snapByteLength(snap);
    expect(bytes, `snap ${bytes}B`).toBeLessThanOrEqual(HUB_CONFIG.maxSnapBytes);
    expect(shouldRelaySnap(null, snap, HUB_CONFIG.maxSnapBytes)).toBe(true);
  });

  it("차트 HPA 상한은 HUB_CONFIG 공식과 같다", () => {
    const yaml = readFileSync(
      path.resolve(__dirname, "../../../../deploy/chart/values.yaml"),
      "utf8",
    );
    const scale = yaml.match(/scale:\n([\s\S]*?)(?:\n  [a-z]|\n[a-z]|$)/)?.[1] ?? "";
    const n = Number(scale.match(/maxReplicas:\s*(\d+)/)?.[1]);
    expect(n).toBe(hubReplicaCount(HUB_CONFIG.targetCcu, HUB_CONFIG.perProcessCcu));
    expect(Number(scale.match(/replicaCount:\s*(\d+)/)?.[1])).toBe(1);
  });
});
