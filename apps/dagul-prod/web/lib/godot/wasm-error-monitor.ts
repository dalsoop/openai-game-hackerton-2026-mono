type ErrorGroup = {
  count: number;
  first: { msg: string; state: Record<string, unknown>; stack: string } | null;
  lastLog: number;
};

type Monitor = {
  groups: Record<string, ErrorGroup>;
  total: number;
  firstAt: number;
};

const W: Monitor = { groups: {}, total: 0, firstAt: 0 };

function classify(msg: string): string {
  if (msg.includes("_fp") && msg.includes("null")) {return "array_fp_null";}
  if (msg.includes("mem") && msg.includes("null")) {return "mem_null";}
  if (msg.includes("read-only")) {return "array_readonly";}
  if (msg.includes("alloc_static")) {return "alloc_static";}
  if (/libcolyseus|colyseus\.gdextension|GDExtension dynamic/i.test(msg)) {return "gdext_cut";}
  if (/PagedAllocator/i.test(msg)) {return "paged_allocator";}
  return "other";
}

const SILENT = new Set(["gdext_cut", "paged_allocator"]);

function gameState(): Record<string, unknown> {
  const d = (window as unknown as Record<string, unknown>).__dagulDebug;
  if (d && typeof d === "object") {return { ...(d as Record<string, unknown>), t: Date.now() };}
  return { t: Date.now() };
}

let installed = false;

export function installWasmErrorMonitor(): void {
  if (installed) {return;}
  if (typeof window === "undefined") {return;}
  installed = true;

  // eslint-disable-next-line no-console -- 디버그 전용: 발생량이 큰 WASM 에러를 그룹으로 압축해 되감는다.
  const orig = console.error.bind(console);
  (window as unknown as Record<string, unknown>).__godotErrors = W;

  // eslint-disable-next-line no-console -- 위와 같은 이유로 console.error 자체를 가로챈다.
  console.error = (...args: unknown[]): void => {
    const msg = args.map(String).join(" ");
    const key = classify(msg);
    if (key === "other") { orig(...args); return; }

    W.groups[key] ??= { count: 0, first: null, lastLog: 0 };
    const g = W.groups[key];
    g.count++;
    W.total++;
    if (!g.first) {
      g.first = { msg: args.slice(0, 2).map(String).join(" "), state: gameState(), stack: new Error().stack?.split("\n").slice(0, 6).join("\n") ?? "" };
      if (!W.firstAt) {W.firstAt = Date.now();}
    }
    const now = Date.now();
    if (SILENT.has(key)) {return;}
    if (now - g.lastLog > 3000) {
      g.lastLog = now;
      orig(`[wasm:${key}] x${g.count}`, args[0]);
    }
  };

  (window as unknown as Record<string, unknown>).__godotErrorSummary = (): Monitor => {
    orig("=== Godot WASM Error Summary ===");
    orig("total:", W.total, "| first at:", W.firstAt ? new Date(W.firstAt).toISOString() : "none");
    for (const [k, g] of Object.entries(W.groups)) {
      orig(`${k}: ${g.count} times`);
      if (g.first) {orig("  first:", g.first);}
    }
    return W;
  };
}
