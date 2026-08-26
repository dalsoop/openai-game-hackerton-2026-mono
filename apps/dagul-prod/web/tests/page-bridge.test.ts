import { describe, expect, it, vi } from "vitest";
import { DOM_EVT, MSG } from "@/lib/contract";
import {
  attachPageBridge,
  encodeBridgePacket,
  encodeHubState,
  isEngineInbound,
  isEngineOutbound,
  parseBridgePacket,
  postToEngine,
  type BridgeEvent,
  type DomBus,
} from "@/lib/hub/page-bridge";

function memoryBus(): DomBus & { emit: (type: string, detail: unknown) => void } {
  const listeners = new Map<string, Set<(ev: BridgeEvent) => void>>();
  const listen = (type: string, cb: (ev: BridgeEvent) => void): void => {
    const set = listeners.get(type) ?? new Set<(ev: BridgeEvent) => void>();
    set.add(cb);
    listeners.set(type, set);
  };
  const forget = (type: string, cb: (ev: BridgeEvent) => void): void => {
    listeners.get(type)?.delete(cb);
  };
  const emit = (type: string, detail: unknown): void => {
    listeners.get(type)?.forEach((cb) => {cb({ type, detail });});
  };
  return {
    addEventListener: listen,
    removeEventListener: forget,
    dispatchEvent: (ev): void => {emit(ev.type, ev.detail);},
    emit,
  };
}

describe("parseBridgePacket", () => {
  it("type·payload 를 읽는다", () => {
    expect(parseBridgePacket(encodeBridgePacket(MSG.SNAP, { t: 1 }))).toEqual({
      type: MSG.SNAP,
      payload: { t: 1 },
    });
  });

  it("반전: 깨진 JSON·빈 type 은 null", () => {
    expect(parseBridgePacket("{")).toBeNull();
    expect(parseBridgePacket("")).toBeNull();
    expect(parseBridgePacket(JSON.stringify({ payload: 1 }))).toBeNull();
    expect(parseBridgePacket(null)).toBeNull();
  });
});

describe("수송 방향", () => {
  it("엔진→허브는 input·leave·snap_off·snap_on", () => {
    expect(isEngineOutbound(MSG.INPUT)).toBe(true);
    expect(isEngineOutbound(MSG.LEAVE)).toBe(true);
    expect(isEngineOutbound(MSG.SNAP_OFF)).toBe(true);
    expect(isEngineOutbound(MSG.SNAP_ON)).toBe(true);
  });

  it("반전: snap 을 엔진이 허브로 보내면 안 된다", () => {
    expect(isEngineOutbound(MSG.SNAP)).toBe(false);
    expect(isEngineOutbound(MSG.START)).toBe(false);
    expect(isEngineOutbound(MSG.PACK_PCT)).toBe(false);
  });

  it("허브→엔진은 snap·gun_fire·error·state", () => {
    expect(isEngineInbound(MSG.SNAP)).toBe(true);
    expect(isEngineInbound(MSG.GUN_FIRE)).toBe(true);
    expect(isEngineInbound(MSG.STATE)).toBe(true);
  });

  it("반전: input 을 페이지가 엔진으로 되먹이면 안 된다", () => {
    expect(isEngineInbound(MSG.INPUT)).toBe(false);
    expect(isEngineInbound(MSG.PACK_PCT)).toBe(false);
  });

  it("허브 전용 키는 엔진 집합에 없다", () => {
    for (const type of [MSG.PACK_PCT, MSG.SET_GAME, MSG.SET_CHARACTER, MSG.ROOM_TOGGLE, MSG.PING, MSG.PONG, MSG.KICKED]) {
      expect(isEngineOutbound(type)).toBe(false);
      expect(isEngineInbound(type)).toBe(false);
    }
  });
});

