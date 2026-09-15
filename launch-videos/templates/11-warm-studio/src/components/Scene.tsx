import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { color } from "../tokens";
import { sceneOpacity } from "./motion";

type SceneProps = {
  children: React.ReactNode;
  background?: string;
};

/** Full-frame scene that fades itself in (ease-out) and out (ease-in). */
export const Scene: React.FC<SceneProps> = ({ children, background = color.paper }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  return (
    <AbsoluteFill style={{ background, opacity: sceneOpacity(frame, durationInFrames) }}>
      {children}
    </AbsoluteFill>
  );
};
