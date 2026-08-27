// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { ConnectionLostModal } from "@/components/ConnectionLostModal";
import type { DropReason } from "@/lib/hub/room-end";
import ko from "../../messages/ko.json";
import en from "../../messages/en.json";

function setup(reason: DropReason): {
  onReconnect: ReturnType<typeof vi.fn>;
  onExit: ReturnType<typeof vi.fn>;
} {
  const onReconnect = vi.fn();
  const onExit = vi.fn();
  render(
    <NextIntlClientProvider locale="ko" messages={ko}>
      <ConnectionLostModal reason={reason} onReconnect={onReconnect} onExit={onExit} />
    </NextIntlClientProvider>,
  );
  return { onReconnect, onExit };
}

afterEach(cleanup);

describe("재접속 모달", () => {
  it("강퇴 — 다시 들어가기 없이 안내만", () => {
    setup("kicked");
    expect(screen.getByText(ko.game.kickedTitle)).toBeTruthy();
    expect(screen.getByText(ko.game.kickedBody)).toBeTruthy();
    expect(screen.queryByText(ko.game.reconnect)).toBeNull();
  });

  it("유휴 — 다시 들어가기 없이 안내만", () => {
    setup("idle");
    expect(screen.getByText(ko.game.idleTitle)).toBeTruthy();
    expect(screen.getByText(ko.game.idleBody)).toBeTruthy();
    expect(screen.queryByText(ko.game.reconnect)).toBeNull();
  });

  it("로딩 타임아웃 — 다시 들어가기 없이 안내만", () => {
    setup("load-wait");
    expect(screen.getByText(ko.game.loadWaitTitle)).toBeTruthy();
    expect(screen.getByText(ko.game.loadWaitBody)).toBeTruthy();
    expect(screen.queryByText(ko.game.reconnect)).toBeNull();
  });

  it("로딩 타임아웃 영어 — 한글 문구가 보이지 않는다", () => {
    render(
      <NextIntlClientProvider locale="en" messages={en}>
        <ConnectionLostModal reason="load-wait" onReconnect={vi.fn()} onExit={vi.fn()} />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText(en.game.loadWaitTitle)).toBeTruthy();
    expect(screen.getByText(en.game.loadWaitBody)).toBeTruthy();
    expect(screen.queryByText(ko.game.loadWaitTitle)).toBeNull();
    expect(screen.queryByText(ko.game.back)).toBeNull();
    expect(screen.getByText(en.game.back)).toBeTruthy();
  });

  it("끊김 — 회색 화면 대신 재접속 안내", () => {
    setup("dropped");
    expect(screen.getByText(ko.game.droppedTitle)).toBeTruthy();
    expect(screen.getByText(ko.game.droppedBody)).toBeTruthy();
    expect(screen.getByText(ko.game.reconnect)).toBeTruthy();
  });

  it("다시 접속하기 클릭 → onReconnect", () => {
    const { onReconnect } = setup("dropped");
    fireEvent.click(screen.getByText(ko.game.reconnect));
    expect(onReconnect).toHaveBeenCalledTimes(1);
  });
});
