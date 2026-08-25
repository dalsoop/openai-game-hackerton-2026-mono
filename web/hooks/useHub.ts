"use client";
import { useCallback, useEffect, useRef, useState } from "react";

export interface HubRoom {
  id: string;
  title: string;
  players: number;
  mode: string;
  playing: boolean;
}

export interface HubPlayer {
  slot: number;
  name: string;
  host?: boolean;
  dropped?: boolean;
}

interface HubState {
  status: "offline" | "connecting" | "lobby" | "in-room" | "playing";
  rooms: HubRoom[];
  players: HubPlayer[];
  you: number;
  roomId: string;
  isHost: boolean;
  chatLog: { from: string; slot: number; text: string }[];
}

export function useHub(game: string) {
  const wsRef = useRef<WebSocket | null>(null);
  const [state, setState] = useState<HubState>({
    status: "offline",
    rooms: [],
    players: [],
    you: -1,
    roomId: "",
    isHost: false,
    chatLog: [],
  });
  const [matchInfo, setMatchInfo] = useState<{
    you: number;
    room: Record<string, unknown>;
    host: boolean;
  } | null>(null);

  const send = useCallback((msg: Record<string, unknown>) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(msg));
    }
  }, []);

  const connect = useCallback((name: string) => {
    if (wsRef.current) wsRef.current.close();
    const proto = location.protocol === "https:" ? "wss" : "ws";
    const url = `${proto}://${location.host}/api/ws/${game}`;
    const ws = new WebSocket(url);
    wsRef.current = ws;
    setState((s) => ({ ...s, status: "connecting" }));

    ws.onopen = () => {
      send({ t: "hello", name, mode: "full" });
      send({ t: "rooms" });
      setState((s) => ({ ...s, status: "lobby" }));
    };

    ws.onclose = () => {
      setState((s) => ({ ...s, status: "offline" }));
    };

    ws.onmessage = (ev) => {
      const msg = JSON.parse(ev.data);
      const t = msg.t as string;

      if (t === "rooms") {
        setState((s) => ({ ...s, rooms: msg.rooms || [] }));
      } else if (t === "joined") {
        setState((s) => ({
          ...s,
          status: "in-room",
          you: msg.you ?? 0,
          roomId: msg.room?.id ?? "",
          isHost: msg.you === 0,
          players: msg.players || [],
          chatLog: [],
        }));
      } else if (t === "peers") {
        setState((s) => ({ ...s, players: msg.players || [] }));
      } else if (t === "start") {
        const info = {
          you: msg.you ?? 0,
          room: msg.room ?? {},
          host: !!msg.host,
        };
        setMatchInfo(info);
        setState((s) => ({ ...s, status: "playing" }));
      } else if (t === "left") {
        setState((s) => ({
          ...s,
          status: "lobby",
          roomId: "",
          players: [],
          chatLog: [],
        }));
        send({ t: "rooms" });
      } else if (t === "chat") {
        setState((s) => ({
          ...s,
          chatLog: [
            ...s.chatLog.slice(-49),
            { from: msg.from ?? "?", slot: msg.slot ?? -1, text: msg.text ?? "" },
          ],
        }));
      }
    };
  }, [game, send]);

  const createRoom = useCallback(() => send({ t: "create" }), [send]);
  const joinRoom = useCallback((id: string) => send({ t: "join", roomId: id }), [send]);
  const leaveRoom = useCallback(() => send({ t: "leave" }), [send]);
  const startMatch = useCallback(() => send({ t: "start" }), [send]);
  const refreshRooms = useCallback(() => send({ t: "rooms" }), [send]);
  const sendChat = useCallback((text: string) => send({ t: "chat", text }), [send]);

  useEffect(() => {
    return () => { wsRef.current?.close(); };
  }, []);

  return {
    ...state,
    matchInfo,
    connect,
    createRoom,
    joinRoom,
    leaveRoom,
    startMatch,
    refreshRooms,
    sendChat,
  };
}
