import { describe, expect, it, vi } from "vitest";
import { GAME_CATALOG, packOf } from "@/lib/games/catalog";
import { godotAssetUrl } from "@/lib/godot/asset-store";
import { emptyListing, loadGameListing, sizeParts } from "@/lib/games/listing";
import type { GameDescriptor } from "@/lib/games/catalog";

function catalogGame(id: string): GameDescriptor {
  const game = GAME_CATALOG.find((g) => g.id === id);
  if (!game) {throw new Error(`catalog missing ${id}`);}
  return game;
}

const dagul = catalogGame("dagul");

describe("sizeParts", () => {
  it("바이트·KB·MB 단위를 나눈다", () => {
    expect(sizeParts(512)).toEqual({ amount: "512", unit: "b" });
    expect(sizeParts(2048)).toEqual({ amount: "2.0", unit: "kb" });
    expect(sizeParts(2 * 1024 * 1024)).toEqual({ amount: "2.0", unit: "mb" });
  });
});

describe("loadGameListing", () => {
  it("매니페스트 버전과 HEAD Content-Length 합을 붙인다", async () => {
    const fetchFn = vi.fn((url: string, init?: { method?: string }): Promise<Response> => {
      if (url.endsWith("manifest.json")) {
        return Promise.resolve(new Response(JSON.stringify({ version: "9", files: ["a.wasm", "b.pck"] }), { status: 200 }));
      }
      if (init?.method === "HEAD") {
        const n = url.endsWith("a.wasm") ? "100" : "50";
        return Promise.resolve(new Response(null, { status: 200, headers: { "content-length": n } }));
      }
      return Promise.resolve(new Response("", { status: 404 }));
    });
    const row = await loadGameListing(dagul, fetchFn);
    expect(row.version).toBe("9");
    expect(row.bytes).toBe(150);
    expect(row.blurbKey).toBe(dagul.blurbKey);
    expect(row.thumbSrc).toBe(dagul.thumbSrc);
  });

  it("매니페스트가 없으면 빈 목록 행을 돌려준다", async () => {
    const fetchFn = vi.fn((): Promise<Response> => Promise.resolve(new Response("", { status: 404 })));
    await expect(loadGameListing(dagul, fetchFn)).resolves.toEqual(emptyListing(dagul));
  });

  it("같은 팩 게임은 GameId 경로가 아니라 팩 매니페스트를 조회한다", async () => {
    const sparring = catalogGame("sparring");
    const pack = packOf(sparring.id);
    const fetchFn = vi.fn((url: string): Promise<Response> => {
      expect(url.startsWith(`${godotAssetUrl(pack)}/`)).toBe(true);
      if (pack !== sparring.id) {
        expect(url.includes(`/${sparring.id}/`)).toBe(false);
      }
      if (url.endsWith("manifest.json")) {
        return Promise.resolve(new Response(JSON.stringify({ version: "1", files: ["index.wasm"] }), { status: 200 }));
      }
      return Promise.resolve(new Response(null, { status: 200, headers: { "content-length": "10" } }));
    });
    const row = await loadGameListing(sparring, fetchFn);
    expect(row.version).toBe("1");
    expect(row.bytes).toBe(10);
    expect(fetchFn).toHaveBeenCalled();
  });
});
