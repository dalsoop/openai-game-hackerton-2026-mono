import type { Server } from "colyseus";
import promClient from "prom-client";
import { CONFIG } from "../config.js";

const register = new promClient.Registry();
register.setDefaultLabels({ slot: CONFIG.slot });
promClient.collectDefaultMetrics({ register });

const gaugeRooms = new promClient.Gauge({ name: "gangup_rooms_total", help: "Total rooms", registers: [register] });
const gaugeUptime = new promClient.Gauge({ name: "gangup_uptime_seconds", help: "Server uptime", registers: [register] });

const SERVER_START = Date.now();

export function setupMetrics(server: Server) {
  setInterval(() => {
    gaugeUptime.set(Math.floor((Date.now() - SERVER_START) / 1000));
    // Colyseus matchmaker가 방 수를 관리하므로 별도 카운트 없이 서버에서 조회 가능
    void server;
    gaugeRooms.set(0); // TODO: Colyseus matchmaker API로 실제 방 수 연동
  }, CONFIG.metricsIntervalMs);
}

export { register as promRegister };
