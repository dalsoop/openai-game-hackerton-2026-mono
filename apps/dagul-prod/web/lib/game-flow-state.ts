// 게임 페이즈 순수 전이 로직 — 훅(useGameFlow)과 테스트가 같이 쓰는 SSOT.
// React 의존 없음: 같은 입력엔 같은 출력 (tests/game-flow-state.test.ts 가 전수 검증).
import type { GamePhase, HubStatus } from "../types";
import { shouldShowReconnect, type DropReason } from "./hub/room-end";
export type { DropReason, RoomEndKind } from "./hub/room-end";
export {
  canOfferReconnect,
  dropReasonFromKick,
  reconnectJoinId,
  roomEndKindFromCode,
  shouldMarkRoomDropped,
  shouldShowReconnect,
} from "./hub/room-end";

export type JoinKind = "create" | "join" | "resume";

/** 홈이 그리는 화면. phase 와 hub.status 가 어긋나도 빈 화면이 되면 안 된다. */
export type HomeSurface =
  | "reconnect"
  | "playing"
  | "intro"
  | "resuming"
  | "matchmaking"
  | "lobby"
  | "room";

/** /create 가 그리는 화면. form/pending/redirect 말고 null 이 되면 안 된다. */
export type CreateSurface = "form" | "pending" | "redirect";

export interface HomeSurfaceFlags {
  joiningKind?: JoinKind | null;
  resuming?: boolean;
  dropReason?: DropReason | null;
}

/** 인트로(시작하기) 화면에서만 켠다. */
export function lobbyBgmOn(phase: GamePhase): boolean {
  return phase === "intro";
}

/**
 * 배포 stale 자동 새로고침 허용 화면. 옛 번들·옛 팩이 새 서버 스키마와 만나면
 * 디코드가 깨지므로, 자리(대기실)나 매치를 잡고 있지 않은 화면에서는 즉시 리로드한다.
 * room·playing 에서는 배너만 두고, 로비로 돌아온 순간 이 판정이 리로드를 발화시킨다.
 */
export function deployReloadSafe(phase: GamePhase, stale: boolean): boolean {
  return stale && (phase === "intro" || phase === "lobby");
}

/** 방 생성·입장 matchmake 중에는 로비 목록을 그리지 않는다. */
export function matchmakePending(
  kind: "create" | "join" | "resume" | null | undefined,
  status: HubStatus,
): boolean {
  if (kind !== "create" && kind !== "join") {return false;}
  return status === "lobby" || status === "connecting";
}

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

/** React 가 허브 reconnect 의 유일한 호출자다. FROM_HUB 는 엔진 부팅 신호일 뿐. */
export function reactOwnsResume(_fromHub: string | null | undefined, token: string | null | undefined): boolean {
  return Boolean(token);
}

/** 반전 가드 — Godot 가 허브 matchmake/reconnect 를 하면 안 된다. */
export function godotMayHubReconnect(): boolean {
  return false;
}

/** 마운트 직후 페이즈 — 재개 성공만 로비. FROM_HUB 만으로는 플레이에 들어가지 않는다. */
export function phaseOnMount(resumed: boolean): GamePhase | null {
  return resumed ? "lobby" : null;
}

/**
 * 저장된 닉(로그인 세션)이 있고 공유 링크가 남아 있으면 인트로를 건너뛰고 바로 입장한다.
 * 첫 방문(닉 없음)은 시작하기를 한 번 눌러야 한다.
 */
export function shouldAutoJoinShare(hasSavedName: boolean, hasPendingShare: boolean): boolean {
  return hasSavedName && hasPendingShare;
}

/** 공유 링크로 들어온 입장은 이전 매치 재개보다 우선한다. */
export function resumeYieldsToShare(hasPendingShare: boolean): boolean {
  return hasPendingShare;
}

/** 유즈맵 팩 받기는 대기실(방 입장 후)에서만 시작한다. 로비에서 돌리면 idle 이 '준비 중'으로 남는다. */
export function packLoadStartsInRoom(phase: GamePhase): boolean {
  return phase === "room";
}

/**
 * 홈 화면 — 허브 상태를 우선한다.
 * 페이즈만 먼저 바뀌어도(나가기·시작·매치 종료) 이전 실화면을 붙든다.
 */
export function homeSurface(
  phase: GamePhase,
  status: HubStatus,
  flags: HomeSurfaceFlags = {},
): HomeSurface {
  if (shouldShowReconnect(status, phase, flags.dropReason ?? null)) {return "reconnect";}
  if (status === "playing") {return "playing";}
  if (status === "in-room") {return "room";}
  if (flags.resuming) {return "resuming";}
  if (matchmakePending(flags.joiningKind, status)) {return "matchmaking";}
  if (status === "offline") {return "intro";}
  return "lobby";
}

/** /create — 방이 생기기 전에는 폼 또는 대기. 홈으로 보낼 때만 redirect. */
export function createSurface(
  phase: GamePhase,
  status: HubStatus,
  joiningKind: JoinKind | null | undefined,
  resuming = false,
): CreateSurface {
  if (phase === "intro" || status === "offline") {return "redirect";}
  if (phase === "room" || phase === "playing" || status === "in-room" || status === "playing") {
    return "redirect";
  }
  if (resuming || status === "connecting" || matchmakePending(joiningKind, status)) {
    return "pending";
  }
  return "form";
}
