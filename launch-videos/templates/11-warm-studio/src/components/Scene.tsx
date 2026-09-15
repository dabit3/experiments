import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { MARGIN, color } from "../tokens";
import { sceneOpacity } from "./motion";

type SceneProps = {
  children: React.ReactNode;
  background?: string;
  /** Small Devin lockup pinned top-right. Off for the end card, which carries the big one. */
  logo?: boolean;
};

const LOGO_WIDTH = 150;

/** Full-frame scene that fades itself in (ease-out) and out (ease-in). */
export const Scene: React.FC<SceneProps> = ({ children, background = color.paper, logo = true }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  return (
    <AbsoluteFill style={{ background, opacity: sceneOpacity(frame, durationInFrames) }}>
      {children}
      {logo && (
        <Img
          src={staticFile("brand/devin-lockup-horizontal-black.png")}
          style={{
            position: "absolute",
            top: 64,
            right: MARGIN,
            width: LOGO_WIDTH,
            height: Math.round((LOGO_WIDTH * 1024) / 2984),
            display: "block",
          }}
        />
      )}
    </AbsoluteFill>
  );
};
