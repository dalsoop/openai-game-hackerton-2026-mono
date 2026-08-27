import { describe, expect, it } from "vitest";
import {
  admissionCcu, congestionOf, hubReplicaCount, parseAdmissionCcu, DEFAULT_ADMISSION_CCU,
} from "@/lib/hub/ccu-plan";
import {
  hubHttpEndpoint, hubPinFromWsUrl, hubPublicAddress, parseHubPinRecord, pinForMatchmake,
} from "@/lib/hub/public-address";
import { HUB_CONFIG } from "@/lib/hub/config";

describe("hubReplicaCount", () => {
  it("1000 CCU / 프로세스당 500 이면 상한 2 대", () => {
    expect(hubReplicaCount(1_000, 500)).toBe(2);
    expect(hubReplicaCount(HUB_CONFIG.targetCcu, HUB_CONFIG.perProcessCcu)).toBe(2);
  });

  it("0 이하여도 최소 1 대", () => {
    expect(hubReplicaCount(0, 500)).toBe(1);
    expect(hubReplicaCount(100, 0)).toBe(100);
  });
});

describe("admissionCcu", () => {
  it("기본 한도는 100", () => {
    expect(DEFAULT_ADMISSION_CCU).toBe(100);
    expect(HUB_CONFIG.admissionCcu).toBe(100);
    expect(parseAdmissionCcu(undefined)).toBe(100);
    expect(admissionCcu(undefined)).toBe(100);
  });

  it("숫자만 받고 1 미만은 기본값", () => {
    expect(parseAdmissionCcu("80")).toBe(80);
    expect(parseAdmissionCcu("0")).toBe(100);
    expect(parseAdmissionCcu("-3")).toBe(100);
    expect(parseAdmissionCcu("nope")).toBe(100);
  });
});

describe("congestionOf", () => {
  it("한도 100 에서 원활·혼잡·매우혼잡·꽉참 경계를 지킨다", () => {
    expect(congestionOf(0, 100)).toEqual({ ccu: 0, cap: 100, level: "quiet", admit: true });
    expect(congestionOf(49, 100).level).toBe("quiet");
    expect(congestionOf(50, 100)).toMatchObject({ level: "busy", admit: true });
    expect(congestionOf(74, 100).level).toBe("busy");
    expect(congestionOf(75, 100)).toMatchObject({ level: "very_busy", admit: true });
    expect(congestionOf(99, 100)).toMatchObject({ level: "very_busy", admit: true });
    expect(congestionOf(100, 100)).toEqual({ ccu: 100, cap: 100, level: "full", admit: false });
    expect(congestionOf(140, 100).admit).toBe(false);
  });

  it("한도 바로 아래만 입장한다", () => {
    expect(congestionOf(1, 1).admit).toBe(false);
    expect(congestionOf(0, 1).admit).toBe(true);
  });
});

describe("hubPublicAddress", () => {
  it("접두사와 파드가 있을 때만 만든다", () => {
    expect(hubPublicAddress("server-yjh-dev1.external.kr/hubp", "pod-a"))
      .toBe("server-yjh-dev1.external.kr/hubp/pod-a");
    expect(hubPublicAddress("server-prod.external.kr/hubp", "server-prod-hub-0"))
      .toBe("server-prod.external.kr/hubp/server-prod-hub-0");
    expect(hubPublicAddress("", "pod-a")).toBeUndefined();
    expect(hubPublicAddress("host/hubp", "")).toBeUndefined();
  });

  it("재개 HTTP 는 WS 핀 경로로 간다", () => {
    expect(hubPinFromWsUrl(
      "wss://server-prod.external.kr/hubp/server-prod-hub-18/proc/room?sessionId=s",
    )).toBe("server-prod.external.kr/hubp/server-prod-hub-18");
    expect(hubHttpEndpoint("https://server-prod.external.kr", "server-prod.external.kr/hubp/server-prod-hub-18"))
      .toBe("https://server-prod.external.kr/hubp/server-prod-hub-18");
    expect(hubHttpEndpoint("https://server-prod.external.kr", null))
      .toBe("https://server-prod.external.kr");
    expect(hubPinFromWsUrl("wss://server-prod.external.kr/proc/room")).toBeUndefined();
  });

  it("같은 방의 join·resume 만 핀을 쓰고 create 는 입구다", () => {
    const stored = { roomId: "r1", pin: "server-prod.external.kr/hubp/server-prod-hub-1" };
    expect(pinForMatchmake("create", undefined, stored)).toBeNull();
    expect(pinForMatchmake("join", "r1", stored)).toBe(stored.pin);
    expect(pinForMatchmake("join", "r2", stored)).toBeNull();
    expect(pinForMatchmake("resume", undefined, stored)).toBe(stored.pin);
    expect(parseHubPinRecord(JSON.stringify(stored))).toEqual(stored);
    expect(parseHubPinRecord("server-prod.external.kr/hubp/server-prod-hub-1"))
      .toEqual({ roomId: "", pin: "server-prod.external.kr/hubp/server-prod-hub-1" });
  });
});
