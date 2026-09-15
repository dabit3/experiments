import { HEIGHT, MARGIN, WIDTH } from "./theme";

/** Shared two-column layout: narration left, printed sheet right. */
export const TEXT_X = MARGIN;
export const TEXT_W = 680;
export const PAPER_X = 820;
export const PAPER_W = WIDTH - MARGIN - PAPER_X; // 980
export const PAPER_PAD = 28;
export const FIG_W = PAPER_W - PAPER_PAD * 2; // 924

/** Vertical centre for a sheet of the given figure height (caption row included). */
export const paperY = (figureHeight: number) => {
  const captionRow = 18 + 16;
  const total = PAPER_PAD * 2 + figureHeight + captionRow;
  return Math.round((HEIGHT - total) / 2);
};

export const TEXT_Y = 400;

/** Full sheet height (padding + figure + caption row). */
export const paperHeight = (figureHeight: number) => PAPER_PAD * 2 + figureHeight + 18 + 16;
