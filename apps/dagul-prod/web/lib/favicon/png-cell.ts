import { crc32, deflateSync, inflateSync } from "node:zlib";
import type { FaviconCell, FaviconSheet } from "./catalog.js";

const PNG_SIG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const BPP = 4;

type PngChunk = { type: string; data: Buffer };

function readChunks(png: Buffer): PngChunk[] {
  if (png.subarray(0, 8).compare(PNG_SIG) !== 0) {throw new Error("png-sig");}
  const chunks: PngChunk[] = [];
  let offset = 8;
  while (offset + 8 <= png.length) {
    const length = png.readUInt32BE(offset);
    const type = png.subarray(offset + 4, offset + 8).toString("ascii");
    const data = png.subarray(offset + 8, offset + 8 + length);
    chunks.push({ type, data });
    if (type === "IEND") {break;}
    offset += 12 + length;
  }
  return chunks;
}

function paeth(a: number, b: number, c: number): number {
  const p = a + b - c;
  const pa = Math.abs(p - a);
  const pb = Math.abs(p - b);
  const pc = Math.abs(p - c);
  if (pa <= pb && pa <= pc) {return a;}
  if (pb <= pc) {return b;}
  return c;
}

function unfilter(raw: Buffer, width: number, height: number): Buffer {
  const stride = width * BPP;
  const out = Buffer.alloc(stride * height);
  let src = 0;
  let prev = Buffer.alloc(stride);
  for (let y = 0; y < height; y += 1) {
    const filter = raw[src];
    src += 1;
    const row = raw.subarray(src, src + stride);
    src += stride;
    const dest = Buffer.alloc(stride);
    for (let i = 0; i < stride; i += 1) {
      const left = i >= BPP ? dest[i - BPP] : 0;
      const up = prev[i];
      const upLeft = i >= BPP ? prev[i - BPP] : 0;
      dest[i] = (row[i] + recon(filter, left, up, upLeft)) & 255;
    }
    dest.copy(out, y * stride);
    prev = dest;
  }
  return out;
}

function recon(filter: number, left: number, up: number, upLeft: number): number {
  if (filter === 1) {return left;}
  if (filter === 2) {return up;}
  if (filter === 3) {return (left + up) >> 1;}
  if (filter === 4) {return paeth(left, up, upLeft);}
  return 0;
}

function copyCell(rgba: Buffer, sheet: FaviconSheet, cell: FaviconCell): Buffer {
  const size = cell.size;
  const out = Buffer.alloc(size * size * BPP);
  const srcStride = sheet.pixelWidth * BPP;
  const originX = cell.col * size;
  const originY = cell.row * size;
  for (let y = 0; y < size; y += 1) {
    const src = (originY + y) * srcStride + originX * BPP;
    rgba.copy(out, y * size * BPP, src, src + size * BPP);
  }
  return out;
}

function encodePng(rgba: Buffer, size: number): Buffer {
  const stride = size * BPP;
  const raw = Buffer.alloc((stride + 1) * size);
  for (let y = 0; y < size; y += 1) {
    raw[y * (stride + 1)] = 0;
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  return Buffer.concat([PNG_SIG, chunk("IHDR", ihdr), chunk("IDAT", deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]);
}

function chunk(type: string, data: Buffer): Buffer {
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  body.copy(out, 4);
  out.writeUInt32BE(crc32(body) >>> 0, 8 + data.length);
  return out;
}

export function pngRgba(png: Buffer): { width: number; height: number; rgba: Buffer } {
  const chunks = readChunks(png);
  const ihdr = chunks.find((c) => c.type === "IHDR");
  if (!ihdr) {throw new Error("png-ihdr");}
  const width = ihdr.data.readUInt32BE(0);
  const height = ihdr.data.readUInt32BE(4);
  if (ihdr.data[8] !== 8 || ihdr.data[9] !== 6 || ihdr.data[12] !== 0) {throw new Error("png-rgba");}
  const idat = Buffer.concat(chunks.filter((c) => c.type === "IDAT").map((c) => c.data));
  return { width, height, rgba: unfilter(inflateSync(idat), width, height) };
}

export function cropPngCell(png: Buffer, sheet: FaviconSheet, cell: FaviconCell): Buffer {
  const decoded = pngRgba(png);
  if (decoded.width !== sheet.pixelWidth || decoded.height !== sheet.pixelHeight) {throw new Error("png-size");}
  return encodePng(copyCell(decoded.rgba, sheet, cell), cell.size);
}
