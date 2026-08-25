// PIN 프롬프트·방 입장 요청 빌더 — useHub 에서 뽑아낸 순수 흐름의 계약.
import { afterEach, describe, expect, it, vi } from "vitest";
import { buildCreateRequest, buildJoinRequest } from "@/lib/hub/pin-prompt";
import type { JoinRequest } from "@/types";

// window.prompt 스텁 — node 환경이라 전역에 심는다.
const stubPrompt = (ret: string | null): void => {
  // 모듈이 window.prompt 를 읽는다 — node 환경엔 window 자체가 없다.
  vi.stubGlobal("window", { prompt: vi.fn(() => ret) });
};
afterEach((): void => {
  vi.unstubAllGlobals();
});

describe("buildCreateRequest — 방 만들기", () => {
  it("게임 지정·PIN 없음(빈 입력)", () => {
    stubPrompt("");
    expect(buildCreateRequest("sparring")).toEqual<JoinRequest>({ kind: "create", game: "sparring" });
  });

  it("유효 PIN(4~8자리 숫자)은 실린다", () => {
    stubPrompt("1234");
    expect(buildCreateRequest()).toEqual<JoinRequest>({ kind: "create", pin: "1234" });
  });

  it("취소(null)는 잠금 없음으로 간주한다", () => {
    stubPrompt(null);
    expect(buildCreateRequest()).toEqual<JoinRequest>({ kind: "create" });
  });

  it("불량 입력(3자리)은 PIN 없음으로 정규화한다", () => {
    stubPrompt("12");
    expect(buildCreateRequest()).toEqual<JoinRequest>({ kind: "create" });
  });
});

describe("buildJoinRequest — 방 입장", () => {
  it("잠기지 않은 방은 PIN 없이 즉시 요청", () => {
    expect(buildJoinRequest("r1", false)).toEqual<JoinRequest>({ kind: "join", id: "r1" });
  });

  it("잠긴 방 + 유효 PIN — PIN 포함 요청", () => {
    stubPrompt("999999");
    expect(buildJoinRequest("r1", true)).toEqual<JoinRequest>({ kind: "join", id: "r1", pin: "999999" });
  });

  it("잠긴 방 + 취소 — null (입장 중단)", () => {
    stubPrompt(null);
    expect(buildJoinRequest("r1", true)).toBeNull();
  });
});
