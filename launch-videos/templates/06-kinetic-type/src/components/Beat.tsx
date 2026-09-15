import React from "react";
import { Sequence } from "remotion";
import { beats } from "../tokens";

type Props = {
  /** Start offset within the scene, in beats. */
  at: number;
  /** Length, in beats. */
  len: number;
  children: React.ReactNode;
};

/** A <Sequence> addressed in beats instead of frames. Hard in / hard out. */
export const Beat: React.FC<Props> = ({ at, len, children }) => (
  <Sequence from={beats(at)} durationInFrames={beats(len)} layout="none">
    {children}
  </Sequence>
);
