"use client";
// 방 만들기 전용 페이지 — 로비 목록과 화면을 섞지 않는다.
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { CONNECTION_CLASS } from "@/types";
import { useGameFlowContext } from "@/hooks/GameFlowProvider";
import { useCreateRoomPage } from "@/hooks/useCreateRoomPage";
import CreateRoom from "@/components/CreateRoom";
import { DeployReloadBanner } from "@/components/DeployReloadBanner";

export default function CreatePage(): JSX.Element {
  const t = useTranslations();
  const { hub, deployStale, reloadDeploy } = useGameFlowContext();
  const { ready, listings, onSubmit, onBack } = useCreateRoomPage();

  return (
    <div className="page-shell">
      <header className="hero">
        <div className="logo-word">{t("logo.word")}</div>
        <div className={CONNECTION_CLASS[hub.status]}>
          <span className="conn-dot" />
          <span className="conn-txt">
            {hub.status === "connecting" ? t("connection.connecting") : t("connection.connected")}
          </span>
        </div>
      </header>
      <DeployReloadBanner visible={deployStale} onReload={reloadDeploy} />
      {ready ? <CreateRoom listings={listings} onSubmit={onSubmit} onBack={onBack} /> : null}
    </div>
  );
}
