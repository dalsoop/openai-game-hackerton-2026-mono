// @vitest-environment jsdom
/**
 * 회귀: 방 만들기에서 "지금 속한 방을 나가게 됩니다" 가 목록에 없는 유령 방 때문에 뜬다.
 * 확인창은 로비 목록에 그 방이 보일 때만 뜬다.
 */
import type { JSX, ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import Lobby from "@/components/Lobby";
import type { HubRoom } from "@/types";
import type { MyRoomIdentity } from "@/lib/room-membership";
import ko from "../../messages/ko.json";

type LinkProps = {
  href: string;
  children: ReactNode;
  className?: string;
  onClick?: (e: { preventDefault: () => void }) => void;
};

vi.mock("@/i18n/routing", (): { Link: (props: LinkProps) => JSX.Element } => ({
  Link: ({ href, children, className, onClick, ...rest }: LinkProps): JSX.Element => (
    <a href={href} className={className} onClick={onClick} {...rest}>{children}</a>
  ),
}));

const messages = { lobby: ko.lobby, congestion: ko.congestion, games: ko.games } as typeof ko;

function openRoom(id: string, title: string): HubRoom {
  return {
    id, gameId: "dagul", title, players: 1, mode: "classic",
    playing: false, open: true, hasPassword: false,
  };
}

function renderLobby(rooms: HubRoom[], myRoom: MyRoomIdentity | null): {
  onJoin: ReturnType<typeof vi.fn>;
  onForgetMyRoom: ReturnType<typeof vi.fn>;
} {
  const onJoin = vi.fn();
  const onForgetMyRoom = vi.fn();
  render(
    <NextIntlClientProvider locale="ko" messages={messages}>
      <Lobby
        rooms={rooms}
        myRoom={myRoom}
        onJoin={onJoin}
        onForgetMyRoom={onForgetMyRoom}
        onRefresh={vi.fn()}
      />
    </NextIntlClientProvider>,
  );
  return { onJoin, onForgetMyRoom };
}

function clickCreate(): boolean {
  return fireEvent.click(screen.getByRole("link", { name: ko.lobby.createButton }));
}

afterEach(cleanup);

describe("로비 나가기 확인 — 목록에 보이는 내 방만", () => {
  it("목록이 비어 있으면 유령 저장 id 로 방 만들기 확인이 안 뜬다", () => {
    const confirmSpy = vi.spyOn(window, "confirm");
    renderLobby([], { roomId: "ghost", host: true });
    expect(screen.getByText(ko.lobby.emptyRooms)).toBeTruthy();
    expect(screen.queryByText(ko.lobby.mineHost)).toBeNull();
    clickCreate();
    expect(confirmSpy).not.toHaveBeenCalled();
    confirmSpy.mockRestore();
  });

  it("남의 방만 있으면 유령 id 로는 확인 없이 만들고 그 방에 들어간다", () => {
    const confirmSpy = vi.spyOn(window, "confirm");
    const { onJoin, onForgetMyRoom } = renderLobby(
      [openRoom("other", "남의방")],
      { roomId: "ghost", host: true },
    );
    expect(screen.queryByText(ko.lobby.mineHost)).toBeNull();
    expect(screen.getByText("남의방")).toBeTruthy();
    clickCreate();
    expect(confirmSpy).not.toHaveBeenCalled();
    fireEvent.click(screen.getByText("남의방"));
    expect(confirmSpy).not.toHaveBeenCalled();
    expect(onForgetMyRoom).not.toHaveBeenCalled();
    expect(onJoin).toHaveBeenCalledWith("other");
    confirmSpy.mockRestore();
  });

  it("확인이 뜨는 방 만들기는 목록에 내 방이 보인다", () => {
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(false);
    const { onForgetMyRoom } = renderLobby(
      [openRoom("mine", "내방")],
      { roomId: "mine", host: true },
    );
    expect(screen.getByText("내방")).toBeTruthy();
    expect(screen.getByText(ko.lobby.mineHost)).toBeTruthy();
    expect(screen.queryByText(ko.lobby.emptyRooms)).toBeNull();
    expect(clickCreate()).toBe(false);
    expect(confirmSpy).toHaveBeenCalledWith(ko.lobby.leaveRoomConfirm);
    expect(onForgetMyRoom).not.toHaveBeenCalled();
    confirmSpy.mockRestore();
  });

  it("목록의 내 방을 두고 방 만들기를 확인하면 저장 식별자를 버린다", () => {
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(true);
    const { onForgetMyRoom } = renderLobby(
      [openRoom("mine", "내방")],
      { roomId: "mine", host: true },
    );
    clickCreate();
    expect(confirmSpy).toHaveBeenCalledWith(ko.lobby.leaveRoomConfirm);
    expect(onForgetMyRoom).toHaveBeenCalledTimes(1);
    confirmSpy.mockRestore();
  });

  it("목록의 내 방을 두고 남의 방에 들어가려 하면 확인을 받는다", () => {
    const confirmSpy = vi.spyOn(window, "confirm").mockReturnValue(false);
    const { onJoin } = renderLobby(
      [openRoom("mine", "내방"), openRoom("other", "남의방")],
      { roomId: "mine", host: true },
    );
    expect(screen.getByText(ko.lobby.mineHost)).toBeTruthy();
    fireEvent.click(screen.getByText("남의방"));
    expect(confirmSpy).toHaveBeenCalledWith(ko.lobby.leaveRoomConfirm);
    expect(onJoin).not.toHaveBeenCalled();
    confirmSpy.mockRestore();
  });
});
