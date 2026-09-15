import { Easing } from "remotion";
import tokens from "../../../assets/tokens.json";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geist = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const FONT_SANS = `${inter.fontFamily}, ${tokens.type.display}`;
export const FONT_MONO = `${geist.fontFamily}, ${tokens.type.mono}`;

export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;
export const FPS = tokens.video.fps;

export const color = tokens.color;
export const type = tokens.type;
export const radius = tokens.radius;
export const space = tokens.space;

/** Blueprint palette: dark drafting sheet, accent ink for every drawn line. */
export const bp = {
  sheet: color.darkBg,
  gridMinor: "rgba(255,255,255,0.045)",
  gridMajor: "rgba(255,255,255,0.09)",
  line: color.accent,
  lineSoft: "rgba(34, 0, 255, 0.45)",
  lineBright: "#6E5CFF",
  text: color.white,
  textDim: color.gray400,
  textFaint: color.gray500,
  frameBorder: color.darkBorder,
};

const [ox1, oy1, ox2, oy2] = tokens.motion.easeOut;
const [ix1, iy1, ix2, iy2] = tokens.motion.easeInOut;
export const easeOut = Easing.bezier(ox1, oy1, ox2, oy2);
export const easeInOut = Easing.bezier(ix1, iy1, ix2, iy2);
export const easeIn = Easing.bezier(0.7, 0, 0.84, 0);

export const ms = (m: number) => Math.round((m / 1000) * FPS);
export const DUR = {
  fast: ms(tokens.motion.durationMs.fast),
  base: ms(tokens.motion.durationMs.base),
  slow: ms(tokens.motion.durationMs.slow),
  hold: ms(tokens.motion.durationMs.hold),
  draw: ms(400),
};

export const MARGIN = space.frameMargin1080p;
export const SAFE = space.safeAreaInset1080p;
