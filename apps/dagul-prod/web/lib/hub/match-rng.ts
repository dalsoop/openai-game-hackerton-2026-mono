/** 방 시드 기반 결정론 LCG — 허브 권위 시뮬에서 Math.random 대신 쓴다. */

/** 시드 0/미지정일 때의 고정 폴백 시드(황금비 해시 상수). */
export const RNG_FALLBACK_SEED = 0x9e3779b9;

const LCG_MUL = 1664525;
const LCG_INC = 1013904223;
const UINT32_RANGE = 4294967296;

export class MatchRng {
  private state: number;

  constructor(seed?: number) {
    const n = Number.isFinite(seed) ? Math.floor(seed as number) : 0;
    // 시드 0/미지정 → 고정 폴백으로 언제나 같은 결정론 스트림.
    this.state = (n >>> 0) || RNG_FALLBACK_SEED;
  }

  /** [0, 1) 균등 난수. */
  next(): number {
    this.state = (Math.imul(this.state, LCG_MUL) + LCG_INC) >>> 0;
    return this.state / UINT32_RANGE;
  }

  /** [min, max) 실수. */
  rangef(min: number, max: number): number {
    return min + (max - min) * this.next();
  }

  /** [min, max] 정수. */
  rangei(min: number, max: number): number {
    return min + Math.floor(this.next() * (max - min + 1));
  }

  /** 확률 p 로 true. */
  chance(p: number): boolean {
    return this.next() < p;
  }
}
