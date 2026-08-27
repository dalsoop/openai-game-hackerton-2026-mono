// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import Room from "@/components/Room";
import { Seat } from "@/lib/domain/roster";
import { DEFAULT_GAME_ID } from "@/lib/games/catalog";
import { defaultCharacterId } from "@/lib/characters";
import ko from "../../messages/ko.json";

function renderRoom(isHost = true): void {
  render(
    <NextIntlClientProvider locale="ko" messages={ko}>
      <Room
        players={[new Seat(0, "host", "방장", true, true, 100, defaultCharacterId())]}
        you={0}
        isHost={isHost}
        gameId={DEFAULT_GAME_ID}
        mode="classic"
        roomOpen
        idleLeftSec={0}
        onStart={vi.fn()}
        onLeave={vi.fn()}
        onSetGame={vi.fn()}
        onToggleRoom={vi.fn()}
        onSetCharacter={vi.fn()}
        onKick={vi.fn()}
        onSetPassword={vi.fn()}
        onSetLock={vi.fn()}
        roomId="abc"
        password="0420"
        matchWait={false}
        canStart
        connClass="conn-ok"
        connText=""
        rttMs={12}
        rttText={null}
        startInSec={0}
      />
    </NextIntlClientProvider>,
  );
}

afterEach(cleanup);

function renderCountdown(startInSec: number, extra?: { isHost?: boolean; onLeave?: () => void }): void {
  render(
    <NextIntlClientProvider locale="ko" messages={ko}>
      <Room
        players={[new Seat(0, "host", "방장", true, true, 100, defaultCharacterId())]}
        you={0}
        isHost={extra?.isHost !== false}
        gameId={DEFAULT_GAME_ID}
        mode="classic"
        roomOpen
        idleLeftSec={0}
        onStart={vi.fn()}
        onLeave={extra?.onLeave ?? vi.fn()}
        onSetGame={vi.fn()}
        onToggleRoom={vi.fn()}
        onSetCharacter={vi.fn()}
        onKick={vi.fn()}
        onSetPassword={vi.fn()}
        onSetLock={vi.fn()}
        roomId="abc"
        password="0420"
        matchWait={false}
        canStart
        connClass="conn-ok"
        connText=""
        rttMs={12}
        rttText={null}
        startInSec={startInSec}
      />
    </NextIntlClientProvider>,
  );
}

describe("대기실 시작 버튼", () => {
  it("팩이 없으면 시작 대신 받는 중을 보여 준다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <Room
          players={[new Seat(0, "host", "방장", true, true, 29, defaultCharacterId())]}
          you={0}
          isHost
          gameId={DEFAULT_GAME_ID}
          mode="classic"
          roomOpen
          idleLeftSec={0}
          onStart={vi.fn()}
          onLeave={vi.fn()}
          onSetGame={vi.fn()}
          onToggleRoom={vi.fn()}
          onSetCharacter={vi.fn()}
          onKick={vi.fn()}
          onSetPassword={vi.fn()}
          onSetLock={vi.fn()}
          roomId="abc"
          password=""
          matchWait={false}
          canStart={false}
          connClass="conn-ok"
          connText=""
          rttMs={12}
          rttText={null}
          startInSec={0}
        />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText(ko.room.downloading)).toBeTruthy();
    expect(screen.queryByRole("button", { name: ko.room.startButton })).toBeNull();
  });
});

describe("대기실 시작 카운트다운 UI", () => {
  it("5초·4초는 나가기가 살아 있다", () => {
    const onLeave = vi.fn();
    renderCountdown(4, { onLeave });
    const leave = screen.getByRole("button", { name: ko.room.leaveButton });
    expect((leave as HTMLButtonElement).disabled).toBe(false);
    expect(screen.getByText("4초 후 시작합니다")).toBeTruthy();
    expect(screen.getAllByText("4초 후 시작합니다")).toHaveLength(1);
    fireEvent.click(leave);
    expect(onLeave).toHaveBeenCalledTimes(1);
  });

  it("세는 동안 시작 버튼만 카운트를 보여 주고 꺼진다", () => {
    renderCountdown(5);
    const start = screen.getByRole("button", { name: "5초 후 시작합니다" });
    expect((start as HTMLButtonElement).disabled).toBe(true);
    expect(screen.getAllByText("5초 후 시작합니다")).toHaveLength(1);
    expect(document.querySelector(".wait-start-count")).toBeNull();
  });

  it("3초부터 나가기 버튼을 끈다", () => {
    renderCountdown(3);
    const leave = screen.getByRole("button", { name: ko.room.leaveLocked });
    expect((leave as HTMLButtonElement).disabled).toBe(true);
  });

  it("게스트도 3초부터 나가기가 꺼진다", () => {
    renderCountdown(3, { isHost: false });
    const leave = screen.getByRole("button", { name: ko.room.leaveLocked });
    expect((leave as HTMLButtonElement).disabled).toBe(true);
    expect(screen.getByText("3초 후 시작합니다")).toBeTruthy();
    expect(screen.queryByRole("button", { name: "3초 후 시작합니다" })).toBeNull();
  });
});

