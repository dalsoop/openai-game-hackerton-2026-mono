"use client";
import { useEffect, useState } from "react";
import { visibleCatalog } from "@/lib/games/catalog";
import { emptyListing, loadGameListing, type GameListing } from "@/lib/games/listing";

export function useGameListings(): GameListing[] {
  const [rows, setRows] = useState<GameListing[]>(() => visibleCatalog().map(emptyListing));

  useEffect(() => {
    let live = true;
    void Promise.all(visibleCatalog().map((g) => loadGameListing(g, fetch))).then((next) => {
      if (live) {setRows(next);}
    });
    return (): void => { live = false; };
  }, []);

  return rows;
}
