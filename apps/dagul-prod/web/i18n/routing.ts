import { defineRouting } from "next-intl/routing";
import { createNavigation } from "next-intl/navigation";
import { DEFAULT_LOCALE, LOCALES } from "./locales";

export const routing = defineRouting({
  locales: LOCALES,
  defaultLocale: DEFAULT_LOCALE,
  localePrefix: "as-needed",
});

// navigate() 메서드로 대체됩니다.
export const { Link, redirect, usePathname, useRouter, getPathname } =
  createNavigation(routing);
