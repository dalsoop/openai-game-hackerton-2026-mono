import type { NextConfig } from "next";
import createNextIntlPlugin from "next-intl/plugin";

const withNextIntl = createNextIntlPlugin("./i18n/request.ts");

const nextConfig: NextConfig = {
  output: "standalone",
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          {
            key: "X-Content-Type-Options",
            value: "nosniff",
          },
          {
            key: "X-Frame-Options",
            value: "DENY",
          },
        ],
      },
    ];
  },
  // Colyeus WebSocket을 위한 프록시 설정
  async rewrites() {
    return [
      {
        source: "/api/rooms",
        destination: process.env.GAME_SERVER_URL
          ? `${process.env.GAME_SERVER_URL}/api/rooms`
          : "http://127.0.0.1:9122/api/rooms",
      },
    ];
  },
  webpack: (config, { isServer }) => {
    // Colyeus SDK를 위한 웹팩 설정
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }
    return config;
  },
};

export default withNextIntl(nextConfig);
