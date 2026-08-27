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
  readonly blurbKey: string;
  /** 방 만들기 목록 썸네일 — public 아래 정적 경로 */
  readonly thumbSrc: string;
  /** 게임 소유 모드 문자열 — 허브는 해석하지 않고 방에 그대로 넣는다. */
  readonly defaultMode: string;
  /** 웹 산출물 폴더명 — `/godot/${pack}/`. GameId 가 아니다. 지금은 통합 export 하나. */
  readonly pack: string;
  /** Player-facing picker hide. Catalog lookup and existing rooms stay valid. */
  readonly hidden?: boolean;
}

export const GAME_CATALOG: ReadonlyArray<GameDescriptor> = [
  {
    id: "dagul" as GameId,
    titleKey: "games.dagul.title",
    blurbKey: "games.dagul.blurb",
    thumbSrc: "/games/dagul.webp?v=3",
    defaultMode: "classic",
    pack: "dagul",
  },
  {
    id: "sparring" as GameId,
    titleKey: "games.sparring.title",
    blurbKey: "games.sparring.blurb",
    thumbSrc: "/games/sparring.webp",
    defaultMode: "default",
    pack: "dagul",
    hidden: true,
  },
];

/** Create Room / Waiting Room pickers. Hidden catalog entries stay resolvable. */
export function visibleCatalog(): ReadonlyArray<GameDescriptor> {
  return GAME_CATALOG.filter((g) => !g.hidden);
}

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

/** 방 state.mode 초기값 — 허브는 모드 사전을 갖지 않는다. */
export function defaultModeOf(id: GameId): string {
  return findGame(id)?.defaultMode ?? findGame(DEFAULT_GAME_ID)?.defaultMode ?? "";
}

/** 대기실/로비 i18n 키. 모르는 값은 서버 mode 원문을 그대로 쓴다. */
export function modeI18nKey(mode: string): "classic" | "full" | "default" | null {
  if (mode === "classic" || mode === "full" || mode === "default") {return mode;}
  return null;
}

/** GameId → 웹 산출물 폴더. URL·런타임 키는 여기만 거친다. */
export function packOf(id: GameId): string {
  return findGame(id)?.pack ?? findGame(DEFAULT_GAME_ID)?.pack ?? "dagul";
}

/** 카탈로그에 등장하는 팩 폴더 — 배포·심링크는 이 집합만 채운다. */
export function catalogPacks(): readonly string[] {
  return [...new Set(GAME_CATALOG.map((g) => g.pack))];
}
