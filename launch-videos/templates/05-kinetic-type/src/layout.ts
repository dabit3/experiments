import type { Layout, MediaSlot, Typography } from "./schema";
import { HEIGHT, WIDTH } from "./defaults";

export type Rect = { x: number; y: number; w: number; h: number };

/** Approximate advance width of Inter Medium per character, in em. */
const CHAR_EM = 0.54;
export const LINE_HEIGHT = 1.12;
const CAPTION_BLOCK_H = 130;
const COLUMN_W = 460;
const COLUMN_GAP = 64;
const PHRASE_PAD = 64;
const INDEX_H = 28;

export const mediaAspect = (m: MediaSlot) => {
  const crop = m.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  return (crop.w * m.naturalWidth) / (crop.h * m.naturalHeight);
};

const contain = (region: Rect, aspect: number, anchor: "start" | "center") => {
  let w = region.w;
  let h = w / aspect;
  if (h > region.h) {
    h = region.h;
    w = h * aspect;
  }
  const x = anchor === "center" ? region.x + (region.w - w) / 2 : region.x;
  const y = region.y + (region.h - h) / 2;
  return { x, y, w, h };
};

export type PhraseFit = {
  captionSize: number;
  phraseSize: number;
  /** Width of the caption block; the phrase is this block scaled by `scale`. */
  width: number;
  scale: number;
  lines: number;
  blockHeight: number;
};

export const estimateLines = (text: string, size: number, width: number) => {
  const perLine = Math.max(1, Math.floor(width / (size * CHAR_EM)));
  const words = text.split(" ");
  let lines = 1;
  let used = 0;
  for (const word of words) {
    const len = word.length + (used === 0 ? 0 : 1);
    if (used + len > perLine && used > 0) {
      lines += 1;
      used = word.length;
    } else {
      used += len;
    }
  }
  return lines;
};

/**
 * Picks caption/phrase sizes so the phrase (caption block x scale) fits inside
 * `rect` with padding, and the caption fits `captionWidth`. Line breaks are
 * identical in both states because the phrase is the caption block scaled.
 */
export const fitPhrase = (
  text: string,
  rect: Rect,
  captionWidth: number,
  typography: Typography,
): PhraseFit => {
  let captionSize = typography.captionSize;
  let phraseSize = typography.phraseSize;
  const scale = phraseSize / captionSize;
  const maxPhraseW = rect.w - PHRASE_PAD * 2;
  const maxPhraseH = rect.h - PHRASE_PAD * 2;
  const width = Math.min(captionWidth, maxPhraseW / scale);
  for (let i = 0; i < 12; i++) {
    const lines = estimateLines(text, captionSize, width);
    const blockHeight = lines * captionSize * LINE_HEIGHT;
    if ((lines <= 5 && blockHeight * scale <= maxPhraseH) || captionSize <= 20) {
      return { captionSize, phraseSize, width, scale, lines, blockHeight };
    }
    captionSize *= 0.92;
    phraseSize *= 0.92;
  }
  const lines = estimateLines(text, captionSize, width);
  return {
    captionSize,
    phraseSize,
    width,
    scale,
    lines,
    blockHeight: lines * captionSize * LINE_HEIGHT,
  };
};

export type BeatGeometry = {
  media: Rect;
  /** Top-left of the caption block once settled. */
  caption: { x: number; y: number };
  /** Top-left of the index label. */
  index: { x: number; y: number };
  /** Top-left of the phrase block while it stands alone (before scaling). */
  phrase: { x: number; y: number };
  fit: PhraseFit;
};

export const beatGeometry = (
  layout: Layout,
  aspect: number,
  text: string,
  typography: Typography,
): BeatGeometry => {
  const m = typography.margin;
  const safe: Rect = { x: m, y: m, w: WIDTH - 2 * m, h: HEIGHT - 2 * m };

  if (layout === "top" || layout === "bottom") {
    const region: Rect = {
      x: safe.x,
      y: layout === "top" ? safe.y + CAPTION_BLOCK_H : safe.y,
      w: safe.w,
      h: safe.h - CAPTION_BLOCK_H,
    };
    const media = contain(region, aspect, "center");
    const fit = fitPhrase(text, media, safe.w, typography);
    const indexY = layout === "top" ? safe.y : safe.y + safe.h - CAPTION_BLOCK_H + 40;
    return {
      media,
      index: { x: safe.x, y: indexY },
      caption: { x: safe.x, y: indexY + INDEX_H },
      phrase: phrasePosition(media, fit),
      fit,
    };
  }

  const regionW = safe.w - COLUMN_W - COLUMN_GAP;
  const media0 = contain({ x: 0, y: safe.y, w: regionW, h: safe.h }, aspect, "start");
  const groupW = media0.w + COLUMN_GAP + COLUMN_W;
  const groupX = safe.x + (safe.w - groupW) / 2;
  const mediaX = layout === "left" ? groupX + COLUMN_W + COLUMN_GAP : groupX;
  const columnX = layout === "left" ? groupX : groupX + media0.w + COLUMN_GAP;
  const media = { ...media0, x: mediaX };
  const fit = fitPhrase(text, media, COLUMN_W, typography);
  return {
    media,
    index: { x: columnX, y: media.y },
    caption: { x: columnX, y: media.y + INDEX_H },
    phrase: phrasePosition(media, fit),
    fit,
  };
};

const phrasePosition = (media: Rect, fit: PhraseFit) => {
  const w = fit.width * fit.scale;
  const h = fit.blockHeight * fit.scale;
  return { x: media.x + (media.w - w) / 2, y: media.y + (media.h - h) / 2 };
};
