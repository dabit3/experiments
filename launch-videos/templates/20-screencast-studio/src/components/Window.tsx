import React from "react";
import { Img, staticFile } from "remotion";
import { SANS } from "../fonts";
import {
  CONTENT_H,
  OVERSCAN,
  sx,
  sy,
  TITLEBAR_H,
  WINDOW_H,
  WINDOW_W,
  WINDOW_X,
  WINDOW_Y,
  Zoom,
} from "../layout";
import { color, radius, shadow } from "../tokens";

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

/**
 * Screen-recorder style zoom: scale the content about the click point and pull
 * that point toward the centre of the window, clamped so the content always
 * covers the frame.
 */
export const zoomTransform = (z: Zoom) => {
  const s = z.scale;
  const tx = clamp(WINDOW_W / 2 - s * sx(z.x) * WINDOW_W, WINDOW_W - s * WINDOW_W, 0);
  const ty = clamp(CONTENT_H / 2 - s * sy(z.y) * CONTENT_H, CONTENT_H - s * CONTENT_H, 0);
  return `translate(${tx}px, ${ty}px) scale(${s})`;
};

export const Screen: React.FC<{ src: string; opacity?: number }> = ({ src, opacity = 1 }) => (
  <Img
    src={staticFile(`screens/${src}.png`)}
    style={{
      position: "absolute",
      left: (WINDOW_W * (1 - OVERSCAN)) / 2,
      top: 0,
      width: WINDOW_W * OVERSCAN,
      height: CONTENT_H * OVERSCAN,
      objectFit: "cover",
      objectPosition: "top center",
      opacity,
    }}
  />
);

type Props = {
  zoom: Zoom;
  /** whole-window transform (entrance / exit / press) */
  scale?: number;
  y?: number;
  opacity?: number;
  press?: number;
  title?: string;
  children?: React.ReactNode;
};

export const Window: React.FC<Props> = ({
  zoom,
  scale = 1,
  y = 0,
  opacity = 1,
  press = 0,
  title = "app.devin.ai",
  children,
}) => {
  const windowScale = scale * (1 - press * 0.006);
  return (
    <div
      style={{
        position: "absolute",
        left: WINDOW_X,
        top: WINDOW_Y,
        width: WINDOW_W,
        height: WINDOW_H,
        transform: `translateY(${y}px) scale(${windowScale})`,
        transformOrigin: "50% 50%",
        opacity,
        borderRadius: radius.md,
        backgroundColor: color.white,
        boxShadow: `${shadow.soft}, 0 0 0 1px rgba(25,25,25,0.06)`,
        overflow: "hidden",
      }}
    >
      <div
        style={{
          height: TITLEBAR_H,
          display: "flex",
          alignItems: "center",
          padding: "0 16px",
          borderBottom: `1px solid ${color.border}`,
          backgroundColor: color.offWhite,
          position: "relative",
        }}
      >
        <div style={{ display: "flex", gap: 8 }}>
          {["#FF5F57", "#FEBC2E", "#28C840"].map((c) => (
            <div key={c} style={{ width: 12, height: 12, borderRadius: 999, backgroundColor: c }} />
          ))}
        </div>
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            textAlign: "center",
            fontFamily: SANS,
            fontSize: 15,
            fontWeight: 500,
            letterSpacing: "-0.01em",
            color: color.gray500,
          }}
        >
          {title}
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          top: TITLEBAR_H,
          left: 0,
          width: WINDOW_W,
          height: CONTENT_H,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            position: "absolute",
            inset: 0,
            width: WINDOW_W,
            height: CONTENT_H,
            transform: zoomTransform(zoom),
            transformOrigin: "0 0",
          }}
        >
          {children}
        </div>
      </div>
    </div>
  );
};
