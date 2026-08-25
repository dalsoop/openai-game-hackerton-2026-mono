"use client";
import { useEffect, useState } from "react";
import { GAME_CATALOG } from "@/lib/games/catalog";
import { emptyListing, loadGameListing, type GameListing } from "@/lib/games/listing";

export function useGameListings(): GameListing[] {
  const [rows, setRows] = useState<GameListing[]>(() => GAME_CATALOG.map(emptyListing));

  useEffect(() => {
    let live = true;
    void Promise.all(GAME_CATALOG.map((g) => loadGameListing(g, fetch))).then((next) => {
      if (live) {setRows(next);}
    });
    return (): void => { live = false; };
  }, []);

  return rows;
}
