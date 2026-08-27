import type { Metadata, Viewport } from "next";
import type { JSX } from "react";
import { NextIntlClientProvider } from "next-intl";
import { getMessages, getTranslations, setRequestLocale } from "next-intl/server";
import { notFound } from "next/navigation";
import { routing } from "@/i18n/routing";
import { GameFlowProvider } from "@/hooks/GameFlowProvider";
import "../globals.css";

export function generateStaticParams(): Array<{ locale: string }> {
  return routing.locales.map((locale) => ({ locale }));
}

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

const OG_IMAGE = "/og.webp";

function metadataBaseUrl(): URL {
  const slot = (process.env.SLOT_FOLDER ?? "dagul-prod").trim() || "dagul-prod";
  return new URL(`https://${slot}.external.kr`);
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "app" });
  const title = t("title");
  const description = t("description");
  return {
    metadataBase: metadataBaseUrl(),
    title,
    description,
    openGraph: {
      title,
      description,
      type: "website",
      locale,
      images: [{ url: OG_IMAGE, width: 1200, height: 675, alt: title }],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [OG_IMAGE],
    },
  };
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}): Promise<JSX.Element> {
  const { locale } = await params;

  // 로케일 유효성 확인
  if (!routing.locales.includes(locale as (typeof routing.locales)[number])) {
    notFound();
  }

  setRequestLocale(locale);

  // 메시지 로드
  const messages = await getMessages();

  return (
    <NextIntlClientProvider locale={locale} messages={messages}>
      <html lang={locale} suppressHydrationWarning>
        <head>
          {/* eslint-disable-next-line @next/next/no-page-custom-font -- App Router 에는 _document 가 없다 */}
          <link
            rel="stylesheet"
            href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0&display=block"
          />
        </head>
        <body suppressHydrationWarning>
          <GameFlowProvider>{children}</GameFlowProvider>
        </body>
      </html>
    </NextIntlClientProvider>
  );
}
