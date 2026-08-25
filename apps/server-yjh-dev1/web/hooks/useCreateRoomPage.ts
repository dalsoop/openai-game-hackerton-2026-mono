"use client";
// /create 게이트 — 접속 전이거나 이미 방 안이면 홈으로 보낸다.
import { useCallback, useEffect } from "react";
import { useRouter } from "@/i18n/routing";
import { useGameFlowContext } from "@/hooks/GameFlowProvider";
import { useGameListings } from "@/hooks/useGameListings";
import type { GameListing } from "@/lib/games/listing";

export function useCreateRoomPage(): {
  ready: boolean;
  listings: GameListing[];
  onSubmit: (game: string, title: string) => void;
  onBack: () => void;
} {
  const flow = useGameFlowContext();
  const router = useRouter();
  const listings = useGameListings();
  const ready = flow.phase === "lobby" && flow.hub.status !== "connecting" && !flow.hub.resuming;

  useEffect(() => {
    if (flow.phase === "intro" || flow.hub.status === "offline") {
      router.replace("/");
      return;
    }
    if (flow.phase === "room" || flow.phase === "playing") {
      router.replace("/");
    }
  }, [flow.phase, flow.hub.status, router]);

  const onSubmit = useCallback((game: string, title: string): void => {
    flow.hub.createRoom({ game, title });
    router.push("/");
  }, [flow.hub, router]);

  const onBack = useCallback((): void => {
    router.push("/");
  }, [router]);

  return { ready, listings, onSubmit, onBack };
}
