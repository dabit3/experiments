import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { SectionAnchor } from "./SectionAnchor";
import { sceneOpacity } from "../theme";

type Props = {
  number: string;
  title: string;
  children: React.ReactNode;
};

/** Scene shell: section anchor + scene-level fade in/out. */
export const Scene: React.FC<Props> = ({ number, title, children }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  return (
    <AbsoluteFill style={{ opacity: sceneOpacity(frame, durationInFrames) }}>
      <SectionAnchor number={number} title={title} />
      {children}
    </AbsoluteFill>
  );
};
