// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import RoomPin from "@/components/RoomPin";
import ko from "../../messages/ko.json";

afterEach(cleanup);

describe("RoomPin", () => {
  it("4칸에 현재 PIN 을 보여 주고 호스트만 변경 아이콘이 있다", () => {
    const onSetPassword = vi.fn();
    const { container, rerender } = render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <RoomPin password="0420" isHost={false} onSetPassword={onSetPassword} />
      </NextIntlClientProvider>,
    );
    const boxes = container.querySelectorAll("input");
    expect(boxes).toHaveLength(4);
    expect([...boxes].map((el) => (el as HTMLInputElement).value).join("")).toBe("0420");
    expect(screen.queryByRole("button", { name: ko.room.pinEdit })).toBeNull();

    rerender(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <RoomPin password="0420" isHost onSetPassword={onSetPassword} />
      </NextIntlClientProvider>,
    );
    const confirm = vi.spyOn(window, "confirm").mockReturnValue(true);
    fireEvent.click(screen.getByRole("button", { name: ko.room.pinEdit }));
    expect(confirm).toHaveBeenCalled();
    expect(onSetPassword).toHaveBeenCalledTimes(1);
    expect(onSetPassword.mock.calls[0][0]).toMatch(/^\d{4}$/);
    confirm.mockRestore();
  });

  it("변경 확인을 취소하면 PIN 을 그대로 둔다", () => {
    const onSetPassword = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <RoomPin password="0420" isHost onSetPassword={onSetPassword} />
      </NextIntlClientProvider>,
    );
    const confirm = vi.spyOn(window, "confirm").mockReturnValue(false);
    fireEvent.click(screen.getByRole("button", { name: ko.room.pinEdit }));
    expect(onSetPassword).not.toHaveBeenCalled();
    confirm.mockRestore();
  });
});
