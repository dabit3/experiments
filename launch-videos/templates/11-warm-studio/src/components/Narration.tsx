import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { dur, easeIn } from "../tokens";
import { Headline } from "./Text";
import { fadeIn, rise } from "./motion";

export type Beat = {
  /** Frame (relative to the scene) at which this line takes over. */
  at: number;
  text: React.ReactNode;
};

type NarrationProps = {
  beats: Beat[];
  size?: "hero" | "h1" | "h2" | "h3";
  align?: "left" | "center";
  maxWidth?: number;
  style?: React.CSSProperties;
};

/**
 * One line of narration at a time. When the next beat starts, the current
 * line eases out (300ms) and the new one eases in with a gentle rise.
 */
export const Narration: React.FC<NarrationProps> = ({
  beats,
  size = "h2",
  align = "left",
  maxWidth = 1100,
  style,
}) => {
  const frame = useCurrentFrame();
  return (
    <div style={{ position: "relative", width: maxWidth, textAlign: align, ...style }}>
      {beats.map((beat, i) => {
        const next = beats[i + 1];
        const out = next
          ? interpolate(frame, [next.at - dur.fast, next.at], [1, 0], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
              easing: easeIn,
            })
          : 1;
        const opacity = Math.min(fadeIn(frame, beat.at), out);
        if (opacity <= 0) return null;
        return (
          <Headline
            key={i}
            size={size}
            style={{
              position: i === 0 ? "relative" : "absolute",
              top: 0,
              left: 0,
              right: 0,
              opacity,
              transform: `translateY(${rise(frame, beat.at)}px)`,
            }}
          >
            {beat.text}
          </Headline>
        );
      })}
    </div>
  );
};
