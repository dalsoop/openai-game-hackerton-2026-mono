import { describe, expect, it, vi } from "vitest";
import { measureHealthRtt } from "@/hooks/useHealthRtt";

describe("measureHealthRtt", () => {
  it("200 이면 경과 시간을 돌려준다", async () => {
    const fetchImpl = vi.fn(() => Promise.resolve(new Response("ok", { status: 200 })));
    let n = 10;
    const now = (): number => {n += 7; return n;};
    await expect(measureHealthRtt(now, fetchImpl as unknown as typeof fetch)).resolves.toBe(7);
  });

  it("실패면 null 이다", async () => {
    const fetchImpl = vi.fn(() => Promise.resolve(new Response("no", { status: 503 })));
    await expect(measureHealthRtt(Date.now, fetchImpl as unknown as typeof fetch)).resolves.toBeNull();
  });
});
