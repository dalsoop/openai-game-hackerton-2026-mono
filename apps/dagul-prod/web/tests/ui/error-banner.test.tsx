// @vitest-environment jsdom
/**
 * 회귀: hub.error(MSG.ERROR·방 접속 실패 등)가 state 에는 쌓이는데 어디서도
 * 렌더링되지 않아서, 호스트 전용 거부·방 꽉 찼음·조인 실패가 화면 반응 없이
 * 조용히 사라졌다. 이 배너가 message/onDismiss/overCanvas 를 정확히 반영하는지
 * 확인한다.
 */
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { ErrorBanner } from "@/components/ErrorBanner";
import { KO } from "@/lib/hub/config";
import ko from "../../messages/ko.json";

const messages = { game: ko.game } as typeof ko;

afterEach(cleanup);

describe("ErrorBanner", () => {
  it("메시지가 없으면 아무것도 그리지 않는다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ErrorBanner message={null} onDismiss={vi.fn()} />
      </NextIntlClientProvider>,
    );
    expect(screen.queryByRole("alert")).toBeNull();
  });

  it("메시지를 그대로 보여주고, 닫기를 누르면 onDismiss 를 부른다", () => {
    const onDismiss = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ErrorBanner message={KO.ROOM_NOT_FOUND} onDismiss={onDismiss} />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText(KO.ROOM_NOT_FOUND)).toBeTruthy();
    fireEvent.click(screen.getByText(ko.game.dismiss));
    expect(onDismiss).toHaveBeenCalledTimes(1);
  });

  it("role 이 alert 다 — 정보성 안내(status)와 다르게 즉시 스크린리더에 읽힌다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ErrorBanner message="에러" onDismiss={vi.fn()} />
      </NextIntlClientProvider>,
    );
    expect(screen.getByRole("alert")).toBeTruthy();
  });

  it("overCanvas 면 캔버스 위에 고정하는 클래스를 더 붙인다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ErrorBanner message="에러" onDismiss={vi.fn()} overCanvas />
      </NextIntlClientProvider>,
    );
    expect(screen.getByRole("alert").className).toContain("shutdown-banner-fixed");
  });

  it("overCanvas 가 아니면 그 클래스가 없다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={messages}>
        <ErrorBanner message="에러" onDismiss={vi.fn()} />
      </NextIntlClientProvider>,
    );
    expect(screen.getByRole("alert").className).not.toContain("shutdown-banner-fixed");
  });
});
