import React from "react";
import { useCurrentFrame } from "remotion";
import { color, dur, FONT_SANS, progress, type } from "../theme";

type Size = "hero" | "heading" | "text";

const sizes: Record<Size, React.CSSProperties> = {
  hero: {
    fontSize: type.hero,
    letterSpacing: type.trackingHero,
    lineHeight: type.leadingTight,
  },
  heading: {
    fontSize: type.heading,
    letterSpacing: type.trackingHeading,
    lineHeight: type.leadingHeading,
  },
  text: {
    fontSize: type.text,
    letterSpacing: type.trackingHeading,
    lineHeight: type.leadingHeading,
  },
};

type Props = {
  size: Size;
  children: React.ReactNode;
  /** Frame at which the line enters (fade + 16px rise, ease-out). */
  enterAt?: number;
  /** Optional frame at which the line exits (fade, ease-in). */
  exitAt?: number;
  muted?: boolean;
  accent?: boolean;
  style?: React.CSSProperties;
};

/** Flush-left Inter Medium line. Three sizes only. */
export const Line: React.FC<Props> = ({
  size,
  children,
  enterAt = 0,
  exitAt,
  muted = false,
  accent = false,
  style,
}) => {
  const frame = useCurrentFrame();
  const enter = progress(frame, enterAt, dur.base);
  const exit = exitAt === undefined ? 0 : progress(frame, exitAt, dur.fast);
  const opacity = enter * (1 - exit);

  return (
    <div
      style={{
        fontFamily: FONT_SANS,
        fontWeight: 500,
        color: accent ? color.accent : muted ? color.gray500 : color.ink,
        opacity,
        transform: `translateY(${(1 - enter) * 16}px)`,
        whiteSpace: "pre-line",
        ...sizes[size],
        ...style,
      }}
    >
      {children}
    </div>
  );
};
