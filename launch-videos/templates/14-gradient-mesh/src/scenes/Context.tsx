import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { sec } from "../tokens";
import { Headline, SceneFade, useRise } from "../ui";

const lines = [
  { text: "Before, iOS teams QA'd by hand —", at: 0 },
  { text: "or waited 20+ minutes for CI.", at: sec(1.4) },
  { text: "No coding agent could tap through an iPhone app.", at: sec(3.3) },
];

const Line: React.FC<{ text: string; at: number; end: number; y: number }> = ({ text, at, end, y }) => {
  const frame = useCurrentFrame();
  const rise = useRise(at, end);
  if (frame < at || frame > end) return null;
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: y, ...rise }}>
      <Headline size="h1" style={{ margin: "0 auto" }} maxWidth={1500}>
        {text}
      </Headline>
    </div>
  );
};

/** Problem / context: two paired lines, then one. */
export const Context: React.FC = () => {
  const { durationInFrames } = useVideoConfig();
  const end = durationInFrames;
  return (
    <SceneFade>
      <AbsoluteFill>
        <Line text={lines[0].text} at={lines[0].at} end={lines[2].at - 4} y={430} />
        <Line text={lines[1].text} at={lines[1].at} end={lines[2].at - 4} y={530} />
        <Line text={lines[2].text} at={lines[2].at} end={end} y={480} />
      </AbsoluteFill>
    </SceneFade>
  );
};
