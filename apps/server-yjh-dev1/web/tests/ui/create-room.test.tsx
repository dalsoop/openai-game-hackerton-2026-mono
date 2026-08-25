// @vitest-environment jsdom
/**
 * 방 만들기 페이지 폼 계약 — 로비와 섞지 않는 전용 화면.
 *   1. 게임(유즈맵)과 방 이름을 제출한다
 *   2. 기본 게임은 카탈로그 정본
 *   3. 뒤로가기는 onBack
 */
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import CreateRoom from "@/components/CreateRoom";
import { DEFAULT_GAME_ID } from "@/lib/games/catalog";
import ko from "../../messages/ko.json";

const messages = { create: ko.create, lobby: ko.lobby } as typeof ko;

function setup(): { onSubmit: ReturnType<typeof vi.fn>; onBack: ReturnType<typeof vi.fn> } {
  const onSubmit = vi.fn();
  const onBack = vi.fn();
  render(
    <NextIntlClientProvider locale="ko" messages={messages}>
      <CreateRoom onSubmit={onSubmit} onBack={onBack} />
    </NextIntlClientProvider>,
  );
  return { onSubmit, onBack };
}

afterEach(cleanup);

describe("방 만들기 폼", () => {
  it("제목·게임 선택·제출이 보인다", () => {
    setup();
    expect(screen.getByRole("heading", { name: ko.create.title })).toBeTruthy();
    expect(screen.getByText(ko.create.blurb)).toBeTruthy();
    expect(screen.getByPlaceholderText(ko.create.roomTitlePlaceholder)).toBeTruthy();
    expect(screen.getByDisplayValue(DEFAULT_GAME_ID)).toBeTruthy();
    expect(screen.getByRole("button", { name: ko.create.submit })).toBeTruthy();
  });

  it("기본 게임만 고르고 제출하면 빈 제목으로 onSubmit", () => {
    const { onSubmit } = setup();
    fireEvent.click(screen.getByRole("button", { name: ko.create.submit }));
    expect(onSubmit).toHaveBeenCalledWith(DEFAULT_GAME_ID, "");
  });

  it("게임과 방 이름을 채워 제출한다", () => {
    const { onSubmit } = setup();
    fireEvent.click(screen.getByDisplayValue("sparring"));
    fireEvent.change(screen.getByPlaceholderText(ko.create.roomTitlePlaceholder), {
      target: { value: "저녁 한 판" },
    });
    fireEvent.click(screen.getByRole("button", { name: ko.create.submit }));
    expect(onSubmit).toHaveBeenCalledWith("sparring", "저녁 한 판");
  });

  it("로비로 — onBack", () => {
    const { onBack } = setup();
    fireEvent.click(screen.getByRole("button", { name: `← ${ko.create.cancel}` }));
    expect(onBack).toHaveBeenCalledTimes(1);
  });
});
