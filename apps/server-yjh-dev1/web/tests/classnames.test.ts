import { describe, expect, it } from "vitest";
import { bem, cn, classNames } from "@/lib/helpers";

describe("cn — 조건부 클래스 조립", () => {
  it("참값만 이어 붙인다", () => {
    expect(cn("foo", true && "bar", false && "baz", undefined, null)).toBe("foo bar");
  });
  it("전부 거짓이면 빈 문자열", () => {
    expect(cn(false && "a", undefined, null)).toBe("");
  });
  it("classNames는 cn의 별칭", () => {
    expect(classNames("a", true && "b")).toBe(cn("a", true && "b"));
  });
});

describe("bem — BEM 생성", () => {
  it("block__element--modifier", () => {
    expect(bem("card")).toBe("card");
    expect(bem("card", "header")).toBe("card__header");
    expect(bem("card", "header", "active")).toBe("card__header--active");
  });
});
