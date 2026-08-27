// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { useLobbyPinPrompt } from "@/hooks/useLobbyPinPrompt";
import type { HubRoom } from "@/types";

const locked: HubRoom = {
  id: "sec", gameId: "dagul", title: "비밀방", players: 1, mode: "classic",
  playing: false, open: true, hasPassword: true,
};

describe("useLobbyPinPrompt", () => {
  it("방을 열면 PIN 초안이 비어 있다", () => {
    const { result } = renderHook(() => useLobbyPinPrompt());
    act(() => {result.current.openPin(locked);});
    expect(result.current.pwRoom?.id).toBe("sec");
    expect(result.current.pwDraft).toBe("");
  });

  it("takePin 은 방 id 와 초안을 꺼내고 닫는다", () => {
    const { result } = renderHook(() => useLobbyPinPrompt());
    act(() => {result.current.openPin(locked);});
    act(() => {result.current.setPwDraft("4242");});
    let taken: { id: string; password: string } | null = null;
    act(() => {taken = result.current.takePin();});
    expect(taken).toEqual({ id: "sec", password: "4242" });
    expect(result.current.pwRoom).toBeNull();
    expect(result.current.pwDraft).toBe("");
  });

  it("열린 방이 없으면 takePin 은 null", () => {
    const { result } = renderHook(() => useLobbyPinPrompt());
    let taken: { id: string; password: string } | null = { id: "x", password: "y" };
    act(() => {taken = result.current.takePin();});
    expect(taken).toBeNull();
  });

  it("Esc 로 모달을 닫는다", () => {
    const { result } = renderHook(() => useLobbyPinPrompt());
    act(() => {result.current.openPin(locked);});
    act(() => {window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));});
    expect(result.current.pwRoom).toBeNull();
  });

  it("검색어를 남긴다", () => {
    const { result } = renderHook(() => useLobbyPinPrompt());
    act(() => {result.current.setQuery("저녁");});
    expect(result.current.query).toBe("저녁");
  });
});
