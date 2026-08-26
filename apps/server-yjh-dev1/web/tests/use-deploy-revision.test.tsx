// @vitest-environment jsdom
import { renderHook, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useDeployRevision } from "@/hooks/useDeployRevision";
import { VERSION_PATH } from "@/lib/hub/revision";

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("useDeployRevision", () => {
  it("원격 id 가 다르면 stale 이다", async () => {
    const fetchImpl = vi.fn(() =>
      Promise.resolve(new Response(JSON.stringify({ id: "new" }), { status: 200 })),
    );
    const { result } = renderHook(() =>
      useDeployRevision("old", { enabled: true, fetchImpl: fetchImpl as unknown as typeof fetch }),
    );
    await waitFor(() => {
      expect(result.current.stale).toBe(true);
    });
    expect(fetchImpl).toHaveBeenCalledWith(VERSION_PATH, { cache: "no-store" });
  });

  it("같으면 stale 이 아니다", async () => {
    const fetchImpl = vi.fn(() =>
      Promise.resolve(new Response(JSON.stringify({ id: "same" }), { status: 200 })),
    );
    const { result } = renderHook(() =>
      useDeployRevision("same", { enabled: true, fetchImpl: fetchImpl as unknown as typeof fetch }),
    );
    await waitFor(() => {
      expect(fetchImpl).toHaveBeenCalled();
    });
    expect(result.current.stale).toBe(false);
  });

  it("꺼져 있으면 요청하지 않는다", () => {
    const fetchImpl = vi.fn();
    renderHook(() =>
      useDeployRevision("old", { enabled: false, fetchImpl: fetchImpl as unknown as typeof fetch }),
    );
    expect(fetchImpl).not.toHaveBeenCalled();
  });
});
