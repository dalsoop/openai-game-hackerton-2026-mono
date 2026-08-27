// Godot 에셋 다운로드의 단일 정본 — URL 체계와 파일별 공유 캐시를 소유한다.
// 프리로드(로비)와 부팅(매치 시작)이 같은 파일을 요구하면 fetch 1회로 공유하며,
// 엔진이 스스로 fetch 하는 URL 과도 무버전으로 일치시켜 ETag 304 재검증을 유도한다.
import { DEFAULT_GAME_ID, packOf } from "../games/catalog.js";
import { ratioProgress } from "./load-progress.js";

export interface AssetPlan {
  readonly engineBase: string;
  readonly files: Readonly<Record<AssetKey, string>>;
}

export type AssetKey = "engineJs" | "wasm" | "pck";

/** 팩 폴더의 공개 URL. GameId 를 넣지 않는다. */
export function godotAssetUrl(pack: string, file?: string): string {
  if (file === undefined || file === "") {return `/godot/${pack}`;}
  return `/godot/${pack}/${file}`;
}

/** 내용 해시가 있으면 불변 URL. 엔진 executable 경로(접미사 concat)에는 쓰지 않는다. */
export function versionedAssetUrl(url: string, filesHash?: string): string {
  if (filesHash === undefined || filesHash === "") {return url;}
  return `${url}?v=${filesHash}`;
}

export function assetPlanOf(pack: string): AssetPlan {
  return {
    engineBase: godotAssetUrl(pack, "index"),
    files: {
      engineJs: godotAssetUrl(pack, "index.js"),
      wasm: godotAssetUrl(pack, "index.wasm"),
      pck: godotAssetUrl(pack, "index.pck"),
    },
  };
}

const WORKLET_FILES = ["index.audio.worklet.js", "index.audio.position.worklet.js"] as const;

/** 로케일 접두사·하위 경로를 버리고 파일명만 남긴다. /godot/ 팩 경로는 대상이 아니다. */
export function godotPageRelativeName(pathname: string): string | null {
  if (pathname.startsWith("/godot/")) {return null;}
  const base = pathname.split("/").filter(Boolean).pop() ?? "";
  return base === "" ? null : base;
}

export function godotWorkletAssetPath(
  pathname: string,
  pack = packOf(DEFAULT_GAME_ID),
): string | null {
  const name = godotPageRelativeName(pathname);
  if (!name || !(WORKLET_FILES as readonly string[]).includes(name)) {return null;}
  return godotAssetUrl(pack, name);
}

type ProgressFn = (progress: number, loaded: number, total: number) => void;
type FileBytes = { loaded: number; total: number };

/** 파일별 진행 중 Promise 메모 — 동시 요청·재요청 모두 네트워크 1회로 수렴시킨다. */
export class AssetStore {
  private readonly inflight = new Map<string, Promise<ArrayBuffer>>();
  private readonly done = new Map<string, ArrayBuffer>();
  private readonly bytesOf = new Map<string, FileBytes>();
  private filesHash = "";
  private peak = 0;

  constructor(
    private readonly plan: AssetPlan,
    private readonly onProgress: ProgressFn,
  ) {}

  /** 파일을 (필요시 내려받아) 반환한다 — 이미 받았거나 진행 중이면 그 결과를 공유한다. */
  get(url: string, expectBytes = 0): Promise<ArrayBuffer> {
    const cached = this.done.get(url);
    if (cached) {
      this.noteFile(url, cached.byteLength, cached.byteLength);
      return Promise.resolve(cached);
    }
    let inflight = this.inflight.get(url);
    if (!inflight) {
      inflight = this.fetchCounted(url, expectBytes);
      this.inflight.set(url, inflight);
    }
    return inflight;
  }

  get wasm(): Promise<ArrayBuffer> {return this.get(this.assetUrl(this.plan.files.wasm));}
  get pck(): Promise<ArrayBuffer> {return this.get(this.assetUrl(this.plan.files.pck));}

  assetUrl(url: string): string {
    return versionedAssetUrl(url, this.filesHash);
  }

  /** 매니페스트(버전 무결성의 정본) — 캐시 대상 아님: 항상 재검증. */
  async loadManifest(pack: string): Promise<{ version: string; filesHash?: string; files: string[] }> {
    const resp = await fetch(godotAssetUrl(pack, "manifest.json"), { cache: "no-cache" });
    if (!resp.ok) {throw new Error(`manifest.json: ${resp.status}`);}
    const body = await resp.json() as { version: string; filesHash?: string; files: string[] };
    const nextHash = typeof body.filesHash === "string" ? body.filesHash : "";
    if (nextHash !== this.filesHash) {
      this.done.clear();
      this.inflight.clear();
      this.bytesOf.clear();
      this.peak = 0;
      this.filesHash = nextHash;
    }
    return body;
  }

  private async fetchCounted(url: string, expectBytes: number): Promise<ArrayBuffer> {
    // FIXME: 진단 계측(제거 예정) — 재다운로드 범인 식별용.
    const fetchLog = ((globalThis as { __assetFetches?: string[] }).__assetFetches ??= []);
    fetchLog.push(url + "@" + new Error().stack?.split("\n")[2]?.trim().slice(0, 60));
    const cache: RequestCache = url.includes("?v=") ? "force-cache" : "no-cache";
    const resp = await fetch(url, { cache });
    if (!resp.ok) {throw new Error(`${url}: ${resp.status}`);}
    const declared = resp.headers.get("content-length");
    const total = declared === null || declared === "" ? expectBytes : Number(declared);
    this.noteFile(url, 0, total);
    const reader = resp.body?.getReader();
    if (!reader) {
      const buf = await resp.arrayBuffer();
      this.remember(url, buf);
      return buf;
    }
    const chunks: Uint8Array[] = [];
    let loaded = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) {break;}
      chunks.push(value);
      loaded += value.byteLength;
      this.noteFile(url, loaded, Math.max(total, loaded));
    }
    const merged = new Uint8Array(loaded);
    let offset = 0;
    for (const c of chunks) {merged.set(c, offset); offset += c.byteLength;}
    const buf = merged.buffer;
    this.remember(url, buf);
    return buf;
  }

  private remember(url: string, buf: ArrayBuffer): void {
    this.done.set(url, buf);
    this.inflight.delete(url);
    this.noteFile(url, buf.byteLength, buf.byteLength);
  }

  private noteFile(url: string, loaded: number, total: number): void {
    this.bytesOf.set(url, { loaded, total: Math.max(total, loaded) });
    let allLoaded = 0;
    let allTotal = 0;
    for (const rec of this.bytesOf.values()) {
      allLoaded += rec.loaded;
      allTotal += rec.total;
    }
    const ratio = Math.max(this.peak, ratioProgress(allLoaded, allTotal));
    this.peak = ratio;
    this.onProgress(ratio, allLoaded, allTotal);
  }
}
