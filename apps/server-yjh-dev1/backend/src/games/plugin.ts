export interface ModeDef {
  id: string;
  titleKey: string;
  blurbKey: string;
}

export interface RelayConfig {
  snapRelay: boolean;
  inputRelay: boolean;
  gameServerNotify: boolean;
}

export interface GamePlugin {
  id: string;
  titleKey: string;
  maxPlayers: number;
  godotPath: string;
  defaultMode: string;
  modes: Record<string, ModeDef>;
  relay: RelayConfig;
}
