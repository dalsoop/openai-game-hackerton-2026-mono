import { describe, expect, it } from "vitest";
import { bem, cn, classNames } from "@/lib/helpers";

// 리터럴 true/false 는 상수 조건으로 좁혀져 실제 호출 패턴 검증이 안 된다 —
// boolean 값을 흘려보내는 헬퍼로 런타임 boolean을 재현한다.
const bool = (b: boolean): boolean => b;

describe("cn — 조건부 클래스 조립", () => {
  it("참값만 이어 붙인다", () => {
    expect(cn("foo", bool(true) && "bar", bool(false) && "baz", undefined, null)).toBe("foo bar");
  });
  it("전부 거짓이면 빈 문자열", () => {
    expect(cn(bool(false) && "a", undefined, null)).toBe("");
  });
  it("classNames는 cn의 별칭", () => {
    expect(classNames("a", bool(true) && "b")).toBe(cn("a", bool(true) && "b"));
  });
});

describe("bem — BEM 생성", () => {
  it("block__element--modifier", () => {
    expect(bem("card")).toBe("card");
    expect(bem("card", "header")).toBe("card__header");
    expect(bem("card", "header", "active")).toBe("card__header--active");
  });
});
