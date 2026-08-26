// @vitest-environment jsdom
import { createRef, type RefObject } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import GodotCanvas from "@/components/GodotCanvas";
import ko from "../../messages/ko.json";

vi.mock("@/hooks/useGodotMatch", () => ({
  useGodotMatch: (): {
    canvasRef: RefObject<HTMLCanvasElement | null>;
    snap: { state: string; progress: number; bytesLoaded: number; bytesTotal: number; error: string | null };
  } => ({
    canvasRef: createRef<HTMLCanvasElement>(),
    snap: {
      state: "downloading",
      progress: 0.42,
      bytesLoaded: 42,
      bytesTotal: 100,
      error: null,
    },
  }),
}));

afterEach(cleanup);

describe("GodotCanvas 부팅 진행률", () => {
  it("다운로드 중이면 로딩 중 N% 를 보여 준다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <GodotCanvas
          visible
          game="dagul"
          matchInfo={{ roomId: "r1", name: "호스트", slot: 0, resumeToken: "" }}
        />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText("로딩 중 42%")).toBeTruthy();
    expect(screen.getByRole("progressbar").getAttribute("aria-valuenow")).toBe("42");
  });
});
