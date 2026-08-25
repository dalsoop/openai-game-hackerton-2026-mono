import { createServer } from "http";
import { readFileSync, existsSync } from "fs";
import { join, extname } from "path";

const PORT = Number(process.env.PORT || 8080);
const PUBLIC = join(__dirname, "..", "public");

const MIME: Record<string, string> = {
  ".html": "text/html", ".js": "application/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png", ".ico": "image/x-icon",
  ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml",
};

createServer((req, res) => {
  if (req.url === "/health") { res.writeHead(200, {"Content-Type":"application/json"}); res.end(JSON.stringify({ok:true,slot:"server-yjh-hexclash"})); return; }
  let file = join(PUBLIC, req.url === "/" ? "index.html" : req.url!);
  if (!existsSync(file)) { res.writeHead(404); res.end("Not Found"); return; }
  const mime = MIME[extname(file)] || "application/octet-stream";
  res.writeHead(200, {"Content-Type": mime});
  res.end(readFileSync(file));
}).listen(PORT, () => console.log(`Hex Clash on :${PORT}`));
