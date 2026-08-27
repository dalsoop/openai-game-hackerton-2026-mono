// @vitest-environment jsdom
import { afterEach, describe, expect, it } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import RoomLock from "@/components/RoomLock";
import ko from "../../messages/ko.json";

afterEach(cleanup);

function renderLock(opts: { password: string; isHost: boolean }): { locks: boolean[] } {
  const locks: boolean[] = [];
  render(
    <NextIntlClientProvider locale="ko" messages={ko}>
      <RoomLock
        password={opts.password}
        isHost={opts.isHost}
        onSetLock={(on: boolean): void => {locks.push(on);}}
        onSetPassword={(): void => { /* pin */ }}
      />
    </NextIntlClientProvider>,
  );
  return { locks };
}

describe("RoomLock", () => {
  it("호스트는 토글로 PIN 을 켠다", () => {
    const { locks } = renderLock({ password: "", isHost: true });
    expect(screen.getByRole("switch")).toBeTruthy();
    expect((screen.getByRole("switch") as HTMLInputElement).checked).toBe(false);
    expect(document.querySelector(".pin-box")).toBeNull();
    fireEvent.click(screen.getByRole("switch"));
    expect(locks).toEqual([true]);
  });

  it("잠긴 방은 4칸을 보여 준다", () => {
    renderLock({ password: "0420", isHost: true });
    expect((screen.getByRole("switch") as HTMLInputElement).checked).toBe(true);
    expect(document.querySelectorAll(".pin-box")).toHaveLength(4);
  });

  it("게스트에게는 토글이 없다", () => {
    renderLock({ password: "0420", isHost: false });
    expect(screen.queryByRole("switch")).toBeNull();
    expect(document.querySelectorAll(".pin-box")).toHaveLength(4);
  });
});
