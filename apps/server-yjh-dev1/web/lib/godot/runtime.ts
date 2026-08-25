"use client";
// Godot 웹 런타임의 단일 소유자.
// 매니페스트(버전) → 프리로드(다운로드+컴파일) → 부팅(핸드오프+엔진) → 종료까지
// 전 수명주기를 이 클래스 하나가 관리한다. UI(훅/컴포넌트)는 구독만 한다.
import { HANDOFF, DOM_EVT, GAME_ID } from "@/lib/hub/config";

export type RuntimeState =
  | "idle" | "downloading" | "compiling" | "ready" | "running" | "error";

export interface RuntimeSnapshot {
  state: RuntimeState;
  progress: number; // 0..1
  bytesLoaded: number;
  bytesTotal: number;
  error: string | null;
}

export interface HandoffInfo {
  roomId: string;
  name: string;
  slot: number;
  resumeToken: string;
}

interface Manifest {
  version: string;
  files: string[];
}

const MATCH_WATCHDOG_MS = 30_000;
// dlink GDExtension — Godot dlopen 요청 경로와 서빙 URL (SSOT: 엔진 부팅 경로).
const EXT_LIB_FILE = "libcolyseus_godot.web.wasm32.release.wasm";
const EXT_LIB_URL = "/addons/colyseus/bin/libcolyseus_godot.web.wasm32.release.wasm";

export class GodotRuntime {
  private static _instance: GodotRuntime | null = null;
  static get instance(): GodotRuntime {
    if (!this._instance) {this._instance = new GodotRuntime(GAME_ID);}
    return this._instance;
  }

  private readonly game: string;
  private manifest: Manifest | null = null;
  private wasmModule: WebAssembly.Module | null = null;
  private pckBuffer: ArrayBuffer | null = null;
  private extBuffer: ArrayBuffer | null = null;
  private engine: { requestQuit?: () => void } | null = null;
  private scriptLoaded = false;
  private scriptPromise: Promise<void> | null = null;
  private bootPromise: Promise<void> | null = null;
  private abort: AbortController | null = null;
  private watchdog: ReturnType<typeof setTimeout> | null = null;
  private listeners = new Set<(s: RuntimeSnapshot) => void>();
  private snap: RuntimeSnapshot = {
    state: "idle", progress: 0, bytesLoaded: 0, bytesTotal: 0, error: null,
  };

  private constructor(game: string) {
    this.game = game;
  }

  get snapshot(): RuntimeSnapshot {
    return this.snap;
  }

  subscribe(fn: (s: RuntimeSnapshot) => void): () => void {
    this.listeners.add(fn);
    fn(this.snap);
    return () => this.listeners.delete(fn);
  }

  private update(partial: Partial<RuntimeSnapshot>): void {
    this.snap = { ...this.snap, ...partial };
    for (const fn of this.listeners) {fn(this.snap);}
  }

  // 버전이 붙은 산출물 URL — 매니페스트 버전이 바뀌면 URL이 바뀐다.
  private assetUrl(file: string): string {
    const v = this.manifest ? `?v=${this.manifest.version}` : "";
    return `/godot/${this.game}/${file}${v}`;
  }

  private async loadManifest(): Promise<Manifest> {
    const resp = await fetch(`/godot/${this.game}/manifest.json`, { cache: "no-cache" });
    if (!resp.ok) {throw new Error(`manifest.json: ${resp.status}`);}
    return resp.json();
  }

