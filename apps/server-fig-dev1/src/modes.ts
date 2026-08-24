export const MAX_PLAYERS = 8;
export const TICK_HZ = 20;
export const ARENA = { w: 1600, h: 900, cx: 800, cy: 450, radius: 420 } as const;

export interface WeaponDef {
  id: string;
  name: string;
  interval: number;
  speed: number;
  damage: number;
  auto: boolean;
}

export interface ItemDef {
  id: string;
  name: string;
  heal?: number;
  charges?: number;
}

export interface ModeDef {
  id: string;
  title: string;
  blurb: string;
  startWeapon: string;
  lootGuns: boolean;
  lootItems: boolean;
}

export const WEAPONS: Record<string, WeaponDef> = {
  pistol_semi: { id: "pistol_semi", name: "단발 권총", interval: 0.42, speed: 620, damage: 14, auto: false },
  pistol_auto: { id: "pistol_auto", name: "연발 권총", interval: 0.09, speed: 600, damage: 7, auto: true },
  smg: { id: "smg", name: "SMG", interval: 0.07, speed: 680, damage: 8, auto: true },
  rifle: { id: "rifle", name: "소총", interval: 0.28, speed: 820, damage: 18, auto: false },
};

export const ITEMS: Record<string, ItemDef> = {
  medkit: { id: "medkit", name: "메드킷", heal: 40 },
  dash: { id: "dash", name: "부스터", charges: 1 },
};

export const MODES: Record<string, ModeDef> = {
  classic: {
    id: "classic",
    title: "클래식",
    blurb: "시작부터 각자 다른 총. 루팅 없음.",
    startWeapon: "unique",
    lootGuns: false,
    lootItems: false,
  },
  "gun-semi": {
    id: "gun-semi",
    title: "무기 · 단발",
    blurb: "전원 단발 권총. 처치하면 총을 줍는다.",
    startWeapon: "pistol_semi",
    lootGuns: true,
    lootItems: false,
  },
  "gun-auto": {
    id: "gun-auto",
    title: "무기 · 연발",
    blurb: "전원 연발 권총. 처치하면 총을 줍는다.",
    startWeapon: "pistol_auto",
    lootGuns: true,
    lootItems: false,
  },
  item: {
    id: "item",
    title: "아이템",
    blurb: "총은 기본 권총 고정. 메드킷·부스터만 줍는다.",
    startWeapon: "pistol_semi",
    lootGuns: false,
    lootItems: true,
  },
  full: {
    id: "full",
    title: "합본",
    blurb: "단발 권총 시작. 총과 아이템을 같이 줍는다.",
    startWeapon: "pistol_semi",
    lootGuns: true,
    lootItems: true,
  },
};

export const UNIQUE_START: string[] = [
  "smg", "rifle", "pistol_semi", "pistol_auto",
  "smg", "rifle", "pistol_semi", "pistol_auto",
];
