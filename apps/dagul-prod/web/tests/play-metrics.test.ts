import { describe, expect, it } from "vitest";
import { playMetricsText } from "@/lib/hub/play-metrics";
import type { RoomAvailable } from "@colyseus/sdk";

function room(id: string, game: string, clients: number, phase: string): RoomAvailable & { locked?: boolean } {
  return {
    roomId: id,
    clients,
    maxClients: 8,
    metadata: { gameId: game, phase },
    createdAt: 0,
    name: "hub",
  } as RoomAvailable;
}

describe("playMetricsText", () => {
  it("emits zero gauges for an empty room list", () => {
    const text = playMetricsText([], "dagul-prod");
    expect(text).toContain('dagul_rooms_total{slot="dagul-prod"} 0');
    expect(text).toContain('dagul_rooms_playing{slot="dagul-prod"} 0');
    expect(text).toContain('dagul_players_playing{slot="dagul-prod"} 0');
  });

  it("counts playing rooms and seated players separately from waiting rooms", () => {
    const text = playMetricsText(
      [room("a", "gang-up", 4, "playing"), room("b", "gang-up", 2, "lobby")],
      "dagul-prod",
    );
    expect(text).toContain('dagul_rooms_total{slot="dagul-prod"} 2');
    expect(text).toContain('dagul_rooms_playing{slot="dagul-prod"} 1');
    expect(text).toContain('dagul_rooms_waiting{slot="dagul-prod"} 1');
    expect(text).toContain('dagul_players_playing{slot="dagul-prod"} 4');
    expect(text).toContain('dagul_players_total{slot="dagul-prod"} 6');
  });

  it("groups rooms by game id and sorts the labels", () => {
    const text = playMetricsText(
      [room("a", "zeta", 1, "playing"), room("b", "alpha", 1, "lobby")],
      "dagul-prod",
    );
    const alpha = text.indexOf('game="alpha"');
    const zeta = text.indexOf('game="zeta"');
    expect(alpha).toBeGreaterThan(-1);
    expect(zeta).toBeGreaterThan(alpha);
  });

  it("escapes quotes and newlines in game labels", () => {
    const text = playMetricsText([room("a", 'ba"d\nr', 1, "playing")], "dagul-prod");
    expect(text).toContain('game="ba\\"d\\nr"} 1');
  });
});
