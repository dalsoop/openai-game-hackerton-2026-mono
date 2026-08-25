import { WebSocket } from "ws";
import type { Phase } from "./config.js";

export interface TaggedWebSocket extends WebSocket {
  _session?: Client;
}

export interface Client {
  id: string;
  resume: string;
  ws: WebSocket;
  name: string;
  mode: string;
  roomId: string | null;
  dead: boolean;
  deadAt: number;
  dropTimer: ReturnType<typeof setTimeout> | null;
  rtt: number;
  lastChatAt?: number;
  msgBudget: number;
  msgRefillAt: number;
  publicHost: string;
}

export interface Room {
  id: string;
  mode: string;
  title: string;
  members: string[];
  phase: Phase;
  hostClientId: string | null;
  timer: ReturnType<typeof setTimeout> | null;
  lastSnap: Record<string, unknown> | null;
  prevSnap: Record<string, unknown> | null;
  snapCount: number;
  seed: number;
}
