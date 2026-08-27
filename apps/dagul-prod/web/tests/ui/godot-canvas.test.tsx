// @vitest-environment jsdom
import { createRef, type RefObject } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, cleanup, fireEvent } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import GodotCanvas from "@/components/GodotCanvas";
import ko from "../../messages/ko.json";
import en from "../../messages/en.json";

vi.mock("@/hooks/useGodotMatch", () => ({
  useGodotMatch: (): {
    canvasRef: RefObject<HTMLCanvasElement | null>;
    snap: { state: string; progress: number; bytesLoaded: number; bytesTotal: number; error: string | null };
  } => ({
    canvasRef: createRef<HTMLCanvasElement>(),
    snap: {
      state: "error",
      progress: 0,
      bytesLoaded: 0,
      bytesTotal: 0,
      error: "match-signal-missing",
    },
  }),
}));

vi.mock("@/lib/godot/runtime", () => ({
  GodotRuntime: { for: (): { resetError: () => void } => ({ resetError: vi.fn() }) },
}));

afterEach(cleanup);

describe("GodotCanvas 오류 문구", () => {
  it("startError 를 앞에 붙이지 않고 매핑 문구 한 줄만 보여 준다", () => {
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <GodotCanvas
          visible
          game="dagul"
          matchInfo={{ roomId: "r1", name: "호스트", slot: 0, resumeToken: "" }}
          onError={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    const node = screen.getByText(ko.game.errors.matchSignalMissing);
    expect(node.textContent).toBe(ko.game.errors.matchSignalMissing);
    expect(node.textContent.includes(ko.godot.startError)).toBe(false);
  });

  it("로비로 돌아가기를 누르면 onError 를 부른다", () => {
    const onError = vi.fn();
    render(
      <NextIntlClientProvider locale="ko" messages={ko}>
        <GodotCanvas
          visible
          game="dagul"
          matchInfo={{ roomId: "r1", name: "호스트", slot: 0, resumeToken: "" }}
          onError={onError}
        />
      </NextIntlClientProvider>,
    );
    fireEvent.click(screen.getByText(ko.godot.backToLobby));
    expect(onError).toHaveBeenCalledTimes(1);
  });

  it("영어 로케일은 Back to lobby 를 쓰고 한글 버튼을 두지 않는다", () => {
    render(
      <NextIntlClientProvider locale="en" messages={en}>
        <GodotCanvas
          visible
          game="dagul"
          matchInfo={{ roomId: "r1", name: "host", slot: 0, resumeToken: "" }}
          onError={vi.fn()}
        />
      </NextIntlClientProvider>,
    );
    expect(screen.getByText(en.game.errors.matchSignalMissing)).toBeTruthy();
    expect(screen.getByText(en.godot.backToLobby)).toBeTruthy();
    expect(screen.queryByText(ko.godot.backToLobby)).toBeNull();
    expect(screen.queryByText(ko.game.errors.matchSignalMissing)).toBeNull();
  });
});
