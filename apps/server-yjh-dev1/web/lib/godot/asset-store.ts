// Godot 에셋 다운로드의 단일 정본 — URL 체계와 파일별 공유 캐시를 소유한다.
// 프리로드(로비)와 부팅(매치 시작)이 같은 파일을 요구하면 fetch 1회로 공유하며,
// 엔진이 스스로 fetch 하는 URL 과도 무버전으로 일치시켜 ETag 304 재검증을 유도한다.
export interface AssetPlan {
  /** 엔진이 init/loadPath 로 쓰는 기본 경로 (무버전 — side.wasm 접미사 concat 규약) */
  readonly engineBase: string;
  readonly files: Readonly<Record<AssetKey, string>>;
  /** GDExtension 웹 라이브러리 — Godot dlopen 이 파일명으로 요청하는 페이지 루트 URL */
  readonly extLibUrl: string;
  /** FS 안에 심을 때 쓰는 파일명 (dlopen 이 p_path.get_file() 로 찾는 이름) */
  readonly extLibFile: string;
}

export type AssetKey = "engineJs" | "wasm" | "pck" | "sideWasm";

export function assetPlanOf(game: string): AssetPlan {
  const base = `/godot/${game}`;
  return {
    engineBase: `${base}/index`,
    files: {
      engineJs: `${base}/index.js`,
      wasm: `${base}/index.wasm`,
      pck: `${base}/index.pck`,
      sideWasm: `${base}/index.side.wasm`,
    },
    // 확장 라이브러리는 addons 경로에서 페이지 루트로 서빙된다(서버 라우트와 계약).
    extLibUrl: "/libcolyseus_godot.web.wasm32.release.wasm",
    extLibFile: "libcolyseus_godot.web.wasm32.release.wasm",
  };
}

type ProgressFn = (progress: number, loaded: number, total: number) => void;

/** 파일별 진행 중 Promise 메모 — 동시 요청·재요청 모두 네트워크 1회로 수렴시킨다. */
export class AssetStore {
  private readonly inflight = new Map<string, Promise<ArrayBuffer>>();
  private readonly done = new Map<string, ArrayBuffer>();
  private loaded = 0;
  private total = 0;

  constructor(
    private readonly plan: AssetPlan,
    private readonly onProgress: ProgressFn,
  ) {}

  /** 파일을 (필요시 내려받아) 반환한다 — 이미 받았거나 진행 중이면 그 결과를 공유한다. */
  get(url: string, expectBytes = 0): Promise<ArrayBuffer> {
    const cached = this.done.get(url);
    if (cached) {return Promise.resolve(cached);}
    let inflight = this.inflight.get(url);
    if (!inflight) {
      inflight = this.fetchCounted(url, expectBytes);
      this.inflight.set(url, inflight);
    }
    return inflight;
  }

  get wasm(): Promise<ArrayBuffer> {return this.get(this.plan.files.wasm);}
  get pck(): Promise<ArrayBuffer> {return this.get(this.plan.files.pck);}
  get sideWasm(): Promise<ArrayBuffer> {return this.get(this.plan.files.sideWasm);}
  get extLib(): Promise<ArrayBuffer> {return this.get(this.plan.extLibUrl);}

  /** 매니페스트(버전 무결성의 정본) — 캐시 대상 아님: 항상 재검증. */
  async loadManifest(game: string): Promise<{ version: string; filesHash?: string; files: string[] }> {
    const resp = await fetch(`/godot/${game}/manifest.json`, { cache: "no-cache" });
    if (!resp.ok) {throw new Error(`manifest.json: ${resp.status}`);}
    return resp.json();
  }

  private async fetchCounted(url: string, expectBytes: number): Promise<ArrayBuffer> {
    // FIXME: 진단 계측(제거 예정) — 재다운로드 범인 식별용.
    ((globalThis as Record<string, unknown>).__assetFetches ??= []).push(url + "@" + new Error().stack?.split("\n")[2]?.trim().slice(0, 60));
    const resp = await fetch(url);
    if (!resp.ok) {throw new Error(`${url}: ${resp.status}`);}
    const total = Number(resp.headers.get("content-length") || expectBytes || 0);
    this.total += total;
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
      this.loaded += value.byteLength;
      this.onProgress(total > 0 ? Math.min(1, this.loaded / Math.max(1, this.total)) : 0, this.loaded, this.total);
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
  }
}
