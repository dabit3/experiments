import { createContext, useContext } from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadGeistMono } from "@remotion/google-fonts/GeistMono";
import tokens from "../../../assets/tokens.json";

const inter = loadInter("normal", { weights: ["400", "500"], subsets: ["latin"] });
const geistMono = loadGeistMono("normal", { weights: ["400", "500"], subsets: ["latin"] });

export const color = tokens.color;
export const radius = tokens.radius;
export const shadow = tokens.shadow;
export const type = tokens.type;
export const MARGIN = tokens.space.frameMargin1080p;

export const font = {
  sans: `${inter.fontFamily}, ${type.body}`,
  mono: `${geistMono.fontFamily}, ${type.mono}`,
};

const bez = (c: number[]) => Easing.bezier(c[0], c[1], c[2], c[3]);

export const easeOut = bez(tokens.motion.easeOut);
export const easeInOut = bez(tokens.motion.easeInOut);
// Mirror of the ease-out curve, used for exits (tokens.json only ships out / in-out).
export const easeIn = Easing.bezier(0.7, 0, 0.84, 0);

/** 0 → 1 over [start, start + dur], clamped. */
export const ramp = (
  frame: number,
  start: number,
  dur: number,
  easing: (t: number) => number = easeOut,
) =>
  interpolate(frame, [start, start + dur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

/**
 * All timing in this template is expressed in absolute composition frames (see scenes.ts).
 * <Seq> (components.tsx) is a <Sequence> that also publishes its offset so useFrame() returns absolute frames.
 */
export const OffsetCtx = createContext(0);

export const useFrame = () => useCurrentFrame() + useContext(OffsetCtx);
