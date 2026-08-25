import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "다굴 게임 플랫폼",
  description: "8인 배틀로얄 + Snake Arena + Hex Clash",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body style={{ margin: 0, background: "#0b0e14", color: "#e8e6e1", fontFamily: "system-ui, sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
