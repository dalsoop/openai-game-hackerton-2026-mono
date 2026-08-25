"use client";
import { useHub } from "@/hooks/useHub";
import { useSession } from "@/hooks/useSession";
import NicknameInput from "@/components/NicknameInput";
import Lobby from "@/components/Lobby";
import Room from "@/components/Room";

export default function HexLobby() {
  const { nickname, saveNickname } = useSession();
  const hub = useHub("hex");

  function handleConnect(name: string) {
    saveNickname(name);
    hub.connect(name);
  }

  return (
    <main style={{ maxWidth: 700, margin: "0 auto", padding: "2rem 1.5rem" }}>
      <h1 style={{ color: "#2f6bff", fontSize: "1.8rem", marginBottom: "0.3rem" }}>Hex Clash</h1>
      <p style={{ color: "#7a8194", fontSize: "0.85rem", marginBottom: "1.5rem" }}>
        6인 실시간 영토 전쟁
      </p>

      {hub.status === "offline" && (
        <NicknameInput initial={nickname} onConfirm={handleConnect} />
      )}
      {hub.status === "connecting" && (
        <p style={{ color: "#c47b17" }}>서버에 연결하는 중입니다...</p>
      )}
      {hub.status === "lobby" && (
        <Lobby rooms={hub.rooms} onCreate={hub.createRoom} onJoin={hub.joinRoom} onRefresh={hub.refreshRooms} />
      )}
      {hub.status === "in-room" && (
        <Room players={hub.players} you={hub.you} isHost={hub.isHost} chatLog={hub.chatLog} onStart={hub.startMatch} onLeave={hub.leaveRoom} onChat={hub.sendChat} />
      )}
      {hub.status === "playing" && (
        <div style={{ textAlign: "center", padding: "3rem", color: "#2f6bff" }}>
          <h2>게임이 시작됩니다!</h2>
          <p style={{ color: "#7a8194" }}>Godot 엔진을 로딩합니다...</p>
        </div>
      )}
    </main>
  );
}
