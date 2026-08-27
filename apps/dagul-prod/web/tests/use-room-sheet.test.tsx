// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { useRoomSheet } from "@/hooks/useRoomSheet";

describe("useRoomSheet", () => {
  it("pin·share·game 을 연다", () => {
    const { result } = renderHook(() => useRoomSheet());
    expect(result.current.kind).toBeNull();
    act(() => {result.current.open("pin");});
    expect(result.current.kind).toBe("pin");
    act(() => {result.current.open("share");});
    expect(result.current.kind).toBe("share");
    act(() => {result.current.open("game");});
    expect(result.current.kind).toBe("game");
    act(() => {result.current.close();});
    expect(result.current.kind).toBeNull();
  });

  it("Esc 로 닫는다", () => {
    const { result } = renderHook(() => useRoomSheet());
    act(() => {result.current.open("share");});
    act(() => {window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));});
    expect(result.current.kind).toBeNull();
  });

  it("닫혀 있을 때 Esc 는 무시한다", () => {
    const { result } = renderHook(() => useRoomSheet());
    act(() => {window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));});
    expect(result.current.kind).toBeNull();
  });
});