describe("대기실 도구 모달", () => {
  it("처음에는 PIN 칸과 QR 을 펼치지 않는다", () => {
    renderRoom();
    expect(screen.getByRole("button", { name: ko.room.pin })).toBeTruthy();
    expect(screen.getByRole("button", { name: ko.room.share })).toBeTruthy();
    expect(screen.getByRole("button", { name: new RegExp(ko.room.changeGame) })).toBeTruthy();
    expect(screen.queryByRole("dialog")).toBeNull();
    expect(document.querySelector(".pin-box")).toBeNull();
    expect(document.querySelector(".room-qr")).toBeNull();
  });

  it("비밀번호 모달에 토글과 PIN 칸이 있다", () => {
    renderRoom();
    fireEvent.click(screen.getByRole("button", { name: ko.room.pin }));
    expect(screen.getByRole("dialog")).toBeTruthy();
    expect(screen.getByRole("switch")).toBeTruthy();
    expect((screen.getByRole("switch") as HTMLInputElement).checked).toBe(true);
    expect(document.querySelectorAll(".pin-box")).toHaveLength(4);
    expect(document.querySelector(".room-qr")).toBeNull();
    fireEvent.click(screen.getAllByRole("button", { name: ko.room.closePanel })[0]);
    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("방 공유 모달에는 QR 만 있고 토글은 없다", () => {
    renderRoom();
    fireEvent.click(screen.getByRole("button", { name: ko.room.share }));
    expect(screen.getByRole("dialog")).toBeTruthy();
    expect(screen.queryByRole("switch")).toBeNull();
    expect(document.querySelector(".pin-box")).toBeNull();
    fireEvent.click(screen.getAllByRole("button", { name: ko.room.closePanel })[0]);
    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("게스트는 게임 선택 버튼이 없다", () => {
    renderRoom(false);
    expect(screen.queryByRole("button", { name: new RegExp(ko.room.changeGame) })).toBeNull();
  });

  it("공개 방 공유 모달에는 PIN 칸이 없다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <Room
          players={[new Seat(0, "host", "방장", true, true, 100, defaultCharacterId())]}
          you={0}
          isHost
          gameId={DEFAULT_GAME_ID}
          mode="classic"
          roomOpen
          idleLeftSec={0}
          onStart={vi.fn()}
          onLeave={vi.fn()}
          onSetGame={vi.fn()}
          onToggleRoom={vi.fn()}
          onSetCharacter={vi.fn()}
          onKick={vi.fn()}
          onSetPassword={vi.fn()}
          onSetLock={vi.fn()}
          roomId="abc"
          password=""
          matchWait={false}
          canStart
          connClass="conn-ok"
          connText=""
          rttMs={12}
          rttText={null}
          startInSec={0}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByRole("button", { name: ko.room.share }));
    expect(screen.queryByRole("switch")).toBeNull();
    expect(document.querySelector(".pin-box")).toBeNull();
    expect(document.querySelector(".share-url")?.textContent ?? "").toContain("room=abc");
    expect(document.querySelector(".share-url")?.textContent ?? "").not.toContain("pw=");
  });

  it("토글을 끄면 onSetLock(false) 를 보낸다", () => {
    const onSetLock = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <Room
          players={[new Seat(0, "host", "방장", true, true, 100, defaultCharacterId())]}
          you={0}
          isHost
          gameId={DEFAULT_GAME_ID}
          mode="classic"
          roomOpen
          idleLeftSec={0}
          onStart={vi.fn()}
          onLeave={vi.fn()}
          onSetGame={vi.fn()}
          onToggleRoom={vi.fn()}
          onSetCharacter={vi.fn()}
          onKick={vi.fn()}
          onSetPassword={vi.fn()}
          onSetLock={onSetLock}
          roomId="abc"
          password="0420"
          matchWait={false}
          canStart
          connClass="conn-ok"
          connText=""
          rttMs={12}
          rttText={null}
          startInSec={0}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByRole("button", { name: ko.room.pin }));
    fireEvent.click(screen.getByRole("switch"));
    expect(onSetLock).toHaveBeenCalledWith(false);
  });

  it("게스트 비밀번호 모달에는 토글이 없다", () => {
    renderRoom(false);
    fireEvent.click(screen.getByRole("button", { name: ko.room.pin }));
    expect(screen.queryByRole("switch")).toBeNull();
    expect(document.querySelectorAll(".pin-box")).toHaveLength(4);
    expect(screen.queryByRole("button", { name: ko.room.pinEdit })).toBeNull();
  });

  it("Esc 로 공유 모달을 닫는다", () => {
    renderRoom();
    fireEvent.click(screen.getByRole("button", { name: ko.room.share }));
    expect(screen.getByRole("dialog")).toBeTruthy();
    fireEvent.keyDown(window, { key: "Escape" });
    expect(screen.queryByRole("dialog")).toBeNull();
  });
});
