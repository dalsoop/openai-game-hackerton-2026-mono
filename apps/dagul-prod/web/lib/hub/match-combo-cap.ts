/**
 * 커리어 콤보 예산 — original_game_world.gd:3780-3784 + hero_movement.gd:1322-1324.
 * 한 콤보 문자열(히트 + 그 런치의 벽 튕김)이 피해자 maxHp * comboCapRatio 를 넘지 못하게 한다.
 * 라이브 pjh damage_system 은 이 객체가 빠져 적립만 한다. 정본은 문서·스모크 계약.
 */
export type ComboCapSource = {
  maxHp?: number;
  comboCapRatio?: number;
  equipment?: { comboCapRatio: number };
};

export type ComboCapHitTarget = ComboCapSource & { comboDamage: number };
export type ComboCapWallTarget = ComboCapSource & { launchWallDamage: number };

/** 한 콤보가 쓸 수 있는 피해 한도. 히트 적립과 벽 튕김이 같은 spent 를 나눠 쓴다. */
export class ComboCap {
  readonly limit: number;
  spent: number;

  constructor(limit: number, spent = 0) {
    this.limit = Math.max(0, limit);
    this.spent = Math.max(0, spent);
  }

  remaining(): number {
    return Math.max(0, this.limit - this.spent);
  }

  /** 후보 피해를 잔여 예산 안으로 자르고 적립한다. 반환 = 실제로 들어가는 양. */
  take(amount: number): number {
    const applied = Math.min(Math.max(0, amount), this.remaining());
    this.spent += applied;
    return applied;
  }

  static limitOf(maxHp: number, comboCapRatio: number): number {
    return Math.max(0, maxHp * comboCapRatio);
  }

  static fromCareer(maxHp: number, comboCapRatio: number, spent = 0): ComboCap {
    return new ComboCap(ComboCap.limitOf(maxHp, comboCapRatio), spent);
  }

  static ratioOf(h: ComboCapSource): number | undefined {
    return h.comboCapRatio ?? h.equipment?.comboCapRatio;
  }

  /** 커리어를 모르면 한도 없음(테스트·환경 피해). 알면 maxHp * ratio. */
  static of(h: ComboCapSource, spent: number): ComboCap {
    const ratio = ComboCap.ratioOf(h);
    if (h.maxHp === undefined || ratio === undefined) {
      return new ComboCap(Number.POSITIVE_INFINITY, spent);
    }
    return ComboCap.fromCareer(h.maxHp, ratio, spent);
  }

  /** 히트 경로 — damage_hero 콤보 클램프. comboDamage 를 spent 로 쓴다. */
  static takeHit(h: ComboCapHitTarget, amount: number): number {
    const cap = ComboCap.of(h, h.comboDamage);
    const applied = cap.take(amount);
    h.comboDamage = cap.spent;
    return applied;
  }

  /**
   * 벽 튕김 경로 — launch_wall_damage 를 spent 로 쓴다.
   * 런치 개시 때 launchWallDamage = comboDamage 이므로 히트와 한 예산을 이어서 쓴다.
   */
  static takeWall(h: ComboCapWallTarget, amount: number): number {
    const cap = ComboCap.of(h, h.launchWallDamage);
    const applied = cap.take(amount);
    h.launchWallDamage = cap.spent;
    return applied;
  }
}

export const seed = ComboCap.fromCareer;
