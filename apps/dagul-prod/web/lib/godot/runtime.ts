"use client";
// Godot 웹 런타임의 수명주기 소유자 — 상태머신(idle→downloading→…→running)과
// 엔진 부팅 시퀀스만 담당한다. URL 체계·다운로드 공유는 AssetStore 가,
// 핸드오프 키 계약은 lib/contract 가 소유한다 (여기선 조립만).
import { DOM_EVT } from "../contract";
import { HUB_CONFIG } from "../hub/config";
import { DEFAULT_GAME_ID, packOf, type GameId } from "../games/catalog";
import { AssetStore, assetPlanOf } from "./asset-store";
import { bindCanvasKeyboardFocus } from "./canvas-focus";
import { bindAudioUnlock, captureAudioContexts } from "./unlock-audio";
import { applyDevicePixelRatioCap, restoreDevicePixelRatio } from "./dpr-cap";
import { isWebGL2Available, type GodotEngineApi } from "./webgl";
import { BootTicket } from "./boot-ticket";
import { persistEngineHandoff, type HandoffInfo } from "./handoff";
import { disposeGodotEngine } from "./engine-dispose";
import { godotEngineConfig, type EngineInstance } from "./engine-config";
import { applyRuntimeProgress } from "./load-progress";

export type { HandoffInfo };
export { persistEngineHandoff, clearEngineHandoff } from "./handoff";

export type RuntimeState =
  | "idle" | "downloading" | "compiling" | "ready" | "running" | "error";

export interface RuntimeSnapshot {
  state: RuntimeState;
  progress: number; // 0..1
  bytesLoaded: number;
  bytesTotal: number;
  error: string | null;
}

interface Manifest {
  version: string;
  filesHash?: string;
  files: string[];
}

type EngineCtor = GodotEngineApi & (new (cfg: unknown) => EngineInstance);


export class GodotRuntime {
  // 팩당 싱글톤 — GameId 는 packOf 로만 폴더에 닿는다.
  private static _instances = new Map<string, GodotRuntime>();
  static for(game: GameId): GodotRuntime {
    const pack = packOf(game);
    let rt = this._instances.get(pack);
    if (!rt) {rt = new GodotRuntime(pack); this._instances.set(pack, rt);}
    return rt;
  }
  /** 호환 진입점 — 기본 게임의 팩 */
  static get instance(): GodotRuntime {return this.for(DEFAULT_GAME_ID);}
  static resetForTests(): void {
    for (const rt of this._instances.values()) {rt.quit();}
    this._instances.clear();
  }

  private readonly pack: string;
  private readonly plan;
  private readonly boots = new BootTicket();

  private readonly store: AssetStore;
  private manifest: Manifest | null = null;
  private wasmModule: WebAssembly.Module | null = null;
  private preloadPromise: Promise<void> | null = null;
  private engine: EngineInstance | null = null;
  private boundCanvas: HTMLCanvasElement | null = null;
  private unbindCanvasFocus: (() => void) | null = null;
  private unbindAudioUnlock: (() => void) | null = null;
  private scriptPromise: Promise<void> | null = null;
  private engineScriptEl: HTMLScriptElement | null = null;
  private bootPromise: Promise<void> | null = null;
  private exitPromise: Promise<void> | null = null;
  private watchdog: ReturnType<typeof setTimeout> | null = null;
  private matchSeen = false;
  private readonly onMatchStart = (): void => {
    this.matchSeen = true;
    if (this.watchdog) { clearTimeout(this.watchdog); this.watchdog = null; }
  };
  private listeners = new Set<(s: RuntimeSnapshot) => void>();
  private snap: RuntimeSnapshot = {
    state: "idle", progress: 0, bytesLoaded: 0, bytesTotal: 0, error: null,
  };

