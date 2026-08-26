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
      sideWasm: godotAssetUrl(pack, "index.side.wasm"),
    },
    // 확장 라이브러리는 addons 경로에서 페이지 루트로 서빙된다(서버 라우트와 계약).
    extLibUrl: "/libcolyseus_godot.web.wasm32.release.wasm",
    extLibFile: "libcolyseus_godot.web.wasm32.release.wasm",
  };
}

/** 엔진 locateFile 은 로케일 경로 상대(/ko/파일명)로 요청한다. 파일명만 맞으면 같은 산출물이다. */
export function isExtLibPath(pathname: string, file = assetPlanOf("dagul").extLibFile): boolean {
  return pathname === `/${file}` || pathname.endsWith(`/${file}`);
}

type ProgressFn = (progress: number, loaded: number, total: number) => void;

/** 파일별 진행 중 Promise 메모 — 동시 요청·재요청 모두 네트워크 1회로 수렴시킨다. */
export class AssetStore {
  private readonly inflight = new Map<string, Promise<ArrayBuffer>>();
  private readonly done = new Map<string, ArrayBuffer>();
  private filesHash = "";
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

  get wasm(): Promise<ArrayBuffer> {return this.get(this.assetUrl(this.plan.files.wasm));}
  get pck(): Promise<ArrayBuffer> {return this.get(this.assetUrl(this.plan.files.pck));}
  get sideWasm(): Promise<ArrayBuffer> {return this.get(this.assetUrl(this.plan.files.sideWasm));}
  get extLib(): Promise<ArrayBuffer> {return this.get(this.plan.extLibUrl);}

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
      this.filesHash = nextHash;
    }
    return body;
  }

  private async fetchCounted(url: string, expectBytes: number): Promise<ArrayBuffer> {
    // FIXME: 진단 계측(제거 예정) — 재다운로드 범인 식별용.
    const fetchLog = ((globalThis as { __assetFetches?: string[] }).__assetFetches ??= []);
    fetchLog.push(url + "@" + new Error().stack?.split("\n")[2]?.trim().slice(0, 60));
    const resp = await fetch(url);
    if (!resp.ok) {throw new Error(`${url}: ${resp.status}`);}
    const declared = resp.headers.get("content-length");
    const total = declared === null || declared === "" ? expectBytes : Number(declared);
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
