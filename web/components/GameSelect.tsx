"use client";
import Link from "next/link";

const games = [
  { id: "dagul", name: "다굴", desc: "8인 탑다운 배틀로얄", players: "1-8", color: "#d4a843" },
  { id: "snake", name: "Snake Arena", desc: "50인 멀티 뱀 게임", players: "1-50", color: "#1f9d55" },
  { id: "hex", name: "Hex Clash", desc: "6인 실시간 영토 전쟁", players: "1-6", color: "#2f6bff" },
];

const s = {
  grid: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))",
    gap: "1.25rem",
  } as const,
  card: {
    background: "#141820",
    border: "1px solid #252b38",
    borderRadius: 14,
    padding: "1.5rem",
    textDecoration: "none",
    color: "inherit",
    display: "block",
    transition: "transform 0.15s, box-shadow 0.15s",
  } as const,
  name: { fontSize: "1.4rem", fontWeight: 900, marginBottom: "0.5rem" } as const,
  desc: { color: "#7a8194", fontSize: "0.9rem" } as const,
  players: { color: "#555", fontSize: "0.8rem", marginTop: "0.5rem" } as const,
};

export default function GameSelect() {
  return (
    <div style={s.grid}>
      {games.map((g) => (
        <Link key={g.id} href={`/${g.id}`} style={s.card}>
          <div style={{ ...s.name, color: g.color }}>{g.name}</div>
          <div style={s.desc}>{g.desc}</div>
          <div style={s.players}>{g.players}명</div>
        </Link>
      ))}
    </div>
  );
}
