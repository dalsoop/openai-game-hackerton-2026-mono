import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { koreanZodiacFavicon } from "./catalog.js";
import { cropPngCell } from "./png-cell.js";

export const size = { width: 256, height: 256 };
export const contentType = "image/png";
export const runtime = "nodejs";

export async function zodiacFaviconResponse(instant = new Date()): Promise<Response> {
  const spec = koreanZodiacFavicon.at(instant);
  const file = await readFile(join(process.cwd(), "public", "characters", "animals.png"));
  const png = cropPngCell(file, spec.sheet, spec.cell);
  return new Response(new Uint8Array(png), {
    headers: {
      "content-type": "image/png",
      "cache-control": "public, max-age=3600",
    },
  });
}

export default function Icon(): Promise<Response> {
  return zodiacFaviconResponse();
}
