import React from "react";
import {
  AbsoluteFill,
  Easing,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { SANS } from "../fonts";
import { color, EASE_OUT, MARGIN, type, WIDTH } from "../tokens";

export type WordTone = "dark" | "light" | "accent";

const TONES: Record<WordTone, { bg: string; fg: string; muted: string }> = {
  dark: { bg: color.darkBg, fg: color.white, muted: color.gray400 },
  light: { bg: color.white, fg: color.ink, muted: color.gray500 },
  accent: { bg: color.accent, fg: color.white, muted: color.accentSoft },
};

type Props = {
  /** Main line(s). A string[] renders one line per entry (max two). */
  text: string | string[];
  /** Small supporting line under the headline (optional). */
  sub?: string;
  tone?: WordTone;
  size?: number;
  align?: "left" | "center";
  /** Frames for the slam-in. */
  inFrames?: number;
  /** Continuous drift scale over the hold (1 = none). */
  drift?: number;
  /** Word rendered in the accent colour (matched by exact token). */
  highlight?: string;
};

/**
 * One kinetic-type "beat": a headline slams in (scale + opacity, ease-out) and holds with a
 * barely-perceptible drift. Exits are hard cuts, so there is no exit animation.
 */
export const Word: React.FC<Props> = ({
  text,
  sub,
  tone = "dark",
  size,
  align = "left",
  inFrames = 6,
  drift = 1.025,
  highlight,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const t = TONES[tone];
  const lines = Array.isArray(text) ? text : [text];
  const maxWidth = WIDTH - MARGIN * 2;
  // Auto-fit: Inter Medium with tight tracking averages ~0.47em per character;
  // the extra headroom absorbs the 1.12x entrance scale.
  const longest = Math.max(...lines.map((l) => l.length));
  const fontSize = size ?? Math.min(180, Math.floor(maxWidth / (longest * 0.54)));

  const enter = interpolate(frame, [0, inFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...EASE_OUT),
  });
  const slam = interpolate(enter, [0, 1], [1.12, 1]);
  const hold = interpolate(frame, [0, Math.max(durationInFrames, 1)], [1, drift], {
    extrapolateRight: "clamp",
  });
  const opacity = interpolate(enter, [0, 0.5], [0.35, 1], {
    extrapolateRight: "clamp",
  });

  const renderLine = (line: string) =>
    line.split(" ").map((w, i) => {
      const isHi = highlight !== undefined && w.replace(/[.,]/g, "") === highlight;
      return (
        <React.Fragment key={i}>
          {i > 0 ? " " : null}
          <span style={{ color: isHi ? (tone === "accent" ? t.fg : color.accent) : undefined }}>
            {w}
          </span>
        </React.Fragment>
      );
    });

  return (
    <AbsoluteFill style={{ backgroundColor: t.bg }}>
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          right: MARGIN,
          top: 0,
          bottom: 0,
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: align === "center" ? "center" : "flex-start",
          textAlign: align,
          transform: `scale(${slam * hold})`,
          transformOrigin: align === "center" ? "50% 50%" : "0% 50%",
          opacity,
        }}
      >
        <div
          style={{
            fontFamily: SANS,
            fontWeight: type.weights.medium,
            fontSize,
            lineHeight: type.leading.tight,
            letterSpacing: type.tracking.hero,
            color: t.fg,
            maxWidth,
            whiteSpace: "nowrap",
          }}
        >
          {lines.map((l, i) => (
            <div key={i}>{renderLine(l)}</div>
          ))}
        </div>
        {sub ? (
          <div
            style={{
              marginTop: 40,
              fontFamily: SANS,
              fontWeight: type.weights.regular,
              fontSize: type.sizes1080p.h3,
              lineHeight: type.leading.heading,
              letterSpacing: type.tracking.body,
              color: t.muted,
              maxWidth,
            }}
          >
            {sub}
          </div>
        ) : null}
      </div>
    </AbsoluteFill>
  );
};
