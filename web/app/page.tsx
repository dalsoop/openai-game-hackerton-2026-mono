import GameSelect from "@/components/GameSelect";

export default function Home() {
  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "3rem 1.5rem" }}>
      <h1 style={{ fontSize: "2.5rem", textAlign: "center", color: "#d4a843", marginBottom: "0.5rem" }}>
        다굴 게임 플랫폼
      </h1>
      <p style={{ textAlign: "center", color: "#7a8194", marginBottom: "2.5rem" }}>
        게임을 선택하세요
      </p>
      <GameSelect />
    </main>
  );
}
