"use client";
// /create 게이트 — 접속 전이거나 이미 방 안이면 홈으로 보낸다.
// 제출 후 홈으로 먼저 가면 로비가 한 프레임 깜빡인다. 방이 생길 때까지 여기서 기다린다.
import { useCallback, useEffect } from "react";
import { useRouter } from "@/i18n/routing";
import { useGameFlowContext } from "@/hooks/GameFlowProvider";
import { useGameListings } from "@/hooks/useGameListings";
import { createSurface } from "@/lib/game-flow-state";
import type { GameListing } from "@/lib/games/listing";

export function useCreateRoomPage(): {
  ready: boolean;
  creating: boolean;
  listings: GameListing[];
  onSubmit: (game: string, title: string) => void;
  onBack: () => void;
} {
  const flow = useGameFlowContext();
  const router = useRouter();
  const listings = useGameListings();
  const surface = createSurface(
    flow.phase,
    flow.hub.status,
    flow.hub.joiningKind,
    flow.hub.resuming,
  );
  const creating = surface === "pending";
  const ready = surface === "form";

  useEffect(() => {
    if (surface === "redirect") {router.replace("/");}
  }, [surface, router]);

  const onSubmit = useCallback((game: string, title: string): void => {
    flow.hub.createRoom({ game, title });
  }, [flow.hub]);

  const onBack = useCallback((): void => {
    router.push("/");
  }, [router]);

  return { ready, creating, listings, onSubmit, onBack };
}
