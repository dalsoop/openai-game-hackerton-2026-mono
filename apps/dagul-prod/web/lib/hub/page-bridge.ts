// React ↔ Godot 인게임 수송 — 허브 소켓은 React 만 연다.
// 정본 이벤트 이름: lib/contract DOM_EVT.TO_ENGINE / FROM_ENGINE
import { DOM_EVT, MSG } from "../contract";
import { plainSeatOf, seatListOf } from "../domain/roster";

export type BridgePacket = { readonly type: string; readonly payload: unknown };

const FROM_ENGINE_TYPES = new Set<string>([
  MSG.INPUT, MSG.LEAVE, MSG.SNAP_OFF, MSG.SNAP_ON, MSG.READY,
]);
const TO_ENGINE_TYPES = new Set<string>([MSG.SNAP, MSG.GUN_FIRE, MSG.ERROR, MSG.STATE]);

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

let lastInboundSnap: unknown = null;

function clonePlain(raw: unknown): unknown {
  if (raw == null || typeof raw !== "object") {return raw;}
  try {return JSON.parse(JSON.stringify(raw));} catch {return null;}
}

/** SNAP JSON 을 평문으로 고정한다. 스키마 dispose 뒤에 winner 를 읽지 않게. */
export function rememberInboundSnap(raw: unknown): void {
  lastInboundSnap = clonePlain(raw);
}

export function lastInboundSnapOf(): unknown {
  return lastInboundSnap;
}

/** 매치 종료·방 이탈 시 모듈 스냅을 버린다. 다음 매치에 낡은 SNAP 이 들어가지 않게. */
export function clearInboundSnap(): void {
  lastInboundSnap = null;
}

export function resetInboundSnapForTests(): void {
  clearInboundSnap();
}

export function freezeMatchEndDetail(detail: unknown, snap: unknown = lastInboundSnap): Record<string, unknown> {
  const base: Record<string, unknown> = {};
  if (detail && typeof detail === "object") {
    Object.assign(base, clonePlain(detail) as Record<string, unknown>);
  }
  if (!snap || typeof snap !== "object") {return base;}
  const frozen = clonePlain(snap);
  if (!frozen || typeof frozen !== "object") {return base;}
  const rec = frozen as Record<string, unknown>;
  if (!("winner" in base) && typeof rec.winner === "number") {base.winner = rec.winner;}
  if (!("result" in base) && typeof rec.result === "string") {base.result = rec.result;}
  base.snap = frozen;
  return base;
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

const DEFER_TYPES = new Set<string>([MSG.STATE]);

export function postToEngine(type: string, payload: unknown, bus?: DomBus): void {
  if (!isEngineInbound(type)) {return;}
  const detail = encodeBridgePacket(type, payload);
  const b = bus ?? windowDomBus();
  if (typeof requestAnimationFrame !== "undefined" && !bus && DEFER_TYPES.has(type)) {
    requestAnimationFrame(() => b.dispatchEvent({ type: DOM_EVT.TO_ENGINE, detail }));
  } else {
    b.dispatchEvent({ type: DOM_EVT.TO_ENGINE, detail });
  }
}

export interface HubWire {
  send: (type: string, payload?: unknown) => void;
}

export interface HubStateInput {
  readonly phase?: string;
  readonly hostSessionId?: string;
  readonly loadHeld?: boolean;
  readonly players?: readonly {
    readonly slot: number;
    readonly sessionId: string;
    readonly name: string;
    readonly connected: boolean;
    readonly matchReady?: boolean;
  }[];
}

/** Godot _sync_state 용 — sessionId 가 없으면 호스트 판정이 비므로 버린다. */
export function encodeHubState(
  snap: HubStateInput,
  sessionId: string,
  rttMs = 0,
): Record<string, unknown> | null {
  if (sessionId === "") {return null;}
  const players = seatListOf(snap.players).map((p) => {
    const seat = plainSeatOf(p);
    return {
      slot: seat.slot,
      sessionId: seat.sessionId,
      name: seat.name,
      connected: seat.connected,
      matchReady: Boolean(seat.matchReady),
    };
  });
  return {
    phase: snap.phase ?? "",
    hostSessionId: snap.hostSessionId ?? "",
    sessionId,
    loadHeld: Boolean(snap.loadHeld),
    players,
    ...(rttMs > 0 ? { rttMs } : {}),
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
