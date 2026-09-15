import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { color, dur, grid, progress, radius } from "../theme";

export type Layer = {
  src: string;
  /** Opacity 0–1 for cross-fades between sequential screenshots. */
  opacity?: number;
  /** Per-layer static crop, e.g. `zoom(1.3, 0.5, 0.6)` to enlarge a sparse UI. */
  zoom?: { scale: number; originX: number; originY: number };
};

/** Maps a fraction of the un-zoomed image to a fraction of the zoomed layer. */
export const zoomed = (p: number, origin: number, scale: number) => origin + (p - origin) * scale;

type Props = {
  /** 0-based first column and column span the figure snaps to. */
  col: number;
  span: number;
  /** Top edge in px. Height follows the screenshot aspect ratio. */
  top: number;
  aspect: number;
  layers: Layer[];
  /** Frame at which the figure enters. */
  enterAt?: number;
  /** Ken Burns: scale + origin (fractions) applied to all layers. */
  scale?: number;
  originX?: number;
  originY?: number;
  children?: React.ReactNode;
};

/** A screenshot snapped to grid columns. Enters with a fade + short rise, no overshoot. */
export const Figure: React.FC<Props> = ({
  col,
  span,
  top,
  aspect,
  layers,
  enterAt = 0,
  scale = 1,
  originX = 0.5,
  originY = 0.5,
  children,
}) => {
  const frame = useCurrentFrame();
  const enter = progress(frame, enterAt, dur.slow);
  const width = grid.span(span);
  const height = width / aspect;

  return (
    <div
      style={{
        position: "absolute",
        left: grid.x(col),
        top,
        width,
        height,
        opacity: enter,
        transform: `translateY(${(1 - enter) * 40}px)`,
        borderRadius: radius.md,
        border: `1px solid ${color.border}`,
        overflow: "hidden",
        background: color.white,
        boxShadow: `0 0 8px ${color.gray300}`,
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          transform: `scale(${scale})`,
          transformOrigin: `${originX * 100}% ${originY * 100}%`,
        }}
      >
        {layers.map((layer) => (
          <Img
            key={layer.src}
            src={staticFile(layer.src)}
            style={{
              position: "absolute",
              inset: 0,
              width: "100%",
              height: "100%",
              objectFit: "cover",
              opacity: layer.opacity ?? 1,
              transform: layer.zoom ? `scale(${layer.zoom.scale})` : undefined,
              transformOrigin: layer.zoom ? `${layer.zoom.originX * 100}% ${layer.zoom.originY * 100}%` : undefined,
            }}
          />
        ))}
        {children}
      </div>
    </div>
  );
};
