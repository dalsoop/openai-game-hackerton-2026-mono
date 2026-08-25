// 방 만들기 목록 — 카탈로그에 매니페스트 버전·에셋 용량을 붙인다.
import { assetPlanOf, godotAssetUrl } from "@/lib/godot/asset-store";
import { packOf, type GameDescriptor, type GameId } from "@/lib/games/catalog";

export type SizeUnit = "b" | "kb" | "mb";

export interface GameListing {
  readonly id: GameId;
  readonly titleKey: string;
  readonly blurbKey: string;
  readonly thumbSrc: string;
  readonly version: string | null;
  readonly bytes: number | null;
}

export function sizeParts(bytes: number): { amount: string; unit: SizeUnit } {
  if (bytes < 1024) {return { amount: String(bytes), unit: "b" };}
  if (bytes < 1024 * 1024) {return { amount: (bytes / 1024).toFixed(1), unit: "kb" };}
  return { amount: (bytes / (1024 * 1024)).toFixed(1), unit: "mb" };
}

export function emptyListing(game: GameDescriptor): GameListing {
  return {
    id: game.id,
    titleKey: game.titleKey,
    blurbKey: game.blurbKey,
    thumbSrc: game.thumbSrc,
    version: null,
    bytes: null,
  };
}

type FetchLike = (url: string, init?: { method?: string; cache?: RequestCache }) => Promise<Response>;

export async function loadGameListing(game: GameDescriptor, fetchFn: FetchLike): Promise<GameListing> {
  const base = emptyListing(game);
  const pack = packOf(game.id);
  try {
    const man = await fetchFn(godotAssetUrl(pack, "manifest.json"), { cache: "no-cache" });
    if (!man.ok) {return base;}
    const json = (await man.json()) as { version?: unknown; files?: unknown };
    const version = typeof json.version === "string" && json.version !== "" ? json.version : null;
    const names = fileNamesOf(json.files, pack);
    const bytes = await sumFileBytes(pack, names, fetchFn);
    return { ...base, version, bytes };
  } catch {
    return base;
  }
}

function fileNamesOf(files: unknown, pack: string): string[] {
  if (Array.isArray(files) && files.every((f) => typeof f === "string")) {
    return files as string[];
  }
  return Object.values(assetPlanOf(pack).files).map((url) => url.slice(url.lastIndexOf("/") + 1));
}

async function sumFileBytes(pack: string, names: string[], fetchFn: FetchLike): Promise<number | null> {
  let total = 0;
  let any = false;
  for (const name of names) {
    const resp = await fetchFn(godotAssetUrl(pack, name), { method: "HEAD" });
    const raw = resp.headers.get("content-length");
    if (!resp.ok || raw === null || raw === "") {continue;}
    const n = Number(raw);
    if (!Number.isFinite(n) || n < 0) {continue;}
    total += n;
    any = true;
  }
  return any ? total : null;
}
