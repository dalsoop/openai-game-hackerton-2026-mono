/** 초상 — 단일 이미지이거나 시트 한 칸. 렌더러만 이 필드를 본다. */
export interface CharacterPortrait {
  readonly src: string;
  readonly cols?: number;
  readonly rows?: number;
  readonly index?: number;
}

/** 캐릭터 계약. 허브는 id 만 보관하고, UI 는 portrait·titleKey 만 쓴다. */
export interface CharacterDescriptor {
  readonly id: string;
  readonly titleKey: string;
  readonly portrait: CharacterPortrait;
  /** 게임 모듈이 해석한다. 허브·대기실 UI 는 읽지 않는다. */
  readonly binds?: Readonly<Record<string, number | string>>;
}

export interface CharacterSource {
  load(): readonly CharacterDescriptor[];
  defaultId(): string;
}
