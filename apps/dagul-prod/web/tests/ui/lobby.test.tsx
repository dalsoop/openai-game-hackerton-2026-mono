// @vitest-environment jsdom
/**
 * 로비 목록 계약 — 방 만들기는 링크만, 생성 폼은 없다.
 */
import type { JSX, ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup, within } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import Lobby from "@/components/Lobby";
import ko from "../../messages/ko.json";

type LinkProps = {
  href: string;
  children: ReactNode;
  className?: string;
  onClick?: (e: { preventDefault: () => void }) => void;
  "aria-disabled"?: boolean | "true" | "false";
};

vi.mock("@/i18n/routing", (): { Link: (props: LinkProps) => JSX.Element } => ({
  Link: ({ href, children, className, onClick, ...rest }: LinkProps): JSX.Element => (
    <a href={href} className={className} onClick={onClick} {...rest}>{children}</a>
  ),
}));

const messages = { lobby: ko.lobby, congestion: ko.congestion, games: ko.games } as typeof ko;

afterEach(cleanup);

describe("로비 목록", () => {
  it("방 만들기 링크는 /create 이고 생성 폼은 없다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby rooms={[]} myRoom={null} onJoin={vi.fn()} onForgetMyRoom={vi.fn()} onRefresh={vi.fn()} />
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
        <Lobby rooms={[]} myRoom={null} onJoin={vi.fn()} onForgetMyRoom={vi.fn()} onRefresh={vi.fn()} />
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
            { id: "c1", gameId: "dagul", title: "닫힌방", players: 1, mode: "classic", playing: false, open: false, hasPassword: false },
            { id: "p1", gameId: "dagul", title: "진행방", players: 2, mode: "classic", playing: true, open: true, hasPassword: false },
          ]}
          myRoom={null}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
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

  it("내 방이 있으면 다른 방 입장 전 확인을 받고, 취소하면 onJoin 을 안 부른다", () => {
    const onJoin = vi.fn();
    const onForgetMyRoom = vi.fn();
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(false);
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[
            { id: "mine", gameId: "dagul", title: "내방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false },
            { id: "other", gameId: "dagul", title: "남의방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false },
          ]}
          myRoom={{ roomId: "mine", host: true }}
          onJoin={onJoin}
          onForgetMyRoom={onForgetMyRoom}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("남의방"));
    expect(confirmSpy).toHaveBeenCalledWith(ko.lobby.leaveRoomConfirm);
    expect(onForgetMyRoom).not.toHaveBeenCalled();
    expect(onJoin).not.toHaveBeenCalled();
    confirmSpy.mockRestore();
  });

  it("확인하면 내 방을 버리고 다른 방에 입장한다", () => {
    const onJoin = vi.fn();
    const onForgetMyRoom = vi.fn();
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(true);
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[
            { id: "mine", gameId: "dagul", title: "내방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false },
            { id: "other", gameId: "dagul", title: "남의방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false },
          ]}
          myRoom={{ roomId: "mine", host: true }}
          onJoin={onJoin}
          onForgetMyRoom={onForgetMyRoom}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("남의방"));
    expect(onForgetMyRoom).toHaveBeenCalledTimes(1);
    expect(onJoin).toHaveBeenCalledWith("other");
    confirmSpy.mockRestore();
  });

  it("내 방을 다시 클릭하는 건 확인 없이 그대로 들어간다", () => {
    const onJoin = vi.fn();
    const confirmSpy = vi.spyOn(window, "confirm");
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "mine", gameId: "dagul", title: "내방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false }]}
          myRoom={{ roomId: "mine", host: true }}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("내방"));
    expect(confirmSpy).not.toHaveBeenCalled();
    expect(onJoin).toHaveBeenCalledWith("mine");
    confirmSpy.mockRestore();
  });

  it("내 방이 없으면 확인 없이 바로 입장한다", () => {
    const onJoin = vi.fn();
    const confirmSpy = vi.spyOn(window, "confirm");
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "other", gameId: "dagul", title: "아무방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false }]}
          myRoom={null}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("아무방"));
    expect(confirmSpy).not.toHaveBeenCalled();
    expect(onJoin).toHaveBeenCalledWith("other");
    confirmSpy.mockRestore();
  });

  it("방 만들기도 목록에 내 방이 있으면 확인을 받고, 취소하면 이동을 막는다", () => {
    const onForgetMyRoom = vi.fn();
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(false);
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "mine", gameId: "dagul", title: "내방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false }]}
          myRoom={{ roomId: "mine", host: true }}
          onJoin={vi.fn()}
          onForgetMyRoom={onForgetMyRoom}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    const link = screen.getByRole("link", { name: ko.lobby.createButton }) as HTMLAnchorElement;
    const event = fireEvent.click(link);
    expect(confirmSpy).toHaveBeenCalledWith(ko.lobby.leaveRoomConfirm);
    expect(onForgetMyRoom).not.toHaveBeenCalled();
    expect(event).toBe(false); // preventDefault 됨 — jsdom 이 false 를 돌린다.
    confirmSpy.mockRestore();
  });

  it("저장소에만 남은 유령 내 방은 목록에 없고 방 만들기 확인도 안 뜬다", () => {
    const confirmSpy = vi.spyOn(window, "confirm");
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[]}
          myRoom={{ roomId: "ghost", host: true }}
          onJoin={vi.fn()}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText(ko.lobby.emptyRooms)).toBeTruthy();
    expect(screen.queryByText(ko.lobby.mineHost)).toBeNull();
    fireEvent.click(screen.getByRole("link", { name: ko.lobby.createButton }));
    expect(confirmSpy).not.toHaveBeenCalled();
    confirmSpy.mockRestore();
  });

  it("꽉참이면 서버 정원을 그리지 않고 방 만들기·새 입장을 막는다", () => {
    const onJoin = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "open", gameId: "dagul", title: "열린방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false }]}
          myRoom={null}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
          ccu={{ ccu: 100, cap: 100, level: "full", admit: false }}
        />
      </NextIntlClientProvider>,
    );
    expect(screen.queryByRole("status")).toBeNull();
    expect(screen.queryByText(ko.congestion.capLabel)).toBeNull();
    expect(screen.getByText(ko.congestion.fullHint)).toBeTruthy();
    const create = screen.getByRole("link", { name: ko.lobby.createButton });
    expect(create.getAttribute("aria-disabled")).toBe("true");
    fireEvent.click(create);
    fireEvent.click(screen.getByText("열린방"));
    expect(onJoin).not.toHaveBeenCalled();
  });

  it("꽉참이어도 내 방은 다시 들어갈 수 있다", () => {
    const onJoin = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "mine", gameId: "dagul", title: "내방", players: 1, mode: "classic", playing: false, open: true, hasPassword: false }]}
          myRoom={{ roomId: "mine", host: true }}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
          ccu={{ ccu: 100, cap: 100, level: "full", admit: false }}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("내방"));
    expect(onJoin).toHaveBeenCalledWith("mine");
  });

  it("검색어에 맞는 방만 남긴다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[
            { id: "a", gameId: "dagul", title: "저녁", players: 1, mode: "classic", playing: false, open: true, hasPassword: false },
            { id: "b", gameId: "dagul", title: "아침", players: 1, mode: "classic", playing: false, open: true, hasPassword: false },
          ]}
          myRoom={null}
          onJoin={vi.fn()}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.change(screen.getByPlaceholderText(ko.lobby.searchPlaceholder), { target: { value: "저녁" } });
    expect(screen.getByText("저녁")).toBeTruthy();
    expect(screen.queryByText("아침")).toBeNull();
  });

  it("비밀번호 방은 바로 입장하지 않고 PIN 칸을 연다", () => {
    const onJoin = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "sec", gameId: "dagul", title: "비밀방", players: 1, mode: "classic", playing: false, open: true, hasPassword: true }]}
          myRoom={null}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("비밀방"));
    expect(onJoin).not.toHaveBeenCalled();
    expect(screen.getByRole("dialog")).toBeTruthy();
    expect(screen.getByRole("group")).toBeTruthy();
    const join = within(screen.getByRole("dialog")).getByRole("button", { name: ko.lobby.join });
    expect((join as HTMLButtonElement).disabled).toBe(true);
  });

  it("PIN 4자리를 채우면 그 값으로 입장한다", () => {
    const onJoin = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "sec", gameId: "dagul", title: "비밀방", players: 1, mode: "classic", playing: false, open: true, hasPassword: true }]}
          myRoom={null}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("비밀방"));
    for (const [i, d] of ["1", "2", "3", "4"].entries()) {
      fireEvent.keyDown(document.querySelectorAll(".pin-box")[i], { key: d });
    }
    const join = within(screen.getByRole("dialog")).getByRole("button", { name: ko.lobby.join });
    expect((join as HTMLButtonElement).disabled).toBe(false);
    fireEvent.click(join);
    expect(onJoin).toHaveBeenCalledWith("sec", { password: "1234" });
    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("비밀번호 모달을 취소하면 입장하지 않는다", () => {
    const onJoin = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "sec", gameId: "dagul", title: "비밀방", players: 1, mode: "classic", playing: false, open: true, hasPassword: true }]}
          myRoom={null}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("비밀방"));
    fireEvent.click(within(screen.getByRole("dialog")).getAllByRole("button", { name: ko.lobby.passwordCancel })[0]);
    expect(onJoin).not.toHaveBeenCalled();
    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("내 잠긴 방은 PIN 없이 다시 들어간다", () => {
    const onJoin = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <Lobby
          rooms={[{ id: "mine", gameId: "dagul", title: "내방", players: 1, mode: "classic", playing: false, open: true, hasPassword: true }]}
          myRoom={{ roomId: "mine", host: true }}
          onJoin={onJoin}
          onForgetMyRoom={vi.fn()}
          onRefresh={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText("내방"));
    expect(onJoin).toHaveBeenCalledWith("mine");
    expect(screen.queryByRole("dialog")).toBeNull();
  });
});

