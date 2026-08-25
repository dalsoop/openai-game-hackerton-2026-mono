"use client";
// 방 만들기 화면 — 유즈맵 고르기 + 방 이름. 값은 비제어 폼으로만 읽는다.
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { GAME_CATALOG, DEFAULT_GAME_ID } from "@/lib/games/catalog";
import { HUB_CONFIG } from "@/lib/hub/config";
import { Button } from "@/components/ui";

interface Props {
  onSubmit: (game: string, title: string) => void;
  onBack: () => void;
}

export default function CreateRoom({ onSubmit, onBack }: Props): JSX.Element {
  const t = useTranslations("create");
  const lobby = useTranslations("lobby");

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
          <div className="modes">
            {GAME_CATALOG.map((g) => (
              <label key={g.id} className="mode-card">
                <input
                  type="radio"
                  name="game"
                  value={g.id}
                  defaultChecked={g.id === DEFAULT_GAME_ID}
                />
                <b>{lobby(g.titleKey)}</b>
                <span className="mode-check" aria-hidden="true" />
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
