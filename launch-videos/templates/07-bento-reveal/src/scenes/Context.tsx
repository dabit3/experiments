import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { copy } from "../content";
import { color, easeIn, easeOut, fontSans, type } from "../tokens";

const IN = 28;
const OUT = 14;

const Line: React.FC<{ text: string; from: number; to: number; frame: number }> = ({ text, from, to, frame }) => {
  const inO = interpolate(frame, [from, from + IN], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const outO = interpolate(frame, [to - OUT, to], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeIn,
  });
  const opacity = Math.min(inO, outO);
  if (opacity <= 0) return null;
  return (
    <div
      style={{
        position: "absolute",
        width: 1400,
        textAlign: "center",
        fontFamily: fontSans,
        fontSize: type.sizes1080p.h2,
        fontWeight: 500,
        letterSpacing: type.tracking.heading,
        lineHeight: type.leading.heading,
        color: color.ink,
        opacity,
        transform: `translateY(${(1 - inO) * 20}px)`,
      }}
    >
      {text}
    </div>
  );
};

// Two ideas, one at a time.
export const Context: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const half = Math.round(durationInFrames * 0.5);
  return (
    <AbsoluteFill style={{ background: color.paper, alignItems: "center", justifyContent: "center" }}>
      <Line text={copy.context1} from={0} to={half} frame={frame} />
      <Line text={copy.context2} from={half} to={durationInFrames} frame={frame} />
    </AbsoluteFill>
  );
};
