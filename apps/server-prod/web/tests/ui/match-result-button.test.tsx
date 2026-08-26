// @vitest-environment jsdom
import { createRef, type RefObject } from "react";
import { act, cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { NextIntlClientProvider } from "next-intl";
import GodotCanvas from "@/components/GodotCanvas";
import { DOM_EVT, MSG } from "@/lib/contract";
import { encodeBridgePacket } from "@/lib/hub/page-bridge";
import ko from "../../messages/ko.json";

vi.mock("@/hooks/useGodotMatch", () => ({
  useGodotMatch: (): {
    canvasRef: RefObject<HTMLCanvasElement | null>;
    snap: { state: string; progress: number; bytesLoaded: number; bytesTotal: number; error: string | null };
  } => ({
    canvasRef: createRef<HTMLCanvasElement>(),
    snap: { state: "running", progress: 1, bytesLoaded: 1, bytesTotal: 1, error: null },
  }),
}));

afterEach(cleanup);

describe("결과 화면 대기실 버튼", () => {
  it("스냅이 끝나면 대기실로 버튼이 생긴다", () => {
    const onMatchEnd = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <GodotCanvas
          visible
          game="dagul"
          matchInfo={{ roomId: "r1", name: "호스트", slot: 0, resumeToken: "" }}
          onMatchEnd={onMatchEnd}
        />
      </NextIntlClientProvider>,
    );
    expect(screen.queryByRole("button", { name: ko.godot.toWaitingRoom })).toBeNull();
    act(() => {
      window.dispatchEvent(new CustomEvent(DOM_EVT.TO_ENGINE, {
        detail: encodeBridgePacket(MSG.SNAP, { result: "won" }),
      }));
    });
    screen.getByRole("button", { name: ko.godot.toWaitingRoom }).click();
    expect(onMatchEnd).toHaveBeenCalled();
  });
});
