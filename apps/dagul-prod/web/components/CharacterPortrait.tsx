"use client";
import type { JSX } from "react";
import { findCharacter, asCharacterId, portraitFrameStyle, portraitImageStyle } from "@/lib/characters";

interface Props {
  characterId: string;
  size: number;
  title?: string;
}

export default function CharacterPortrait({ characterId, size, title }: Props): JSX.Element {
  const item = findCharacter(asCharacterId(characterId));
  if (!item) {
    return (
      <span
        className="char-portrait"
        // eslint-disable-next-line react/forbid-dom-props -- 초상 칸 크기
        style={portraitFrameStyle(size)}
      />
    );
  }
  return (
    <span
      className="char-portrait"
      title={title}
      // eslint-disable-next-line react/forbid-dom-props -- 초상 칸 크기는 카탈로그가 정한다
      style={portraitFrameStyle(size)}
    >
      {/* eslint-disable-next-line @next/next/no-img-element -- 시트 좌표 잘라 쓰는 초상 */}
      <img
        src={item.portrait.src}
        alt={title ?? ""}
        // eslint-disable-next-line react/forbid-dom-props -- 시트 한 칸 위치는 카탈로그가 정한다
        style={portraitImageStyle(item.portrait, size)}
      />
    </span>
  );
}
