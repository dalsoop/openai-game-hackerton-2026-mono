"use client";
// Godot 웹 런타임의 수명주기 소유자 — 상태머신(idle→downloading→…→running)과
// 엔진 부팅 시퀀스만 담당한다. URL 체계·다운로드 공유는 AssetStore 가,
// 핸드오프 키 계약은 lib/hub/config 가 소유한다 (여기선 조립만).
import { HANDOFF, DOM_EVT } from "@/lib/hub/config";
import { DEFAULT_GAME_ID, type GameId } from "@/lib/games/catalog";
import { AssetStore, assetPlanOf } from "@/lib/godot/asset-store";

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
  filesHash?: string;
  files: string[];
}

const MATCH_WATCHDOG_MS = 30_000;

export class GodotRuntime {
  // 유즈맵 — 게임별 런타임. 엔진 산출물 URL 도 게임별로 갈라진다.
  private static _instances = new Map<string, GodotRuntime>();
  static for(game: GameId): GodotRuntime {
    let rt = this._instances.get(game);
    if (!rt) {rt = new GodotRuntime(game); this._instances.set(game, rt);}
    return rt;
  }
  /** 호환 진입점 — 기본 게임(다굴) */
  static get instance(): GodotRuntime {return this.for(DEFAULT_GAME_ID);}

  private readonly game: string;
  private readonly plan;

  // 게임별 plan 은 생성자에서 확정한다 (필드 초기화 순서 문제 회피).

  private readonly store: AssetStore;
  private manifest: Manifest | null = null;
  private wasmModule: WebAssembly.Module | null = null;
  private preloadPromise: Promise<void> | null = null;
  private engine: { requestQuit?: () => void } | null = null;
  private scriptPromise: Promise<void> | null = null;
  private bootPromise: Promise<void> | null = null;
  private watchdog: ReturnType<typeof setTimeout> | null = null;
  private listeners = new Set<(s: RuntimeSnapshot) => void>();
  private snap: RuntimeSnapshot = {
    state: "idle", progress: 0, bytesLoaded: 0, bytesTotal: 0, error: null,
  };

  private constructor(game: string) {
    this.game = game;
    this.plan = assetPlanOf(game);
    this.store = new AssetStore(this.plan, (progress, loaded, total): void => {
      this.update({ progress, bytesLoaded: loaded, bytesTotal: total });
    });
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

  // 로비 단계 백그라운드 프리로드 — wasm·pck·side 를 받아 wasm 을 컴파일해 둔다.
  // 호출이 겹쳐도 preloadPromise 로 1회만 수행된다 (재호출은 같은 결과를 기다린다).
  preload(): Promise<void> {
    this.preloadPromise ??= this.doPreload().catch((e: unknown): void => {
      this.preloadPromise = null; // 실패는 재시도 가능하게
      this.update({ state: "error", error: e instanceof Error ? e.message : String(e) });
    });
    return this.preloadPromise;
  }

  private async doPreload(): Promise<void> {
    if (this.snap.state === "running") {return;}
    this.update({ state: "downloading", progress: 0, bytesLoaded: 0, bytesTotal: 0, error: null });

    const fresh = await this.store.loadManifest(this.game);
    if (this.manifest?.version === fresh.version && this.wasmModule) {
      this.update({ state: "ready", progress: 1 });
      return;
    }
    this.manifest = fresh;
    this.wasmModule = null;

    // 네 부작용: 부팅 전에 브라우저 캐시가 채워진다 — 엔진이 스스로 fetch 하는
    // 무버전 URL 과 같은 엔트리라 부팅 시 ETag 304(본문 0)로 재검증된다.
    const [wasmBuf] = await Promise.all([
      this.store.wasm,
      this.store.pck,
      this.store.sideWasm,
    ]);

    this.update({ state: "compiling" });
    this.wasmModule = await WebAssembly.compile(wasmBuf);
    this.update({ state: "ready", progress: 1 });
  }

  // 매치 시작: 핸드오프 기록 → 엔진 부팅 → 매치 신호 워치독.
  // startGame() 대신 수동 시퀀스(init→copyToFS→start)를 쓴다:
  // 프리로드한 버퍼를 FS 에 직접 넣어 엔진의 재다운로드를 원천 차단한다.
  boot(canvas: HTMLCanvasElement, handoff: HandoffInfo): Promise<void> {
    if (this.engine) {return Promise.resolve();}
    if (this.bootPromise) {return this.bootPromise;}
    // StrictMode 리마운트 등 동시 boot — 한쪽만 진행한다.
    this.bootPromise = this.doBoot(canvas, handoff)
      .catch((e: unknown): void => {
        this.update({ state: "error", error: e instanceof Error ? e.message : String(e) });
      })
      .finally((): void => { this.bootPromise = null; });
    return this.bootPromise;
  }

  private async doBoot(canvas: HTMLCanvasElement, handoff: HandoffInfo): Promise<void> {
    this.manifest ??= await this.store.loadManifest(this.game);
    // 프리로드가 아직 진행 중이어도 AssetStore 공유로 중복 다운로드 없이 합류한다.
    const [pckBuffer, extBuffer] = await Promise.all([this.store.pck, this.store.extLib]);

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
    if (!EngineCtor) {throw new Error("engine-missing");}

    const config: Record<string, unknown> = {
      canvas,
      canvasResizePolicy: 2,
      executable: this.plan.engineBase,
      args: ["--main-pack", "index.pck"],
      // dlink GDExtension — locateFile 매핑용 파일명 목록.
      gdextensionLibs: [this.plan.extLibFile],
    };
    // 사전컴파일한 wasm 주입 — 부팅 시 엔진의 index.wasm 재다운로드를 막는다.
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
    // side.wasm 도 캐시가 찬 뒤에 init — 엔진의 자체 fetch 가 304 로 떨어지게.
    await this.store.sideWasm;
    await engine.init(this.plan.engineBase);
    engine.copyToFS("index.pck", pckBuffer);
    // Godot 웹 dlopen 은 파일명만 쓴다(os_web.cpp p_path.get_file()) —
    // FS 루트에 파일명으로 심어 find_dylib 이 바로 찾게 한다.
    engine.copyToFS(`/${this.plan.extLibFile}`, extBuffer);
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
    if (this.scriptPromise) {return this.scriptPromise;}
    this.scriptPromise = new Promise((resolve, reject) => {
      const el = document.createElement("script");
      el.src = this.plan.files.engineJs;
      el.onload = (): void => resolve();
      el.onerror = (): void => {
        this.scriptPromise = null; // 재시도 가능하게
        reject(new Error("engine-load-failed"));
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
      this.update({ state: "error", error: "match-signal-missing" });
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
