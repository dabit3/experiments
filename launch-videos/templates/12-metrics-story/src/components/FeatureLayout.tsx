import React from "react";
import { MARGIN } from "../tokens";
import { Figure, Shot } from "./Figure";
import { SceneFade, Fade } from "./SceneFade";
import { MonoLabel, Narration } from "./Text";

export const FIGURE = {
  x: MARGIN,
  y: 392,
  width: 1920 - MARGIN * 2,
  height: 1080 - 392 + 40, // bleeds off the bottom edge on purpose
};

/**
 * Shared "stat above, proof beneath" layout used by every feature moment.
 * Left: animated numeral + mono label. Right: one narration line (≤2 lines).
 * Below: the masked screenshot figure.
 */
export const FeatureLayout: React.FC<{
  stat: React.ReactNode;
  label: React.ReactNode;
  narration: React.ReactNode;
  shots: Shot[];
  dark?: boolean;
  labelColor?: string;
  textColor?: string;
}> = ({ stat, label, narration, shots, dark = false, labelColor, textColor }) => (
  <SceneFade background={dark ? "#121111" : undefined}>
    <div style={{ position: "absolute", left: MARGIN, top: MARGIN - 8 }}>
      {stat}
      <Fade start={10} style={{ marginTop: 20 }}>
        <MonoLabel color={labelColor}>{label}</MonoLabel>
      </Fade>
    </div>
    <div style={{ position: "absolute", right: MARGIN, top: MARGIN + 4, width: 780 }}>
      <Fade start={14}>
        <Narration color={textColor} maxWidth={780}>
          {narration}
        </Narration>
      </Fade>
    </div>
    <Figure {...FIGURE} shots={shots} dark={dark} enter={6} />
  </SceneFade>
);
