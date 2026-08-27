import { existsSync, readdirSync, statSync, unlinkSync } from "fs";
import path from "path";

export const ENCODING_SUFFIXES = [".br", ".gz"];

/** Serve 와 publish 가 같이 쓰는 판정. 원본이 없으면 압축본을 허용한다. */
export function encodingIsCurrent(rawMtimeMs, encodedMtimeMs) {
  if (rawMtimeMs == null) {return true;}
  return encodedMtimeMs >= rawMtimeMs;
}

export function rawNameFromEncoded(name) {
  for (const suffix of ENCODING_SUFFIXES) {
    if (name.endsWith(suffix)) {return name.slice(0, -suffix.length);}
  }
  return null;
}

function mtimeMs(file) {
  try {
    const st = statSync(file);
    return st.isFile() ? st.mtimeMs : null;
  } catch {
    return null;
  }
}

/** 원본이 없거나(고아) 원본보다 오래되면 발행하지 않는다. */
export function shouldPublishEncoding(rawMtimeMs, encodedMtimeMs) {
  if (encodedMtimeMs == null || rawMtimeMs == null) {return false;}
  return encodingIsCurrent(rawMtimeMs, encodedMtimeMs);
}

export function staleEncodingReason(dir, name) {
  const raw = rawNameFromEncoded(name);
  if (raw === null) {return null;}
  const encMtime = mtimeMs(path.join(dir, name));
  if (encMtime == null) {return "missing";}
  const rawMtime = mtimeMs(path.join(dir, raw));
  if (rawMtime == null) {return "orphan";}
  if (!encodingIsCurrent(rawMtime, encMtime)) {return "stale";}
  return null;
}

export function listStaleEncodings(dir) {
  if (!existsSync(dir)) {return [];}
  return readdirSync(dir).filter((name) => staleEncodingReason(dir, name) !== null);
}

export function dropStaleEncodings(dir) {
  const stale = listStaleEncodings(dir);
  for (const name of stale) {unlinkSync(path.join(dir, name));}
  return stale;
}

export function shouldCopyName(dir, name) {
  const file = path.join(dir, name);
  if (!existsSync(file)) {return false;}
  if (rawNameFromEncoded(name) === null) {return true;}
  return staleEncodingReason(dir, name) === null;
}
