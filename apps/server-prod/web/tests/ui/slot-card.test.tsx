// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import SlotCard from "@/components/SlotCard";
import { Seat } from "@/lib/domain/roster";
import { defaultCharacterId, listCharacters, stepCharacterId } from "@/lib/characters";
import ko from "../../messages/ko.json";

function seat(characterId: string, connected = true, packPct = 100): Seat {
  return new Seat(0, "me", "플레이어", true, connected, packPct, characterId);
}

function renderMine(characterId: string, onSetCharacter = vi.fn()): ReturnType<typeof vi.fn> {
  render(
    <NextIntlClientProvider locale="ko" messages={ko}>
      <SlotCard index={0} player={seat(characterId)} you={0} onSetCharacter={onSetCharacter} />
    </NextIntlClientProvider>,
  );
  return onSetCharacter;
}

afterEach(cleanup);

describe("SlotCard 캐릭터 순환", () => {
  it("자기 좌석에만 이전/다음 버튼이 있다", () => {
    renderMine(defaultCharacterId());
    expect(screen.getByRole("button", { name: "이전 캐릭터" })).toBeTruthy();
    expect(screen.getByRole("button", { name: "다음 캐릭터" })).toBeTruthy();
    cleanup();
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <SlotCard index={1} player={seat(defaultCharacterId())} you={0} onSetCharacter={vi.fn()} />
      </NextIntlClientProvider>,
    );
    expect(screen.queryByRole("button", { name: "다음 캐릭터" })).toBeNull();
  });

  it("다음/이전은 카탈로그 step 과 같은 id 를 보낸다", () => {
    const id = defaultCharacterId();
    const onSet = renderMine(id);
    fireEvent.click(screen.getByRole("button", { name: "다음 캐릭터" }));
    fireEvent.click(screen.getByRole("button", { name: "이전 캐릭터" }));
    expect(onSet.mock.calls.map((c) => c[0])).toEqual([
      stepCharacterId(id, 1),
      stepCharacterId(id, -1),
    ]);
  });

  it("받는 중이면 카드에 다운로드중(n%) 을 단다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <SlotCard index={0} player={seat(defaultCharacterId(), true, 42)} you={0} />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText("다운로드중(42%)")).toBeTruthy();
  });

  it("초상 img 는 카탈로그 src 를 쓴다", () => {
    const first = listCharacters()[0];
    expect(first).toEqual(expect.objectContaining({ id: expect.any(String) }));
    renderMine(first.id);
    const img = screen.getByRole("img", { name: ko.characters.unknown });
    expect(img.getAttribute("src")).toBe(first.portrait.src);
  });
});
