import React from "react";
import { useCurrentFrame } from "remotion";
import { glass, radius } from "../tokens";
import { parallax } from "../lib/motion";

type Props = {
  x: number;
  y: number;
  width: number;
  height: number;
  /** 0 = far back, 1 = front. Drives parallax amplitude and material strength. */
  depth: number;
  /** Absolute frame offset of the enclosing Sequence so parallax is continuous across scenes. */
  sceneFrom: number;
  opacity?: number;
  /** Extra transform applied after parallax (entrances). */
  transform?: string;
  padding?: number;
  children?: React.ReactNode;
  style?: React.CSSProperties;
};

/**
 * Frosted-glass card. Light source is top-left: a 1px highlight along the top and left edges,
 * a soft inner sheen in the top-left corner, and a shadow cast toward the bottom-right.
 */
export const Glass: React.FC<Props> = ({
  x,
  y,
  width,
  height,
  depth,
  sceneFrom,
  opacity = 1,
  transform = "",
  padding = 0,
  children,
  style,
}) => {
  const frame = useCurrentFrame();
  const p = parallax(frame + sceneFrom, depth);
  const front = depth >= 0.9;
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width,
        height,
        padding,
        boxSizing: "border-box",
        borderRadius: radius.lg,
        background: front ? glass.bgFront : glass.bg,
        backdropFilter: `blur(${glass.blur}px) saturate(1.3)`,
        WebkitBackdropFilter: `blur(${glass.blur}px) saturate(1.3)`,
        border: `1px solid ${glass.border}`,
        boxShadow: [
          `inset 1px 1px 0 ${glass.highlight}`,
          `inset -1px -1px 0 rgba(255,255,255,0.04)`,
          front ? glass.shadowFront : glass.shadow,
        ].join(","),
        backgroundImage: `linear-gradient(135deg, rgba(255,255,255,${front ? 0.14 : 0.1}) 0%, rgba(255,255,255,0) 45%)`,
        opacity,
        transform: `translate(${p.x}px, ${p.y}px) ${transform}`,
        overflow: "hidden",
        ...style,
      }}
    >
      {children}
    </div>
  );
};
