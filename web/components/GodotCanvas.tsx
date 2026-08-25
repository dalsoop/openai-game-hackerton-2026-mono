"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { startGodotEngine, quitEngine } from "@/lib/godot/engine-loader";

export interface MatchInfo {
  roomId: string;
  name: string;
  slot: number;
  hubUrl?: string;
  gameUrl?: string;
}

interface GodotCanvasProps {
  game: string;
  matchInfo: MatchInfo;
  visible: boolean;
  onMatchEnd?: (detail: Record<string, unknown>) => void;
}

export default function GodotCanvas({
  game,
  matchInfo,
  visible,
  onMatchEnd,
}: GodotCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const engineRef = useRef<unknown>(null);
  const [booting, setBooting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const writeMatchInfo = useCallback((info: MatchInfo) => {
    try {
      localStorage.setItem("gangup_from_hub", "1");
      localStorage.setItem("gangup_name", info.name);
      localStorage.setItem("gangup_room_id", info.roomId);
      localStorage.setItem("gangup_you", String(info.slot));
      if (info.gameUrl) {
        localStorage.setItem("gangup_game_url", info.gameUrl);
      }
    } catch {
      // localStorage unavailable — continue without
    }
  }, []);

  useEffect(() => {
    if (!visible || !canvasRef.current || engineRef.current || booting) return;

    let cancelled = false;
    setBooting(true);
    setError(null);

    writeMatchInfo(matchInfo);

    startGodotEngine({ game, canvas: canvasRef.current })
      .then((eng) => {
        if (cancelled) {
          quitEngine(eng);
          return;
        }
        engineRef.current = eng;
        setBooting(false);
      })
      .catch((e) => {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : String(e));
          setBooting(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [visible, game, matchInfo, booting, writeMatchInfo]);

  useEffect(() => {
    if (!onMatchEnd) return;
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail || {};
      onMatchEnd(detail);
    };
    window.addEventListener("godot-match-end", handler);
    return () => window.removeEventListener("godot-match-end", handler);
  }, [onMatchEnd]);

  useEffect(() => {
    return () => {
      if (engineRef.current) {
        quitEngine(engineRef.current);
        engineRef.current = null;
      }
    };
  }, []);

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 100,
        display: visible ? "flex" : "none",
        alignItems: "center",
        justifyContent: "center",
        background: "#000",
      }}
    >
      <canvas
        ref={canvasRef}
        id="godot-canvas"
        style={{ width: "100%", height: "100%", display: "block" }}
        tabIndex={0}
      />
      {booting && (
        <div
          style={{
            position: "absolute",
            color: "#d4a843",
            fontSize: "1.2rem",
          }}
        >
          게임을 시작하는 중...
        </div>
      )}
      {error && (
        <div
          style={{
            position: "absolute",
            color: "#c0392b",
            fontSize: "1rem",
            textAlign: "center",
            padding: "1rem",
          }}
        >
          게임을 시작할 수 없습니다: {error}
        </div>
      )}
    </div>
  );
}
