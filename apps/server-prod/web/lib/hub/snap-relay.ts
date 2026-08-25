export function snapUnchanged(
  prev: Record<string, unknown> | null,
  next: Record<string, unknown>,
): boolean {
  if (!prev) {return false;}
  return JSON.stringify(prev) === JSON.stringify(next);
}

export function snapByteLength(data: Record<string, unknown>): number {
  return Buffer.byteLength(JSON.stringify(data), "utf8");
}

export function shouldRelaySnap(
  prev: Record<string, unknown> | null,
  next: Record<string, unknown>,
  maxBytes: number,
): boolean {
  if (snapUnchanged(prev, next)) {return false;}
  return snapByteLength(next) <= maxBytes;
}
