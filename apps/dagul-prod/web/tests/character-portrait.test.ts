import { describe, expect, it } from "vitest";
import { portraitFrameStyle, portraitImageStyle, portraitStyle } from "@/lib/characters/portrait";

describe("portrait 배치", () => {
  it("래퍼는 한 변과 클립을 같이 가진다", () => {
    expect(portraitFrameStyle(44)).toMatchObject({
      width: 44, height: 44, overflow: "hidden", position: "relative", minWidth: 0,
    });
    expect(portraitStyle({ src: "/x.png" }, 32)).toMatchObject({
      width: 32, height: 32, overflow: "hidden",
    });
  });

  it("단일 초상은 contain 이다", () => {
    expect(portraitImageStyle({ src: "/u.png" }, 44)).toMatchObject({
      width: 44, height: 44, objectFit: "contain", imageRendering: "pixelated",
    });
  });

  it("시트는 칸 크기만큼 절대 위치로 밀어 맞춘다", () => {
    const cell = { src: "/s.png", cols: 4, rows: 3, index: 6 };
    expect(portraitImageStyle(cell, 40)).toMatchObject({
      position: "absolute", width: 160, height: 120, left: -80, top: -40, maxWidth: "none",
    });
    expect(portraitImageStyle({ ...cell, index: 0 }, 40).left).toBe(0);
    expect(portraitImageStyle({ ...cell, index: 0 }, 40).top).toBe(0);
  });

  it("토끼(index 3, 44px)는 4열 시트의 맨 오른쪽 칸이다", () => {
    const rabbit = { src: "/characters/animals.png", cols: 4, rows: 3, index: 3 };
    expect(portraitImageStyle(rabbit, 44)).toMatchObject({
      width: 176, height: 132, left: -132, top: 0, maxWidth: "none",
    });
    expect(portraitFrameStyle(44).overflow).toBe("hidden");
  });

  it("깨진 격자(0열)는 한 칸으로 본다", () => {
    expect(portraitImageStyle({ src: "/s.png", cols: 0, rows: 0, index: 2 }, 20)).toMatchObject({
      width: 20, height: 20, objectFit: "contain",
    });
  });

  it("12칸 전부 열·행 오프셋이 칸 크기 배수이고 마진 크롭을 쓰지 않는다", () => {
    for (let index = 0; index < 12; index++) {
      const style = portraitImageStyle({ src: "/s.png", cols: 4, rows: 3, index }, 44);
      const col = index % 4;
      const row = Math.floor(index / 4);
      expect(style.left, `index ${index} left`).toBe(col === 0 ? 0 : -(col * 44));
      expect(style.top, `index ${index} top`).toBe(row === 0 ? 0 : -(row * 44));
      expect(style, `index ${index}`).not.toHaveProperty("marginLeft");
      expect(style, `index ${index}`).not.toHaveProperty("marginTop");
      expect(style.maxWidth).toBe("none");
      expect(style.position).toBe("absolute");
    }
  });
});

