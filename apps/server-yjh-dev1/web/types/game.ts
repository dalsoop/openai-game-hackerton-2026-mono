/**
 * 게임/UI 관련 타입 정의
 * 페이지 페이즈, 매치 정보 등
 */

/**
 * 게임 페이즈 상태
 */
export type GamePhase = "intro" | "lobby" | "room" | "playing";

import type { StartPayload, SeatStart } from "@/lib/hub/start-payload";
export type { StartPayload, SeatStart };

/**
 * 매치 시작 정보
 */
export interface MatchInfo {
  roomId: string;
  name: string;
  slot: number;
  resumeToken: string;
  /** START 본문 — 엔진 재부팅 때 gangup_match 를 다시 심는다 */
  match?: StartPayload;
  gameId?: string;
}

/**
 * Godot 캔버스 Props
 */
export interface GodotCanvasProps {
  game: string;
  matchInfo: MatchInfo;
  visible: boolean;
  onMatchEnd?: (detail: Record<string, unknown>) => void;
  onError?: () => void;
}

/**
 * 세션 Props
 */
export interface SessionProps {
  nickname: string;
  saveNickname: (name: string) => void;
}

/**
 * 로더 상태 타입 (useGodotLoader 반환)
 */
export type LoaderState = "idle" | "downloading" | "compiling" | "ready" | "running" | "error";

/**
 * 로더 결과 타입
 */
export interface LoaderResult {
  state: LoaderState;
  progress: number;
  bytesLoaded: number;
  bytesTotal: number;
  error: string | null;
  start: () => void;
}
// CONNECTION_CLASS 는 hub.ts 가 SSOT 다 — 이곳에 복제하지 않는다.
