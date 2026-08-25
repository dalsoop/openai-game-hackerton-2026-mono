// 게임 카탈로그 도메인 — 유즈맵 모델에서 "어떤 게임이 존재하는가"의 단일 정본.
// 서버(방 생성 검증)와 클라(선택 UI·조건부 다운로드)가 모두 여기를 참조한다.
// Godot 쪽 대칭 정본: project/core/contract/game_registry.gd (games/<id>/game.gd 탐색).
// 신규 게임 추가 = games/<id>/ 폴더 + 여기 항목 1줄.

/** 게임 식별자 — 카탈로그에 등재된 id 만 이 타입이 된다. */
export type GameId = string & { readonly __brand: "GameId" };

export interface GameDescriptor {
  readonly id: GameId;
  /** 표시명 i18n 키 — 문구는 messages/*.json 이 정본 (하드코딩 금지) */
  readonly titleKey: string;
}

export const GAME_CATALOG: ReadonlyArray<GameDescriptor> = [
  { id: "dagul" as GameId, titleKey: "games.dagul.title" },
  { id: "sparring" as GameId, titleKey: "games.sparring.title" },
];

export const DEFAULT_GAME_ID: GameId = GAME_CATALOG[0]?.id ?? ("dagul" as GameId);

export function findGame(id: string): GameDescriptor | undefined {
  return GAME_CATALOG.find((g) => g.id === id);
}

/** 신뢰할 수 없는 입력(방 생성 옵션·쿼리)을 게임 id 로 정규화 — 미등재면 기본 게임. */
export function asGameId(raw: unknown): GameId {
  return findGame(typeof raw === "string" ? raw : "")?.id ?? DEFAULT_GAME_ID;
}

/** 카탈로그 등재 여부 — 서버 검증용 (정규화 없이 판정만). */
export function isKnownGame(id: string): boolean {
  return findGame(id) !== undefined;
}
