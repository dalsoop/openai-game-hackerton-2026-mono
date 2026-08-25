import { describe, expect, it } from "vitest";
import { idleLeftMs, idleLeftSec, shouldBurstIdle } from "@/lib/hub/lobby-idle";

describe("lobby-idle", () => {
  it("제한 시간이 남아 있으면 터지지 않는다", () => {
    expect(shouldBurstIdle(1000, 1000, 300_000)).toBe(false);
    expect(idleLeftSec(1000, 1000, 300_000)).toBe(300);
  });

  it("예산이 끝나면 터진다", () => {
    expect(shouldBurstIdle(1000, 301_000, 300_000)).toBe(true);
    expect(idleLeftMs(1000, 301_000, 300_000)).toBe(0);
  });
});
