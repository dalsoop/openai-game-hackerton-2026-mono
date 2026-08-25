"use client";

interface LoadingBarProps {
  progress: number;
  bytesLoaded: number;
  bytesTotal: number;
  label?: string;
}

function formatMB(bytes: number): string {
  return (bytes / (1024 * 1024)).toFixed(1);
}

export default function LoadingBar({
  progress,
  bytesLoaded,
  bytesTotal,
  label = "게임 에셋 로딩 중",
}: LoadingBarProps) {
  const pct = Math.min(100, Math.round(progress * 100));
  return (
    <div style={{ padding: "0.75rem 0" }}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          fontSize: "0.8rem",
          color: "#7a8194",
          marginBottom: "0.35rem",
        }}
      >
        <span>{label}</span>
        <span>
          {formatMB(bytesLoaded)} / {bytesTotal > 0 ? formatMB(bytesTotal) : "?"} MB ({pct}%)
        </span>
      </div>
      <div
        style={{
          height: 6,
          background: "#252b38",
          borderRadius: 3,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            width: `${pct}%`,
            height: "100%",
            background: "#d4a843",
            borderRadius: 3,
            transition: "width 0.2s ease",
          }}
        />
      </div>
    </div>
  );
}
