// React ↔ Godot 인게임 수송 — 허브 소켓은 React 만 연다.
// 정본 이벤트 이름: lib/contract DOM_EVT.TO_ENGINE / FROM_ENGINE
import { DOM_EVT, MSG } from "@/lib/contract";

export type BridgePacket = { readonly type: string; readonly payload: unknown };

const FROM_ENGINE_TYPES = new Set<string>([MSG.INPUT, MSG.HOST_SNAP, MSG.LEAVE]);
const TO_ENGINE_TYPES = new Set<string>([MSG.SNAP, MSG.PEER_INPUT, MSG.ERROR, MSG.STATE]);

export function parseBridgePacket(raw: unknown): BridgePacket | null {
  if (typeof raw !== "string" || raw === "") {return null;}
  let parsed: unknown;
  try {parsed = JSON.parse(raw);} catch {return null;}
  if (typeof parsed !== "object" || parsed === null) {return null;}
  const type = (parsed as { type?: unknown }).type;
  if (typeof type !== "string" || type === "") {return null;}
  return { type, payload: (parsed as { payload?: unknown }).payload };
}

export function encodeBridgePacket(type: string, payload: unknown): string {
  return JSON.stringify({ type, payload });
}

export function isEngineOutbound(type: string): boolean {
  return FROM_ENGINE_TYPES.has(type);
}

export function isEngineInbound(type: string): boolean {
  return TO_ENGINE_TYPES.has(type);
}

export type BridgeEvent = { readonly type: string; readonly detail: unknown };

export interface DomBus {
  addEventListener: (type: string, cb: (ev: BridgeEvent) => void) => void;
  removeEventListener: (type: string, cb: (ev: BridgeEvent) => void) => void;
  dispatchEvent: (ev: BridgeEvent) => void;
}

function windowDomBus(): DomBus {
  return {
    addEventListener: (type, cb): void => {
      window.addEventListener(type, cb as unknown as EventListener);
    },
    removeEventListener: (type, cb): void => {
      window.removeEventListener(type, cb as unknown as EventListener);
    },
    dispatchEvent: (ev): void => {
      window.dispatchEvent(new CustomEvent(ev.type, { detail: ev.detail }));
    },
  };
}

export function postToEngine(type: string, payload: unknown, bus?: DomBus): void {
  if (!isEngineInbound(type)) {return;}
  (bus ?? windowDomBus()).dispatchEvent({ type: DOM_EVT.TO_ENGINE, detail: encodeBridgePacket(type, payload) });
}

export interface HubWire {
  send: (type: string, payload?: unknown) => void;
}

export interface HubStateInput {
  readonly phase?: string;
  readonly hostSessionId?: string;
  readonly players?: readonly {
    readonly slot: number;
    readonly sessionId: string;
    readonly name: string;
    readonly connected: boolean;
  }[];
}

/** Godot _sync_state 용 — sessionId 가 없으면 호스트 판정이 비므로 버린다. */
export function encodeHubState(snap: HubStateInput, sessionId: string): Record<string, unknown> | null {
  if (sessionId === "") {return null;}
  const players = Array.isArray(snap.players)
    ? snap.players.map((p) => ({
      slot: p.slot,
      sessionId: p.sessionId,
      name: p.name,
      connected: p.connected,
    }))
    : [];
  return {
    phase: snap.phase ?? "",
    hostSessionId: snap.hostSessionId ?? "",
    sessionId,
    players,
  };
}

export interface AttachPageBridgeOpts {
  readonly onLeave?: () => void;
  readonly bus?: DomBus;
}

/** 엔진 → 허브. 허브 → 엔진은 postToEngine / useRoomMessage 가 담당한다(핸들러 누수 방지). */
export function attachPageBridge(room: HubWire, opts?: AttachPageBridgeOpts): () => void {
  const onFromEngine = (ev: BridgeEvent): void => {
    const packet = parseBridgePacket(ev.detail);
    if (!packet || !isEngineOutbound(packet.type)) {return;}
    if (packet.type === MSG.LEAVE) {
      opts?.onLeave?.();
      return;
    }
    room.send(packet.type, packet.payload ?? {});
  };
  const bus = opts?.bus ?? windowDomBus();
  bus.addEventListener(DOM_EVT.FROM_ENGINE, onFromEngine);
  return (): void => {bus.removeEventListener(DOM_EVT.FROM_ENGINE, onFromEngine);};
}
