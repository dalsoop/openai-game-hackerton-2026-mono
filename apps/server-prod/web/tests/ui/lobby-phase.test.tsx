// @vitest-environment jsdom
/**
 * 로비 페이즈 — 뒤로가기는 연결 중에도 살아 있어야 한다.
 */
import type { JSX, ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { LobbyPhase } from "@/components/phases/LobbyPhase";
import ko from "../../messages/ko.json";

vi.mock("@/i18n/routing", () => ({
  Link: ({ href, children }: { href: string; children: ReactNode }): JSX.Element => (
    <a href={href}>{children}</a>
  ),
}));

const messages = { game: ko.game, lobby: ko.lobby } as typeof ko;

afterEach(cleanup);

describe("LobbyPhase 뒤로가기", () => {
  it("방 목록이 떠 있을 때 뒤로가기가 인트로 콜백을 부른다", () => {
    const onBack = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <LobbyPhase
          rooms={[]}
          status="lobby"
          myRoom={null}
          onJoinRoom={vi.fn()}
          onRefresh={vi.fn()}
          onBackToIntro={onBack}
          connClass="conn-ok"
          connText=""
          rttMs={0}
          rttText={null}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByRole("button", { name: ko.game.back }));
    expect(onBack).toHaveBeenCalledTimes(1);
    expect(screen.queryByText(ko.game.loading.preparing)).toBeNull();
  });

  it("연결 중에도 뒤로가기가 있다", () => {
    const onBack = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <LobbyPhase
          rooms={[]}
          status="connecting"
          myRoom={null}
          onJoinRoom={vi.fn()}
          onRefresh={vi.fn()}
          onBackToIntro={onBack}
          connClass="conn-ok"
          connText=""
          rttMs={0}
          rttText={null}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByRole("button", { name: ko.game.back }));
    expect(onBack).toHaveBeenCalledTimes(1);
  });
});