  // 로비 단계에서 호출: 백그라운드로 wasm+pck를 받고 wasm을 컴파일해 둔다.
  async preload(): Promise<void> {
    if (this.snap.state !== "idle" && this.snap.state !== "error") {return;}

    this.abort = new AbortController();
    this.update({ state: "downloading", progress: 0, bytesLoaded: 0, bytesTotal: 0, error: null });

    try {
      const fresh = await this.loadManifest();
      if (this.manifest?.version === fresh.version && this.wasmModule) {
        this.update({ state: "ready", progress: 1 });
        return;
      }
      this.manifest = fresh;
      this.wasmModule = null;
      this.pckBuffer = null;

      const [wasmBuf, pckBuf] = await Promise.all([
        this.fetchWithProgress(this.assetUrl("index.wasm")),
        this.fetchWithProgress(this.assetUrl("index.pck")),
        this.fetchWithProgress(this.assetUrl("index.side.wasm")),
      ]);
      this.pckBuffer = pckBuf;
      // side.wasm 은 엔진이 init 시 자체 fetch 한다 — 여기서 받아두는 건
      // 진행률 표시용이고, 실제 절약은 ?v= immutable 캐시로 얻는다.

      this.update({ state: "compiling" });
      this.wasmModule = await WebAssembly.compile(wasmBuf);
      this.update({ state: "ready", progress: 1 });
    } catch (e) {
      if ((e as Error).name === "AbortError") {return;}
      this.update({ state: "error", error: e instanceof Error ? e.message : String(e) });
    }
  }

