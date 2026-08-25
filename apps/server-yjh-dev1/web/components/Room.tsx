"use client";
import type { JSX } from "react";
import type { HubPlayer } from "@/types";
import { HUB_CONFIG } from "@/lib/hub/config";
import { useTranslations } from "next-intl";

interface Props {
  players: HubPlayer[];
  you: number;
  isHost: boolean;
  onStart: () => void;
  onLeave: () => void;
}

export default function Room({ players, you, isHost, onStart, onLeave }: Props): JSX.Element {
  const t = useTranslations("room");
  const slots = Array.from(
    { length: HUB_CONFIG.maxPlayers },
    (_, i) => players.find((p) => p.slot === i) ?? null,
  );

  return (
    <div className="fade-in">
      <header className="wait-head">
        <span className="wait-mode">{t("mode")}</span>
        <h1>{t("title")}</h1>
        <button className="ghost danger" onClick={onLeave}>
          {t("leaveButton")}
        </button>
      </header>

      <div className="slots">
        {slots.map((player, i) => {
          const filled = !!player;
          const isMe = i === you;
          const classes = [
            "slot-card",
            filled && "filled",
            isMe && "me",
          ]
            .filter(Boolean)
            .join(" ");
          return (
            // eslint-disable-next-line react/no-array-index-key -- 슬롯 인덱스가 곧 신원이다 (고정 좌석)
            <div key={i} className={classes}>
              {filled ? (
                <>
                  <div className={`slot-name c${i + 1}`}>
                    {player.host && <span className="slot-crown">👑 </span>}
                    {player.name}
                    {isMe ? ` (${t("me")})` : ""}
                  </div>
                  <div
                    className={`slot-tag ${
                      player.dropped ? "bad" : player.host ? "cyan" : "ok"
                    }`}
                  >
                    {player.dropped
                      ? t("waitingReconnect")
                      : player.host
                        ? t("host")
                        : t("waiting")}
                  </div>
                </>
              ) : (
                <div className="slot-cpu">{t("cpuAtStart")}</div>
              )}
            </div>
          );
        })}
      </div>

      <div className="wait-summary">
        {t("playerCount", { count: players.length, max: HUB_CONFIG.maxPlayers })}
      </div>

      <div className="host-bar">
        {isHost ? (
          <button className="cta block" onClick={onStart}>
            {t("startButton")}
          </button>
        ) : (
          <div className="host-wait">{t("waitingForHost")}</div>
        )}
      </div>
    </div>
  );
}
