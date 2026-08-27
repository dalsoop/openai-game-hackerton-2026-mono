const DYLINK = Buffer.from("dylink");

/** Godot dlink 웹 템플릿은 wasm 선두 custom section 이름이 dylink 다.
 * nothreads 정식 템플릿은 type section 부터 시작하고 dylink 가 없다. */
export function wasmHasDylinkSection(bytes) {
  if (!bytes || bytes.length < 16) {return false;}
  const head = bytes.length > 64 ? bytes.subarray(0, 64) : bytes;
  return Buffer.from(head).includes(DYLINK);
}
