import { describe, expect, it } from "vitest";
import { HUB_CONFIG, HANDOFF } from "@/lib/hub/config";
import type { JoinRequest } from "@/types";

describe("세션 재개 계약 — 재접속 유예", () => {
  it("페이즈별 유예가 양수이고 플레이가 대기실보다 길다", () => {
    expect(HUB_CONFIG.graceLobbyMs).toBeGreaterThan(0);
    expect(HUB_CONFIG.gracePlayMs).toBeGreaterThan(HUB_CONFIG.graceLobbyMs);
  });

  it("재개 토큰 저장 키가 계약 정본과 일치한다", () => {
    expect(HANDOFF.RESUME).toBe("gangup_resume");
  });

  it("JoinRequest 는 세션 재개(resume) 종류를 허용한다", () => {
    const requests: JoinRequest[] = [
      { kind: "create" },
      { kind: "join", id: "r1" },
      { kind: "resume" },
    ];
    expect(requests.map((r) => r.kind)).toEqual(["create", "join", "resume"]);
  });
});
