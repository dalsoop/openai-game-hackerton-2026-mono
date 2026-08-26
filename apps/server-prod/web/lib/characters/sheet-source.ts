import type { CharacterDescriptor, CharacterPortrait, CharacterSource } from "./types";

export interface CharacterEntryData {
  readonly id: string;
  readonly titleKey: string;
  readonly portrait: CharacterPortrait;
  readonly binds?: Readonly<Record<string, number | string>>;
}

export interface CharacterSheetData {
  readonly src: string;
  readonly cols: number;
  readonly rows: number;
  readonly idPrefix: string;
  readonly titleKeyPrefix: string;
  readonly indexBind?: string;
}

export interface CharacterCatalogData {
  readonly defaultId: string;
  readonly entries?: readonly CharacterEntryData[];
  readonly sheets?: readonly CharacterSheetData[];
}

function expandSheet(sheet: CharacterSheetData): CharacterDescriptor[] {
  const count = Math.max(0, sheet.cols) * Math.max(0, sheet.rows);
  const out: CharacterDescriptor[] = [];
  for (let index = 0; index < count; index++) {
    const id = `${sheet.idPrefix}${index}`;
    const binds = sheet.indexBind ? { [sheet.indexBind]: index } : undefined;
    out.push({
      id,
      titleKey: `${sheet.titleKeyPrefix}${index}`,
      portrait: { src: sheet.src, cols: sheet.cols, rows: sheet.rows, index },
      binds,
    });
  }
  return out;
}

export class CharacterSheetSource implements CharacterSource {
  constructor(private readonly data: CharacterCatalogData) {}

  load(): readonly CharacterDescriptor[] {
    const fromEntries = [...(this.data.entries ?? [])];
    const fromSheets = (this.data.sheets ?? []).flatMap(expandSheet);
    return [...fromEntries, ...fromSheets];
  }

  defaultId(): string {
    return this.data.defaultId;
  }
}
