// @vitest-environment jsdom
/**
 * 로비 목록 계약 — 방 만들기는 링크만, 생성 폼은 없다.
 */
import type { JSX, ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import Lobby from "@/components/Lobby";
import ko from "../../messages/ko.json";

vi.mock("@/i18n/routing", (): { Link: (props: { href: string; children: ReactNode; className?: string }) => JSX.Element } => ({
  Link: ({ href, children, className }: { href: string; children: ReactNode; className?: string }): JSX.Element => (
    <a href={href} className={className}>{children}</a>
  ),
}));

const messages = { lobby: ko.lobby } as typeof ko;

afterEach(cleanup);

describe("로비 목록", () => {
  it("방 만들기 링크는 /create 이고 생성 폼은 없다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby rooms={[]} myRoom={null} onJoin={vi.fn()} onRefresh={vi.fn()} />
      </NextIntlClientProvider>,
    );
    const link = screen.getByRole("link", { name: ko.lobby.createButton });
    expect(link.getAttribute("href")).toBe("/create");
    expect(screen.queryByRole("combobox")).toBeNull();
    expect(document.querySelector('input[name="title"]')).toBeNull();
    expect(document.querySelector('select[name="game"]')).toBeNull();
  });

  it("빈 목록은 안내만 보여 준다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby rooms={[]} myRoom={null} onJoin={vi.fn()} onRefresh={vi.fn()} />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText(ko.lobby.emptyRooms)).toBeTruthy();
  });

  it("닫힌 방·진행 중 방은 입장하지 않는다", () => {
    const onJoin = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[
            { id: "c1", gameId: "dagul", title: "닫힌방", players: 1, mode: "classic", playing: false, open: false },
            { id: "p1", gameId: "dagul", title: "진행방", players: 2, mode: "classic", playing: true, open: true },
          ]}
          myRoom={null}
          onJoin={onJoin}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("닫힌방"));
    fireEvent.click(screen.getByText("진행방"));
    expect(onJoin).not.toHaveBeenCalled();
    expect(screen.getByText(ko.lobby.closed)).toBeTruthy();
    expect(screen.getByText(ko.lobby.inProgress)).toBeTruthy();
    expect(screen.getAllByText(/클래식/).length).toBeGreaterThan(0);
  });
});
