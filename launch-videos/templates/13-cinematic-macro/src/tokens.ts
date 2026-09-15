import { Easing } from "remotion";
import raw from "../../../assets/tokens.json";

export const tokens = raw;

const [o1, o2, o3, o4] = tokens.motion.easeOut;
const [i1, i2, i3, i4] = tokens.motion.easeInOut;

export const easeOut = Easing.bezier(o1, o2, o3, o4);
export const easeInOut = Easing.bezier(i1, i2, i3, i4);
// Ease-in for exits: mirror of the ease-out curve.
export const easeIn = Easing.bezier(1 - o3, 1 - o4, 1 - o1, 1 - o2);

export const FPS = tokens.video.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;

// 2.39:1 letterbox inside the 16:9 frame.
export const PICTURE_HEIGHT = Math.round(WIDTH / 2.39); // 803
export const BAR_HEIGHT = Math.round((HEIGHT - PICTURE_HEIGHT) / 2); // 138 / 139
export const PICTURE_TOP = BAR_HEIGHT;
export const PICTURE_BOTTOM = BAR_HEIGHT + PICTURE_HEIGHT;

export const FRAME_MARGIN = tokens.space.frameMargin1080p;
