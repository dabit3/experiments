import { space } from "./tokens";

/** Shared geometry for the feature scenes so every card sits on the same grid. */
export const CARD = {
  width: 1400,
  height: 740,
  x: (1920 - 1400) / 2,
  y: 280,
} as const;

/** Headline centre line for feature scenes (sits between the top frame margin and the card). */
export const FEATURE_HEADLINE_Y = (space.frameMargin1080p + CARD.y) / 2 - 35;