  private constructor(pack: string) {
    this.pack = pack;
    this.plan = assetPlanOf(pack);
    this.store = new AssetStore(this.plan, (progress, loaded, total): void => {
      if (this.snap.state !== "downloading") {return;}
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
    this.snap = applyRuntimeProgress(this.snap, partial);
    for (const fn of this.listeners) {fn(this.snap);}
  }

  private manifestKey(m: Manifest | null): string {
    if (!m) {return "";}
    return m.filesHash ?? m.version;
  }

  private applyManifest(fresh: Manifest): void {
    const prev = this.manifestKey(this.manifest);
    const next = this.manifestKey(fresh);
    this.manifest = fresh;
    if (prev !== "" && prev !== next) {
      this.wasmModule = null;
      this.scriptPromise = null;
      this.preloadPromise = null;
    }
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
    this.update({ state: "downloading", error: null });

    const fresh = await this.store.loadManifest(this.pack);
    this.applyManifest(fresh);
    if (this.wasmModule) {
      this.update({ state: "ready", progress: 1 });
      return;
    }

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
    this.writeHandoff(handoff);
    if (this.engine && this.boundCanvas === canvas) {return Promise.resolve();}
    if (this.bootPromise && this.boundCanvas === canvas) {return this.bootPromise;}
    const gen = this.boots.issue();
    this.disposeEngine();
    this.boundCanvas = canvas;
    this.bootPromise = this.doBoot(canvas, handoff, gen)
      .catch((e: unknown): void => {
        this.update({ state: "error", error: e instanceof Error ? e.message : String(e) });
      })
      .finally((): void => {
        if (this.boots.isLive(gen)) {this.bootPromise = null;}
      });
    return this.bootPromise;
  }

  private async doBoot(canvas: HTMLCanvasElement, handoff: HandoffInfo, gen: number): Promise<void> {
    if (!this.boots.isLive(gen)) {return;}
    // 이전 WASM 힙이 내려가기 전에 새 인스턴스를 올리면 메모리가 겹친다.
    await this.awaitPreviousExit();
    if (!this.boots.isLive(gen)) {return;}
    this.update({ state: "downloading", error: null });
    this.applyManifest(await this.store.loadManifest(this.pack));
    const [pckBuffer, extBuffer] = await Promise.all([this.store.pck, this.store.extLib]);
    if (!this.boots.isLive(gen)) {return;}
    this.writeHandoff(handoff);
    captureAudioContexts();
    await this.loadEngineScript();
    if (!this.boots.isLive(gen)) {return;}
    await this.launchPrepared(canvas, pckBuffer, extBuffer, gen);
  }

  private async launchPrepared(
    canvas: HTMLCanvasElement,
    pckBuffer: ArrayBuffer,
    extBuffer: ArrayBuffer,
    gen: number,
  ): Promise<void> {
    const EngineCtor = (window as unknown as { Engine?: EngineCtor }).Engine;
    if (!EngineCtor) {throw new Error("engine-missing");}
    if (!isWebGL2Available({ createCanvas: () => document.createElement("canvas") })) {
      throw new Error("webgl2-missing");
    }
    applyDevicePixelRatioCap();
    try {
      await this.launchEngine(EngineCtor, canvas, pckBuffer, extBuffer, gen);
    } catch (e: unknown) {
      restoreDevicePixelRatio();
      throw e;
    }
  }

  private async launchEngine(
    EngineCtor: new (cfg: unknown) => EngineInstance,
    canvas: HTMLCanvasElement,
    pckBuffer: ArrayBuffer,
    extBuffer: ArrayBuffer,
    gen: number,
  ): Promise<void> {
    if (!this.boots.isLive(gen)) {
      restoreDevicePixelRatio();
      return;
    }
    const config = godotEngineConfig(canvas, this.plan.engineBase, this.plan.extLibFile, this.wasmModule);
    this.attachExitPromise(config);
    captureAudioContexts();
    const engine = new EngineCtor(config);
    this.catchMatchStart();
    await this.store.sideWasm;
    await engine.init(this.plan.engineBase);
    engine.copyToFS("index.pck", pckBuffer);
    engine.copyToFS(`/${this.plan.extLibFile}`, extBuffer);
    if (!this.boots.isLive(gen)) {
      disposeGodotEngine(engine, canvas, this.exitPromise);
      restoreDevicePixelRatio();
      return;
    }
    try {
      await engine.start(config);
    } catch (err: unknown) {
      disposeGodotEngine(engine, canvas, this.exitPromise);
      throw err;
    }
    if (!this.boots.isLive(gen)) {
      disposeGodotEngine(engine, canvas, this.exitPromise);
      restoreDevicePixelRatio();
      return;
    }
    this.bindRunning(engine, canvas);
  }

  private attachExitPromise(config: Record<string, unknown>): void {
    this.exitPromise = new Promise<void>((resolve): void => {
      config.onExit = (): void => { resolve(); };
    });
  }

  private awaitPreviousExit(): Promise<void> {
    if (!this.exitPromise) {return Promise.resolve();}
    return Promise.race([
      this.exitPromise,
      new Promise<void>((resolve) => { setTimeout(resolve, 1500); }),
    ]);
  }

  private bindRunning(engine: EngineInstance, canvas: HTMLCanvasElement): void {
    this.engine = engine;
    this.boundCanvas = canvas;
    this.unbindCanvasFocus?.();
    this.unbindCanvasFocus = bindCanvasKeyboardFocus(canvas);
    this.unbindAudioUnlock?.();
    this.unbindAudioUnlock = bindAudioUnlock(canvas);
    this.update({ state: "running", progress: 1 });
    this.armWatchdog();
  }

  private writeHandoff(info: HandoffInfo): void {
    try { persistEngineHandoff(info.game ?? DEFAULT_GAME_ID, info); }
    catch { /* sessionStorage 불가 환경 — 엔진이 resume 없이 시도한다 */ }
  }

  private loadEngineScript(): Promise<void> {
    if (this.scriptPromise) {return this.scriptPromise;}
    this.scriptPromise = new Promise((resolve, reject) => {
      this.engineScriptEl?.remove();
      const el = document.createElement("script");
      el.src = this.store.assetUrl(this.plan.files.engineJs);
      el.onload = (): void => resolve();
      el.onerror = (): void => {
        el.remove();
        this.engineScriptEl = null;
        this.scriptPromise = null;
        reject(new Error("engine-load-failed"));
      };
      this.engineScriptEl = el;
      document.head.appendChild(el);
    });
    return this.scriptPromise;
  }

  private catchMatchStart(): void {
    window.removeEventListener(DOM_EVT.MATCH_START, this.onMatchStart);
    if (this.matchSeen) {return;}
    window.addEventListener(DOM_EVT.MATCH_START, this.onMatchStart, { once: true });
  }

  private armWatchdog(): void {
    if (this.matchSeen) {return;}
    this.watchdog = setTimeout((): void => {
      if (this.matchSeen) {return;}
      this.quit();
      this.update({ state: "error", error: "match-signal-missing" });
    }, HUB_CONFIG.matchWatchdogMs);
  }

  private disposeEngine(): void {
    if (this.watchdog) { clearTimeout(this.watchdog); this.watchdog = null; }
    this.matchSeen = false;
    window.removeEventListener(DOM_EVT.MATCH_START, this.onMatchStart);
    this.unbindCanvasFocus?.();
    this.unbindCanvasFocus = null;
    this.unbindAudioUnlock?.();
    this.unbindAudioUnlock = null;
    disposeGodotEngine(this.engine, this.boundCanvas, this.exitPromise);
    this.engine = null;
    this.boundCanvas = null;
    restoreDevicePixelRatio();
  }

  quit(): void {
    this.boots.invalidate();
    const wasBusy = this.snap.state === "running"
      || this.snap.state === "downloading"
      || this.snap.state === "compiling";
    this.disposeEngine();
    if (wasBusy) {this.update({ state: "ready" });}
  }

  resetError(): void {
    if (this.snap.state === "error") {this.update({ state: "idle", error: null });}
  }
}

