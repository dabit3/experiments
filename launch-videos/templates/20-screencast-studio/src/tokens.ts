import tokens from "../../../assets/tokens.json";

export const color = tokens.color;
export const radius = tokens.radius;
export const shadow = tokens.shadow;
export const type = tokens.type;
export const space = tokens.space;
export const motion = tokens.motion;

export const EASE_OUT = motion.easeOut as [number, number, number, number];
export const EASE_IN_OUT = motion.easeInOut as [number, number, number, number];
export const EASE_IN: [number, number, number, number] = [0.7, 0, 0.84, 0];

export const FPS = tokens.video.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;
export const FRAME_MARGIN = space.frameMargin1080p;
