import { describe, expect, it, vi } from "vitest";
import { fetchCcuSnapshot } from "@/hooks/useCcuStatus";

describe("fetchCcuSnapshot", () => {
  it("/health 에 ccu 가 있으면 그걸 쓴다", async () => {
    const fetchImpl = vi.fn(() => Promise.resolve(new Response(JSON.stringify({
      ok: true, slot: "dagul-prod", ccu: 80, cap: 100, level: "very_busy", admit: true,
    }), { status: 200 })));
    await expect(fetchCcuSnapshot(fetchImpl as unknown as typeof fetch)).resolves.toEqual({
      ccu: 80, cap: 100, level: "very_busy", admit: true,
    });
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it("/health 에 ccu 가 없으면 /ccu 로 폴백한다", async () => {
    const fetchImpl = vi.fn((url: string) => {
      if (url === "/health") {
        return Promise.resolve(new Response(JSON.stringify({ ok: true, slot: "dagul-prod" }), { status: 200 }));
      }
      return Promise.resolve(new Response(JSON.stringify({
        ccu: 12, cap: 100, level: "quiet", admit: true,
      }), { status: 200 }));
    });
    await expect(fetchCcuSnapshot(fetchImpl as unknown as typeof fetch)).resolves.toEqual({
      ccu: 12, cap: 100, level: "quiet", admit: true,
    });
  });

  it("둘 다 실패면 null", async () => {
    const fetchImpl = vi.fn(() => Promise.resolve(new Response("no", { status: 503 })));
    await expect(fetchCcuSnapshot(fetchImpl as unknown as typeof fetch)).resolves.toBeNull();
  });
});
