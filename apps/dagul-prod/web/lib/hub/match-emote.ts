/**
 * 이모트 중계 — 원본 hero_movement.gd:125-127(입력) + match_lifecycle.gd:38(타이머)의
 * 결정론 포팅. RNG·시계 없음. 허브는 마지막 입력을 매 틱 재적용하므로
 * medkit use 와 같은 에지 검출로 홀드 재트리거를 막는다.
 */

/** 이모트 표시 시간(초) — 스냅 P_EMOTE_TIME 으로 전달, Godot draw_emote 가 감쇠 알파를 그린다. */
export const EMOTE_TIME = 1.6;
/** 유효 이모트 수 — 입력 0..3 (원본 emote >= 0 and emote < 4). */
export const EMOTE_COUNT = 4;

export type EmoteFields = {
  emote: number;
  emoteTime: number;
  emoteHeld: boolean;
};

/** SimHero 생성 시 이모트 초기 필드 묶음 — 없음(-1)·미표시. */
export function emoteSeedFields(): EmoteFields {
  return { emote: -1, emoteTime: 0, emoteHeld: false };
}

/** 입력 에지 — 0..3 이면 시작, -1(무입력)이면 에지 해제. 범위 밖 값은 무입력 취급. */
export function applyEmoteInput(hero: EmoteFields, value: number): void {
  const want = Number.isInteger(value) && value >= 0 && value < EMOTE_COUNT;
  if (want && !hero.emoteHeld) {
    hero.emote = value;
    hero.emoteTime = EMOTE_TIME;
  }
  hero.emoteHeld = want;
}

/** 타이머 감소 — update_timers(match_lifecycle.gd:38) 대응. */
export function tickEmotes(heroes: Iterable<EmoteFields>, dt: number): void {
  for (const h of heroes) {
    h.emoteTime = Math.max(0, h.emoteTime - dt);
  }
}
export const seed = emoteSeedFields;
export const tick = tickEmotes;
export const apply = applyEmoteInput;
