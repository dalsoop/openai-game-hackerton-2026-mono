import { createServer } from "http";
import next from "next";
import { WebSocketServer } from "ws";
import { onConnection } from "./lib/hub/relay.js";

const dev = process.env.NODE_ENV !== "production";
const port = Number(process.env.PORT || 3000);
const app = next({ dev });
const handle = app.getRequestHandler();

const GAME_PATHS: Record<string, string> = {
  "/api/ws/dagul": "dagul",
  "/api/ws/snake": "snake",
  "/api/ws/hex": "hex",
};

app.prepare().then(() => {
  const server = createServer((req, res) => handle(req, res));
  const wss = new WebSocketServer({ noServer: true });

  server.on("upgrade", (req, socket, head) => {
    const url = req.url || "";
    const game = GAME_PATHS[url.split("?")[0]];
    if (game) {
      wss.handleUpgrade(req, socket, head, (ws) => {
        onConnection(ws, game);
      });
    } else {
      socket.destroy();
    }
  });

  server.listen(port, () => {
    console.log(`> Ready on http://localhost:${port}`);
    console.log(`> WebSocket hubs: ${Object.keys(GAME_PATHS).join(", ")}`);
  });
});
