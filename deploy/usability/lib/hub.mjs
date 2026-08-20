export function healthUrl(wsUrl) {
  const u = new URL(wsUrl);
  const http = u.protocol === "wss:" ? "https:" : "http:";
  return `${http}//${u.host}/health`;
}

export function defaultWsUrl() {
  return process.env.GANG_UP_WS || process.env.HUB_URL || "wss://server-yjh-dev1.external.kr/gang-up/ws";
}

export function isProdUrl(url) {
  return /server-prod(\.|\/|$)/i.test(url) || /\/\/prod\./i.test(url);
}

export async function fetchHealth(wsUrl, timeoutMs = 8000) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(healthUrl(wsUrl), { signal: ctrl.signal, cache: "no-store" });
    const body = await res.json().catch(() => ({}));
    return { ok: res.ok, status: res.status, body };
  } finally {
    clearTimeout(timer);
  }
}

export function openSocket(url, timeoutMs = 8000) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url);
    ws._inbox = [];
    ws.addEventListener("message", (ev) => {
      try {
        const msg = JSON.parse(String(ev.data));
        msg._at = performance.now();
        ws._inbox.push(msg);
      } catch {
        /* ignore */
      }
    });
    const timer = setTimeout(() => {
      try {
        ws.close();
      } catch {
        /* ignore */
      }
      reject(new Error(`연결 시간 초과: ${url}`));
    }, timeoutMs);
    ws.addEventListener("open", () => {
      clearTimeout(timer);
      resolve(ws);
    });
    ws.addEventListener("error", () => {
      clearTimeout(timer);
      reject(new Error(`소켓 오류: ${url}`));
    });
  });
}

function takeInbox(ws, pred) {
  const i = ws._inbox.findIndex(pred);
  if (i < 0) return null;
  return ws._inbox.splice(i, 1)[0];
}

export function waitMsg(ws, pred, timeoutMs = 8000) {
  return new Promise((resolve, reject) => {
    const hit = takeInbox(ws, pred);
    if (hit) {
      resolve(hit);
      return;
    }
    const started = Date.now();
    const tick = () => {
      const found = takeInbox(ws, pred);
      if (found) {
        resolve(found);
        return;
      }
      if (Date.now() - started > timeoutMs) {
        reject(new Error("메시지 시간 초과"));
        return;
      }
      setTimeout(tick, 10);
    };
    tick();
  });
}

export function send(ws, msg) {
  ws.send(JSON.stringify(msg));
}

export async function hello(ws, name, mode = "classic") {
  const welcome = await waitMsg(ws, (m) => m.t === "welcome");
  send(ws, { t: "hello", name, mode });
  await waitMsg(ws, (m) => m.t === "rooms");
  return welcome;
}

export async function createRoom(ws, title) {
  send(ws, { t: "create", title });
  return waitMsg(ws, (m) => m.t === "joined");
}

export async function joinRoom(ws, roomId) {
  send(ws, { t: "join", roomId });
  return waitMsg(ws, (m) => m.t === "joined" || m.t === "error");
}

export function startMatch(ws) {
  send(ws, { t: "start" });
  return waitMsg(ws, (m) => m.t === "start");
}

export function leave(ws) {
  try {
    send(ws, { t: "leave" });
  } catch {
    /* ignore */
  }
  try {
    ws.close();
  } catch {
    /* ignore */
  }
}

export function drainSnaps(ws) {
  const out = [];
  const rest = [];
  for (const m of ws._inbox) {
    if (m.t === "snap") out.push({ at: m._at ?? performance.now(), snap: m });
    else rest.push(m);
  }
  ws._inbox = rest;
  return out;
}

export async function driveInput(ws, ms) {
  let seq = 0;
  const started = performance.now();
  while (performance.now() - started < ms) {
    seq += 1;
    const ang = seq * 0.18;
    send(ws, {
      t: "input",
      seq,
      mx: Math.cos(ang),
      my: Math.sin(ang),
      fire: seq % 7 === 0,
      dash: seq % 80 === 0,
      use: false,
      aimX: 900,
      aimY: 450,
    });
    await sleep(16);
  }
  return seq;
}

export function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

export function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--") continue;
    if (a.startsWith("--")) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith("--")) {
        out[key] = next;
        i += 1;
      } else {
        out[key] = true;
      }
    } else {
      out._.push(a);
    }
  }
  return out;
}
