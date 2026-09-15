import { HEIGHT, WIDTH } from "./tokens";

/** Screenshots are ~2990x1624 (2x retina), aspect ≈ 1.842. */
export const SCREEN_ASPECT = 2990 / 1624;

export const WINDOW_W = 1400;
export const CONTENT_H = Math.round(WINDOW_W / SCREEN_ASPECT); // 760
export const TITLEBAR_H = 44;
export const WINDOW_H = CONTENT_H + TITLEBAR_H; // 804
export const WINDOW_X = (WIDTH - WINDOW_W) / 2; // 260
export const WINDOW_Y = 96;

/** Caption band sits under the window. */
export const CAPTION_TOP = WINDOW_Y + WINDOW_H + 30;
export const CAPTION_H = HEIGHT - CAPTION_TOP - 24;

/**
 * The captures have rounded bottom corners, so they are drawn 3% larger than
 * the content area (cropping the edges). All positions in scenes are given as
 * fractions of the *screenshot*; `sx`/`sy` map them into content space.
 */
export const OVERSCAN = 1.03;
export const sx = (x: number) => 0.5 + (x - 0.5) * OVERSCAN;
export const sy = (y: number) => y * OVERSCAN;

/** Zoom target: scale plus the screenshot-fraction point to zoom toward. */
export type Zoom = { scale: number; x: number; y: number };
export const NO_ZOOM: Zoom = { scale: 1, x: 0.5, y: 0.5 };
