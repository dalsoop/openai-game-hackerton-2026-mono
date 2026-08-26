import { defineRouting } from "next-intl/routing";
import { createNavigation } from "next-intl/navigation";

export const routing = defineRouting({
  // 로케일 목록
  locales: ["ko", "en"],
  // 기본 로케일
  defaultLocale: "ko",
  // 로케일 전략
  localePrefix: "as-needed",
});

// navigate() 메서드로 대체됩니다.
export const { Link, redirect, usePathname, useRouter, getPathname } =
  createNavigation(routing);
