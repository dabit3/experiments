import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { dur, MARGIN } from "../tokens";
import { Card, Cursor, CursorKey, Headline, Label, SceneFade, Shot, ShotStack, useRise } from "../ui";

export type Line = { text: string; at: number };

type Props = {
  index: string;
  label: string;
  lines: Line[];
  shots: Shot[];
  cursor?: CursorKey[];
  zoom?: [number, number];
};

const NarrationLine: React.FC<{ line: Line; end: number }> = ({ line, end }) => {
  const frame = useCurrentFrame();
  const rise = useRise(line.at, end);
  if (frame < line.at || frame > end) return null;
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: 0, ...rise }}>
      <Headline size="h2" style={{ margin: "0 auto" }} maxWidth={1300}>
        {line.text}
      </Headline>
    </div>
  );
};

/** One product feature: mono index + label, narration line(s), white card with animated screenshots. */
export const Feature: React.FC<Props> = ({ index, label, lines, shots, cursor, zoom }) => {
  const { durationInFrames } = useVideoConfig();
  const labelRise = useRise(0, undefined, dur.base);
  return (
    <SceneFade>
      <AbsoluteFill>
        <div style={{ position: "absolute", left: 0, right: 0, top: MARGIN - 16, display: "flex", justifyContent: "center", ...labelRise }}>
          <Label>
            {index} — {label}
          </Label>
        </div>
        <div style={{ position: "absolute", left: MARGIN, right: MARGIN, top: MARGIN + 30, height: 130 }}>
          {lines.map((l, i) => {
            const next = lines[i + 1];
            const end = next ? next.at + 3 : durationInFrames;
            return <NarrationLine key={l.text} line={l} end={end} />;
          })}
        </div>
        <Card enter={dur.fast}>
          <ShotStack shots={shots} zoom={zoom} />
          {cursor ? <Cursor keys={cursor} /> : null}
        </Card>
      </AbsoluteFill>
    </SceneFade>
  );
};
