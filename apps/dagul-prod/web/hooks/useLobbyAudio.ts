"use client";
import { useEffect, useRef } from "react";
import { lobbyBgmOn } from "@/lib/game-flow-state";
import { unlockGodotAudio } from "@/lib/godot/unlock-audio";
import { playMedia } from "@/lib/ui-sfx";
import type { GamePhase } from "@/types";

const LOBBY_SRC = "/assets/lobby.ogg";
const CLICK_SRC = "/assets/ui_click.wav";
const BGM_VOL = 0.55;
const CLICK_VOL = 0.55;

let liveBgm: HTMLAudioElement | null = null;
let holdOff = false;

/** 대기실에서 매치 시작을 누른 즉시 로비 BGM을 끊는다. 인게임 클릭이 다시 켜지 않는다. */
export function holdLobbyBgmOff(): void {
  holdOff = true;
  liveBgm?.pause();
}

function wantLobbyBgm(phase: GamePhase): boolean {
  if (phase === "intro") {
    holdOff = false;
    return true;
  }
  return lobbyBgmOn(phase) && !holdOff;
}

/** 로비 BGM + 버튼 클릭. 매치가 시작되면 멈추고 Godot 오디오 잠금을 푼다. */
export function useLobbyAudio(phase: GamePhase): void {
  const bgmRef = useRef<HTMLAudioElement | null>(null);
  const clickRef = useRef<HTMLAudioElement | null>(null);
  const wantBgmRef = useRef(wantLobbyBgm(phase));

  useEffect(() => {
    wantBgmRef.current = wantLobbyBgm(phase);
  }, [phase]);

  useEffect(() => {
    const bgm = new Audio(LOBBY_SRC);
    bgm.loop = true;
    bgm.volume = BGM_VOL;
    const click = new Audio(CLICK_SRC);
    click.volume = CLICK_VOL;
    bgmRef.current = bgm;
    liveBgm = bgm;
    clickRef.current = click;
    const tryPlay = (): void => {
      if (holdOff || !wantBgmRef.current) {return;}
      playMedia(bgm);
    };
    const onGesture = (): void => {
      unlockGodotAudio();
      tryPlay();
    };
    const onClick = (ev: Event): void => {
      const t = ev.target as HTMLElement | null;
      if (!t?.closest) {return;}
      if (!t.closest("button, a, [role=button]")) {return;}
      if (t.closest("[data-sfx=ok]")) {return;}
      click.currentTime = 0;
      playMedia(click);
    };
    window.addEventListener("pointerdown", onGesture, true);
    window.addEventListener("mousedown", onGesture, true);
    window.addEventListener("touchstart", onGesture, true);
    window.addEventListener("keydown", onGesture, true);
    document.addEventListener("click", onClick, true);
    tryPlay();
    return (): void => {
      window.removeEventListener("pointerdown", onGesture, true);
      window.removeEventListener("mousedown", onGesture, true);
      window.removeEventListener("touchstart", onGesture, true);
      window.removeEventListener("keydown", onGesture, true);
      document.removeEventListener("click", onClick, true);
      bgm.pause();
      bgmRef.current = null;
      if (liveBgm === bgm) {liveBgm = null;}
      clickRef.current = null;
    };
  }, []);

  useEffect(() => {
    const bgm = bgmRef.current;
    if (!bgm) {return;}
    if (wantLobbyBgm(phase)) {
      void bgm.play().catch(() => { /* 제스처 전 */ });
      return;
    }
    bgm.pause();
  }, [phase]);
}
