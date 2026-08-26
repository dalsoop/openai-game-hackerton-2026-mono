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
  /** 아틀라스·궁극기용 부가값. 인게임 정체는 id 다. */
  readonly binds?: Readonly<Record<string, number | string>>;
  /** 대기실 버튼. 매치 시작 때 bind 가 있는 항목 중 하나를 고른다. */
  readonly pick?: "random";
}

export interface CharacterSource {
  load(): readonly CharacterDescriptor[];
  defaultId(): string;
}
