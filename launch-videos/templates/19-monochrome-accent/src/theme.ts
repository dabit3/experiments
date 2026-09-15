import { Easing } from "remotion";
import tokens from "../../../assets/tokens.json";

export const color = {
  black: tokens.color.black,
  ink: tokens.color.ink,
  white: tokens.color.white,
  paper: tokens.color.paper,
  gray500: tokens.color.gray500,
  gray400: tokens.color.gray400,
  gray300: tokens.color.gray300,
  darkBg: tokens.color.darkBg,
  darkBorder: tokens.color.darkBorder,
  border: tokens.color.border,
  accent: tokens.color.accent,
};

export const size = tokens.type.sizes1080p;
export const tracking = tokens.type.tracking;
export const radius = tokens.radius;
export const shadow = tokens.shadow;
export const MARGIN = tokens.space.frameMargin1080p;

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;
export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
export const easeIn = Easing.bezier(0.7, 0, 0.84, 0);

export const FPS = tokens.video.fps;
export const sec = (s: number) => Math.round(s * FPS);

export type Palette = { bg: string; fg: string; muted: string; rule: string };
export const light: Palette = {
  bg: color.white,
  fg: color.ink,
  muted: color.gray500,
  rule: color.border,
};
export const dark: Palette = {
  bg: color.darkBg,
  fg: color.white,
  muted: color.gray400,
  rule: color.darkBorder,
};
