import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { sans } from "../fonts";
import { color, easeOut, type } from "../tokens";
import { useWindowOpacity } from "./Fade";

type Size = "hero" | "h1" | "h2" | "h3";

type Props = {
  children: React.ReactNode;
  size?: Size;
  /** Frame (relative to the scene) at which the line appears. */
  from?: number;
  /** Frame at which the line has fully left. Defaults to "never". */
  until?: number;
  /** Vertical position of the text block's centre, in px. */
  y?: number;
  align?: "center" | "left";
  x?: number;
  tone?: "ink" | "muted";
  maxWidth?: number;
};

/**
 * One line (or two) of display copy. Enters with a fade and a 24px rise (ease-out);
 * leaves with a plain fade (ease-in). Two motion types, nothing else.
 */
export const Headline: React.FC<Props> = ({
  children,
  size = "h1",
  from = 0,
  until = Number.POSITIVE_INFINITY,
  y = 540,
  align = "center",
  x = 960,
  tone = "ink",
  maxWidth = 1400,
}) => {
  const frame = useCurrentFrame();
  const opacity = useWindowOpacity(from, until);
  const rise = interpolate(frame, [from, from + 26], [24, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });

  const fontSize = type.sizes1080p[size];
  const tracking = size === "hero" ? type.tracking.hero : type.tracking.heading;

  return (
    <div
      style={{
        position: "absolute",
        top: y,
        left: align === "center" ? x - maxWidth / 2 : x,
        width: maxWidth,
        transform: `translateY(calc(-50% + ${rise}px))`,
        opacity,
        fontFamily: sans,
        fontSize,
        fontWeight: type.weights.medium,
        letterSpacing: tracking,
        lineHeight: type.leading.heading,
        color: tone === "ink" ? color.ink : color.gray500,
        textAlign: align,
        whiteSpace: "pre-line",
        textWrap: "balance",
      }}
    >
      {children}
    </div>
  );
};
