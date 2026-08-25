"use client";
import type { HubRoom } from "@/hooks/useHub";

const s = {
  wrap: { marginTop: "1.5rem" } as const,
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: "1rem",
  } as const,
  title: { fontSize: "1.1rem", fontWeight: 700, color: "#e8e6e1" } as const,
  row: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    background: "#141820",
    border: "1px solid #252b38",
    borderRadius: 10,
    padding: "0.8rem 1rem",
    marginBottom: "0.5rem",
    cursor: "pointer",
    transition: "background 0.12s",
  } as const,
  roomName: { fontWeight: 600, color: "#e8e6e1" } as const,
  roomMeta: { fontSize: "0.82rem", color: "#7a8194" } as const,
  btn: {
    background: "#2f6bff",
    color: "#fff",
    border: "none",
    borderRadius: 8,
    padding: "0.5rem 1rem",
    fontSize: "0.85rem",
    fontWeight: 700,
    cursor: "pointer",
  } as const,
  btnGreen: {
    background: "#1f9d55",
    color: "#fff",
    border: "none",
    borderRadius: 8,
    padding: "0.5rem 1rem",
    fontSize: "0.85rem",
    fontWeight: 700,
    cursor: "pointer",
  } as const,
  btnMuted: {
    background: "#1a1f2a",
    color: "#7a8194",
    border: "1px solid #252b38",
    borderRadius: 8,
    padding: "0.5rem 1rem",
    fontSize: "0.85rem",
    cursor: "pointer",
  } as const,
  empty: { color: "#7a8194", textAlign: "center" as const, padding: "2rem" },
};

interface Props {
  rooms: HubRoom[];
  onCreate: () => void;
  onJoin: (id: string) => void;
  onRefresh: () => void;
}

export default function Lobby({ rooms, onCreate, onJoin, onRefresh }: Props) {
  return (
    <div style={s.wrap}>
      <div style={s.header}>
        <span style={s.title}>방 목록</span>
        <div style={{ display: "flex", gap: "0.5rem" }}>
          <button style={s.btnMuted} onClick={onRefresh}>
            새로고침
          </button>
          <button style={s.btnGreen} onClick={onCreate}>
            방 만들기
          </button>
        </div>
      </div>

      {rooms.length === 0 ? (
        <div style={s.empty}>열린 방이 없습니다. 방을 만들어 시작하세요!</div>
      ) : (
        rooms.map((room) => (
          <div
            key={room.id}
            style={s.row}
            onClick={() => !room.playing && onJoin(room.id)}
          >
            <div>
              <div style={s.roomName}>{room.title || `방 ${room.id.slice(0, 6)}`}</div>
              <div style={s.roomMeta}>
                {room.players}/8명 · {room.playing ? "게임 중" : "대기 중"}
              </div>
            </div>
            {room.playing ? (
              <button style={s.btnMuted} onClick={(e) => { e.stopPropagation(); onJoin(room.id); }}>
                관전
              </button>
            ) : (
              <button style={s.btn} onClick={(e) => { e.stopPropagation(); onJoin(room.id); }}>
                참가
              </button>
            )}
          </div>
        ))
      )}
    </div>
  );
}
