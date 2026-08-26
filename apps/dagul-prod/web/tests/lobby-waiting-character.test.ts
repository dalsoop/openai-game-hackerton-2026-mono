import { describe, expect, it, vi } from "vitest";
import { handleSetCharacter, type LobbyHandle } from "@/lib/hub/lobby-waiting";
import { LobbyState, PlayerSchema } from "@/lib/hub/lobby-state";
import { defaultCharacterId } from "@/lib/characters";

function handleOf(state: LobbyState): LobbyHandle {
  return {
    state,
    clients: [],
    metadata: {},
    setMetadata: vi.fn(),
    clock: { setTimeout: () => ({ clear: (): void => { /* no-op */ } }) },
    broadcast: vi.fn(),
  };
}

function seated(phase: "lobby" | "playing" = "lobby"): { room: LobbyHandle; player: PlayerSchema } {
  const state = new LobbyState();
  state.phase = phase;
  const player = new PlayerSchema();
  player.sessionId = "s1";
  player.slot = 0;
  player.characterId = defaultCharacterId();
  state.players.push(player);
  return { room: handleOf(state), player };
}

describe("handleSetCharacter", () => {
  it("등재 id 만 남기고 그 외는 기본값이다", () => {
    const { room, player } = seated();
    const client = { sessionId: "s1" } as never;
    handleSetCharacter(room, client, { characterId: "a7" });
    expect(player.characterId).toBe("a7");
    handleSetCharacter(room, client, { characterId: 3 });
    expect(player.characterId).toBe(defaultCharacterId());
  });

  it("다른 세션·playing 은 바꾸지 않는다", () => {
    const { room, player } = seated();
    handleSetCharacter(room, { sessionId: "other" } as never, { characterId: "a1" });
    expect(player.characterId).toBe(defaultCharacterId());
    const playing = seated("playing");
    handleSetCharacter(playing.room, { sessionId: "s1" } as never, { characterId: "a1" });
    expect(playing.player.characterId).toBe(defaultCharacterId());
  });
});
