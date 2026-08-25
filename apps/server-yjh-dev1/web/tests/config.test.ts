// 허브 계약 정본(config.ts) 단위 테스트 — 키 추가·삭제 시 이곳에서 걸린다.
// GD 거울(web_contract.gd)과의 정합은 check-contract.mjs 가 담당한다.
import { describe, expect, it } from "vitest";
import { CloseCode } from "@colyseus/sdk";
import { MSG, HANDOFF, DOM_EVT, HUB_CONFIG, KO, CLOSE_CODE, ROOM_LEAVE, DEFAULT_SLOT, slotId, slotRoomName, ROOM_NAME } from "@/lib/hub/config";

describe("MSG 메시지 계약", () => {
  it("메시지 타입은 중복 없고 비어 있지 않다", () => {
    const values = Object.values(MSG);
    expect(new Set(values).size).toBe(values.length);
    for (const v of values) {expect(v.length).toBeGreaterThan(0);}
  });

  it("필수 메시지(START/INPUT/SNAP/PEER_INPUT/HOST_SNAP/ERROR/STATE/LEAVE/PING/PONG)가 존재한다", () => {
    expect(MSG.START).toBeDefined();
    expect(MSG.INPUT).toBeDefined();
    expect(MSG.SNAP).toBeDefined();
    expect(MSG.PEER_INPUT).toBeDefined();
    expect(MSG.HOST_SNAP).toBeDefined();
    expect(MSG.ERROR).toBeDefined();
    expect(MSG.STATE).toBe("state");
    expect(MSG.LEAVE).toBe("leave");
    expect(MSG.PING).toBe("ping");
    expect(MSG.PONG).toBe("pong");
    expect(MSG.SET_GAME).toBe("set_game");
    expect(HUB_CONFIG.idleStartMs).toBe(5 * 60 * 1000);
  });
});

describe("HANDOFF 핸드오프 키", () => {
  it("localStorage 키는 서로 겹치지 않는다", () => {
    const values = Object.values(HANDOFF);
    expect(new Set(values).size).toBe(values.length);
  });
});

describe("DOM_EVT · 핸드오프", () => {
  it("매치 시작/종료 이벤트가 정의돼 있다", () => {
    expect(DOM_EVT.MATCH_START.length).toBeGreaterThan(0);
    expect(DOM_EVT.MATCH_END.length).toBeGreaterThan(0);
  });

  it("핸드오프 키는 서로 겹치지 않는다(브릿지 컷오프 이후 MATCH 포함)", () => {
    const keys = Object.values(HANDOFF);
    expect(new Set(keys).size).toBe(keys.length);
    expect(HANDOFF.MATCH).toBe("gangup_match");
  });
});

describe("슬롯 룸 이름", () => {
  it("빈 슬롯은 이 앱 기본 폴더를 쓴다", () => {
    expect(slotId("")).toBe(DEFAULT_SLOT);
    expect(slotId("  ")).toBe(DEFAULT_SLOT);
    expect(slotRoomName("lobby", "")).toBe(`${DEFAULT_SLOT}-lobby`);
  });

  it("슬롯이 있으면 핸들러 이름 앞에 붙는다", () => {
    expect(slotRoomName("lobby", "server-fig-dev1")).toBe("server-fig-dev1-lobby");
    expect(slotRoomName("room_list", "server-prod")).toBe("server-prod-room_list");
  });

  it("실행 중 ROOM_NAME 은 다른 슬롯의 lobby 와 같지 않다", () => {
    expect(ROOM_NAME).toBe(slotRoomName("lobby"));
    expect(ROOM_NAME).not.toBe("lobby");
  });
});

describe("HUB_CONFIG", () => {
  it("최대 인원은 8(다굴), 시드 상한이 양수다", () => {
    expect(HUB_CONFIG.maxPlayers).toBe(8);
    expect(HUB_CONFIG.seedMax).toBeGreaterThan(0);
  });

  it("ROOM_FULL 안내문에 최대 인원이 반영된다", () => {
    expect(KO.ROOM_FULL).toContain(String(HUB_CONFIG.maxPlayers));
  });

  it("워치독·종료 코드는 공식 SDK 값과 같다", () => {
    expect(HUB_CONFIG.matchWatchdogMs).toBeGreaterThan(0);
    expect(HUB_CONFIG.rttIntervalMs).toBeGreaterThan(0);
    expect(HUB_CONFIG.maxPayload).toBeLessThanOrEqual(32 * 1024);
    expect(HUB_CONFIG.maxSnapBytes).toBeLessThan(HUB_CONFIG.maxPayload);
    expect(HUB_CONFIG.listPollMs).toBeGreaterThanOrEqual(2_000);
    expect(HUB_CONFIG.lobbyHealthRttMs).toBe(0);
    expect(CLOSE_CODE.CONSENTED).toBe(CloseCode.CONSENTED);
    expect(CLOSE_CODE.KICKED).toBe(CloseCode.CONSENTED);
    expect(ROOM_LEAVE.HANDOFF).toBe(false);
    expect(ROOM_LEAVE.CONSENTED).toBe(true);
  });
});
