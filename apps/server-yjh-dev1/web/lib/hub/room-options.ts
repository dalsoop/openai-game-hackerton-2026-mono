// 방 설정 계약의 단일 정본 — 서버(onCreate/onAuth/onJoin)와 클라(생성/입장 빌더)가
// 같은 규칙으로 입력을 정규화한다. 규칙이 여기 한 곳에만 있으므로
// 정책이 양쪽에서 어긋나는 일이 타입·테스트로 걸린다.
import { asGameId, type GameId } from "../games/catalog";
import { HUB_CONFIG } from "./config";

/** 정규화된 플레이어 표시명 */
export type PlayerName = string & { readonly __brand: "PlayerName" };

/** 신뢰할 수 없는 방 만들기 입력 — 와이어/폼에서 온 raw. */
export interface RoomSettingsInput {
  readonly game?: unknown;
  readonly title?: unknown;
  readonly name?: unknown;
}

/** 방 만들기 설정 — 서버 state 로 확정되기 전의 정규화 결과. */
export interface RoomSettings {
  readonly game: GameId;
  readonly title: string;
  readonly name: PlayerName;
}

export interface RoomOptionLimits {
  readonly maxTitle: number;
  readonly maxName: number;
  readonly defaultName: string;
  readonly fallbackTitle: string;
}

/** 길이·기본명 한도 — 호출부가 12/24/"손님" 을 다시 쓰지 않게 한다. */
export function hubLimits(fallbackTitle: string): RoomOptionLimits {
  return {
    maxTitle: HUB_CONFIG.maxTitleLength,
    maxName: HUB_CONFIG.maxNameLength,
    defaultName: HUB_CONFIG.defaultName,
    fallbackTitle,
  };
}

/** 창 표시명 — 특수문기 제거 후 길이 컷. 빈 값은 기본명으로 치환한다. */
export function parsePlayerName(raw: unknown, max: number, fallback: string): PlayerName {
  const cleaned = (typeof raw === "string" ? raw : "")
    .replace(/[<>&"'`]/g, "").trim().slice(0, max);
  return (cleaned || fallback) as PlayerName;
}

/** 방 제목 — 표시명과 같은 소독 규칙, fallback 은 호출자(서버)가 만든 기본 제목. */
export function parseRoomTitle(raw: unknown, max: number, fallback: string): string {
  const cleaned = (typeof raw === "string" ? raw : "")
    .replace(/[<>&"'`]/g, "").trim().slice(0, max);
  return cleaned || fallback;
}

/** 방 만들기 입력 일괄 정규화 — 서버 onCreate 와 클라 빌더가 같이 쓴다. */
export function parseRoomSettings(
  raw: RoomSettingsInput,
  limits: RoomOptionLimits,
): RoomSettings {
  return {
    game: asGameId(raw.game),
    title: parseRoomTitle(raw.title, limits.maxTitle, limits.fallbackTitle),
    name: parsePlayerName(raw.name, limits.maxName, limits.defaultName),
  };
}
