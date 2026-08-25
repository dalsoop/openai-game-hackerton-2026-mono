// 접속 상태 사다리 — 순수 함수 (tests 대상).
// 우선순위: 매치 진행 > 방 파생 > 접속 시도 상태.
import type { HubStatus, MatchInfo } from "@/types";

export function deriveStatus(
  derived: { status: HubStatus } | null,
  connected: boolean,
  lobbyErr: Error | undefined,
  lobbyConnecting: boolean,
  matchInfo: MatchInfo | null,
): HubStatus {
  if (matchInfo) {return "playing";} // 핸드오프 후 방을 떠났어도 매치는 진행 중
  if (derived) {return derived.status;}
  if (!connected) {return "offline";}
  if (lobbyErr) {return "offline";}
  if (lobbyConnecting) {return "connecting";}
  return "lobby";
}
