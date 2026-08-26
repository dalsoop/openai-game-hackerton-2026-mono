import { describe, expect, it } from "vitest";
import { portraitFrameStyle, portraitImageStyle, portraitStyle } from "@/lib/characters/portrait";

describe("portrait 배치", () => {
  it("래퍼는 요청한 한 변만 가진다", () => {
    expect(portraitFrameStyle(44)).toEqual({ width: 44, height: 44 });
    expect(portraitStyle({ src: "/x.png" }, 32)).toMatchObject({
      width: 32, height: 32, overflow: "hidden",
    });
  });

  it("단일 초상은 contain 이다", () => {
    expect(portraitImageStyle({ src: "/u.png" }, 44)).toMatchObject({
      width: 44, height: 44, objectFit: "contain", imageRendering: "pixelated",
    });
  });

  it("시트는 칸 크기만큼 밀어 맞춘다", () => {
    const cell = { src: "/s.png", cols: 4, rows: 3, index: 6 };
    expect(portraitImageStyle(cell, 40)).toMatchObject({
      width: 160, height: 120, marginLeft: -80, marginTop: -40, maxWidth: "none",
    });
    expect(portraitImageStyle({ ...cell, index: 0 }, 40).marginLeft).toBe(0);
    expect(portraitImageStyle({ ...cell, index: 0 }, 40).marginTop).toBe(0);
  });

  it("깨진 격자(0열)는 한 칸으로 본다", () => {
    expect(portraitImageStyle({ src: "/s.png", cols: 0, rows: 0, index: 2 }, 20)).toMatchObject({
      width: 20, height: 20, objectFit: "contain",
    });
  });
});
