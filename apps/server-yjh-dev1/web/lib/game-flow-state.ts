// 게임 페이즈 순수 전이 로직 — 훅(useGameFlow)과 테스트가 같이 쓰는 SSOT.
// React 의존 없음: 같은 입력엔 같은 출력 (tests/game-flow-state.test.ts 가 전수 검증).
import type { GamePhase, HubStatus } from "@/types";

/** 튕김·강퇴 이유 — 재접속 모달 문구 분기. */
export type DropReason = "offline" | "kicked" | "dropped";

/** 허브 상태가 화면 페이즈를 몰아간다 — 아니면 현재 유지. */
export function phaseFromHubStatus(status: HubStatus, current: GamePhase): GamePhase {
  if (status === "in-room") {return "room";}
  if (status === "playing") {return "playing";}
  // 강퇴·단절로 방이 사라졌는데 대기실을 붙잡으면 빈 슬롯(회색 화면)이 남는다.
  if (current === "room" && status === "offline") {return "intro";}
  if (current === "room") {return "lobby";}
  return current;
}

/** 매치 종료 후 페이즈 — 연결이 살아있으면 로비로, 아니면 인트로로. */
export function phaseAfterMatchEnd(status: HubStatus): GamePhase {
  if (status === "playing" || status === "in-room" || status === "lobby") {return "lobby";}
  return "intro";
}

/** 표시 이름 — 입력값 우선, 비면 기본 플레이어. */
export function displayNameOf(name: string, defaultPlayer: string): string {
  return name.trim() || defaultPlayer;
}

/** 연결 끊김 모달 표시 여부 — 인트로(접속 전)는 모달 대상이 아니다. */
export function shouldShowConnectionLost(status: HubStatus, phase: GamePhase): boolean {
  return status === "offline" && phase !== "intro";
}

/** 회색 화면 대신 재접속 모달을 띄울지 — 강퇴·강제 퇴장·오프라인. */
export function shouldShowReconnect(
  status: HubStatus,
  phase: GamePhase,
  dropReason: DropReason | null,
): boolean {
  if (dropReason) {return true;}
  return shouldShowConnectionLost(status, phase);
}

/** 재접속 대상 방 — 강퇴·빈 id 는 로비만. */
export function reconnectJoinId(reason: DropReason | null, lastRoomId: string): string | null {
  if (reason === "kicked" || lastRoomId === "") {return null;}
  return lastRoomId;
}

/** 유즈맵 — 게임 다운로드는 대기실(방 입장 후)에서만 시작한다. 로비에서 돌리면 idle 이 '준비 중'으로 남는다. */
export function downloadStartsInRoom(phase: GamePhase): boolean {
  return phase === "room";
}
