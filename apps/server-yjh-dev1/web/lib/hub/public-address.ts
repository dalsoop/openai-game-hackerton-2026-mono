/** Colyseus publicAddress — 프로토콜 없이 host/path. */
export function hubPublicAddress(prefix?: string, pod?: string): string | undefined {
  const host = prefix?.trim() ?? "";
  const name = pod?.trim() ?? "";
  if (!host || !name) {return undefined;}
  return `${host}/${name}`;
}
