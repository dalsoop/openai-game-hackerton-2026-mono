/**
 * Godot 4.7 web-export Engine loader utility.
 *
 * The export produces index.js which registers `window.Engine`.
 * This module loads that script, creates an Engine instance, and starts the game.
 */

let scriptLoaded = new Set<string>();

export async function loadEngineScript(game: string): Promise<void> {
  const src = `/godot/${game}/index.js`;
  if (scriptLoaded.has(src)) return;
  return new Promise<void>((resolve, reject) => {
    const el = document.createElement("script");
    el.src = src;
    el.onload = () => {
      scriptLoaded.add(src);
      resolve();
    };
    el.onerror = () => reject(new Error(`Failed to load ${src}`));
    document.head.appendChild(el);
  });
}

export interface StartGameOptions {
  game: string;
  canvas: HTMLCanvasElement;
}

export async function startGodotEngine(opts: StartGameOptions): Promise<unknown> {
  await loadEngineScript(opts.game);
  const EngineCtor = (window as any).Engine;
  if (!EngineCtor) throw new Error("Godot Engine not found on window");
  const engine = new EngineCtor({
    args: ["--main-pack", `/godot/${opts.game}/index.pck`],
    canvasResizePolicy: 2,
    canvas: opts.canvas,
    executable: `/godot/${opts.game}/index`,
  });
  await engine.startGame();
  return engine;
}

export function quitEngine(engine: unknown): void {
  if (engine && typeof (engine as any).requestQuit === "function") {
    (engine as any).requestQuit();
  }
}
