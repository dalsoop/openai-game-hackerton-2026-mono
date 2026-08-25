import type { MatchInfo } from "./game";
/**
 * 허브/방 관련 타입 정의
 * Colyseus WebSocket 통합 타입
 */

/**
 * 허브 연결 상태
 */
export type HubStatus = "offline" | "connecting" | "lobby" | "in-room" | "playing";

/**
 * 연결 상태 → 표시용 CSS 클래스 (SSOT: 이곳만 고친다)
 */
export const CONNECTION_CLASS: Record<HubStatus, string> = {
  lobby: "conn ok",
  "in-room": "conn ok",
  connecting: "conn",
  offline: "conn bad",
  playing: "conn ok",
};

/**
 * 방 입장 요청 타입
 */
export type JoinRequest = { kind: "create" } | { kind: "join"; id: string } | { kind: "resume" };

/**
 * 허브 방 메타데이터
 */
export interface HubRoom {
  id: string;
  title: string;
  players: number;
  mode: string;
  playing: boolean;
}

/**
 * 플레이어 정보
 */
export interface HubPlayer {
  slot: number;
  id?: string;
  name: string;
  host?: boolean;
  dropped?: boolean;
}

/**
 * 허브 훅 반환 타입
 */
export interface UseHubResult {
  // 상태
  status: HubStatus;
  rooms: HubRoom[];
  players: HubPlayer[];
  you: number;
  roomId: string;
  isHost: boolean;
  resumeToken: string;
  error: string | null;
  matchInfo: MatchInfo | null;

  // 동작
  connect: (name: string) => void;
  createRoom: () => void;
  joinRoom: (id: string) => void;
  leaveRoom: () => void;
  returnToLobby: (name: string) => void;
  startMatch: () => void;
  refreshRooms: () => void;

  // 세션 재개 — 세션이 살아있는(유예 안) 동안 재접근하면 그 세션으로 복귀한다.
  tryResume: () => boolean;
  resuming: boolean;
  resumeFailed: boolean;
}

/**
 * Godot 브릿지 인터페이스 (window.__dagulBridge)
 */
export interface GodotBridge {
  send: (type: string, json: string) => void;
  on: (type: string, cb: (json: string) => void) => void;
  getMatch: () => string | null;
  clearMatch: () => void;
  leave: () => void;
  sessionId: string;
}

/**
 * 브릿지 게시 가능 룸 타입 — Colyseus Room 에서 브릿지가 쓰는 최소 구조만 요구한다.
 * (제네릭 공변 문제를 피하기 위해 Room 을 직접 확장하지 않는다.)
 */
export interface BridgeableRoom {
  /** SDK 0.17 공식 필드 — 핸드오프 전 자동 재접속을 끌 때 쓴다. */
  reconnection: { enabled: boolean };
  sessionId: string;
  reconnectionToken: string;
  send: (type: string, payload: unknown) => void;
  onMessage: (type: string, callback: (payload: unknown) => void) => void;
  leave: (consent: boolean) => void;
}
