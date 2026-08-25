import { describe, expect, it } from "vitest";
import { parsePingStamp, rttFromPong } from "@/lib/hub/rtt";

describe("parsePingStamp", () => {
  it("본문 t 또는 숫자 시각을 읽는다", () => {
    expect(parsePingStamp({ t: 100 })).toBe(100);
    expect(parsePingStamp(100)).toBe(100);
  });

  it("반전: 없거나 0 이하면 버린다", () => {
    expect(parsePingStamp(null)).toBeNull();
    expect(parsePingStamp({})).toBeNull();
    expect(parsePingStamp({ t: 0 })).toBeNull();
    expect(parsePingStamp(-1)).toBeNull();
  });
});

describe("rttFromPong", () => {
  it("왕복을 반올림한다", () => {
    expect(rttFromPong(1000, 1042.4)).toBe(42);
  });

  it("반전: 시계가 거꾸로면 버린다", () => {
    expect(rttFromPong(100, 90)).toBeNull();
    expect(rttFromPong(0, 10)).toBeNull();
  });
});
