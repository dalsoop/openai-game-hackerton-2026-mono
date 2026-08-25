"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export type LoaderState = "idle" | "downloading" | "compiling" | "ready" | "running" | "error";

export interface GodotLoaderResult {
  state: LoaderState;
  progress: number; // 0..1
  bytesLoaded: number;
  bytesTotal: number;
  error: string | null;
  start: () => void;
}

const moduleCache = new Map<string, WebAssembly.Module>();
const pckCache = new Map<string, ArrayBuffer>();

export function useGodotLoader(game: string): GodotLoaderResult {
  const [state, setState] = useState<LoaderState>("idle");
  const [progress, setProgress] = useState(0);
  const [bytesLoaded, setBytesLoaded] = useState(0);
  const [bytesTotal, setBytesTotal] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  const fetchWithProgress = useCallback(
    async (url: string, signal: AbortSignal): Promise<ArrayBuffer> => {
      const resp = await fetch(url, { signal, cache: "force-cache" });
      if (!resp.ok) throw new Error(`${url}: ${resp.status}`);
      const total = Number(resp.headers.get("content-length") || 0);
      setBytesTotal((prev) => prev + total);
      const reader = resp.body?.getReader();
      if (!reader) return resp.arrayBuffer();
      const chunks: Uint8Array[] = [];
      let loaded = 0;
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
        loaded += value.byteLength;
        setBytesLoaded((prev) => prev + value.byteLength);
        if (total > 0) setProgress(loaded / total);
      }
      const buf = new Uint8Array(loaded);
      let offset = 0;
      for (const c of chunks) {
        buf.set(c, offset);
        offset += c.byteLength;
      }
      return buf.buffer;
    },
    [],
  );

  const start = useCallback(async () => {
    if (state !== "idle" && state !== "error") return;
    if (moduleCache.has(game) && pckCache.has(game)) {
      setState("ready");
      setProgress(1);
      return;
    }

    const abort = new AbortController();
    abortRef.current = abort;
    setError(null);
    setBytesLoaded(0);
    setBytesTotal(0);
    setProgress(0);

    try {
      setState("downloading");
      const wasmUrl = `/godot/${game}/index.wasm`;
      const pckUrl = `/godot/${game}/index.pck`;

      const [wasmBuf, pckBuf] = await Promise.all([
        fetchWithProgress(wasmUrl, abort.signal),
        fetchWithProgress(pckUrl, abort.signal),
      ]);

      setState("compiling");
      const module = await WebAssembly.compile(wasmBuf);
      moduleCache.set(game, module);
      pckCache.set(game, pckBuf);
      setProgress(1);
      setState("ready");
    } catch (e: unknown) {
      if ((e as Error).name === "AbortError") return;
      const msg = e instanceof Error ? e.message : String(e);
      setError(msg);
      setState("error");
    }
  }, [game, state, fetchWithProgress]);

  useEffect(() => {
    return () => abortRef.current?.abort();
  }, []);

  return { state, progress, bytesLoaded, bytesTotal, error, start };
}

export function getCachedModule(game: string): WebAssembly.Module | undefined {
  return moduleCache.get(game);
}

export function getCachedPck(game: string): ArrayBuffer | undefined {
  return pckCache.get(game);
}
