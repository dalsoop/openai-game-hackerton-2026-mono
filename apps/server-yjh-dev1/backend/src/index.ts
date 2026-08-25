import { Server } from "colyseus";
import { WebSocketTransport } from "@colyseus/ws-transport";
import { createServer } from "node:http";
import { CONFIG } from "./config.js";
import { LobbyRoom } from "./rooms/LobbyRoom.js";
import { httpHandler } from "./lib/http.js";
import { setupMetrics } from "./lib/metrics.js";
import { allGames } from "./games/registry.js";

const httpServer = createServer(httpHandler);
const server = new Server({ transport: new WebSocketTransport({ server: httpServer }) });

server.define("lobby", LobbyRoom);

setupMetrics(server);

server.listen(CONFIG.port).then(() => {
  const ids = allGames().map(g => g.id).join(", ");
  console.log(`[lobby] listening on :${CONFIG.port}  games: ${ids}`);
});
