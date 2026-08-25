"use client";
import { useState } from "react";
import type { HubPlayer } from "@/hooks/useHub";

const SLOT_COLORS = [
  "#5bc0eb", "#9bc53d", "#e55934", "#fa7921",
  "#b084cc", "#70e7ff", "#ffd166", "#ff8dac",
];

const s = {
  wrap: { marginTop: "1.5rem" } as const,
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: "1rem",
  } as const,
  title: { fontSize: "1.1rem", fontWeight: 700, color: "#e8e6e1" } as const,
  grid: {
    display: "grid",
    gridTemplateColumns: "repeat(4, 1fr)",
    gap: "0.6rem",
    marginBottom: "1rem",
  } as const,
  slot: {
    background: "#141820",
    border: "1px solid #252b38",
    borderRadius: 10,
    padding: "0.8rem",
    textAlign: "center" as const,
    minHeight: 80,
  },
  slotName: { fontWeight: 600, fontSize: "0.9rem" } as const,
  slotLabel: { fontSize: "0.72rem", marginTop: "0.3rem" } as const,
  chatWrap: {
    background: "#141820",
    border: "1px solid #252b38",
    borderRadius: 10,
    padding: "0.8rem",
    maxHeight: 160,
    overflowY: "auto" as const,
    marginBottom: "0.8rem",
    fontSize: "0.85rem",
    color: "#7a8194",
  } as const,
  chatInput: {
    display: "flex",
    gap: "0.4rem",
    marginBottom: "1rem",
  } as const,
  input: {
    background: "#1a1f2a",
    border: "1px solid #252b38",
    borderRadius: 8,
    color: "#e8e6e1",
    padding: "0.5rem 0.8rem",
    fontSize: "0.85rem",
    flex: 1,
    outline: "none",
  } as const,
  btn: {
    background: "#2f6bff",
    color: "#fff",
    border: "none",
    borderRadius: 8,
    padding: "0.6rem 1.5rem",
    fontSize: "1rem",
    fontWeight: 700,
    cursor: "pointer",
    width: "100%",
  } as const,
  btnMuted: {
    background: "#1a1f2a",
    color: "#7a8194",
    border: "1px solid #252b38",
    borderRadius: 8,
    padding: "0.4rem 0.8rem",
    fontSize: "0.8rem",
    cursor: "pointer",
  } as const,
};

interface Props {
  players: HubPlayer[];
  you: number;
  isHost: boolean;
  chatLog: { from: string; slot: number; text: string }[];
  onStart: () => void;
  onLeave: () => void;
  onChat: (text: string) => void;
}

export default function Room({
  players,
  you,
  isHost,
  chatLog,
  onStart,
  onLeave,
  onChat,
}: Props) {
  const [chatText, setChatText] = useState("");

  function handleChat(e: React.FormEvent) {
    e.preventDefault();
    if (chatText.trim()) {
      onChat(chatText.trim());
      setChatText("");
    }
  }

  const slots = Array.from({ length: 8 }, (_, i) => {
    const player = players.find((p) => p.slot === i);
    return { index: i, player };
  });

  return (
    <div style={s.wrap}>
      <div style={s.header}>
        <span style={s.title}>대기실</span>
        <button style={s.btnMuted} onClick={onLeave}>
          나가기
        </button>
      </div>

      <div style={s.grid}>
        {slots.map(({ index, player }) => (
          <div
            key={index}
            style={{
              ...s.slot,
              borderColor: player ? SLOT_COLORS[index] : "#252b38",
            }}
          >
            <div style={{ ...s.slotName, color: player ? SLOT_COLORS[index] : "#555" }}>
              {player
                ? `${player.name}${index === you ? " (나)" : ""}`
                : "빈 자리"}
            </div>
            <div
              style={{
                ...s.slotLabel,
                color: player?.host
                  ? "#2f6bff"
                  : player?.dropped
                  ? "#c0392b"
                  : player
                  ? "#1f9d55"
                  : "#555",
              }}
            >
              {player?.host
                ? "호스트"
                : player?.dropped
                ? "재접속 대기"
                : player
                ? "대기 중"
                : "시작 시 CPU"}
            </div>
          </div>
        ))}
      </div>

      <div style={s.chatWrap}>
        {chatLog.length === 0 ? (
          <div>채팅이 여기에 표시됩니다.</div>
        ) : (
          chatLog.map((msg, i) => (
            <div key={i}>
              <span style={{ color: SLOT_COLORS[msg.slot] || "#7a8194", fontWeight: 600 }}>
                {msg.from}
              </span>
              : {msg.text}
            </div>
          ))
        )}
      </div>

      <form onSubmit={handleChat} style={s.chatInput}>
        <input
          style={s.input}
          value={chatText}
          onChange={(e) => setChatText(e.target.value)}
          placeholder="메시지 입력..."
          maxLength={200}
        />
        <button type="submit" style={s.btnMuted}>
          전송
        </button>
      </form>

      {isHost ? (
        <button style={s.btn} onClick={onStart}>
          게임 시작
        </button>
      ) : (
        <div style={{ textAlign: "center", color: "#7a8194", padding: "0.5rem" }}>
          호스트가 게임을 시작할 때까지 기다리세요.
        </div>
      )}
    </div>
  );
}
