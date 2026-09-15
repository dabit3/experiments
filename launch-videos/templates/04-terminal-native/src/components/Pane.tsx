import React from "react";
import { Easing, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { color, easeIn, easeInOut, easeOut, radius, space, terminal, VIDEO } from "../tokens";

export type Rect = { x: number; y: number; w: number; h: number };

/** Docked position inside the terminal body, right-aligned, screenshot aspect (~1.84). */
export const DOCKED: Rect = (() => {
  const w = 880;
  const h = Math.round(w / 1.84);
  return {
    x: terminal.margin + terminal.width - terminal.padX - w,
    y: terminal.margin + terminal.titleBar + terminal.padY,
    w,
    h,
  };
})();

/** Expanded position: full width minus the safe-area inset, screenshot aspect, so
 *  no UI text is cropped at the frame edge. */
export const FULL: Rect = (() => {
  const w = VIDEO.width - space.safeAreaInset1080p * 2;
  const h = Math.round(w / 1.84);
  return { x: space.safeAreaInset1080p, y: Math.round((VIDEO.height - h) / 2), w, h };
})();

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

export const EXPAND_FRAMES = 26;
export const ENTER_FRAMES = 18;
export const EXIT_FRAMES = 12;
const XFADE = 10;

/**
 * An embedded "screen recording" pane: enters docked (fade + scale), expands to
 * full frame (ease-in-out), cross-fades between sequential screenshots and keeps a
 * slow push-in going for its whole life so nothing is ever static.
 */
export const Pane: React.FC<{
  shots: string[];
  enterAt: number;
  expandAt: number;
  exitAt: number;
  /** Where the push-in starts / ends (scale). */
  push?: [number, number];
  children?: React.ReactNode;
}> = ({ shots, enterAt, expandAt, exitAt, push = [1, 1.06], children }) => {
  const frame = useCurrentFrame();
  if (frame < enterAt || frame > exitAt + EXIT_FRAMES) return null;

  const enter = interpolate(frame, [enterAt, enterAt + ENTER_FRAMES], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeOut),
  });
  const exit = interpolate(frame, [exitAt, exitAt + EXIT_FRAMES], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeIn),
  });
  const t = interpolate(frame, [expandAt, expandAt + EXPAND_FRAMES], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...easeInOut),
  });

  const rect: Rect = {
    x: lerp(DOCKED.x, FULL.x, t),
    y: lerp(DOCKED.y, FULL.y, t),
    w: lerp(DOCKED.w, FULL.w, t),
    h: lerp(DOCKED.h, FULL.h, t),
  };
  const r = radius.md;
  const zoom = interpolate(frame, [enterAt, exitAt], push, {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const segment = (exitAt - enterAt) / shots.length;

  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: rect.w,
        height: rect.h,
        borderRadius: r,
        overflow: "hidden",
        backgroundColor: color.darkSurface,
        boxShadow: `0 0 0 1px ${color.darkBorder}`,
        opacity: enter * exit,
        transform: `scale(${lerp(0.97, 1, enter)})`,
        transformOrigin: "50% 50%",
      }}
    >
      {shots.map((shot, i) => {
        const start = enterAt + segment * i;
        const opacity =
          i === 0
            ? 1
            : interpolate(frame, [start - XFADE / 2, start + XFADE / 2], [0, 1], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              });
        return (
          <Img
            key={shot}
            src={staticFile(`screens/${shot}.png`)}
            style={{
              position: "absolute",
              inset: 0,
              width: "100%",
              height: "100%",
              objectFit: "cover",
              objectPosition: "0% 0%",
              opacity,
              transform: `scale(${zoom})`,
              transformOrigin: "0% 0%",
            }}
          />
        );
      })}
      {children}
    </div>
  );
};
