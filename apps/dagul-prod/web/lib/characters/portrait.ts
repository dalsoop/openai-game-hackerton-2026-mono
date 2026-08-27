import type { CSSProperties } from "react";
import type { CharacterPortrait } from "./types";

function sheetCell(portrait: CharacterPortrait): { cols: number; rows: number; col: number; row: number } {
  const cols = Math.max(1, portrait.cols ?? 1);
  const rows = Math.max(1, portrait.rows ?? 1);
  const index = portrait.index ?? 0;
  return {
    cols,
    rows,
    col: index % cols,
    row: Math.floor(index / cols),
  };
}

/** 래퍼 크기. 시트는 이 칸 안에서만 보이게 자른다. overflow 는 인라인 — 클래스만 믿으면 시트가 그대로 샌다. */
export function portraitFrameStyle(size: number): CSSProperties {
  return {
    width: size,
    height: size,
    overflow: "hidden",
    position: "relative",
    minWidth: 0,
    minHeight: 0,
    flexShrink: 0,
    display: "inline-block",
  };
}

/** img 배치. 단일 초상은 contain, 시트는 칸 크기만큼 절대 위치로 민다. */
export function portraitImageStyle(portrait: CharacterPortrait, size: number): CSSProperties {
  const { cols, rows, col, row } = sheetCell(portrait);
  if (cols === 1 && rows === 1) {
    return {
      width: size,
      height: size,
      objectFit: "contain",
      imageRendering: "pixelated",
    };
  }
  return {
    position: "absolute",
    left: col === 0 ? 0 : -(col * size),
    top: row === 0 ? 0 : -(row * size),
    width: cols * size,
    height: rows * size,
    maxWidth: "none",
    imageRendering: "pixelated",
  };
}

/** 프레임 호환. overflow 는 portraitFrameStyle 에 있다. */
export function portraitStyle(_portrait: CharacterPortrait, size: number): CSSProperties {
  return portraitFrameStyle(size);
}
