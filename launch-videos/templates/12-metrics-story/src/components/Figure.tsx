import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { easeInOut, easeOut, tween } from "../anim";
import { color, radius, shadow } from "../tokens";

export type Shot = {
  /** Path under launch-videos/assets, e.g. "screens/devin-web-4.png" */
  src: string;
  /** Frame (relative to the Figure) at which this shot starts fading in. */
  from: number;
  /** Cross-fade length in frames. */
  fade?: number;
  /** Vertical offset of the image inside the mask, px, start → end. */
  offsetY?: [number, number];
  /** Push-in scale, start → end. */
  scale?: [number, number];
  /** Transform origin of the push-in. */
  origin?: string;
  /** Overlay rendered in image space (e.g. a cursor). */
  overlay?: React.ReactNode;
};

/**
 * Masked screenshot "proof" panel. The mask sits below the stat; the
 * image inside can pan (offsetY) and push in (scale) so nothing is static.
 */
export const Figure: React.FC<{
  x: number;
  y: number;
  width: number;
  height: number;
  shots: Shot[];
  dark?: boolean;
  enter?: number;
}> = ({ x, y, width, height, shots, dark = false, enter = 0 }) => {
  const frame = useCurrentFrame();
  const appear = tween(frame, enter, 20, easeOut);

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        height,
        borderRadius: radius.md,
        overflow: "hidden",
        backgroundColor: dark ? color.darkSurface : color.white,
        boxShadow: dark ? shadow.dark : shadow.figure,
        outline: `1px solid ${dark ? color.darkBorder : color.border}`,
        opacity: appear,
        transform: `scale(${0.985 + 0.015 * appear})`,
        transformOrigin: "50% 0%",
      }}
    >
      {shots.map((shot, i) => {
        const next = shots[i + 1];
        const fadeIn = i === 0 ? 1 : tween(frame, shot.from, shot.fade ?? 18, easeInOut);
        const fadeOut = next ? tween(frame, next.from, next.fade ?? 18, easeInOut, 1, 0) : 1;
        const opacity = Math.min(fadeIn, fadeOut);
        if (opacity <= 0) return null;

        const end = next ? next.from + (next.fade ?? 18) : shot.from + 400;
        const span = Math.max(1, end - shot.from);
        const [y0, y1] = shot.offsetY ?? [0, 0];
        const [s0, s1] = shot.scale ?? [1, 1];
        const oy = tween(frame, shot.from, span, easeInOut, y0, y1);
        const sc = tween(frame, shot.from, span, easeInOut, s0, s1);

        return (
          <div
            key={shot.src + i}
            style={{
              position: "absolute",
              inset: 0,
              opacity,
            }}
          >
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                width,
                transform: `translateY(${oy}px) scale(${sc})`,
                transformOrigin: shot.origin ?? "50% 0%",
              }}
            >
              <Img
                src={staticFile(shot.src)}
                style={{ width, display: "block" }}
              />
              {shot.overlay}
            </div>
          </div>
        );
      })}
    </div>
  );
};
