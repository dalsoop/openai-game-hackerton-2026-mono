import { KO } from "./messages.js";

export const MAX_PLAYERS = 8;
export const TICK_HZ = 20;
export const ARENA = { w: 7840, h: 4760, cx: 3920, cy: 2380, radius: 3500 } as const;

export interface ModeDef {
  id: string;
  title: string;
  blurb: string;
  startWeapon: string;
  lootGuns: boolean;
  lootItems: boolean;
}

export const MODES: Record<string, ModeDef> = {
  classic: {
    id: "classic",
    title: KO.MODE_CLASSIC,
    blurb: KO.MODE_CLASSIC_BLURB,
    startWeapon: "unique",
    lootGuns: false,
    lootItems: false,
  },
  "gun-semi": {
    id: "gun-semi",
    title: KO.MODE_GUN_SEMI,
    blurb: KO.MODE_GUN_SEMI_BLURB,
    startWeapon: "pistol_semi",
    lootGuns: true,
    lootItems: false,
  },
  "gun-auto": {
    id: "gun-auto",
    title: KO.MODE_GUN_AUTO,
    blurb: KO.MODE_GUN_AUTO_BLURB,
    startWeapon: "pistol_auto",
    lootGuns: true,
    lootItems: false,
  },
  item: {
    id: "item",
    title: KO.MODE_ITEM,
    blurb: KO.MODE_ITEM_BLURB,
    startWeapon: "pistol_semi",
    lootGuns: false,
    lootItems: true,
  },
  full: {
    id: "full",
    title: KO.MODE_FULL,
    blurb: KO.MODE_FULL_BLURB,
    startWeapon: "pistol_semi",
    lootGuns: true,
    lootItems: true,
  },
};
