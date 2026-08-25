import Link from "next/link";

const games = [
  { id: "dagul", name: "다굴", desc: "8인 탑다운 배틀로얄", players: "1-8", color: "#d4a843" },
  { id: "snake", name: "Snake Arena", desc: "50인 멀티 뱀 게임", players: "1-50", color: "#1f9d55" },
  { id: "hex", name: "Hex Clash", desc: "6인 실시간 영토 전쟁", players: "1-6", color: "#2f6bff" },
];

export default function Home() {
  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "3rem 1.5rem" }}>
      <h1 style={{ fontSize: "2.5rem", textAlign: "center", color: "#d4a843", marginBottom: "0.5rem" }}>
        다굴 게임 플랫폼
      </h1>
      <p style={{ textAlign: "center", color: "#7a8194", marginBottom: "2.5rem" }}>
        게임을 선택하세요
      </p>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "1.25rem" }}>
        {games.map((g) => (
          <Link key={g.id} href={`/${g.id}`} style={{ textDecoration: "none", color: "inherit" }}>
            <div style={{
              background: "#141820", border: "1px solid #252b38", borderRadius: 14,
              padding: "1.5rem", transition: "transform 0.15s",
            }}>
              <h2 style={{ fontSize: "1.4rem", color: g.color, marginBottom: "0.5rem" }}>{g.name}</h2>
              <p style={{ color: "#7a8194", fontSize: "0.9rem" }}>{g.desc}</p>
              <p style={{ color: "#555", fontSize: "0.8rem", marginTop: "0.5rem" }}>{g.players}명</p>
            </div>
          </Link>
        ))}
      </div>
    </main>
  );
}
