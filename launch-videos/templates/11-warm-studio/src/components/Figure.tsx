import React from "react";
import { Img, staticFile } from "remotion";
import { color, radius, shadow } from "../tokens";

export type Layer = {
  /** Path under launch-videos/assets, e.g. "screens/devin-web-1.png". */
  src: string;
  opacity?: number;
};

type FigureProps = {
  /** Display width in px. Height follows the source aspect ratio. */
  width: number;
  /** Source aspect ratio (w / h) so every layer is laid out identically. */
  aspect: number;
  layers: Layer[];
  /** Uniform scale applied to the image stack (push-in). */
  scale?: number;
  /** Pan of the image stack in px at display size. */
  x?: number;
  y?: number;
  /** Anchor for the scale, as CSS transform-origin. */
  origin?: string;
  children?: React.ReactNode;
  style?: React.CSSProperties;
};

/**
 * A soft, rounded product frame. Screenshots keep their aspect ratio; motion
 * is applied to the inner stack so the frame itself never moves.
 */
export const Figure: React.FC<FigureProps> = ({
  width,
  aspect,
  layers,
  scale = 1,
  x = 0,
  y = 0,
  origin = "50% 50%",
  children,
  style,
}) => {
  const height = Math.round(width / aspect);
  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius.md,
        overflow: "hidden",
        background: color.white,
        boxShadow: `${shadow.soft}, 0 0 0 1px ${color.border}`,
        position: "relative",
        ...style,
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          transform: `translate(${x}px, ${y}px) scale(${scale})`,
          transformOrigin: origin,
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
              display: "block",
              opacity: layer.opacity ?? 1,
            }}
          />
        ))}
        {children}
      </div>
    </div>
  );
};

/** Aspect ratios of the screenshot groups (see assets/screens/MANIFEST.md). */
export const ASPECT = {
  web: 2990 / 1624,
  webDark: 2978 / 1620,
  ipad: 2982 / 1626,
  chat: 2982 / 1620,
  desktopWide: 3024 / 1898,
};
