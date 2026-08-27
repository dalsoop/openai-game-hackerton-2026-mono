/**
 * Colyseus Phaser 튜토리얼 고정 틱 입력:
 * enqueue 한 뒤 틱마다 next() 한 프레임. 빈 틱은 이동·조준·fire 홀드만 유지하고
 * 에지(firePressed 등)는 다시 켜지 않는다. 0.17 이라 defineInput 은 없다.
 */

export type MatchInput = {
  mx?: unknown;
  my?: unknown;
  aimX?: unknown;
  aimY?: unknown;
  fire?: unknown;
  firePressed?: unknown;
  equipment?: unknown;
  equipmentPressed?: unknown;
  equipmentReleased?: unknown;
  dash?: unknown;
  mobility?: unknown;
  use?: unknown;
  reload?: unknown;
  ultimate?: unknown;
  hop?: unknown;
  finish?: unknown;
  emote?: unknown;
  seq?: unknown;
};

/** 한 틱만 true 로 오는 에지. 아이들 홀드에 복사하지 않는다. */
export const ONE_SHOT_INPUT_KEYS = [
  "firePressed", "equipmentPressed", "equipmentReleased",
  "dash", "mobility", "use", "reload", "ultimate", "hop", "finish",
] as const satisfies readonly (keyof MatchInput)[];

/** 클라 60Hz 가 서버보다 잠깐 앞설 때 버퍼. 약 0.5초. */
export const INPUT_QUEUE_CAP = 32;

export function idleHoldInput(last: MatchInput): MatchInput {
  const held: MatchInput = { ...last };
  for (const key of ONE_SHOT_INPUT_KEYS) {
    held[key] = false;
  }
  held.emote = -1;
  return held;
}

/** 캡에서 버린 프레임의 에지를 살아 남은 머리에 붙인다. */
export function foldOneShots(from: MatchInput, onto: MatchInput): void {
  for (const key of ONE_SHOT_INPUT_KEYS) {
    if (from[key]) {onto[key] = true;}
  }
  if (Number(from.emote ?? -1) >= 0 && Number(onto.emote ?? -1) < 0) {
    onto.emote = from.emote;
  }
}

function foldOldestIntoHead(q: MatchInput[]): void {
  const dropped = q.shift();
  if (dropped === undefined) {return;}
  foldOneShots(dropped, q[0]);
}

export class SlotInputBuffer {
  readonly q: MatchInput[] = [];
  last?: MatchInput;

  enqueue(data: MatchInput): void {
    if (this.q.length >= INPUT_QUEUE_CAP) {foldOldestIntoHead(this.q);}
    this.q.push({ ...data });
  }

  /** 큐 머리 한 프레임. 비었으면 last 의 홀드 복제. */
  next(): MatchInput | undefined {
    const head = this.q.shift();
    if (head) {
      this.last = head;
      return head;
    }
    if (!this.last) {return undefined;}
    return idleHoldInput(this.last);
  }

  /** 카운트다운처럼 시뮬이 입력을 안 먹을 때 잔여 에지를 버리고 홀드만 남긴다. */
  flushToIdle(): MatchInput | undefined {
    while (this.q.length > 0) {
      this.last = this.q.shift();
    }
    if (!this.last) {return undefined;}
    this.last = idleHoldInput(this.last);
    return this.last;
  }
}
