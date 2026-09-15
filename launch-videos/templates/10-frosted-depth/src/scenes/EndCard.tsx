import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { SceneFrame } from "../components/SceneFrame";
import { Glass } from "../components/Glass";
import { color, fontMono, fontSans, type } from "../tokens";
import { enter } from "../lib/motion";

const W = 620;
const H = 240;

export const EndCard: React.FC<{ sceneFrom: number }> = ({ sceneFrom }) => {
  const frame = useCurrentFrame();
  const tile = enter(frame, 0, 30);
  const line = enter(frame, 16, 28);
  const url = enter(frame, 30, 28);
  return (
    <SceneFrame>
      <Glass
        x={(1920 - W) / 2}
        y={330}
        width={W}
        height={H}
        depth={1}
        sceneFrom={sceneFrom}
        opacity={tile}
        transform={`translateY(${(1 - tile) * 30}px)`}
      >
        <Img
          src={staticFile("brand/devin-lockup-horizontal-white.png")}
          style={{ position: "absolute", left: (W - 440) / 2, top: (H - 151) / 2, width: 440, height: 151 }}
        />
      </Glass>
      <div
        style={{
          position: "absolute",
          left: 120,
          top: 640,
          width: 1680,
          textAlign: "center",
          fontFamily: fontSans,
          fontWeight: type.weights.medium,
          fontSize: type.sizes1080p.h3,
          letterSpacing: type.tracking.heading,
          color: color.offWhite,
          opacity: line,
          transform: `translateY(${(1 - line) * 24}px)`,
        }}
      >
        Build, run and test iOS apps in the cloud.
      </div>
      <div
        style={{
          position: "absolute",
          left: 120,
          top: 716,
          width: 1680,
          textAlign: "center",
          fontFamily: fontMono,
          fontSize: type.sizes1080p.label,
          letterSpacing: type.tracking.caps,
          textTransform: "uppercase",
          color: color.gray400,
          opacity: url,
        }}
      >
        devin.ai
      </div>
    </SceneFrame>
  );
};
