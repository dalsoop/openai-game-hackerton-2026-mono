import { describe, expect, it } from "vitest";
import { shouldRelaySnap, snapByteLength, snapUnchanged } from "@/lib/hub/snap-relay";

describe("snap-relay", () => {
  it("같은 본문은 보내지 않는다", () => {
    const a = { tick: 1, result: "playing" };
    expect(snapUnchanged(a, { tick: 1, result: "playing" })).toBe(true);
    expect(shouldRelaySnap(a, { tick: 1, result: "playing" }, 1024)).toBe(false);
  });

  it("바이트 상한을 넘으면 보내지 않는다", () => {
    const big = { blob: "x".repeat(200) };
    expect(snapByteLength(big)).toBeGreaterThan(100);
    expect(shouldRelaySnap(null, big, 100)).toBe(false);
    expect(shouldRelaySnap(null, { tick: 2 }, 100)).toBe(true);
  });
});
