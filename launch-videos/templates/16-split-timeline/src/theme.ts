import { Easing } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import tokens from "../../../assets/tokens.json";

const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const color = tokens.color;
export const radius = tokens.radius;
export const shadow = tokens.shadow;
export const sizes = tokens.type.sizes1080p;
export const tracking = tokens.type.tracking;
export const leading = tokens.type.leading;
export const weight = tokens.type.weights;

export const font = {
  sans: `${inter.fontFamily}, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`,
  mono: `${geistMono.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`,
};

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;
export const ease = {
  out: Easing.bezier(o1, o2, o3, o4),
  inOut: Easing.bezier(i1, i2, i3, i4),
  in: Easing.bezier(0.7, 0, 0.84, 0),
};

export const FPS = tokens.video.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;
export const MARGIN = tokens.space.frameMargin1080p;

/** Split layout geometry (px at 1080p). */
export const layout = {
  timelineY: 84,
  panelLabelY: 176,
  contentTop: 240,
  contentBottom: HEIGHT - MARGIN,
  dividerX: 800,
  left: { x: MARGIN, w: 800 - 80 - MARGIN },
  right: { x: 880, w: WIDTH - MARGIN - 880 },
  figure: { w: WIDTH - MARGIN - 880, h: 500 },
};

export const secondsToFrames = (s: number) => Math.round(s * FPS);
