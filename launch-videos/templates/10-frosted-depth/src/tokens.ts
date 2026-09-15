import { Easing } from "remotion";
import tokens from "../../../assets/tokens.json";

export const color = tokens.color;
export const type = tokens.type;
export const radius = tokens.radius;
export const space = tokens.space;

export const FPS = tokens.video.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;
export const MARGIN = tokens.space.frameMargin1080p;

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;

export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
export const easeIn = Easing.in(Easing.cubic);

export const sec = (s: number) => Math.round(s * FPS);

export const fontSans = "Inter, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif";
export const fontMono = "'Geist Mono', 'SF Mono', Menlo, Consolas, monospace";

/** Glass surface: top-left light, shadow cast to the bottom-right. Consistent across every scene. */
export const glass = {
  bg: "rgba(255, 255, 255, 0.07)",
  bgFront: "rgba(255, 255, 255, 0.10)",
  border: "rgba(255, 255, 255, 0.16)",
  highlight: "rgba(255, 255, 255, 0.45)",
  blur: 36,
  shadow: "28px 40px 90px -24px rgba(0,0,0,0.65)",
  shadowFront: "36px 52px 110px -28px rgba(0,0,0,0.75)",
};
