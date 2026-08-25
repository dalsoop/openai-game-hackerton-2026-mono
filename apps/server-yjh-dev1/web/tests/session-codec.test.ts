import { describe, expect, it } from "vitest";
import { normalizeNickname, persistableNickname } from "@/lib/session-codec";

describe("normalizeNickname", () => {
  it("앞뒤 공백 제거", () => {
    expect(normalizeNickname("  다굴 ")).toBe("다굴");
    expect(normalizeNickname("다굴")).toBe("다굴");
  });

  it("공백만 → 빈 문자열", () => {
    expect(normalizeNickname("   ")).toBe("");
    expect(normalizeNickname("")).toBe("");
  });

  it("중간 공백은 유지", () => {expect(normalizeNickname(" 골 드 러너 ")).toBe("골 드 러너");});
});

describe("persistableNickname", () => {
  it("유효한 이름은 trim 결과", () => {expect(persistableNickname(" 다굴 ")).toBe("다굴");});

  it("공백만 있으면 null — 저장 금지", () => {
    expect(persistableNickname("")).toBeNull();
    expect(persistableNickname("   ")).toBeNull();
  });
});
