import { describe, expect, it } from "vitest";
import { applyRuntimeProgress, clamp01, monotonicProgress, ratioProgress } from "@/lib/godot/load-progress";
import { shouldSendPackPct } from "@/lib/domain/waiting-room-pack";

describe("load-progress", () => {
  it("비율은 0..1 이고 분모 0 이면 0 이다", () => {
    expect(ratioProgress(0, 0)).toBe(0);
    expect(ratioProgress(50, 100)).toBe(0.5);
    expect(clamp01(1.4)).toBe(1);
    expect(clamp01(-0.2)).toBe(0);
  });

  it("한 세션에서 진행률은 줄어들지 않는다", () => {
    expect(monotonicProgress(0.5, 0.02)).toBe(0.5);
    expect(monotonicProgress(0.5, 0)).toBe(0.5);
    expect(monotonicProgress(0.2, 0.74)).toBe(0.74);
    expect(monotonicProgress(0.9, 0, true)).toBe(0);
  });

  it("부팅 2% 가 이미 올라간 다운로드를 덮지 않는다", () => {
    const held = applyRuntimeProgress(
      { state: "downloading", progress: 0.5 },
      { progress: 0.02 },
    );
    expect(held.progress).toBe(0.5);
    const done = applyRuntimeProgress(held, { state: "running", progress: 1 });
    expect(done.progress).toBe(1);
  });
});

describe("shouldSendPackPct — 대기실 보고", () => {
  it("80 에서 0 으로 되돌리지 않는다", () => {
    expect(shouldSendPackPct(80, 0)).toBe(false);
    expect(shouldSendPackPct(80, 50)).toBe(false);
    expect(shouldSendPackPct(80, 100)).toBe(true);
    expect(shouldSendPackPct(0, 5)).toBe(true);
  });
});
