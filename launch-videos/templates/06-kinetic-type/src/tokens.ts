import tokens from "../../../assets/tokens.json";

export const color = tokens.color;
export const type = tokens.type;
export const radius = tokens.radius;
export const space = tokens.space;
export const motion = tokens.motion;

export const FPS = tokens.video.fps;
export const WIDTH = tokens.video.width;
export const HEIGHT = tokens.video.height;

/** 120 BPM → one beat every half second. */
export const BPM = 120;
export const BEAT = Math.round((FPS * 60) / BPM); // 15 frames
export const beats = (n: number): number => Math.round(n * BEAT);

export const MARGIN = space.frameMargin1080p;

export const EASE_OUT = motion.easeOut as [number, number, number, number];
export const EASE_IN_OUT = motion.easeInOut as [number, number, number, number];
