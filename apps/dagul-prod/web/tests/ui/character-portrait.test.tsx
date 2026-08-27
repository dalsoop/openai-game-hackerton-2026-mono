// @vitest-environment jsdom
import { afterEach, describe, expect, it } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import CharacterPortrait from "@/components/CharacterPortrait";
import { findCharacter } from "@/lib/characters";
import ko from "../../messages/ko.json";

afterEach(cleanup);

const SLOT_SIZE = 44;

function frameOf(img: HTMLElement): HTMLElement {
  const frame = img.parentElement;
  expect(frame).toBeTruthy();
  return frame as HTMLElement;
}

describe("CharacterPortrait DOM — 시트 한 칸 클립", () => {
  it("토끼는 animals 시트 4열 칸만 보이게 자른다", () => {
    const rabbit = findCharacter("a3");
    expect(rabbit?.portrait).toEqual({
      src: "/characters/animals.png", cols: 4, rows: 3, index: 3,
    });
    render(<CharacterPortrait characterId="a3" size={SLOT_SIZE} title={ko.characters.a3} />);
    const img = screen.getByRole("img", { name: ko.characters.a3 });
    const frame = frameOf(img);
    expect(frame.className).toBe("char-portrait");
    expect(frame.style.overflow).toBe("hidden");
    expect(frame.style.position).toBe("relative");
    expect(frame.style.width).toBe("44px");
    expect(frame.style.height).toBe("44px");
    expect(frame.style.minWidth).toBe("0px");
    expect(img.getAttribute("src")).toBe("/characters/animals.png");
    expect(img.style.position).toBe("absolute");
    expect(img.style.left).toBe("-132px");
    expect(img.style.top).toBe("0px");
    expect(img.style.width).toBe("176px");
    expect(img.style.height).toBe("132px");
    expect(img.style.maxWidth).toBe("none");
    expect(img.style.marginLeft).toBe("");
    expect(img.style.marginTop).toBe("");
  });

  it("랜덤은 시트 오프셋 없이 한 장을 칸에 담는다", () => {
    render(
      <CharacterPortrait characterId="unknown" size={SLOT_SIZE} title={ko.characters.unknown} />,
    );
    const img = screen.getByRole("img", { name: ko.characters.unknown });
    expect(img.getAttribute("src")).toBe("/characters/unknown.png");
    expect(img.style.objectFit).toBe("contain");
    expect(img.style.width).toBe("44px");
    expect(img.style.height).toBe("44px");
    expect(img.style.position).not.toBe("absolute");
    expect(frameOf(img).style.overflow).toBe("hidden");
  });

  it("없는 id 는 기본 캐릭터 초상으로 정규화한다", () => {
    const { container } = render(<CharacterPortrait characterId="nope" size={SLOT_SIZE} />);
    const img = container.querySelector("img");
    expect(img?.getAttribute("src")).toBe("/characters/unknown.png");
    expect(img?.getAttribute("alt")).toBe("");
  });
});
