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

/** 래퍼 크기. 시트는 이 칸 안에서만 보이게 자른다. */
export function portraitFrameStyle(size: number): CSSProperties {
  return { width: size, height: size };
}

/** img 배치. 단일 초상은 contain, 시트는 칸 크기만큼 밀어 맞춘다. */
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
    width: cols * size,
    height: rows * size,
    maxWidth: "none",
    marginLeft: -(col * size),
    marginTop: -(row * size),
    imageRendering: "pixelated",
  };
}

/** 배경-이미지 방식. 기존 호출부 호환. */
export function portraitStyle(portrait: CharacterPortrait, size: number): CSSProperties {
  return {
    ...portraitFrameStyle(size),
    overflow: "hidden",
  };
}
