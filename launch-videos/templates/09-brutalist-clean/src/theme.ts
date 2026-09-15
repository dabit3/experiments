import { Easing } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import tokens from "../../../assets/tokens.json";

const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const mono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const fontsReady = Promise.all([inter.waitUntilDone(), mono.waitUntilDone()]);

export const color = tokens.color;
export const radius = tokens.radius;

export const font = {
  sans: `${inter.fontFamily}, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`,
  mono: `${mono.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`,
  weight: tokens.type.weights,
  tracking: tokens.type.tracking,
  leading: tokens.type.leading,
  size: tokens.type.sizes1080p,
};

export const space = {
  margin: tokens.space.frameMargin1080p,
  safe: tokens.space.safeAreaInset1080p,
  unit: tokens.space.unit,
};

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;

export const ease = {
  out: Easing.bezier(o1, o2, o3, o4),
  inOut: Easing.bezier(i1, i2, i3, i4),
  // mirror of the ease-out curve, for exits
  in: Easing.bezier(1 - o3, 1 - o4, 1 - o1, 1 - o2),
};

export const FPS = tokens.video.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;

export const sec = (s: number) => Math.round(s * FPS);

/** Brutalist frame constants */
export const RULE = 4; // thick black rule
export const FRAME_BORDER = 14; // screenshot frame border
export const TICKER_HEIGHT = 64;
