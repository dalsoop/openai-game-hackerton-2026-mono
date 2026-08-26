import type { MatchInfo } from "./game";
import type { MyRoomIdentity } from "@/lib/room-membership";
import type { DropReason } from "@/lib/game-flow-state";
import type { Seat } from "@/lib/domain/roster";
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
export type JoinRequest =
  | { kind: "create"; game?: string; title?: string }
  | { kind: "join"; id: string; game?: string }
  | { kind: "resume" };

/**
 * 허브 방 메타데이터
 */
export interface HubRoom {
  id: string;
  gameId: string;
  title: string;
  players: number;
  mode: string;
  playing: boolean;
  /** 방장의 문 — 닫히면 목록에서 입장 불가 */
  open: boolean;
}

/**
 * 허브 훅 반환 타입
 */
export interface UseHubResult {
  // 상태
  status: HubStatus;
  /** 접속 중인 방의 게임(유즈맵) — 방 밖이면 빈 문자열 */
  gameId: string;
  rooms: HubRoom[];
  players: Seat[];
  you: number;
  /** 인게임 로딩 장벽. 전원 ready 또는 타임아웃이면 false. */
  loadHeld: boolean;
  roomId: string;
  isHost: boolean;
  /** 방장의 문 — 닫힌 방은 입장 불가 (닫는 순간 재실자 강퇴) */
  roomOpen: boolean;
  resumeToken: string;
  /** 게임 방 소켓 왕복 ms. 방 밖이거나 아직 표본이 없으면 0. */
  rttMs: number;
  error: string | null;
  matchInfo: MatchInfo | null;

  // 동작
  connect: (name: string) => void;
  createRoom: (raw?: { game?: string; title?: string }) => void;
  joinRoom: (id: string) => void;
  leaveRoom: () => void;
  /** 리스트 룸까지 내리고 인트로로 돌아갈 때. */
  disconnect: () => void;
  returnToLobby: (name: string) => void;
  startMatch: () => void;
  sendPackPct: (pct: number) => void;
  setGame: (game: string) => void;
  setCharacter: (characterId: string) => void;
  idleLeftSec: number;
  toggleRoom: () => void;
  refreshRooms: () => void;
  refreshingRooms: boolean;

  // 세션 재개 — 세션이 살아있는(유예 안) 동안 재접근하면 그 세션으로 복귀한다.
  tryResume: () => boolean;
  resuming: boolean;
  resumeFailed: boolean;
  /** 진행 중인 matchmake. 방 안이면 유지되지만 로비 깜빡임 판정은 matchmakePending 이 가른다. */
  joiningKind: JoinRequest["kind"] | null;

  /** 강퇴·강제 퇴장 — 회색 화면 대신 재접속 모달. */
  dropReason: DropReason | null;
  lastRoomId: string;
  reconnectAfterDrop: () => void;

  // 내 방 멤버십 — 로비 목록 상단 고정·배지 판정 원천 (room-membership 모듈)
  myRoom: MyRoomIdentity | null;
}

/**
 * 핸드오프용 룸 최소 구조 — Colyseus Room 전체를 요구하지 않는다.
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
