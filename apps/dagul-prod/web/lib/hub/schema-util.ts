import type { ArraySchema, Schema } from "@colyseus/schema";

export function syncLen<T extends Schema>(arr: ArraySchema<T>, n: number, make: () => T): void {
  while (arr.length > n) {arr.pop();}
  while (arr.length < n) {arr.push(make());}
}
