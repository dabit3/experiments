import React from "react";
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { MONO } from "../fonts";
import { color, EASE_IN_OUT, EASE_OUT, HEIGHT, MARGIN, type, WIDTH } from "../tokens";

/** A 16:9 crop window in source-image pixels. Height is derived from width. */
export type Crop = { x: number; y: number; w: number };

export type ShotProps = {
  /** Path relative to the shared assets public dir, e.g. "screens/devin-web-4.png". */
  src: string;
  /** Natural size of the source PNG (used to clamp the crop). */
  imgW: number;
  imgH: number;
  /** Crop at the first and last frame; interpolated with ease-in-out (push-in / pan). */
  from: Crop;
  to?: Crop;
  /** Short narration label pinned to the bottom-left. */
  label?: string;
  /** Optional overlay in source-image coordinate space (cursor, tap ring…). */
  children?: React.ReactNode;
};

const clampCrop = (c: Crop, imgW: number, imgH: number): Required<Crop> & { h: number } => {
  const w = Math.min(c.w, imgW);
  const h = (w * HEIGHT) / WIDTH;
  const x = Math.min(Math.max(c.x, 0), imgW - w);
  const y = Math.min(Math.max(c.y, 0), Math.max(imgH - h, 0));
  return { x, y, w, h };
};

/**
 * Full-bleed UI insert. The screenshot is never stretched: a 16:9 window is cut out of the
 * source and scaled uniformly to fill the frame. Motion is a single ease-in-out move of that
 * window (push-in or pan), plus a fast ease-out fade on the label.
 */
export const Shot: React.FC<ShotProps> = ({ src, imgW, imgH, from, to, label, children }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const a = clampCrop(from, imgW, imgH);
  const b = clampCrop(to ?? from, imgW, imgH);
  const p = interpolate(frame, [0, durationInFrames - 1], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...EASE_IN_OUT),
  });
  const w = a.w + (b.w - a.w) * p;
  const x = a.x + (b.x - a.x) * p;
  const y = a.y + (b.y - a.y) * p;
  const scale = WIDTH / w;

  const labelIn = interpolate(frame, [2, 8], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...EASE_OUT),
  });

  return (
    <AbsoluteFill style={{ backgroundColor: color.darkBg, overflow: "hidden" }}>
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          width: imgW,
          height: imgH,
          transform: `translate(${-x * scale}px, ${-y * scale}px) scale(${scale})`,
          transformOrigin: "0 0",
        }}
      >
        <Img
          src={staticFile(src)}
          style={{ width: imgW, height: imgH, display: "block" }}
        />
        {children}
      </div>
      {label ? (
        <div
          style={{
            position: "absolute",
            left: MARGIN,
            bottom: MARGIN - 40,
            padding: "14px 20px",
            backgroundColor: color.ink,
            color: color.white,
            fontFamily: MONO,
            fontWeight: type.weights.medium,
            fontSize: type.sizes1080p.caption,
            letterSpacing: type.tracking.caps,
            textTransform: "uppercase",
            borderRadius: 2,
            opacity: labelIn,
            transform: `translateY(${(1 - labelIn) * 12}px)`,
          }}
        >
          {label}
        </div>
      ) : null}
    </AbsoluteFill>
  );
};
