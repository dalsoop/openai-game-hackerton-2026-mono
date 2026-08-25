"use client";
import { useEffect } from "react";
import { useHub } from "@/hooks/useHub";
import { useSession } from "@/hooks/useSession";
import { useGodotLoader } from "@/hooks/useGodotLoader";
import NicknameInput from "@/components/NicknameInput";
import Lobby from "@/components/Lobby";
import Room from "@/components/Room";
import AssetStatus from "@/components/AssetStatus";
import GodotCanvas from "@/components/GodotCanvas";

export default function DagulLobby() {
  const { nickname, saveNickname } = useSession();
  const hub = useHub("dagul");
  const loader = useGodotLoader("dagul");

  useEffect(() => {
    if (hub.status === "lobby" || hub.status === "in-room") {
      loader.start();
    }
  }, [hub.status]);

  function handleConnect(name: string) {
    saveNickname(name);
    hub.connect(name);
  }

  function handleStart() {
    if (loader.state !== "ready") return;
    hub.startMatch();
  }

  return (
    <main style={{ maxWidth: 700, margin: "0 auto", padding: "2rem 1.5rem" }}>
      <h1 style={{ color: "#d4a843", fontSize: "1.8rem", marginBottom: "0.3rem" }}>다굴</h1>
      <p style={{ color: "#7a8194", fontSize: "0.85rem", marginBottom: "1.5rem" }}>
        8인 탑다운 배틀로얄
      </p>

      {hub.status === "offline" && (
        <NicknameInput initial={nickname} onConfirm={handleConnect} />
      )}

      {hub.status === "connecting" && (
        <p style={{ color: "#c47b17" }}>서버에 연결하는 중입니다...</p>
      )}

      {hub.status === "lobby" && (
        <>
          <Lobby
            rooms={hub.rooms}
            onCreate={hub.createRoom}
            onJoin={hub.joinRoom}
            onRefresh={hub.refreshRooms}
          />
          <AssetStatus {...loader} />
        </>
      )}

      {hub.status === "in-room" && (
        <>
          <Room
            players={hub.players}
            you={hub.you}
            isHost={hub.isHost}
            chatLog={hub.chatLog}
            onStart={handleStart}
            onLeave={hub.leaveRoom}
            onChat={hub.sendChat}
          />
          <AssetStatus {...loader} />
          {hub.isHost && loader.state !== "ready" && (
            <p style={{ color: "#c47b17", fontSize: "0.85rem", textAlign: "center", marginTop: "0.5rem" }}>
              게임 에셋을 받는 중입니다. 완료되면 시작할 수 있습니다.
            </p>
          )}
        </>
      )}

      <GodotCanvas
        visible={hub.status === "playing"}
        game="dagul"
        matchInfo={{
          roomId: hub.roomId,
          name: nickname,
          slot: hub.you,
          hubUrl: "",
        }}
        onMatchEnd={() => hub.leaveRoom()}
      />
    </main>
  );
}
