// @vitest-environment jsdom
import { afterEach, describe, expect, it } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import RoomShare from "@/components/RoomShare";
import ko from "../../messages/ko.json";

afterEach(cleanup);

function renderShare(password: string): void {
  render(
    <NextIntlClientProvider locale="ko" messages={ko}>
      <RoomShare roomId="abc" password={password} />
    </NextIntlClientProvider>,
  );
}

describe("RoomShare", () => {
  it("잠긴 방 링크에 pw 를 넣고 PIN 칸은 두지 않는다", () => {
    renderShare("0420");
    expect(screen.queryByRole("switch")).toBeNull();
    expect(document.querySelector(".pin-box")).toBeNull();
    expect(document.querySelector(".share-url")?.textContent).toContain("room=abc");
    expect(document.querySelector(".share-url")?.textContent).toContain("pw=0420");
  });

  it("공개 방 링크에는 pw 가 없다", () => {
    renderShare("");
    expect(document.querySelector(".pin-box")).toBeNull();
    expect(document.querySelector(".share-url")?.textContent).toContain("room=abc");
    expect(document.querySelector(".share-url")?.textContent ?? "").not.toContain("pw=");
  });
});
