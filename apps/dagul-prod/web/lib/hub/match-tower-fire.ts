/**
 * 중앙 타워 발사 서브시스템 — 원본 mid_tower.gd 의 tower_shell / ring / fan / carpet 포팅.
 * 타워 본체 상태·피해·보상은 match-tower.ts 가 소유한다.
 */
export const TOWER_RADIUS = 86;
export const TOWER_INTERVAL = 1.85;
export const TOWER_DAMAGE = 22;
const FIRE_BOING = 0.22;
const FAN_ANGLE_STEP = 0.18;
const SHELL_MUZZLE_OFFSET = TOWER_RADIUS + 10;
const TAU = Math.PI * 2;

/** 타워 포탄 — tower_shell 필드의 구조적 타입. 통합 때 id 부여 후 projectiles 로 합류. */
export type TowerShell = {
  owner: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  damage: number;
  radius: number;
  ttl: number;
  splash: number;
  knockback: number;
  pierce: number;
  homing: number;
  ccTime: number;
  leech: boolean;
  kind: "shell";
  label: "TOWER";
  controlKind: "slow";
  source: "tower";
};

/** 타워 카펫 장판 — add_zone(-1, land, 78, delay, 30, tower, 0, 26, BOOM, explosion). */
export type TowerZone = {
  owner: number;
  x: number;
  y: number;
  radius: number;
  delay: number;
  damage: number;
  ccTime: number;
  knockback: number;
  kind: "tower";
  label: "BOOM";
  effectKind: "explosion";
};

export interface TowerHooks {
  /** 근접 크러시 환경 피해 — damage_hero_environment(slot, 22*0.85, true). */
  damageHeroEnvironment(slot: number, damage: number): void;
  /** 크러시 밀치기(34px) — 통합측이 resolve_cover_motion 으로 적용한다. */
  pushHero(slot: number, pushX: number, pushY: number): void;
  spawnShell(shell: TowerShell): void;
  spawnZone(zone: TowerZone): void;
}

/** 발사에 필요한 타워 상태 조각 — SimMidTower 가 구조적으로 만족한다. */
export type TowerFireState = {
  x: number;
  y: number;
  fireCd: number;
  pattern: number;
  boing: number;
};

function towerShell(
  tower: TowerFireState,
  dirX: number,
  dirY: number,
  speed: number,
  splash: number,
  damage: number,
  ttl: number,
  hooks: TowerHooks,
): void {
  let dx = dirX;
  let dy = dirY;
  const lenSq = dx * dx + dy * dy;
  if (lenSq < 0.0001) {
    dx = 1;
    dy = 0;
  } else {
    const len = Math.sqrt(lenSq);
    dx /= len;
    dy /= len;
  }
  hooks.spawnShell({
    owner: -1,
    x: tower.x + dx * SHELL_MUZZLE_OFFSET,
    y: tower.y + dy * SHELL_MUZZLE_OFFSET,
    vx: dx * speed,
    vy: dy * speed,
    damage,
    radius: 11,
    ttl,
    splash,
    knockback: 22,
    pierce: 0,
    homing: 0,
    ccTime: 0,
    leech: false,
    kind: "shell",
    label: "TOWER",
    controlKind: "slow",
    source: "tower",
  });
}

function towerRingShot(tower: TowerFireState, count: number, rot: number, hooks: TowerHooks): void {
  for (let i = 0; i < count; i += 1) {
    const ang = rot + (TAU * i) / count;
    towerShell(tower, Math.cos(ang), Math.sin(ang), 620, 46, TOWER_DAMAGE, 1.15, hooks);
  }
}

function towerFanShot(
  tower: TowerFireState,
  aimX: number,
  aimY: number,
  count: number,
  hooks: TowerHooks,
): void {
  const mid = (count - 1) * 0.5;
  for (let i = 0; i < count; i += 1) {
    const ang = (i - mid) * FAN_ANGLE_STEP;
    const cos = Math.cos(ang);
    const sin = Math.sin(ang);
    towerShell(tower, aimX * cos - aimY * sin, aimX * sin + aimY * cos, 860, 58, TOWER_DAMAGE + 4, 0.95, hooks);
  }
}

function towerCarpet(tower: TowerFireState, aimX: number, aimY: number, hooks: TowerHooks): void {
  for (let i = 0; i < 6; i += 1) {
    const side = i % 2 === 0 ? -1 : 1;
    const dist = 170 + i * 95;
    const lateral = side * (40 + i * 18);
    hooks.spawnZone({
      owner: -1,
      // orthogonal() = (y, -x) — Godot Vector2.orthogonal 그대로.
      x: tower.x + aimX * dist + aimY * lateral,
      y: tower.y + aimY * dist - aimX * lateral,
      radius: 78,
      delay: 0.42 + i * 0.08,
      damage: TOWER_DAMAGE + 8,
      ccTime: 0,
      knockback: 26,
      kind: "tower",
      label: "BOOM",
      effectKind: "explosion",
    });
  }
  towerFanShot(tower, aimX, aimY, 3, hooks);
}

/** 3패턴 순환 발사 — 링 10발(1.85s) → 부채꼴 7발(x0.82) → 카펫(x1.15). */
export function firePattern(
  tower: TowerFireState,
  targetX: number,
  targetY: number,
  hooks: TowerHooks,
): void {
  let aimX = targetX - tower.x;
  let aimY = targetY - tower.y;
  const len = Math.hypot(aimX, aimY);
  if (len * len < 0.0001) {
    aimX = 1;
    aimY = 0;
  } else {
    aimX /= len;
    aimY /= len;
  }
  const pattern = tower.pattern % 3;
  tower.boing = FIRE_BOING;
  if (pattern === 0) {
    towerRingShot(tower, 10, 0, hooks);
    tower.fireCd = TOWER_INTERVAL;
  } else if (pattern === 1) {
    towerFanShot(tower, aimX, aimY, 7, hooks);
    tower.fireCd = TOWER_INTERVAL * 0.82;
  } else {
    towerCarpet(tower, aimX, aimY, hooks);
    tower.fireCd = TOWER_INTERVAL * 1.15;
  }
  tower.pattern = pattern + 1;
}

export const applyTowerFire = firePattern;
export const apply = firePattern;
