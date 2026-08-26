import { describe, expect, it } from "vitest";
import { idleBudgetSec, idleLeftFromUntil, idleUntilSecOf, nowUnixSec, shouldBurstIdle } from "@/lib/hub/lobby-idle";

describe("lobby-idle — unix 초 마감", () => {
  it("예산만큼 남으면 터지지 않는다", () => {
    const until = idleUntilSecOf(1_700_000_000, 300_000);
    expect(until).toBe(1_700_000_000 + 300);
    expect(shouldBurstIdle(until, 1_700_000_000)).toBe(false);
    expect(idleLeftFromUntil(until, 1_700_000_000)).toBe(300);
  });

  it("마감이 지나면 터진다", () => {
    const until = idleUntilSecOf(1_000, 300_000);
    expect(shouldBurstIdle(until, 1_000 + 300)).toBe(true);
    expect(idleLeftFromUntil(until, 1_301)).toBe(0);
  });

  it("0 마감은 타이머 없음", () => {
    expect(idleLeftFromUntil(0, nowUnixSec())).toBe(0);
    expect(shouldBurstIdle(0, nowUnixSec())).toBe(false);
  });

  it("5분 예산은 300초", () => {
    expect(idleBudgetSec(300_000)).toBe(300);
  });
});
