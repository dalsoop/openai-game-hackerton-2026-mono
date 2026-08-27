import { describe, expect, it } from "vitest";
import { assertCanAdmitCcu } from "@/lib/hub/ccu-admit";
import { ccuHttpBody } from "@/lib/hub/ccu-http";
import { KO } from "@/lib/hub/config";

describe("assertCanAdmitCcu", () => {
  it("한도 미만이면 통과한다", async () => {
    await expect(assertCanAdmitCcu(() => 0, 100)).resolves.toBeUndefined();
    await expect(assertCanAdmitCcu(() => 99, 100)).resolves.toBeUndefined();
    await expect(assertCanAdmitCcu(() => Promise.resolve(49), 50)).resolves.toBeUndefined();
  });

  it("한도에 닿으면 SERVER_FULL 을 던진다", async () => {
    await expect(assertCanAdmitCcu(() => 100, 100)).rejects.toThrow(KO.SERVER_FULL);
    await expect(assertCanAdmitCcu(() => 101, 100)).rejects.toThrow(KO.SERVER_FULL);
  });
});

describe("ccuHttpBody", () => {
  it("공식 통계 숫자를 혼잡 스냅으로 직렬화한다", () => {
    expect(ccuHttpBody(12, 100)).toEqual({
      ccu: 12, cap: 100, level: "quiet", admit: true,
    });
    expect(ccuHttpBody(50, 100).level).toBe("busy");
    expect(ccuHttpBody(75, 100).level).toBe("very_busy");
    expect(ccuHttpBody(100, 100).level).toBe("full");
    expect(ccuHttpBody(100, 100).admit).toBe(false);
  });
});
