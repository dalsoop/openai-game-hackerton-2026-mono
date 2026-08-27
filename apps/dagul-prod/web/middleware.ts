import createMiddleware from "next-intl/middleware";
import { routing } from "./i18n/routing";

export default createMiddleware(routing);

export const config = {
  // 페이지 경로만. .wasm·.js 같은 확장자 요청은 로케일 미들웨어를 타지 않는다.
  matcher: [
    "/",
    "/((?!api|_next|_vercel|health|healthz|ccu|metrics|rooms|matchmake|godot|addons|icon|apple-icon|favicon.ico|.*\\..*).*)",
  ],
};
