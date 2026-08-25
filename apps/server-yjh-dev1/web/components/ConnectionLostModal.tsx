"use client";
/**
 * 재접속 모달 — 튕김·강퇴·오프라인 때 회색 캔버스 대신 이 대화상자가 소유권을 갖는다.
 */
import type { ReactNode } from "react";
import { useTranslations } from "next-intl";
import { Button, Modal } from "@/components/ui";
import type { DropReason } from "@/lib/game-flow-state";

interface ConnectionLostModalProps {
  reason: DropReason;
  onReconnect: () => void;
  onExit: () => void;
}

export function ConnectionLostModal({ reason, onReconnect, onExit }: ConnectionLostModalProps): ReactNode {
  const t = useTranslations();
  const titleKey =
    reason === "kicked" ? "game.kickedTitle" : reason === "dropped" ? "game.droppedTitle" : "game.serverConnectFailed";
  const bodyKey =
    reason === "kicked" ? "game.kickedBody" : reason === "dropped" ? "game.droppedBody" : "connection.offline";

  return (
    <Modal tone="error">
      <h2 className="modal-title">{t(titleKey)}</h2>
      <p className="modal-body">{t(bodyKey)}</p>
      <div className="modal-actions">
        <Button variant="primary" onClick={onReconnect} autoFocus>
          {t("game.reconnect")}
        </Button>
        <Button variant="ghost" onClick={onExit}>
          {t("game.back")}
        </Button>
      </div>
    </Modal>
  );
}
