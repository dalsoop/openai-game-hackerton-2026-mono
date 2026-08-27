export const ENCODING_SUFFIXES: readonly string[];
export function encodingIsCurrent(rawMtimeMs: number | null, encodedMtimeMs: number): boolean;
export function rawNameFromEncoded(name: string): string | null;
export function shouldPublishEncoding(
  rawMtimeMs: number | null,
  encodedMtimeMs: number | null,
): boolean;
export function staleEncodingReason(dir: string, name: string): "missing" | "orphan" | "stale" | null;
export function listStaleEncodings(dir: string): string[];
export function dropStaleEncodings(dir: string): string[];
export function shouldCopyName(dir: string, name: string): boolean;
