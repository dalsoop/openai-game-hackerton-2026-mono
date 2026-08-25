import { afterEach, describe, expect, it, vi } from "vitest";
import { AssetStore, assetPlanOf } from "@/lib/godot/asset-store";

// fetch 스텁 — URL별 응답 몸통을 Promise로 돌려준다 (async 키워드 불필요).
function stubFetch(calls: string[], bodies: Record<string, string>, status = 200): void {
  vi.stubGlobal("fetch", (url: string): Promise<Response> => {
    calls.push(url);
    const body = bodies[url] ?? "";
    return Promise.resolve({
      ok: status < 400,
      status,
      headers: new Map([["content-length", String(body.length)]]),
      body: null,
      arrayBuffer: (): Promise<ArrayBuffer> => Promise.resolve(new TextEncoder().encode(body).buffer),
      json: (): Promise<unknown> => Promise.resolve({ version: "abc123", files: Object.keys(bodies) }),
    } as unknown as Response);
  });
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("assetPlanOf — URL 체계 SSOT", () => {
  it("게임별 경로 4종 + 확장 라이브러리", () => {
    const plan = assetPlanOf("dagul");
    expect(plan.engineBase).toBe("/godot/dagul/index");
    expect(plan.files.wasm).toBe("/godot/dagul/index.wasm");
    expect(plan.files.pck).toBe("/godot/dagul/index.pck");
    expect(plan.files.sideWasm).toBe("/godot/dagul/index.side.wasm");
    expect(plan.extLibUrl).toBe("/libcolyseus_godot.web.wasm32.release.wasm");
  });
});

describe("AssetStore — 공유 캐시", () => {
  it("동시 요청은 fetch 1회로 수렴", async () => {
    const calls: string[] = [];
    stubFetch(calls, { "/godot/dagul/index.pck": "PACK" });
    const store = new AssetStore(assetPlanOf("dagul"), () => {});
    const [a, b] = await Promise.all([store.pck, store.pck]);
    expect(calls).toEqual(["/godot/dagul/index.pck"]);
    expect(a.byteLength).toBe(b.byteLength);
  });

  it("이미 받은 파일은 재요청 없이 캐시", async () => {
    const calls: string[] = [];
    stubFetch(calls, { "/godot/dagul/index.wasm": "W" });
    const store = new AssetStore(assetPlanOf("dagul"), () => {});
    await store.wasm;
    await store.wasm;
    expect(calls).toEqual(["/godot/dagul/index.wasm"]);
  });

  it("매니페스트는 항상 fetch (캐시 아님)", async () => {
    const calls: string[] = [];
    stubFetch(calls, {});
    const store = new AssetStore(assetPlanOf("dagul"), () => {});
    const m1 = await store.loadManifest("dagul");
    await store.loadManifest("dagul");
    expect(calls.filter((u) => u.endsWith("manifest.json"))).toHaveLength(2);
    expect(m1.version).toBe("abc123");
  });

  it("실패 응답은 예외", async () => {
    stubFetch([], {}, 404);
    const store = new AssetStore(assetPlanOf("dagul"), () => {});
    await expect(store.pck).rejects.toThrow("404");
  });
});
