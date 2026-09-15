import tokens from "../../../assets/tokens.json";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";

const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geist = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const color = tokens.color;
export const radius = tokens.radius;
export const shadow = tokens.shadow;
export const space = tokens.space;
export const type = tokens.type;

export const font = {
  sans: `${inter.fontFamily}, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif`,
  mono: `${geist.fontFamily}, 'SF Mono', Menlo, Consolas, monospace`,
};

/** Sampled from the real Devin CLI window (assets/screens/devin-cli-*.png) so the
 *  React-drawn chrome and the screenshot crops are seamless. */
export const terminal = {
  bg: "#080808",
  margin: space.frameMargin1080p,
  width: tokens.video.width - space.frameMargin1080p * 2,
  height: tokens.video.height - space.frameMargin1080p * 2,
  titleBar: 44,
  padX: 40,
  padY: 32,
  fontSize: 24,
  lineHeight: 40,
};

export const easeOut = tokens.motion.easeOut as [number, number, number, number];
export const easeInOut = tokens.motion.easeInOut as [number, number, number, number];
/** ease-in for exits: the mirror of easeOut. */
export const easeIn: [number, number, number, number] = [0.7, 0, 0.84, 0];

export const VIDEO = tokens.video;
