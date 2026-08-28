// 플레이(방·매치) 게이지 — 순수 함수 (tests 대상). /rooms 와 같은 RoomAvailable 원본을 받는다.
import type { RoomAvailable } from "@colyseus/sdk";
import { toHubRoom } from "./room-mapper";

function labelSlot(slot: string): string {
  return slot.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"");
}

function labelValue(value: string): string {
  return value.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"").replaceAll("\n", "\\n");
}

/** 방 목록 스냅샷 → Prometheus 게이지 텍스트. 슬롯 라벨은 ccu 메트릭과 같은 관례. */
export function playMetricsText(rooms: Array<RoomAvailable & { locked?: boolean }>, slot = process.env.SLOT_FOLDER ?? ""): string {
  const s = labelSlot(slot || "unknown");
  const views = rooms.map(toHubRoom);
  const playing = views.filter((r) => r.playing);
  const byGame = new Map<string, number>();
  for (const r of views) {
    const key = r.gameId || "unknown";
    byGame.set(key, (byGame.get(key) ?? 0) + 1);
  }
  const lines = [
    "# HELP dagul_rooms_total Rooms on this hub process (all phases).",
    "# TYPE dagul_rooms_total gauge",
    `dagul_rooms_total{slot="${s}"} ${views.length}`,
    "# HELP dagul_rooms_playing Rooms in playing phase.",
    "# TYPE dagul_rooms_playing gauge",
    `dagul_rooms_playing{slot="${s}"} ${playing.length}`,
    "# HELP dagul_rooms_waiting Rooms not yet playing (lobby/waiting).",
    "# TYPE dagul_rooms_waiting gauge",
    `dagul_rooms_waiting{slot="${s}"} ${views.length - playing.length}`,
    "# HELP dagul_players_playing Clients seated in playing rooms.",
    "# TYPE dagul_players_playing gauge",
    `dagul_players_playing{slot="${s}"} ${playing.reduce((a, r) => a + r.players, 0)}`,
    "# HELP dagul_players_total Clients seated in all rooms.",
    "# TYPE dagul_players_total gauge",
    `dagul_players_total{slot="${s}"} ${views.reduce((a, r) => a + r.players, 0)}`,
    "# HELP dagul_rooms_by_game Rooms grouped by game id.",
    "# TYPE dagul_rooms_by_game gauge",
  ];
  for (const [game, count] of [...byGame.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    lines.push(`dagul_rooms_by_game{slot="${s}",game="${labelValue(game)}"} ${count}`);
  }
  lines.push("");
  return lines.join("\n");
}