  private async fetchWithProgress(url: string): Promise<ArrayBuffer> {
    const resp = await fetch(url, { signal: this.abort?.signal });
    if (!resp.ok) {throw new Error(`${url}: ${resp.status}`);}
    const total = Number(resp.headers.get("content-length") || 0);
    this.update({ bytesTotal: this.snap.bytesTotal + total });
    const reader = resp.body?.getReader();
    if (!reader) {return resp.arrayBuffer();}
    const chunks: Uint8Array[] = [];
    let loaded = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) {break;}
      chunks.push(value);
      loaded += value.byteLength;
      this.update({
        bytesLoaded: this.snap.bytesLoaded + value.byteLength,
        progress: total > 0 ? Math.min(1, loaded / total) : this.snap.progress,
      });
    }
    const buf = new Uint8Array(loaded);
    let offset = 0;
    for (const c of chunks) { buf.set(c, offset); offset += c.byteLength; }
    return buf.buffer;
  }

  // 매치 시작: 핸드오프 기록 → 엔진 부팅 → 매치 신호 워치독.
  // startGame() 대신 수동 시퀀스(init→copyToFS→start)를 쓴다:
  // startGame 은 mainPack 문자열을 URL이자 FS 경로로 겸용해서
  // 버전 쿼리(?v=)가 붙으면 pck 를 못 연다. 프리로드한 버퍼를 FS 에 직접 넣는다.
  async boot(canvas: HTMLCanvasElement, handoff: HandoffInfo): Promise<void> {
    if (this.engine) {return;}
    if (this.bootPromise) {return this.bootPromise;}
    // StrictMode 리마운트 등 동시 boot — 한쪽만 진행한다 (engine 은 부팅 완료 후에야
    // 세팅되므로 this.engine 가드만으론 창이 열린다 — index.js 이중 삽입으로 이어진다).
    this.bootPromise = this.doBoot(canvas, handoff).finally((): void => { this.bootPromise = null; });
    return this.bootPromise;
  }

  private async doBoot(canvas: HTMLCanvasElement, handoff: HandoffInfo): Promise<void> {
    if (!this.manifest) {this.manifest = await this.loadManifest();}
    if (!this.pckBuffer) {
      this.pckBuffer = await this.fetchWithProgress(this.assetUrl("index.pck"));
    }

    this.writeHandoff(handoff);
    await this.loadEngineScript();

    const EngineCtor = (window as unknown as {
      Engine?: new (cfg: unknown) => {
        init: (basePath: string) => Promise<unknown>;
        copyToFS: (path: string, buffer: ArrayBuffer) => void;
        start: (override: Record<string, unknown>) => Promise<void>;
        requestQuit?: () => void;
      };
    }).Engine;
    if (!EngineCtor) {throw new Error("Godot Engine 스크립트를 찾지 못했습니다");}

    const config: Record<string, unknown> = {
      canvas,
      canvasResizePolicy: 2,
      executable: `/godot/${this.game}/index`,
      args: ["--main-pack", "index.pck"],
      // dlink GDExtension — Godot 가 res:// 경로 그대로 dlopen 한다.
      gdextensionLibs: [EXT_LIB_FILE],
    };
    // 사전컴파일한 wasm 을 주입해 부팅 시 재다운로드를 막는다.
    // (dlopen 실패의 원인은 오버라이드가 아니라 FS 경로 문제였다 — 별도 해결 완료.)
    if (this.wasmModule) {
      const wasmMod = this.wasmModule;
      config.instantiateWasm = (
        imports: WebAssembly.Imports,
        onDone: (inst: WebAssembly.Instance, mod: WebAssembly.Module) => void,
      ): Record<string, unknown> => {
        void WebAssembly.instantiate(wasmMod, imports).then((inst) => onDone(inst, wasmMod));
        return {};
      };
    }

    const engine = new EngineCtor(config);
    this.armWatchdog();
    // loadPath 는 무버전으로 둔다 — 엔진이 `${loadPath}.side.wasm` 을 단순
    // 이어붙이므로 쿼리가 파일명을 오염시킨다. 재전송은 서버측 ETag/304 로 막는다.
    await engine.init(`/godot/${this.game}/index`);
    engine.copyToFS("index.pck", this.pckBuffer);
    // GDExtension 웹 라이브러리 — dlopen 이 res:// 경로로 동기 읽기 하므로
    // 부팅 전에 MEMFS 의 정확한 경로에 심어 둔다 (pck 과 같은 방식).
    if (!this.extBuffer) {
      const resp = await fetch(EXT_LIB_URL, { signal: this.abort?.signal });
      if (!resp.ok) {throw new Error(`colyseus ext: ${resp.status}`);}
      this.extBuffer = await resp.arrayBuffer();
    }
    // Godot 웹 dlopen 은 파일명만 쓴다(os_web.cpp p_path.get_file()) —
    // FS 루트에 파일명으로 심어 find_dylib 이 바로 찾게 한다.
    engine.copyToFS(`/${EXT_LIB_FILE}`, this.extBuffer);
    await engine.start(config);
    this.engine = engine;
    this.update({ state: "running" });
  }

  private writeHandoff(info: HandoffInfo): void {
    try {
      localStorage.setItem(HANDOFF.FROM_HUB, "1");
      localStorage.setItem(HANDOFF.GAME, this.game);
      localStorage.setItem(HANDOFF.NAME, info.name);
      localStorage.setItem(HANDOFF.ROOM_ID, info.roomId);
      localStorage.setItem(HANDOFF.SLOT, String(info.slot));
      if (info.resumeToken) {localStorage.setItem(HANDOFF.RESUME, info.resumeToken);}
    } catch { /* localStorage 불가 환경 — 엔진이 resume 없이 시도한다 */ }
  }

  private loadEngineScript(): Promise<void> {
    if (this.scriptLoaded) {return Promise.resolve();}
    if (this.scriptPromise) {return this.scriptPromise;}
    this.scriptPromise = new Promise((resolve, reject) => {
      const el = document.createElement("script");
      el.src = this.assetUrl("index.js");
      el.onload = (): void => { this.scriptLoaded = true; resolve(); };
      el.onerror = (): void => {
        this.scriptPromise = null; // 재시도 가능하게
        reject(new Error("엔진 스크립트 로드 실패"));
      };
      document.head.appendChild(el);
    });
    return this.scriptPromise;
  }

  // 실왕복 게이트: 허브의 매치 신호가 제한시간 내 없으면 실패로 판정한다.
  private armWatchdog(): void {
    const clear = (): void => { if (this.watchdog) { clearTimeout(this.watchdog); this.watchdog = null; } };
    window.addEventListener(DOM_EVT.MATCH_START, clear, { once: true });
    this.watchdog = setTimeout((): void => {
      window.removeEventListener(DOM_EVT.MATCH_START, clear);
      this.quit();
      this.update({ state: "error", error: "게임이 서버 매치에 합류하지 못했습니다 (매치 신호 없음)" });
    }, MATCH_WATCHDOG_MS);
  }

  quit(): void {
    if (this.watchdog) { clearTimeout(this.watchdog); this.watchdog = null; }
    if (this.engine?.requestQuit) {
      try { this.engine.requestQuit(); } catch { /* 이미 종료됨 */ }
    }
    this.engine = null;
    if (this.snap.state === "running") {this.update({ state: "ready" });}
  }

  resetError(): void {
    if (this.snap.state === "error") {this.update({ state: "idle", error: null });}
  }
}
