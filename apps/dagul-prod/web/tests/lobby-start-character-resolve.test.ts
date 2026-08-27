// 회귀: "랜덤"(characters.json defaultId, pick:"random") 픽은 허브가 매치 시드로
// 단 한 번만 굴린다. Godot 은 그 결과를 받아 그대로 실행할 뿐, 재해석하지 않는다
// (character_view.gd 주석: "랜덤 해소는 허브가 한다. 여기서 다시 굴리지 않는다").
// START 페이로드가 해소 전 원본을 보내면 클라가 "unknown" 을 그대로 받는다.
import { describe, expect, it, vi } from "vitest";
import type { Client } from "colyseus";
import { commitStart, sendStartBodies, type LobbyBag, type LobbyHandle } from "@/lib/hub/lobby-waiting";
import { bootAuthority } from "@/lib/hub/lobby-play";
import { LobbyState, PlayerSchema } from "@/lib/hub/lobby-state";
import { defaultCharacterId, isRandomCharacterId } from "@/lib/characters";

function emptyBag(): LobbyBag {
  return {
    lastSnap: null, prevSnap: null, gameTimer: null, idleTimer: null,
    authority: null, hostLossTimer: null, shutdownTimer: null, loadWaitMs: 0, startTimer: null,
  };
}

function roomWithHost(): { room: LobbyHandle; bag: LobbyBag; host: PlayerSchema; sent: Map<string, unknown> } {
  const state = new LobbyState();
  state.phase = "lobby";
  const host = new PlayerSchema();
  host.sessionId = "host";
  host.slot = 0;
  host.characterId = defaultCharacterId(); // 아무도 스테퍼를 만지지 않은 기본값 — "랜덤"
  state.players.push(host);
  state.hostSessionId = "host";
  const sent = new Map<string, unknown>();
  const room: LobbyHandle = {
    state,
    clients: [{ sessionId: "host", send: vi.fn((_type: string, payload: unknown) => {sent.set("host", payload);}) } as unknown as Client],
    metadata: {},
    setMetadata: vi.fn(),
    clock: { setTimeout: () => ({ clear: (): void => { /* no-op */ } }) },
    broadcast: vi.fn(),
    roomId: "room1",
  };
  return { room, bag: emptyBag(), host, sent };
}

describe("매치 시작 — 랜덤 픽 해소가 START 보다 먼저 끝난다", () => {
  it("host 가 랜덤을 두고 시작해도 players.characterId 는 실제 동물로 해소된다", () => {
    const { room, bag, host } = roomWithHost();
    const started = commitStart(room, bag);
    expect(started).toBe(true);
    expect(bag.authority).toBeNull(); // commitStart 는 아직 해소하지 않는다
    bootAuthority(room, bag);
    expect(host.characterId).not.toBe(defaultCharacterId());
    expect(isRandomCharacterId(host.characterId)).toBe(false);
  });

  it("START 페이로드의 seats[].characterId 는 unknown 을 보내지 않는다", () => {
    const { room, bag, sent } = roomWithHost();
    commitStart(room, bag);
    bootAuthority(room, bag);
    sendStartBodies(room, bag);
    const payload = sent.get("host") as { seats: Array<{ slot: number; characterId: string }> };
    expect(payload.seats).toHaveLength(1);
    expect(payload.seats[0].characterId).not.toBe(defaultCharacterId());
    expect(isRandomCharacterId(payload.seats[0].characterId)).toBe(false);
  });

  it("해소된 값은 매치 시뮬(hero)과 START 페이로드가 정확히 같다 — 두 번 안 굴린다", () => {
    const { room, bag, sent } = roomWithHost();
    commitStart(room, bag);
    bootAuthority(room, bag);
    sendStartBodies(room, bag);
    const heroId = bag.authority?.sim.heroes.get(0)?.characterId;
    const payload = sent.get("host") as { seats: Array<{ slot: number; characterId: string }> };
    expect(heroId).toBeDefined();
    expect(payload.seats[0].characterId).toBe(heroId);
  });

  it("직접 캐릭터를 고른 플레이어는 그 선택을 그대로 유지한다", () => {
    const { room, bag, host, sent } = roomWithHost();
    host.characterId = "a3";
    commitStart(room, bag);
    bootAuthority(room, bag);
    sendStartBodies(room, bag);
    expect(host.characterId).toBe("a3");
    const payload = sent.get("host") as { seats: Array<{ slot: number; characterId: string }> };
    expect(payload.seats[0].characterId).toBe("a3");
  });
});
