/**
 * 히어로 `item` 문자열 와이어 SSOT.
 * 스키마는 string 만 싣는다. 개수 문법은 여기만 정한다.
 * '' | kind | `${kind}:${count}` — count 1 은 접미사 없음(하위호환).
 */
export type ItemStack = { kind: string; count: number };

export const EMPTY_ITEM_STACK: ItemStack = { kind: "", count: 0 };

export const ITEM_WIRE_CASES: readonly { kind: string; count: number; wire: string }[] = [
  { kind: "medkit", count: 0, wire: "" },
  { kind: "medkit", count: 1, wire: "medkit" },
  { kind: "medkit", count: 2, wire: "medkit:2" },
  { kind: "medkit", count: 3, wire: "medkit:3" },
  { kind: "spring", count: 1, wire: "spring" },
  { kind: "pull", count: 2, wire: "pull:2" },
];

export function packItemStack(kind: string, count: number): string {
  const id = kind.trim();
  if (id === "" || count <= 0) {return "";}
  if (count === 1) {return id;}
  return `${id}:${count}`;
}

export function unpackItemStack(raw: string): ItemStack {
  const wire = raw.trim();
  if (wire === "") {return { ...EMPTY_ITEM_STACK };}
  const sep = wire.indexOf(":");
  if (sep < 0) {return { kind: wire, count: 1 };}
  const kind = wire.slice(0, sep);
  const n = Number.parseInt(wire.slice(sep + 1), 10);
  if (kind === "" || !Number.isFinite(n) || n <= 0) {return { kind, count: 0 };}
  return { kind, count: n };
}

/** full/classic 메드킷 스택 — packItemStack("medkit", n) 별칭. */
export function packItemField(medkits: number): string {
  return packItemStack("medkit", medkits);
}

export function unpackMedkits(raw: string): number {
  const stack = unpackItemStack(raw);
  return stack.kind === "medkit" ? stack.count : 0;
}
