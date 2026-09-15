import { Easing } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import { loadFont as loadCaveat } from "@remotion/google-fonts/Caveat";
import tokens from "../../../assets/tokens.json";

const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });
const caveat = loadCaveat("normal", { weights: ["500", "600"], subsets: ["latin"] });

export const color = tokens.color;
export const radius = tokens.radius;
export const shadow = tokens.shadow;
export const space = tokens.space;
export const type = tokens.type;

export const font = {
  sans: `${inter.fontFamily}, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`,
  mono: `${geistMono.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`,
  hand: `${caveat.fontFamily}, 'Comic Sans MS', cursive`,
};

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;

export const ease = {
  out: Easing.bezier(o1, o2, o3, o4),
  inOut: Easing.bezier(i1, i2, i3, i4),
  in: Easing.bezier(0.7, 0, 0.84, 0),
};

export const FPS = tokens.motion.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;
export const MARGIN = tokens.space.frameMargin1080p;

export const sec = (s: number) => Math.round(s * FPS);
