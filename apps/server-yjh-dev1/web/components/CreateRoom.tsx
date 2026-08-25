"use client";
// 방 만들기 — 목록에서 게임을 고르면 썸네일·설명이 열린다. 값은 비제어 폼.
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { DEFAULT_GAME_ID } from "@/lib/games/catalog";
import { sizeParts, type GameListing } from "@/lib/games/listing";
import { HUB_CONFIG } from "@/lib/hub/config";
import { Button } from "@/components/ui";

interface Props {
  listings: ReadonlyArray<GameListing>;
  onSubmit: (game: string, title: string) => void;
  onBack: () => void;
}

export default function CreateRoom({ listings, onSubmit, onBack }: Props): JSX.Element {
  const t = useTranslations("create");
  const games = useTranslations();

  return (
    <div className="fade-in">
      <div className="back-row">
        <Button variant="ghost" size="sm" onClick={onBack}>
          ← {t("cancel")}
        </Button>
      </div>

      <h1 className="create-heading">{t("title")}</h1>
      <p className="create-blurb">{t("blurb")}</p>

      <form
        className="create-form"
        onSubmit={(e) => {
          e.preventDefault();
          const data = new FormData(e.currentTarget);
          onSubmit(String(data.get("game") ?? DEFAULT_GAME_ID), String(data.get("title") ?? ""));
        }}
      >
        <fieldset className="create-fieldset">
          <legend className="sec-title">{t("gameSelect")}</legend>
          <div className="game-list">
            {listings.map((g) => (
              <label key={g.id} className="game-card">
                <input
                  type="radio"
                  name="game"
                  value={g.id}
                  defaultChecked={g.id === DEFAULT_GAME_ID}
                />
                <div className="game-card-art">
                  {/* eslint-disable-next-line @next/next/no-img-element -- 카탈로그 정적 썸네일 */}
                  <img src={g.thumbSrc} alt={games(g.titleKey)} />
                </div>
                <div className="game-card-body">
                  <div className="game-row-head">
                    <b>{games(g.titleKey)}</b>
                    <span className="mode-check" aria-hidden="true" />
                  </div>
                  <p>{games(g.blurbKey)}</p>
                  <span className="game-meta">
                    {t("meta", {
                      version: g.version ?? t("versionUnknown"),
                      size: sizeLabel(t, g.bytes),
                    })}
                  </span>
                </div>
              </label>
            ))}
          </div>
        </fieldset>

        <label className="create-field">
          <span className="sec-title">{t("roomTitle")}</span>
          <input
            className="name-input"
            type="text"
            name="title"
            maxLength={HUB_CONFIG.maxTitleLength}
            placeholder={t("roomTitlePlaceholder")}
            autoComplete="off"
          />
        </label>

        <button className="cta block" type="submit">
          {t("submit")}
        </button>
      </form>
    </div>
  );
}

function sizeLabel(t: (key: "sizeUnknown" | "sizeB" | "sizeKb" | "sizeMb", values?: { amount: string }) => string, bytes: number | null): string {
  if (bytes === null) {return t("sizeUnknown");}
  const { amount, unit } = sizeParts(bytes);
  if (unit === "b") {return t("sizeB", { amount });}
  if (unit === "kb") {return t("sizeKb", { amount });}
  return t("sizeMb", { amount });
}
