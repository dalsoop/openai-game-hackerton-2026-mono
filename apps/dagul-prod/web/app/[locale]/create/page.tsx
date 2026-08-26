"use client";
// 방 만들기 전용 페이지 — 로비 목록과 화면을 섞지 않는다.
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { CONNECTION_CLASS } from "@/types";
import { useGameFlowContext } from "@/hooks/GameFlowProvider";
import { useCreateRoomPage } from "@/hooks/useCreateRoomPage";
import { ConnectingPhase } from "@/components/phases";
import CreateRoom from "@/components/CreateRoom";

export default function CreatePage(): JSX.Element {
  const t = useTranslations();
  const { hub } = useGameFlowContext();
  const { ready, creating, listings, onSubmit, onBack } = useCreateRoomPage();

  return (
    <div className="page-shell">
      {creating ? (
        <ConnectingPhase message={t("create.pending")} />
      ) : ready ? (
        <CreateRoom
          listings={listings}
          onSubmit={onSubmit}
          onBack={onBack}
          connClass={CONNECTION_CLASS[hub.status]}
          connText={hub.status === "connecting" ? t("connection.connecting") : t("connection.connected")}
        />
      ) : null}
    </div>
  );
}
