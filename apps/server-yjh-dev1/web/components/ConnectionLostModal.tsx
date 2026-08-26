"use client";
/**
 * 끊김·강퇴·유휴 안내 — 회색 캔버스 대신 이 대화상자가 소유권을 갖는다.
 * 다시 들어가기는 canOfferReconnect 일 때만 보인다.
 */
import type { ReactNode } from "react";
import { useTranslations } from "next-intl";
import { Button, Modal } from "@/components/ui";
import { canOfferReconnect, type DropReason } from "@/lib/hub/room-end";

interface ConnectionLostModalProps {
  reason: DropReason;
  onReconnect: () => void;
  onExit: () => void;
}

const TITLE: Record<DropReason, string> = {
  kicked: "game.kickedTitle",
  dropped: "game.droppedTitle",
  idle: "game.idleTitle",
  offline: "game.serverConnectFailed",
};

const BODY: Record<DropReason, string> = {
  kicked: "game.kickedBody",
  dropped: "game.droppedBody",
  idle: "game.idleBody",
  offline: "connection.offline",
};

export function ConnectionLostModal({ reason, onReconnect, onExit }: ConnectionLostModalProps): ReactNode {
  const t = useTranslations();
  const offer = canOfferReconnect(reason);

  return (
    <Modal tone="error">
      <h2 className="modal-title">{t(TITLE[reason])}</h2>
      <p className="modal-body">{t(BODY[reason])}</p>
      <div className="modal-actions">
        {offer ? (
          <Button variant="primary" onClick={onReconnect} autoFocus>
            {t("game.reconnect")}
          </Button>
        ) : null}
        <Button variant="ghost" onClick={onExit} autoFocus={!offer}>
          {t("game.back")}
        </Button>
      </div>
    </Modal>
  );
}
