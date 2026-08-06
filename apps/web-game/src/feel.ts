/** 조작감 파라미터 — 튜닝 패널과 물리 엔진이 공유하는 SSOT */
export type FeelParams = {
  accel: number;
  maxSpeed: number;
  friction: number;
  turnRate: number;
  drift: number;
  reverseFactor: number;
  wallBounce: number;
  wallFriction: number;
};

/** 기본값: 의도적으로 빡센 관성 */
export const DEFAULT_FEEL: FeelParams = {
  accel: 0.18,
  maxSpeed: 6.5,
  friction: 0.985,
  turnRate: 0.045,
  drift: 0.92,
  reverseFactor: 0.45,
  wallBounce: 0.35,
  wallFriction: 0.7,
};

export function cloneFeel(f: FeelParams = DEFAULT_FEEL): FeelParams {
  return { ...f };
}
