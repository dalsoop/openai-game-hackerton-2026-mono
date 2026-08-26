import { describe, expect, it } from "vitest";
import { hubReplicaCount } from "@/lib/hub/ccu-plan";
import { hubPublicAddress } from "@/lib/hub/public-address";
import { HUB_CONFIG } from "@/lib/hub/config";

describe("hubReplicaCount", () => {
  it("1만 CCU / 프로세스당 500 이면 20 대", () => {
    expect(hubReplicaCount(10_000, 500)).toBe(20);
    expect(hubReplicaCount(HUB_CONFIG.targetCcu, HUB_CONFIG.perProcessCcu)).toBe(20);
  });

  it("0 이하여도 최소 1 대", () => {
    expect(hubReplicaCount(0, 500)).toBe(1);
    expect(hubReplicaCount(100, 0)).toBe(100);
  });
});

describe("hubPublicAddress", () => {
  it("접두사와 파드가 있을 때만 만든다", () => {
    expect(hubPublicAddress("server-yjh-dev1.external.kr/hubp", "pod-a"))
      .toBe("server-yjh-dev1.external.kr/hubp/pod-a");
    expect(hubPublicAddress("server-yjh-dev1.external.kr/hubp", "server-yjh-dev1-hub-0"))
      .toBe("server-yjh-dev1.external.kr/hubp/server-yjh-dev1-hub-0");
    expect(hubPublicAddress("", "pod-a")).toBeUndefined();
    expect(hubPublicAddress("host/hubp", "")).toBeUndefined();
  });
});
