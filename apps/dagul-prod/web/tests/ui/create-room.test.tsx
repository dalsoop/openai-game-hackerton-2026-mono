// @vitest-environment jsdom
/**
 * 방 만들기 페이지 폼 계약 — 로비와 섞지 않는 전용 화면.
 *   1. 게임(유즈맵)과 방 이름을 제출한다
 *   2. 기본 게임은 카탈로그 정본
 *   3. 뒤로가기는 onBack
 *   4. 선택한 줄에 버전·용량·썸네일·설명이 있다
 */
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import CreateRoom from "@/components/CreateRoom";
import { DEFAULT_GAME_ID, GAME_CATALOG, type GameId } from "@/lib/games/catalog";
import type { GameListing } from "@/lib/games/listing";
import ko from "../../messages/ko.json";

function listingOf(id: string, extra: Pick<GameListing, "version" | "bytes">): GameListing {
  const game = GAME_CATALOG.find((g) => g.id === id);
  if (!game) {throw new Error(`catalog missing ${id}`);}
  return {
    id: game.id,
    titleKey: game.titleKey,
    blurbKey: game.blurbKey,
    thumbSrc: game.thumbSrc,
    version: extra.version,
    bytes: extra.bytes,
  };
}

const listings: GameListing[] = [
  listingOf(DEFAULT_GAME_ID, { version: "1.0.0", bytes: 2048 }),
  listingOf("sparring" as GameId, { version: null, bytes: null }),
];

function setup(): { onSubmit: ReturnType<typeof vi.fn>; onBack: ReturnType<typeof vi.fn> } {
  const onSubmit = vi.fn();
  const onBack = vi.fn();
  render(
    <NextIntlClientProvider locale="ko" messages={ko}>
      <CreateRoom
        listings={listings}
        onSubmit={onSubmit}
        onBack={onBack}
        connClass="conn-ok"
        connText=""
      />
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

  it("기본 게임에 버전·용량·설명·썸네일이 있다", () => {
    setup();
    expect(screen.getByText(ko.create.meta.replace("{version}", "1.0.0").replace("{size}", "2.0KB"))).toBeTruthy();
    expect(screen.getByText(ko.games.dagul.blurb)).toBeTruthy();
    expect(screen.getByRole("img", { name: ko.games.dagul.title })).toBeTruthy();
  });

  it("내보내기가 없으면 버전·용량 없음을 쓴다", () => {
    setup();
    expect(screen.getByText(
      ko.create.meta.replace("{version}", ko.create.versionUnknown).replace("{size}", ko.create.sizeUnknown),
    )).toBeTruthy();
    expect(screen.getByText(ko.games.sparring.blurb)).toBeTruthy();
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
    fireEvent.click(screen.getByRole("button", { name: ko.create.cancel }));
    expect(onBack).toHaveBeenCalledTimes(1);
  });

  it("꽉참이면 제출을 막고 안내를 보여 준다", () => {
    const onSubmit = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <CreateRoom
          listings={listings}
          onSubmit={onSubmit}
          onBack={vi.fn()}
          connClass="conn-ok"
          connText=""
          ccu={{ ccu: 100, cap: 100, level: "full", admit: false }}
        />
      </NextIntlClientProvider>,
    );
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.full);
    expect(screen.getByText(ko.congestion.fullHint)).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: ko.congestion.full }));
    expect(onSubmit).not.toHaveBeenCalled();
  });
});
