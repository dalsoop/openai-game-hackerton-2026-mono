import { loadAllLocales } from "./i18n-util.sync.js";
import { i18nObject } from "./i18n-util.js";
import type { TranslationFunctions } from "./i18n-types.js";

loadAllLocales();

export const LL: TranslationFunctions = i18nObject("ko");
