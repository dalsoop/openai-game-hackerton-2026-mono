import fs from "node:fs";
import path from "node:path";
import type { IncomingMessage, ServerResponse } from "node:http";
import { CONFIG, ROUTES, MIME_TYPES, JSON_HEADERS, API_HEADERS } from "../config.js";
import { allGames } from "../games/registry.js";

const PUBLIC_DIR = path.resolve(CONFIG.frontendDir);
const DEFAULT_PATH = "/";
const DEFAULT_CONTENT_TYPE = "application/octet-stream";

function reqUrl(req: IncomingMessage): string {
  return req.url ? req.url : DEFAULT_PATH;
}

export function httpHandler(req: IncomingMessage, res: ServerResponse) {
  const pathname = new URL(reqUrl(req), "http://localhost").pathname;

  if (ROUTES.health.includes(pathname)) {
    res.writeHead(200, JSON_HEADERS);
    res.end(JSON.stringify({ ok: true, slot: CONFIG.slot, games: allGames().map(g => g.id) }));
    return;
  }

  if (ROUTES.metrics.includes(pathname)) {
    res.writeHead(200, { "content-type": "text/plain", ...API_HEADERS });
    res.end("# metrics endpoint — integrate with Colyseus monitor");
    return;
  }

  if (ROUTES.status.includes(pathname)) {
    res.writeHead(200, JSON_HEADERS);
    res.end(JSON.stringify({ ok: true, slot: CONFIG.slot }));
    return;
  }

  const url = new URL(reqUrl(req), "http://localhost");
  const stripped = url.pathname.replace(new RegExp(`^${ROUTES.prefix}`), "");
  const raw = stripped ? stripped : DEFAULT_PATH;
  const file = raw === "/" ? "/index.html" : raw;
  const full = path.normalize(path.join(PUBLIC_DIR, file));
  if (full !== PUBLIC_DIR && !full.startsWith(PUBLIC_DIR + path.sep)) {
    res.writeHead(403).end();
    return;
  }
  fs.readFile(full, (err, buf) => {
    if (err) {
      res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      res.end("not found");
      return;
    }
    const ext = path.extname(full);
    const ct = MIME_TYPES[ext] ? MIME_TYPES[ext] : DEFAULT_CONTENT_TYPE;
    res.writeHead(200, {
      "content-type": ct,
      "cache-control": ext === ".html" ? "no-store" : "no-cache",
    });
    res.end(buf);
  });
}
