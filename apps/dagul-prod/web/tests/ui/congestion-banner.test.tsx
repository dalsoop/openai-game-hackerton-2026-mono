// @vitest-environment jsdom
import { afterEach, describe, expect, it } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { CongestionBanner } from "@/components/CongestionBanner";
import { congestionOf } from "@/lib/hub/ccu-plan";
import ko from "../../messages/ko.json";

afterEach(cleanup);

function mount(ccu: number, cap = 100): void {
  render(
    <NextIntlClientProvider locale="ko" messages={{ congestion: ko.congestion }}>
      <CongestionBanner snap={congestionOf(ccu, cap)} />
    </NextIntlClientProvider>,
  );
}

describe("CongestionBanner", () => {
  it("원활·혼잡·매우혼잡·꽉참을 순서대로 보여 준다", () => {
    mount(10);
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.capLabel);
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.quiet);
    cleanup();
    mount(50);
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.busy);
    cleanup();
    mount(80);
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.very_busy);
    cleanup();
    mount(100);
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.full);
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.capLabel);
    expect(screen.getByRole("status").textContent).toContain("100 / 100");
  });

  it("스냅이 없으면 그리지 않는다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={{ congestion: ko.congestion }}>
        <CongestionBanner snap={null} />
      </NextIntlClientProvider>,
    );
    expect(screen.queryByRole("status")).toBeNull();
  });
});
