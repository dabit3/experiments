import { Easing } from "remotion";
import tokensJson from "../../../assets/tokens.json";

export const tokens = tokensJson;
export const color = tokens.color;
export const radius = tokens.radius;
export const shadow = tokens.shadow;
export const type = tokens.type;

export const FRAME_MARGIN = tokens.space.frameMargin1080p;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;
export const FPS = tokens.video.fps;

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;

export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
export const easeIn = Easing.bezier(0.7, 0, 0.84, 0);

export const fontSans = "Inter, -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif";
export const fontMono = "'Geist Mono', 'SF Mono', Menlo, Consolas, monospace";
