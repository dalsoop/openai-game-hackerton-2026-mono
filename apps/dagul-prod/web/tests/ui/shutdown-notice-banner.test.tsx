// @vitest-environment jsdom
/**
 * 회귀: LobbyRoom.onBeforeShutdown 이 MSG.SERVER_SHUTDOWN 으로 안내를 보내지만,
 * 클라이언트 쪽에 이걸 실제로 보여주는 곳이 없어서 플레이어가 전혀 못 봤다.
 * 이 배너가 message/onDismiss/overCanvas 를 정확히 반영하는지 확인한다.
 */
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { ShutdownNoticeBanner } from "@/components/ShutdownNoticeBanner";
import ko from "../../messages/ko.json";

const messages = { game: ko.game } as typeof ko;

afterEach(cleanup);

describe("ShutdownNoticeBanner", () => {
  it("메시지가 없으면 아무것도 그리지 않는다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ShutdownNoticeBanner message={null} onDismiss={vi.fn()} />
      </NextIntlClientProvider>,
    );
    expect(screen.queryByRole("status")).toBeNull();
  });

  it("메시지를 그대로 보여주고, 닫기를 누르면 onDismiss 를 부른다", () => {
    const onDismiss = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ShutdownNoticeBanner message="서버가 곧 재시작됩니다." onDismiss={onDismiss} />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText("서버가 곧 재시작됩니다.")).toBeTruthy();
    fireEvent.click(screen.getByText(ko.game.dismiss));
    expect(onDismiss).toHaveBeenCalledTimes(1);
  });

  it("overCanvas 면 캔버스 위에 고정하는 클래스를 더 붙인다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ShutdownNoticeBanner message="안내" onDismiss={vi.fn()} overCanvas />
      </NextIntlClientProvider>,
    );
    expect(screen.getByRole("status").className).toContain("shutdown-banner-fixed");
  });

  it("overCanvas 가 아니면 그 클래스가 없다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ShutdownNoticeBanner message="안내" onDismiss={vi.fn()} />
      </NextIntlClientProvider>,
    );
    expect(screen.getByRole("status").className).not.toContain("shutdown-banner-fixed");
  });
});