describe("attachPageBridge", () => {
  it("엔진 leave 는 send 가 아니라 onLeave 다", () => {
    const bus = memoryBus();
    const send = vi.fn();
    const onLeave = vi.fn();
    const off = attachPageBridge({ send }, { onLeave, bus });
    bus.emit(DOM_EVT.FROM_ENGINE, encodeBridgePacket(MSG.LEAVE, {}));
    expect(onLeave).toHaveBeenCalledTimes(1);
    expect(send).not.toHaveBeenCalled();
    off();
  });

  it("엔진 FROM 이벤트를 room.send 로 넘긴다", () => {
    const bus = memoryBus();
    const send = vi.fn();
    const off = attachPageBridge({ send }, { bus });
    bus.emit(DOM_EVT.FROM_ENGINE, encodeBridgePacket(MSG.INPUT, { mx: 1 }));
    expect(send).toHaveBeenCalledWith(MSG.INPUT, { mx: 1 });
    bus.emit(DOM_EVT.FROM_ENGINE, encodeBridgePacket(MSG.SNAP_OFF, {}));
    expect(send).toHaveBeenCalledWith(MSG.SNAP_OFF, {});
    bus.emit(DOM_EVT.FROM_ENGINE, encodeBridgePacket(MSG.SNAP_ON, {}));
    expect(send).toHaveBeenCalledWith(MSG.SNAP_ON, {});
    off();
  });

  it("반전: 허용 밖 type 은 send 하지 않는다", () => {
    const bus = memoryBus();
    const send = vi.fn();
    const off = attachPageBridge({ send }, { bus });
    bus.emit(DOM_EVT.FROM_ENGINE, encodeBridgePacket(MSG.SNAP, { tick: 9 }));
    expect(send).not.toHaveBeenCalled();
    off();
  });

  it("반전: off 이후에는 엔진 이벤트를 보내지 않는다", () => {
    const bus = memoryBus();
    const send = vi.fn();
    const off = attachPageBridge({ send }, { bus });
    off();
    bus.emit(DOM_EVT.FROM_ENGINE, encodeBridgePacket(MSG.INPUT, { mx: 1 }));
    expect(send).not.toHaveBeenCalled();
  });
});

describe("postToEngine", () => {
  it("허용된 inbound 는 TO_ENGINE 으로 나간다", () => {
    const bus = memoryBus();
    const seen: string[] = [];
    bus.addEventListener(DOM_EVT.TO_ENGINE, (ev) => {seen.push(String(ev.detail));});
    postToEngine(MSG.SNAP, { t: 3 }, bus);
    expect(seen.some((d) => d.includes(MSG.SNAP) && d.includes("3"))).toBe(true);
  });

  it("반전: outbound type 은 창에 올리지 않는다", () => {
    const bus = memoryBus();
    const spy = vi.fn();
    bus.addEventListener(DOM_EVT.TO_ENGINE, spy);
    postToEngine(MSG.INPUT, {}, bus);
    expect(spy).not.toHaveBeenCalled();
  });
});

describe("encodeHubState", () => {
  it("sessionId 를 넣어 Godot 호스트 판정에 쓴다", () => {
    expect(encodeHubState({
      phase: "playing",
      hostSessionId: "h1",
      players: [{ slot: 0, sessionId: "h1", name: "A", connected: true }],
    }, "h1")).toEqual({
      phase: "playing",
      hostSessionId: "h1",
      sessionId: "h1",
      players: [{ slot: 0, sessionId: "h1", name: "A", connected: true }],
    });
  });

  it("반전: 빈 sessionId 는 패키지를 만들지 않는다", () => {
    expect(encodeHubState({ phase: "playing", hostSessionId: "h1" }, "")).toBeNull();
  });

  it("표본이 있으면 rttMs 를 싣는다", () => {
    expect(encodeHubState({ phase: "lobby" }, "s1", 42)).toMatchObject({ sessionId: "s1", rttMs: 42 });
  });

  it("반전: 0ms 는 필드 없이 보낸다", () => {
    expect(encodeHubState({ phase: "lobby" }, "s1", 0)).not.toHaveProperty("rttMs");
  });
});
